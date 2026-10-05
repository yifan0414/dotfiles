#!/usr/bin/env python3
"""Opt-in, verified Linux Miniforge base installation; never replace a prefix."""

import argparse
import contextlib
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import urllib.request


ARCHITECTURES = ("x86_64", "aarch64", "ppc64le")
MANIFEST = Path(__file__).resolve().parents[1] / "packages/conda/miniforge-release.json"
SOCKET_TIMEOUT = 30
DOWNLOAD_TIMEOUT = 300
INSTALL_TIMEOUT = 1800
CHECK_TIMEOUT = 120
PROCESS_TERMINATION_GRACE = 1
MAX_INSTALLER_BYTES = 512 * 1024 * 1024


class InstallError(Exception):
    def __init__(self, stage, message):
        super().__init__(message)
        self.stage = stage


def supported_system():
    if platform.system() != "Linux":
        raise InstallError("platform", "This optional installation module supports Linux only.")
    machine = platform.machine().lower()
    architecture = {"amd64": "x86_64", "arm64": "aarch64"}.get(machine, machine)
    if architecture not in ARCHITECTURES:
        raise InstallError("architecture", "Supported Linux architectures: x86_64, aarch64, ppc64le.")
    try:
        libc = os.confstr("CS_GNU_LIBC_VERSION") or ""
    except (AttributeError, OSError, ValueError):
        name, version = platform.libc_ver()
        libc = name + " " + version
    match = re.fullmatch(r"glibc\s+(\d+)\.(\d+)(?:\.\d+)?", libc)
    if not match or (int(match[1]), int(match[2])) < (2, 17):
        raise InstallError("glibc", "Miniforge requires Linux with glibc >= 2.17; unknown or musl libc is unsupported.")
    return architecture, libc


def load_asset(architecture):
    try:
        manifest = json.loads(MANIFEST.read_text())
        asset = manifest["assets"][architecture]
        release = manifest["version"]
        if manifest.get("schema_version") != 1 or not re.fullmatch(r"\d+\.\d+\.\d+-\d+", release):
            raise ValueError("unexpected release")
        url = f"https://github.com/conda-forge/miniforge/releases/download/{release}/Miniforge3-{release}-Linux-{architecture}.sh"
        if asset["url"] != url or not re.fullmatch(r"[0-9a-f]{64}", asset["sha256"]):
            raise ValueError("invalid pinned asset")
        return dict(asset, release=release)
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise InstallError("manifest", "Cannot read the pinned official Miniforge release manifest.") from error


def clean_environment():
    environment = os.environ.copy()
    for key in ("BASH_ENV", "ENV", "PYTHONHOME", "PYTHONPATH", "CONDARC",
                "CONDA_PREFIX", "CONDA_DEFAULT_ENV", "CONDA_SHLVL", "CONDA_EXE",
                "_CONDA_EXE", "CONDA_PYTHON_EXE"):
        environment.pop(key, None)
    return environment


def terminate_process_group(process):
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        process.communicate(timeout=PROCESS_TERMINATION_GRACE)
    except subprocess.TimeoutExpired:
        pass
    # The leader may already have exited while a descendant ignores SIGTERM.
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.communicate()


def run_checked(command, stage, timeout=CHECK_TIMEOUT):
    try:
        # Python 3.8 lacks Popen(umask=...); restore immediately after spawning.
        previous_umask = os.umask(0o022) if stage in ("installer", "base-config") else None
        try:
            process = subprocess.Popen(command, env=clean_environment(), text=True,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       start_new_session=True)
        finally:
            if previous_umask is not None:
                os.umask(previous_umask)
    except (OSError, ValueError) as error:
        raise InstallError(stage, "Required command could not run.") from error
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except (subprocess.TimeoutExpired, KeyboardInterrupt) as error:
        terminate_process_group(process)
        raise InstallError(stage, "Required command timed out or was interrupted; its process group was terminated.") from error
    if process.returncode:
        # Do not copy third-party stderr, which can contain local authentication settings.
        raise InstallError(stage, f"Required command exited with status {process.returncode}.")
    return subprocess.CompletedProcess(command, process.returncode, stdout, stderr)


def check_structure(prefix):
    required = (("bin/conda", os.R_OK | os.X_OK), ("bin/python", os.R_OK | os.X_OK),
                ("etc/profile.d/conda.sh", os.R_OK))
    if not prefix.is_dir():
        raise InstallError("prefix", "Existing prefix is not a directory; it will not be overwritten.")
    for relative, mode in required:
        path = prefix / relative
        if not path.is_file() or not os.access(path, mode):
            raise InstallError("prefix", f"Existing prefix lacks readable/executable {relative}; it will not be overwritten.")


def check_health(prefix):
    check_structure(prefix)
    conda = str(prefix / "bin/conda")
    version = run_checked([conda, "--version"], "conda-version").stdout.strip()
    if not re.fullmatch(r"conda \S+", version):
        raise InstallError("conda-version", "Conda did not report a valid version.")
    base = run_checked([conda, "info", "--base"], "conda-base").stdout.strip()
    try:
        matches = Path(base).is_absolute() and Path(base).resolve(strict=True) == prefix.resolve(strict=True)
    except (OSError, RuntimeError, ValueError):
        matches = False
    if not matches:
        raise InstallError("conda-base", "Conda reports a different or unavailable base prefix.")
    python = run_checked([str(prefix / "bin/python"), "-I", "--version"], "base-python")
    python_version = (python.stdout or python.stderr).strip()
    if not re.fullmatch(r"Python \d+\.\d+\.\d+\S*", python_version):
        raise InstallError("base-python", "Base Python did not report a valid version.")
    return {"conda_version": version, "python_version": python_version, "base": str(prefix.resolve())}


def check_parent(prefix, require_writable=True):
    try:
        parent = prefix.parent.resolve(strict=True)
    except (OSError, RuntimeError) as error:
        raise InstallError("parent", "The installation parent must already exist; create and authorize it separately.") from error
    if not parent.is_dir() or (require_writable and not os.access(parent, os.W_OK | os.X_OK)):
        raise InstallError("parent", "The installation parent is not a writable directory; this module does not use sudo.")
    return parent


def verify_hash(path, expected):
    try:
        digest = hashlib.sha256()
        total = 0
        with path.open("rb") as stream:
            while chunk := stream.read(1024 * 1024):
                total += len(chunk)
                if total > MAX_INSTALLER_BYTES:
                    raise InstallError("checksum", "Installer exceeds the expected size limit.")
                digest.update(chunk)
    except OSError as error:
        raise InstallError("installer-file", "Cannot read the supplied installer file.") from error
    if digest.hexdigest() != expected:
        raise InstallError("checksum", "Installer SHA256 does not match the pinned release; nothing was installed.")


def check_local_installer(path, asset):
    if not path.is_file():
        raise InstallError("installer-file", "The supplied installer must be a readable regular file.")
    verify_hash(path, asset["sha256"])


def download_installer(asset, destination):
    deadline = time.monotonic() + DOWNLOAD_TIMEOUT
    total = 0
    try:
        with urllib.request.urlopen(asset["url"], timeout=SOCKET_TIMEOUT) as response, destination.open("wb") as output:
            # read1 avoids waiting for a full chunk while a slow peer keeps its socket alive.
            read_chunk = getattr(response, "read1", response.read)
            while chunk := read_chunk(64 * 1024):
                if time.monotonic() > deadline:
                    raise InstallError("download", "Installer download exceeded its total time limit.")
                total += len(chunk)
                if total > MAX_INSTALLER_BYTES:
                    raise InstallError("download", "Installer download exceeds the expected size limit.")
                output.write(chunk)
    except InstallError:
        raise
    except (OSError, ValueError) as error:
        raise InstallError("download", "Could not download the pinned installer within the network time limit.") from error
    verify_hash(destination, asset["sha256"])


@contextlib.contextmanager
def installation_lock(parent):
    lock = parent / ".miniforge-install.lock"
    try:
        lock.mkdir(mode=0o700)
    except FileExistsError as error:
        raise InstallError("lock", "Another installation or stale lock occupies this parent; inspect it before retrying.") from error
    except OSError as error:
        raise InstallError("lock", "Cannot create the exclusive installation lock in the parent directory.") from error
    try:
        identity = (lock.stat().st_dev, lock.stat().st_ino)
    except OSError as error:
        raise InstallError("lock-cleanup", "Cannot identify the created lock; inspect the retained lock before retrying.") from error
    primary = None
    try:
        yield
    except BaseException as error:
        primary = error
        raise
    finally:
        # Remove only the lock this process created, never an externally replaced lock.
        try:
            current = lock.stat()
            if (current.st_dev, current.st_ino) == identity:
                lock.rmdir()
        except FileNotFoundError:
            pass
        except OSError as error:
            message = "Cannot remove the installer lock; inspect the retained lock before retrying."
            if isinstance(primary, InstallError):
                message += " Earlier failure stage: " + primary.stage + "."
            raise InstallError("lock-cleanup", message) from error


def initialize_base(prefix):
    config = prefix / ".condarc"
    if config.is_symlink() or (os.path.lexists(config) and not config.is_file()):
        raise InstallError("base-config", "New base .condarc is not a regular file; refusing to follow or replace it.")
    run_checked([str(prefix / "bin/conda"), "config", "--file", str(config),
                 "--set", "auto_activate_base", "false"], "base-config")
    try:
        configured = re.search(r"^(?:auto_activate_base|auto_activate):\s*false\s*(?:#.*)?$",
                               config.read_text(), re.IGNORECASE | re.MULTILINE)
    except OSError as error:
        raise InstallError("base-config", "Cannot verify the new base configuration.") from error
    if not configured:
        raise InstallError("base-config", "New base configuration did not disable automatic base activation.")


def execute(prefix, dry_run=False, installer_file=None):
    if not prefix.is_absolute():
        raise InstallError("prefix", "--prefix must be an explicit absolute path.")
    architecture, libc = supported_system()
    asset = load_asset(architecture)
    report = {"prefix": str(prefix), "installer_release": asset["release"], "architecture": architecture,
              "libc": libc, "scope": "conda-base-only", "training_validated": False}
    exists = os.path.lexists(prefix)
    parent = check_parent(prefix, require_writable=not exists)
    # A new installer can expose usable files before it completes configuration.
    if os.path.lexists(parent / ".miniforge-install.lock"):
        raise InstallError("lock", "Another installation or stale lock occupies this parent; inspect it before retrying.")
    if exists:
        check_structure(prefix)
        if dry_run:
            return dict(report, status="planned", action="reuse-and-verify", health_verified=False)
        return dict(report, status="reused", health_verified=True, **check_health(prefix))

    if installer_file is not None:
        check_local_installer(installer_file, asset)
    if dry_run:
        return dict(report, status="planned", action="install", installer_url=asset["url"],
                    sha256=asset["sha256"], health_verified=False)

    bash = shutil.which("bash")
    if bash is None:
        raise InstallError("installer", "bash is required to run the verified installer.")
    with installation_lock(parent):
        # A different process may have created the prefix while this one waited.
        if os.path.lexists(prefix):
            raise InstallError("prefix", "Prefix appeared before installation; refusing to overwrite it.")
        try:
            with tempfile.TemporaryDirectory(prefix="yadm-miniforge-") as temporary:
                directory = Path(temporary)
                directory.chmod(0o700)
                installer = directory / "installer.sh"
                if installer_file is None:
                    download_installer(asset, installer)
                else:
                    shutil.copyfile(installer_file, installer)
                    # Verify the private copy too, protecting against source changes after preflight.
                    verify_hash(installer, asset["sha256"])
                installer.chmod(0o600)
                run_checked([bash, str(installer), "-b", "-p", str(prefix)], "installer", INSTALL_TIMEOUT)
                health = check_health(prefix)
                initialize_base(prefix)
        except OSError as error:
            raise InstallError("installation", "Installation filesystem operation failed; any partial prefix was preserved.") from error
    return dict(report, status="installed", health_verified=True, **health,
                auto_activate_base=False,
                next="Apply machine-specific Conda/cache/ACL rules and validate them with setup-machine.")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prefix", required=True, type=Path,
                        help="explicit absolute installation prefix; existing healthy bases are reused")
    parser.add_argument("--dry-run", action="store_true", help="read-only plan; no commands, downloads, locks, or files created")
    parser.add_argument("--installer-file", type=Path,
                        help="already downloaded pinned installer; SHA256 verification remains mandatory")
    arguments = parser.parse_args(argv)
    try:
        result = execute(arguments.prefix, arguments.dry_run, arguments.installer_file)
    except InstallError as error:
        print(json.dumps({"status": "failed", "stage": error.stage, "message": str(error),
                          "prefix": str(arguments.prefix), "partial_prefix_preserved": os.path.lexists(arguments.prefix)},
                         ensure_ascii=False))
        return 1
    except OSError:
        print(json.dumps({"status": "failed", "stage": "filesystem",
                          "message": "Filesystem operation failed; any partial prefix was preserved.",
                          "prefix": str(arguments.prefix),
                          "partial_prefix_preserved": os.path.lexists(arguments.prefix)}, ensure_ascii=False))
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
