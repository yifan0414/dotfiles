#!/usr/bin/env python3
"""Read-only bootstrap inspection; this does not validate a training environment."""

import argparse
import csv
import json
import os
import platform
import shutil
import stat
import subprocess
from pathlib import Path

try:
    import grp
    import pwd
except ImportError:  # Still produce an unsupported-OS error outside Unix.
    grp = pwd = None


PROFILES = {"mac-client": "Darwin", "dl-server": "Linux"}
ESSENTIAL_TOOLS = {
    "ssh": ("ssh",),
    "python3": ("python3",),
    "curl": ("curl",),
    "git": ("git",),
    "gh": ("gh",),
    "gpg": ("gpg",),
    "yadm": ("yadm",),
    "zsh": ("zsh",),
    "fzf": ("fzf",),
    "fd": ("fd", "fdfind"),
    "ripgrep": ("rg",),
    "neovim": ("nvim",),
    "tmux": ("tmux",),
    "node": ("node",),
    "npm": ("npm",),
    "codex": ("codex",),
    "pi": ("pi",),
}


def tool_paths():
    paths = {}
    for name, variants in ESSENTIAL_TOOLS.items():
        paths[name] = next((path for variant in variants
                            if (path := shutil.which(variant))), None)
    return paths


def local_class(home, git, diagnostics):
    """Use Git directly: yadm config can run hooks, alt, perms, or mkdir."""
    for repo in (home / ".local/share/yadm/repo.git",
                 home / ".config/yadm/repo.git", home / ".yadm/repo.git"):
        config = repo / "config"
        if not repo.is_dir() or not config.is_file():
            continue
        if not git:
            diagnostics.append("Cannot inspect initialized yadm local.class: git is missing.")
            return None
        env = {key: value for key, value in os.environ.items()
               if not key.startswith("GIT_")}
        env.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
                   GIT_CONFIG_COUNT="0", GIT_TERMINAL_PROMPT="0")
        try:
            result = subprocess.run(
                [git, "config", "--no-includes", "--file", str(config),
                 "--get", "local.class"], cwd=home, env=env,
                capture_output=True, text=True, timeout=5, check=False)
        except (OSError, subprocess.TimeoutExpired):
            raise ValueError("Cannot read initialized yadm local.class; Git query failed.")
        if result.returncode == 1:
            return None
        if result.returncode != 0:
            raise ValueError("Cannot read initialized yadm local.class; check repository config.")
        value = result.stdout.strip()
        return value or None
    return None


def select_profile(requested, system, home, paths, diagnostics):
    if system not in PROFILES.values():
        raise ValueError("Unsupported operating system; expected macOS or Linux.")
    if requested != "auto":
        name, source = requested, "argument"
    elif os.environ.get("DOTFILES_MACHINE_PROFILE") not in (None, "", "auto"):
        name, source = os.environ["DOTFILES_MACHINE_PROFILE"], "environment"
    else:
        stored = local_class(home, paths["git"], diagnostics)
        if stored:
            name, source = stored, "yadm.local.class"
        else:
            name = "mac-client" if system == "Darwin" else "dl-server"
            source = "operating-system"
    if name not in PROFILES:
        # Do not echo arbitrary stored configuration/environment values.
        raise ValueError(f"Invalid machine profile from {source}; expected mac-client or dl-server.")
    if PROFILES[name] != system:
        raise ValueError(f"Profile {name} requires {PROFILES[name]}; actual OS is {system}.")
    return {"name": name, "source": source}


def path_status(path):
    result = {"path": str(path), "exists": False}
    try:
        info = path.stat()
    except FileNotFoundError:
        return result
    except OSError:
        result["exists"] = None
        result["inspection_error"] = "Path metadata is inaccessible."
        return result
    group = None
    if grp is not None:
        try:
            group = grp.getgrgid(info.st_gid).gr_name
        except KeyError:
            pass
    result.update(exists=True, directory=stat.S_ISDIR(info.st_mode),
                  mode=f"{stat.S_IMODE(info.st_mode):04o}", owner_uid=info.st_uid,
                  group_gid=info.st_gid, group=group,
                  group_writable=bool(info.st_mode & stat.S_IWGRP),
                  setgid=bool(info.st_mode & stat.S_ISGID),
                  current_process_access={
                      "read": os.access(path, os.R_OK),
                      "write": os.access(path, os.W_OK),
                      "execute": os.access(path, os.X_OK)})
    return result


def conda_roots(home, diagnostics=None):
    if diagnostics is None:
        diagnostics = []
    candidates = []
    configured_root = None
    override = os.environ.get("DOTFILES_CONDA_ROOT")
    if override:
        root = Path(override)
        if not root.is_absolute():
            diagnostics.append("DOTFILES_CONDA_ROOT must be an absolute path; ignoring that override.")
        else:
            try:
                configured_root = root.resolve()
                candidates.append(configured_root)
            except (OSError, RuntimeError, ValueError):
                diagnostics.append("DOTFILES_CONDA_ROOT could not be resolved; ignoring that override.")
    for executable in (os.environ.get("CONDA_EXE"), shutil.which("conda")):
        if not executable:
            continue
        conda = Path(executable).expanduser()
        if conda.is_absolute():
            try:
                conda = conda.resolve()
            except (OSError, RuntimeError, ValueError):
                continue
            if conda.parent.name in ("bin", "condabin"):
                candidates.append(conda.parent.parent)
    for base in (Path("/opt"), Path("/usr/local"), Path("/srv"), home):
        candidates.extend(base / name for name in
                          ("miniforge3", "miniforge", "miniconda3", "miniconda",
                           "anaconda3", "mambaforge"))
    candidates.extend(home / name for name in (".miniforge3", ".miniconda3"))
    found = []
    for root in candidates:
        try:
            root = root.resolve()
        except (OSError, RuntimeError, ValueError):
            continue
        if root in found:
            continue
        if ((root / "bin/conda").is_file() or
                (root / "condabin/conda").is_file() or
                (root / "conda-meta/history").is_file()):
            found.append(root)
    if configured_root is not None and configured_root not in found:
        diagnostics.append("DOTFILES_CONDA_ROOT has no recognizable Conda installation; "
                           "ignoring that override.")
    return found


def datausers_status():
    if grp is None or pwd is None:
        return {"exists": None, "current_process_member": None, "account_member": None}
    try:
        group = grp.getgrnam("datausers")
    except KeyError:
        return {"exists": False, "current_process_member": False, "account_member": False}
    account = pwd.getpwuid(os.geteuid())
    return {"exists": True, "gid": group.gr_gid,
            "current_process_member": group.gr_gid in {*os.getgroups(), os.getegid()},
            "account_member": account.pw_gid == group.gr_gid or account.pw_name in group.gr_mem}


def credential_presence(home):
    # Never read credential contents, invoke auth, or run credential helpers.
    files = {
        "github_shared_token": home / ".config/gh-token",
        "github_cli_hosts": home / ".config/gh/hosts.yml",
        "codex_auth": home / ".codex/auth.json",
        "pi_auth": home / ".pi/agent/auth.json",
        "yadm_encrypted_archive": home / ".local/share/yadm/archive",
    }
    result = {name: path.is_file() for name, path in files.items()}
    result["standard_ssh_private_key"] = any(
        (home / ".ssh" / name).is_file()
        for name in ("id_ed25519", "id_rsa", "id_ecdsa"))
    return result


def gpu_status():
    executable = shutil.which("nvidia-smi")
    if not executable:
        return {"state": "nvidia-smi-not-found"}
    try:
        result = subprocess.run(
            [executable, "--query-gpu=name,driver_version,memory.total",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=5, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return {"state": "query-failed"}
    if result.returncode:
        return {"state": "query-failed"}
    devices = []
    for row in list(csv.reader(result.stdout.splitlines()))[:64]:
        if len(row) != 3:
            return {"state": "unexpected-query-output"}
        name, driver, memory = (value.strip() for value in row)
        try:
            memory_mib = int(memory)
        except ValueError:
            memory_mib = None
        devices.append({"name": name[:160], "driver": driver[:40], "memory_mib": memory_mib})
    return {"state": "queried", "devices": devices}


def mac_apps(home):
    locations = {
        "ghostty": (Path("/Applications/Ghostty.app"), home / "Applications/Ghostty.app"),
        "kitty": (Path("/Applications/kitty.app"), home / "Applications/kitty.app"),
        "squirrel": (Path("/Library/Input Methods/Squirrel.app"),
                     home / "Library/Input Methods/Squirrel.app"),
    }
    return {name: {"state": "present" if any(path.is_dir() for path in paths) else "not-found",
                   "checked_paths": [str(path) for path in paths]}
            for name, paths in locations.items()}


def inspect(home, requested):
    system = platform.system()
    machine = {"os": system, "architecture": platform.machine(), "hostname": platform.node()}
    paths = tool_paths()
    diagnostics = []
    try:
        profile = select_profile(requested, system, home, paths, diagnostics)
    except ValueError as error:
        return {"inspection": "bootstrap", "machine": machine, "error": str(error)}, 2
    roots = conda_roots(home, diagnostics)
    if not roots:
        diagnostics.append("No known Conda root was found; other installation paths may exist. "
                           "Inventory absence does not prove Conda is absent.")
    shared = [Path("/ssd_4t/shared"), Path("/var/cache/pip")]
    for root in roots:
        shared.extend((root / "envs", root / "pkgs"))
    missing = [name for name, path in paths.items() if path is None]
    report = {
        "inspection": "bootstrap",
        "training_environment_validated": False,
        "machine": machine,
        "profile": profile,
        "essential_tools": paths,
        "missing_essential_tools": missing,
        "credential_files_present": credential_presence(home),
        "conda_roots": [str(root) for root in roots],
        "shared_paths": [path_status(path) for path in shared] if system == "Linux" else [],
        "datausers": datausers_status() if system == "Linux" else None,
        "gpu": gpu_status() if system == "Linux" else {"state": "not-applicable"},
        "mac_apps": mac_apps(home) if system == "Darwin" else None,
        "diagnostics": diagnostics,
    }
    return report, 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", choices=("auto", *PROFILES), default="auto")
    parser.add_argument("--home", type=Path, default=Path.home(),
                        help="Home directory to inspect; useful for isolated checks.")
    parser.add_argument("--strict", action="store_true",
                        help="Exit 1 if essential CLI tools are missing; not a training acceptance test.")
    args = parser.parse_args(argv)
    report, status = inspect(args.home.expanduser().absolute(), args.profile)
    if args.strict and status == 0 and report["missing_essential_tools"]:
        status = 1
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return status


if __name__ == "__main__":
    raise SystemExit(main())
