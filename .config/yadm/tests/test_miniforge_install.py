"""Exercise only copied modules and fake verified installers in temporary homes."""

import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import tempfile
import time
import unittest
from unittest import mock
import urllib.error


ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / ".config/yadm/scripts/install-miniforge.py"
MANIFEST = ROOT / ".config/yadm/packages/conda/miniforge-release.json"
FAKE_INSTALLER = r'''#!/bin/bash
set -eu
[[ "$1" == -b && "$2" == -p && "$#" == 3 ]]
prefix="$3"
mkdir -p "$prefix/bin" "$prefix/etc/profile.d"
if [[ "${FIXTURE_INSTALL_FAIL:-0}" == 1 ]]; then
  printf partial > "$prefix/partial-marker"
  exit 7
fi
cat > "$prefix/bin/conda" <<'CONDA'
#!/bin/bash
set -eu
prefix="${0%/bin/conda}"
case "$*" in
  --version) printf 'conda 26.7.2\n' ;;
  "info --base") printf '%s\n' "$prefix" ;;
  config\ --file\ *)
    [[ "${FIXTURE_CONFIG_FAIL:-0}" != 1 ]] || { printf 'secret-token\n' >&2; exit 9; }
    [[ "$4 $5 $6" == "--set auto_activate_base false" ]]
    printf 'auto_activate_base: false\n' > "$3" ;;
  *) exit 8 ;;
esac
CONDA
cat > "$prefix/bin/python" <<'PYTHON'
#!/bin/bash
[[ "$*" == "-I --version" ]] || exit 8
printf 'Python 3.13.7\n'
PYTHON
printf '# fake conda shell hook\n' > "$prefix/etc/profile.d/conda.sh"
chmod +x "$prefix/bin/conda" "$prefix/bin/python"
'''


class MiniforgeInstallTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="miniforge-module-")
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name) / "home with spaces"
        self.home.mkdir()
        scripts = self.home / ".config/yadm/scripts"
        scripts.mkdir(parents=True)
        packages = self.home / ".config/yadm/packages/conda"
        packages.mkdir(parents=True)
        self.module_path = scripts / MODULE.name
        shutil.copyfile(MODULE, self.module_path)
        self.manifest_path = packages / MANIFEST.name
        shutil.copyfile(MANIFEST, self.manifest_path)
        spec = importlib.util.spec_from_file_location("miniforge_fixture", self.module_path)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)
        self.prefix = self.home / "miniforge prefix"
        self.installer = self.home / "offline installer.sh"
        self.installer.write_text(FAKE_INSTALLER)
        # Only this copied manifest is adjusted to trust the fixture, never the real release.
        self.manifest = json.loads(self.manifest_path.read_text())
        self.fixture_sha = hashlib.sha256(self.installer.read_bytes()).hexdigest()
        for asset in self.manifest["assets"].values():
            asset["sha256"] = self.fixture_sha
        self.manifest_path.write_text(json.dumps(self.manifest))
        self.environment = {key: value for key, value in os.environ.items()
                            if not key.startswith(("CONDA", "FIXTURE_", "BASH_FUNC_"))
                            and key not in ("BASH_ENV", "ENV", "PYTHONHOME", "PYTHONPATH")}
        self.environment["HOME"] = str(self.home)
        self.addCleanup(mock.patch.stopall)
        mock.patch.dict(os.environ, self.environment, clear=True).start()
        mock.patch.object(self.module.platform, "system", return_value="Linux").start()
        mock.patch.object(self.module.platform, "machine", return_value="x86_64").start()
        mock.patch.object(self.module.os, "confstr", return_value="glibc 2.17").start()
        # Unexpected calls must never reach the network.
        self.network = mock.patch.object(self.module.urllib.request, "urlopen",
                                         side_effect=AssertionError("unexpected network access")).start()

    def invoke(self, *extra):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = self.module.main(["--prefix", str(self.prefix), *extra])
        return result, json.loads(output.getvalue())

    def offline_install(self, *extra):
        return self.invoke("--installer-file", str(self.installer), *extra)

    def snapshot(self):
        return sorted((str(path.relative_to(self.home)), path.read_bytes() if path.is_file() else None)
                      for path in self.home.rglob("*") if not path.is_symlink())

    def test_dry_run_is_read_only_without_download_or_commands(self):
        before = self.snapshot()
        with mock.patch.object(self.module.subprocess, "Popen", side_effect=AssertionError("unexpected command")):
            result, report = self.invoke("--dry-run")
        self.assertEqual(result, 0)
        self.assertEqual(report["action"], "install")
        self.assertFalse(report["health_verified"])
        self.assertFalse(report["training_validated"])
        self.assertEqual(before, self.snapshot())
        self.network.assert_not_called()

    def test_offline_dry_run_checks_sha_without_changing_files(self):
        before = self.snapshot()
        result, report = self.offline_install("--dry-run")
        self.assertEqual(result, 0)
        self.assertEqual(report["sha256"], self.fixture_sha)
        self.assertEqual(before, self.snapshot())

    def test_offline_install_only_initializes_a_new_base(self):
        result, report = self.offline_install()
        self.assertEqual(result, 0)
        self.assertEqual(report["status"], "installed")
        self.assertTrue(report["health_verified"])
        self.assertEqual(report["scope"], "conda-base-only")
        self.assertFalse(report["training_validated"])
        self.assertFalse(report["auto_activate_base"])
        self.assertEqual((self.prefix / ".condarc").read_text(), "auto_activate_base: false\n")
        self.assertFalse((self.home / ".miniforge-install.lock").exists())
        self.assertFalse((self.home / ".zshrc").exists())
        self.network.assert_not_called()

    def test_healthy_existing_prefix_is_reused_without_configuration_changes(self):
        self.assertEqual(self.offline_install()[0], 0)
        config = self.prefix / ".condarc"
        config.write_text("channels:\n  - existing-channel\nauto_activate_base: true\n")
        before = self.snapshot()
        result, report = self.invoke()
        self.assertEqual(result, 0)
        self.assertEqual(report["status"], "reused")
        self.assertEqual(report["base"], str(self.prefix))
        self.assertEqual(before, self.snapshot())
        self.network.assert_not_called()

    def test_existing_prefix_dry_run_does_not_execute_conda(self):
        self.assertEqual(self.offline_install()[0], 0)
        before = self.snapshot()
        with mock.patch.object(self.module.subprocess, "Popen", side_effect=AssertionError("unexpected command")):
            result, report = self.invoke("--dry-run")
        self.assertEqual(result, 0)
        self.assertEqual(report["action"], "reuse-and-verify")
        self.assertFalse(report["health_verified"])
        self.assertEqual(before, self.snapshot())

    def test_occupied_empty_directory_file_and_dangling_link_are_not_overwritten(self):
        for kind in ("empty-directory", "file", "dangling-link", "loop-link"):
            with self.subTest(kind=kind):
                if kind == "empty-directory":
                    self.prefix.mkdir()
                elif kind == "file":
                    self.prefix.write_text("existing data")
                elif kind == "dangling-link":
                    self.prefix.symlink_to(self.home / "missing-target")
                else:
                    self.prefix.symlink_to(self.prefix)
                before = self.prefix.lstat()
                result, report = self.offline_install()
                self.assertEqual(result, 1)
                self.assertEqual(report["stage"], "prefix")
                self.assertEqual(before.st_ino, self.prefix.lstat().st_ino)
                if self.prefix.is_dir():
                    self.assertEqual(list(self.prefix.iterdir()), [])
                    self.prefix.rmdir()
                else:
                    self.prefix.unlink()
                self.network.assert_not_called()

    def test_broken_conda_and_wrong_base_are_not_reinstalled(self):
        self.assertEqual(self.offline_install()[0], 0)
        conda = self.prefix / "bin/conda"
        original = conda.read_text()
        for code, stage in (("#!/bin/sh\nprintf secret-token >&2\nexit 6\n", "conda-version"),
                            (original.replace("printf '%s\\n' \"$prefix\"", "printf '/wrong-base\\n'"), "conda-base")):
            with self.subTest(stage=stage):
                conda.write_text(code)
                result, report = self.invoke()
                self.assertEqual(result, 1)
                self.assertEqual(report["stage"], stage)
                self.assertNotIn("secret-token", json.dumps(report))
                self.assertEqual(conda.read_text(), code)

    def test_checksum_failure_never_creates_a_prefix_or_lock(self):
        self.installer.write_text(FAKE_INSTALLER + "\n# tampered\n")
        for extra in ((), ("--dry-run",)):
            with self.subTest(extra=extra):
                result, report = self.offline_install(*extra)
                self.assertEqual(result, 1)
                self.assertEqual(report["stage"], "checksum")
                self.assertFalse(self.prefix.exists())
                self.assertFalse((self.home / ".miniforge-install.lock").exists())

    def test_non_linux_unsupported_architecture_and_glibc_are_rejected(self):
        cases = (("Darwin", "x86_64", "glibc 2.36", "platform"),
                 ("Linux", "riscv64", "glibc 2.36", "architecture"),
                 ("Linux", "x86_64", "glibc 2.16", "glibc"),
                 ("Linux", "x86_64", "musl 1.2.5", "glibc"))
        for system, machine, libc, stage in cases:
            with self.subTest(system=system, machine=machine, libc=libc):
                with mock.patch.object(self.module.platform, "system", return_value=system), \
                     mock.patch.object(self.module.platform, "machine", return_value=machine), \
                     mock.patch.object(self.module.os, "confstr", return_value=libc):
                    result, report = self.invoke("--dry-run")
                self.assertEqual(result, 1)
                self.assertEqual(report["stage"], stage)
                self.assertFalse(self.prefix.exists())

    def test_all_supported_architectures_select_their_pinned_asset(self):
        for architecture in ("x86_64", "aarch64", "ppc64le"):
            with self.subTest(architecture=architecture):
                with mock.patch.object(self.module.platform, "machine", return_value=architecture):
                    result, report = self.invoke("--dry-run")
                self.assertEqual(result, 0)
                self.assertEqual(report["architecture"], architecture)
                self.assertTrue(report["installer_url"].endswith("Linux-" + architecture + ".sh"))

    def test_relative_prefix_missing_parent_and_unwritable_parent_fail_preflight(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = self.module.main(["--prefix", "relative-prefix", "--dry-run"])
        self.assertEqual(result, 1)
        self.assertEqual(json.loads(output.getvalue())["stage"], "prefix")
        self.prefix = self.home / "missing-parent" / "conda"
        result, report = self.invoke("--dry-run")
        self.assertEqual((result, report["stage"]), (1, "parent"))
        self.prefix = self.home / "miniforge"
        real_access = os.access
        with mock.patch.object(self.module.os, "access", side_effect=lambda path, mode:
                               False if Path(path) == self.home else real_access(path, mode)):
            result, report = self.invoke("--dry-run")
        self.assertEqual((result, report["stage"]), (1, "parent"))

    def test_installer_failure_preserves_partial_prefix_and_clears_lock(self):
        with mock.patch.dict(os.environ, FIXTURE_INSTALL_FAIL="1"):
            result, report = self.offline_install()
        self.assertEqual((result, report["stage"]), (1, "installer"))
        self.assertTrue(report["partial_prefix_preserved"])
        self.assertEqual((self.prefix / "partial-marker").read_text(), "partial")
        self.assertFalse((self.home / ".miniforge-install.lock").exists())

    def test_installer_timeout_kills_descendants_before_clearing_lock(self):
        fixture = r'''#!/bin/bash
set -eu
prefix="$3"
mkdir -p "$prefix"
printf partial > "$prefix/partial-marker"
(trap '' TERM; sleep 0.3; touch "$prefix/orphan-marker"; sleep 5) &
wait
'''
        self.installer.write_text(fixture)
        digest = hashlib.sha256(self.installer.read_bytes()).hexdigest()
        for asset in self.manifest["assets"].values():
            asset["sha256"] = digest
        self.manifest_path.write_text(json.dumps(self.manifest))
        with mock.patch.object(self.module, "INSTALL_TIMEOUT", 0.05), \
             mock.patch.object(self.module, "PROCESS_TERMINATION_GRACE", 0.05):
            result, report = self.offline_install()
        self.assertEqual((result, report["stage"]), (1, "installer"))
        self.assertEqual((self.prefix / "partial-marker").read_text(), "partial")
        self.assertFalse((self.home / ".miniforge-install.lock").exists())
        time.sleep(0.4)
        self.assertFalse((self.prefix / "orphan-marker").exists())

    def test_new_shared_base_uses_umask_022_and_restores_the_caller_umask(self):
        previous = os.umask(0o077)
        try:
            result, report = self.offline_install()
            inherited = os.umask(0o077)
            self.assertEqual(inherited, 0o077)
        finally:
            os.umask(previous)
        self.assertEqual(result, 0)
        self.assertEqual(report["status"], "installed")
        self.assertEqual(self.prefix.stat().st_mode & 0o777, 0o755)
        self.assertEqual((self.prefix / ".condarc").stat().st_mode & 0o777, 0o644)

    def test_lock_cleanup_failure_has_a_structured_diagnostic(self):
        original = Path.rmdir

        def fail_only_lock(path):
            if path == self.home / ".miniforge-install.lock":
                raise PermissionError("secret-token")
            return original(path)

        with mock.patch.object(Path, "rmdir", fail_only_lock), \
             mock.patch.dict(os.environ, FIXTURE_INSTALL_FAIL="1"):
            result, report = self.offline_install()
        self.assertEqual((result, report["stage"]), (1, "lock-cleanup"))
        self.assertIn("Earlier failure stage: installer", report["message"])
        self.assertNotIn("secret-token", json.dumps(report))
        self.assertTrue((self.home / ".miniforge-install.lock").is_dir())
        self.assertTrue((self.prefix / "partial-marker").is_file())

    def test_configuration_failure_preserves_installed_files_without_false_success(self):
        with mock.patch.dict(os.environ, FIXTURE_CONFIG_FAIL="1"):
            result, report = self.offline_install()
        self.assertEqual((result, report["stage"]), (1, "base-config"))
        self.assertTrue((self.prefix / "bin/conda").is_file())
        self.assertNotIn("secret-token", json.dumps(report))
        self.assertFalse((self.home / ".miniforge-install.lock").exists())

    def test_validated_installer_download_uses_private_temporary_directory(self):
        self.network.side_effect = None
        self.network.return_value = io.BytesIO(self.installer.read_bytes())
        original = self.module.run_checked
        seen = []

        def check_private(command, stage, timeout=self.module.CHECK_TIMEOUT):
            if stage == "installer":
                temporary = Path(command[1]).parent
                self.assertEqual(temporary.stat().st_mode & 0o777, 0o700)
                self.assertEqual(Path(command[1]).stat().st_mode & 0o777, 0o600)
                seen.append(temporary)
            return original(command, stage, timeout)

        with mock.patch.object(self.module, "run_checked", side_effect=check_private):
            result, report = self.invoke()
        self.assertEqual(result, 0)
        self.assertEqual(report["status"], "installed")
        self.network.assert_called_once_with(self.manifest["assets"]["x86_64"]["url"],
                                             timeout=self.module.SOCKET_TIMEOUT)
        self.assertEqual(len(seen), 1)
        self.assertFalse(seen[0].exists())

    def test_download_failure_checksum_and_timeout_leave_no_prefix(self):
        cases = ((urllib.error.URLError("secret-token"), None, "download"),
                 (None, b"wrong installer bytes", "checksum"))
        for error, contents, stage in cases:
            with self.subTest(stage=stage):
                self.network.side_effect = error
                self.network.return_value = io.BytesIO(contents or b"")
                result, report = self.invoke()
                self.assertEqual((result, report["stage"]), (1, stage))
                self.assertNotIn("secret-token", json.dumps(report))
                self.assertFalse(self.prefix.exists())
                self.assertFalse((self.home / ".miniforge-install.lock").exists())
        self.network.side_effect = None
        self.network.return_value = io.BytesIO(self.installer.read_bytes())
        with mock.patch.object(self.module.time, "monotonic", side_effect=[0, self.module.DOWNLOAD_TIMEOUT + 1]):
            result, report = self.invoke()
        self.assertEqual((result, report["stage"]), (1, "download"))

    def test_existing_lock_blocks_new_install_and_healthy_reuse(self):
        lock = self.home / ".miniforge-install.lock"
        lock.mkdir()
        before = lock.stat().st_ino
        result, report = self.offline_install()
        self.assertEqual((result, report["stage"]), (1, "lock"))
        self.assertEqual(before, lock.stat().st_ino)
        lock.rmdir()
        self.assertEqual(self.offline_install()[0], 0)
        lock.mkdir()
        result, report = self.invoke()
        self.assertEqual((result, report["stage"]), (1, "lock"))
        self.assertTrue(lock.is_dir())

    def test_prefix_created_after_lock_is_not_overwritten(self):
        real_lock = self.module.installation_lock

        @contextlib.contextmanager
        def race(parent):
            with real_lock(parent):
                self.prefix.mkdir()
                (self.prefix / "other-process").write_text("retain")
                yield

        with mock.patch.object(self.module, "installation_lock", side_effect=race):
            result, report = self.offline_install()
        self.assertEqual((result, report["stage"]), (1, "prefix"))
        self.assertEqual((self.prefix / "other-process").read_text(), "retain")
        self.assertFalse((self.home / ".miniforge-install.lock").exists())

    def test_installer_and_validation_sanitize_shell_startup_environment(self):
        poison = self.home / "poison.sh"
        poison.write_text('touch "$HOME/poisoned"\nexit 99\n')
        with mock.patch.dict(os.environ, BASH_ENV=str(poison), ENV=str(poison)):
            result, report = self.offline_install()
        self.assertEqual(result, 0)
        self.assertEqual(report["status"], "installed")
        self.assertFalse((self.home / "poisoned").exists())

    def test_unpinned_manifest_url_or_release_is_rejected(self):
        for field in ("version", "url"):
            manifest = json.loads(json.dumps(self.manifest))
            if field == "version":
                manifest["version"] = "latest"
            else:
                manifest["assets"]["x86_64"]["url"] = "https://untrusted.example/installer.sh"
            self.manifest_path.write_text(json.dumps(manifest))
            result, report = self.invoke("--dry-run")
            self.assertEqual((result, report["stage"]), (1, "manifest"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
