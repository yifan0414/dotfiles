"""Offline inspection checks; no installers or live dotfiles are executed."""

import contextlib
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import patch

sys.dont_write_bytecode = True
SCRIPT = Path(__file__).resolve().parents[1] / "scripts/machine-status.py"
SPEC = importlib.util.spec_from_file_location("machine_status", SCRIPT)
status = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(status)


class MachineStatusTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="yadm-inspect-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home with spaces"
        self.home.mkdir()
        self.env = patch.dict(os.environ, {}, clear=True)
        self.env.start()
        self.addCleanup(self.env.stop)
        self.discovery = patch.object(status.shutil, "which", side_effect=self.which)
        self.discovery.start()
        self.addCleanup(self.discovery.stop)
        self.subprocess = patch.object(status.subprocess, "run",
                                       side_effect=AssertionError("Unexpected subprocess"))
        self.run = self.subprocess.start()
        self.addCleanup(self.subprocess.stop)
        self.groups = patch.object(status, "shared_group_status", return_value={"exists": False})
        self.group_query = self.groups.start()
        self.addCleanup(self.groups.stop)
        self.available = {variants[0] for variants in status.ESSENTIAL_TOOLS.values()}

    def which(self, name):
        return f"/mock/bin/{name}" if name in self.available else None

    def inspect(self, system="Linux", profile="auto", strict=False):
        output = io.StringIO()
        args = ["--home", str(self.home), "--profile", profile]
        if strict:
            args.append("--strict")
        with patch.object(status.platform, "system", return_value=system), \
                patch.object(status.platform, "machine", return_value="test-arch"), \
                patch.object(status.platform, "node", return_value="test-host"), \
                contextlib.redirect_stdout(output):
            code = status.main(args)
        return code, json.loads(output.getvalue())

    def initialize(self, legacy=False):
        repo = self.home / (".config/yadm/repo.git" if legacy else ".local/share/yadm/repo.git")
        repo.mkdir(parents=True)
        (repo / "config").write_text("[local]\n class = dl-server\n")
        return repo

    def set_query(self, value=None, returncode=0):
        self.run.side_effect = None
        self.run.return_value = subprocess.CompletedProcess([], returncode, value or "", "")

    def test_os_defaults_and_explicit_profiles(self):
        for system, role in (("Darwin", "mac-client"), ("Linux", "dl-server")):
            for requested, source in (("auto", "operating-system"), (role, "argument")):
                with self.subTest(system=system, requested=requested):
                    code, report = self.inspect(system, requested, strict=True)
                    self.assertEqual(code, 0)
                    self.assertEqual(report["profile"], {"name": role, "source": source})
                    self.assertEqual(report["machine"]["architecture"], "test-arch")
                    self.assertFalse(report["training_environment_validated"])
        self.run.assert_not_called()

    def test_mismatch_unknown_roles_and_unsupported_os(self):
        for system, requested in (("Darwin", "dl-server"), ("Linux", "mac-client"),
                                  ("Windows", "auto")):
            code, report = self.inspect(system, requested)
            self.assertEqual(code, 2)
            self.assertIn("error", report)
        for value in ("unexpected-secret-role",):
            os.environ["DOTFILES_MACHINE_PROFILE"] = value
            code, report = self.inspect()
            self.assertEqual(code, 2)
            self.assertNotIn(value, json.dumps(report))

    def test_unknown_argument_and_invalid_stored_auto_are_rejected(self):
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as error:
            status.main(["--profile", "unknown-profile"])
        self.assertEqual(error.exception.code, 2)
        self.initialize()
        self.set_query("auto\n")
        code, report = self.inspect()
        self.assertEqual(code, 2)
        self.assertIn("Invalid machine profile", report["error"])

    def test_precedence_argument_then_environment_then_local_class(self):
        self.initialize()
        self.set_query("unrecognized-secret-role\n")
        os.environ["DOTFILES_MACHINE_PROFILE"] = "mac-client"
        code, report = self.inspect("Darwin", "mac-client")
        self.assertEqual((code, report["profile"]["source"]), (0, "argument"))
        code, report = self.inspect("Darwin")
        self.assertEqual((code, report["profile"]["source"]), (0, "environment"))
        self.run.assert_not_called()
        del os.environ["DOTFILES_MACHINE_PROFILE"]
        code, report = self.inspect()
        self.assertEqual(code, 2)
        self.assertNotIn("unrecognized-secret-role", json.dumps(report))
        self.set_query("dl-server\n")
        code, report = self.inspect()
        self.assertEqual((code, report["profile"]["source"]), (0, "yadm.local.class"))
        os.environ["DOTFILES_MACHINE_PROFILE"] = "auto"
        code, report = self.inspect()
        self.assertEqual((code, report["profile"]["source"]), (0, "yadm.local.class"))

    def test_local_class_query_is_bounded_and_cannot_run_yadm_hooks(self):
        repo = self.initialize(legacy=True)
        self.set_query("dl-server\n")
        os.environ.update(GIT_CONFIG_PARAMETERS="sensitive config", GIT_CONFIG_COUNT="999")
        code, _ = self.inspect()
        self.assertEqual(code, 0)
        args, kwargs = self.run.call_args
        self.assertEqual(args[0], ["/mock/bin/git", "config", "--no-includes", "--file",
                                   str(repo / "config"), "--get", "local.class"])
        self.assertEqual(kwargs["timeout"], 5)
        self.assertEqual(kwargs["cwd"], self.home)
        self.assertEqual(kwargs["env"]["GIT_CONFIG_COUNT"], "0")
        self.assertNotIn("GIT_CONFIG_PARAMETERS", kwargs["env"])

    def test_absent_local_class_and_failed_query_are_distinct(self):
        self.initialize()
        self.set_query(returncode=1)
        code, report = self.inspect()
        self.assertEqual((code, report["profile"]["source"]), (0, "operating-system"))
        self.set_query("dl-server", returncode=128)
        code, report = self.inspect()
        self.assertEqual(code, 2)
        self.assertIn("Cannot read", report["error"])
        self.run.side_effect = subprocess.TimeoutExpired("git", 5, output="secret config")
        code, report = self.inspect()
        self.assertEqual(code, 2)
        self.assertNotIn("secret config", json.dumps(report))

    def test_missing_git_reports_diagnostic_without_query(self):
        self.initialize()
        self.available.remove("git")
        code, report = self.inspect()
        self.assertEqual(code, 0)
        self.assertEqual(report["profile"]["source"], "operating-system")
        self.assertTrue(report["diagnostics"])
        self.run.assert_not_called()

    def test_fd_alias_and_strict_missing_agent(self):
        self.available.remove("fd")
        self.available.add("fdfind")
        self.available.remove("codex")
        code, report = self.inspect(strict=True)
        self.assertEqual(code, 1)
        self.assertEqual(report["essential_tools"]["fd"], "/mock/bin/fdfind")
        self.assertEqual(report["missing_essential_tools"], ["codex"])
        self.assertEqual(self.inspect(strict=False)[0], 0)

    def test_credentials_are_only_presence_and_home_is_read_only(self):
        for name in (".config/gh-token", ".config/gh/hosts.yml", ".codex/auth.json",
                     ".pi/agent/auth.json", ".ssh/id_ed25519"):
            path = self.home / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("never-log-this-secret-token-or-configuration")
            path.chmod(0o600)
        before = {str(path.relative_to(self.home)): (path.stat().st_mode, path.read_bytes())
                  for path in self.home.rglob("*") if path.is_file()}
        before_paths = sorted(str(path.relative_to(self.home)) for path in self.home.rglob("*"))
        # Any content read during inspection would fail, including auth/config reads.
        with patch.object(Path, "read_text", side_effect=AssertionError("Content read")), \
                patch.object(Path, "read_bytes", side_effect=AssertionError("Content read")):
            code, report = self.inspect()
        after = {str(path.relative_to(self.home)): (path.stat().st_mode, path.read_bytes())
                 for path in self.home.rglob("*") if path.is_file()}
        self.assertEqual(code, 0)
        self.assertEqual(before, after)
        self.assertEqual(before_paths, sorted(str(path.relative_to(self.home))
                                             for path in self.home.rglob("*")))
        self.assertNotIn("never-log-this", json.dumps(report))
        self.assertTrue(report["credential_files_present"]["codex_auth"])
        self.assertFalse(report["credential_files_present"]["yadm_encrypted_archive"])
        self.run.assert_not_called()

    def test_conda_discovery_and_shared_metadata(self):
        root = self.home / "custom forge"
        (root / "bin").mkdir(parents=True)
        (root / "bin/conda").touch()
        (root / "pkgs").mkdir(mode=0o2770)
        (root / "pkgs").chmod(0o2770)
        os.environ["CONDA_EXE"] = str(root / "bin/conda")
        code, report = self.inspect()
        self.assertEqual(code, 0)
        self.assertIn(str(root), report["conda_roots"])
        packages = next(item for item in report["shared_paths"] if item["path"] == str(root / "pkgs"))
        self.assertEqual(packages["mode"], "2770")
        self.assertTrue(packages["setgid"])
        self.assertTrue(packages["group_writable"])

    def test_shared_root_comes_from_this_machine_data(self):
        config = self.home / '.config/yadm/machines/test-host.json'
        config.parent.mkdir(parents=True)
        shared = self.home / 'custom shared root'
        shared.mkdir()
        config.write_text(json.dumps({'hostname': 'test-host', 'shared_root': str(shared),
                                      'shared_group': 'fixture-team', 'dotfiles_user': 'fixture'}))
        code, report = self.inspect()
        self.assertEqual(code, 0)
        self.assertTrue(report['machine_config']['loaded'])
        self.group_query.assert_called_once_with('fixture-team')
        self.assertIn(str(shared), [p['path'] for p in report['shared_paths']])
        self.assertNotIn('/ssd_4t/shared', [p['path'] for p in report['shared_paths']])

    def test_unknown_machine_has_no_guessed_shared_disk(self):
        code, report = self.inspect()
        self.assertEqual(code, 0)
        self.assertFalse(report['machine_config']['loaded'])
        self.assertTrue(any('shared root is unknown' in d for d in report['diagnostics']))
        self.assertNotIn('/ssd_4t/shared', [p['path'] for p in report['shared_paths']])

    def test_hf_inventory_is_metadata_only_and_uses_machine_paths(self):
        config = self.home / '.config/yadm/machines/test-host.json'
        config.parent.mkdir(parents=True)
        prefix = self.home / 'test prefix'
        runtime = prefix / 'lib/huggingface/hf_runtime.py'
        runtime.parent.mkdir(parents=True)
        runtime.write_text('raise RuntimeError("Must not execute")')
        config.write_text(json.dumps({'hostname': 'test-host', 'shared_root': str(self.home / 'shared'),
                                     'shared_group': 'fixture-team', 'dotfiles_user': 'fixture',
                                     'huggingface': {'prefix': str(prefix), 'tools_root': str(self.home / 'tools')}}))
        code, report = self.inspect()
        self.assertEqual(code, 0)
        paths = report['huggingface_paths']
        self.assertEqual(paths['public_cache']['path'], str(self.home / 'shared/huggingface/hub'))
        self.assertTrue(paths['lib/huggingface/hf_runtime.py']['exists'])
        self.assertFalse(paths['hf']['exists'])
        self.run.assert_not_called()

    def test_invalid_machine_data_is_reported_without_creating_paths(self):
        config = self.home / '.config/yadm/machines/test-host.json'
        config.parent.mkdir(parents=True)
        config.write_text(json.dumps({'hostname': 'test-host', 'shared_root': 'relative/root',
                                      'shared_group': 'datausers', 'dotfiles_user': 'fixture'}))
        _, report = self.inspect()
        self.assertFalse(report['machine_config']['loaded'])
        self.assertTrue(any('shared_root' in d for d in report['diagnostics']))

    def test_conda_executable_symlink_identifies_actual_root(self):
        root = self.home / "actual conda root"
        (root / "bin").mkdir(parents=True)
        (root / "bin/conda").touch()
        link = self.home / "some-prefix/bin/conda"
        link.parent.mkdir(parents=True)
        link.symlink_to(root / "bin/conda")
        os.environ["CONDA_EXE"] = str(link)
        self.assertIn(root, status.conda_roots(self.home))
        self.assertNotIn(link.parent.parent, status.conda_roots(self.home))

    def test_conda_path_only_custom_root_is_discovered_without_running_conda(self):
        root = self.home.parent / "srv/miniforge"
        executable = root / "bin/conda"
        executable.parent.mkdir(parents=True)
        executable.touch()
        self.discovery.stop()
        with patch.object(status.shutil, "which",
                          side_effect=lambda name: str(executable) if name == "conda" else self.which(name)):
            code, report = self.inspect()
        self.assertEqual(code, 0)
        self.assertIn(str(root), report["conda_roots"])
        self.run.assert_not_called()

    def test_configured_conda_root_is_first_and_preserves_other_installations(self):
        configured = self.home / "custom Conda installation"
        common = self.home / "miniforge3"
        for root in (configured, common):
            (root / "bin").mkdir(parents=True)
            (root / "bin/conda").touch()
        os.environ.update(DOTFILES_CONDA_ROOT=str(configured), CONDA_EXE=str(common / "bin/conda"))
        before = sorted(str(path.relative_to(self.home)) for path in self.home.rglob("*"))
        code, report = self.inspect()
        self.assertEqual(code, 0)
        self.assertEqual(report["conda_roots"][0], str(configured))
        self.assertIn(str(common), report["conda_roots"])
        self.assertEqual(before, sorted(str(path.relative_to(self.home)) for path in self.home.rglob("*")))
        self.run.assert_not_called()

    def test_configured_conda_root_needs_installation_markers(self):
        common = self.home / "miniforge3"
        (common / "bin").mkdir(parents=True)
        (common / "bin/conda").touch()
        empty = self.home / "empty root"
        empty.mkdir()
        nonexistent = self.home / "missing root"
        for override in ("", str(empty), str(nonexistent)):
            with self.subTest(override=override):
                os.environ["DOTFILES_CONDA_ROOT"] = override
                code, report = self.inspect()
                self.assertEqual(code, 0)
                self.assertIn(str(common), report["conda_roots"])
                self.assertNotIn(str(empty), report["conda_roots"])
                self.assertNotIn(str(nonexistent), report["conda_roots"])
                if override:
                    self.assertTrue(any("DOTFILES_CONDA_ROOT has no recognizable" in message
                                        for message in report["diagnostics"]))
        self.assertFalse(nonexistent.exists())
        self.assertEqual(list(empty.iterdir()), [])
        self.run.assert_not_called()

    def test_relative_conda_override_is_ignored_even_if_it_exists_in_cwd(self):
        relative_root = self.home.parent / "relative-conda"
        common = self.home / "miniforge3"
        for root in (relative_root, common):
            (root / "bin").mkdir(parents=True)
            (root / "bin/conda").touch()
        os.environ["DOTFILES_CONDA_ROOT"] = relative_root.name
        previous_cwd = Path.cwd()
        try:
            os.chdir(self.home.parent)
            code, report = self.inspect()
        finally:
            os.chdir(previous_cwd)
        self.assertEqual(code, 0)
        self.assertIn(str(common), report["conda_roots"])
        self.assertNotIn(str(relative_root), report["conda_roots"])
        self.assertTrue(any("DOTFILES_CONDA_ROOT must be an absolute path" in message
                            for message in report["diagnostics"]))
        self.run.assert_not_called()

    def test_configured_conda_symlink_canonicalizes_and_deduplicates_roots(self):
        actual = self.home / "actual Conda root"
        (actual / "bin").mkdir(parents=True)
        (actual / "bin/conda").touch()
        configured = self.home / "current Conda"
        configured.symlink_to(actual, target_is_directory=True)
        common = self.home / "miniforge3"
        common.symlink_to(actual, target_is_directory=True)
        os.environ.update(DOTFILES_CONDA_ROOT=str(configured),
                          CONDA_EXE=str(common / "bin/conda"))
        code, report = self.inspect()
        self.assertEqual(code, 0)
        self.assertEqual(report["conda_roots"][0], str(actual))
        self.assertEqual(report["conda_roots"].count(str(actual)), 1)
        self.assertNotIn(str(configured), report["conda_roots"])
        self.assertNotIn(str(common), report["conda_roots"])
        self.run.assert_not_called()

    def test_unresolvable_conda_override_keeps_other_root_discovery(self):
        broken = self.home / "symlink loop"
        broken.symlink_to(broken)
        common = self.home / "miniforge3"
        (common / "bin").mkdir(parents=True)
        (common / "bin/conda").touch()
        os.environ["DOTFILES_CONDA_ROOT"] = str(broken)
        code, report = self.inspect()
        self.assertEqual(code, 0)
        self.assertIn(str(common), report["conda_roots"])
        self.assertNotIn(str(broken), report["conda_roots"])
        self.assertTrue(any("DOTFILES_CONDA_ROOT could not be resolved" in message
                            for message in report["diagnostics"]))
        self.run.assert_not_called()

    def test_no_known_conda_root_does_not_claim_conda_is_absent(self):
        with patch.object(status, "conda_roots", return_value=[]):
            code, report = self.inspect()
        self.assertEqual(code, 0)
        self.assertEqual(report["conda_roots"], [])
        self.assertTrue(any("does not prove Conda is absent" in message
                            for message in report["diagnostics"]))

    def test_mac_gui_apps_are_detected_without_homebrew(self):
        (self.home / "Applications/Ghostty.app").mkdir(parents=True)
        (self.home / "Applications/kitty.app").mkdir(parents=True)
        (self.home / "Library/Input Methods/Squirrel.app").mkdir(parents=True)
        self.available.add("brew")
        code, report = self.inspect("Darwin")
        self.assertEqual(code, 0)
        self.assertTrue(all(app["state"] == "present" for app in report["mac_apps"].values()))
        self.run.assert_not_called()

    def test_optional_gpu_query_never_changes_strict_success(self):
        self.available.add("nvidia-smi")
        self.set_query("Example GPU, 555.42, 24576\n")
        code, report = self.inspect(strict=True)
        self.assertEqual(code, 0)
        self.assertEqual(report["gpu"]["devices"][0]["memory_mib"], 24576)
        self.assertEqual(self.run.call_args.kwargs["timeout"], 5)
        self.run.side_effect = subprocess.TimeoutExpired("nvidia-smi", 5)
        code, report = self.inspect(strict=True)
        self.assertEqual(code, 0)
        self.assertEqual(report["gpu"]["state"], "query-failed")

    def test_group_membership_distinguishes_account_and_current_session(self):
        self.groups.stop()
        group = types.SimpleNamespace(gr_gid=4321, gr_mem=["test-user"])
        account = types.SimpleNamespace(pw_gid=1000, pw_name="test-user")
        with patch.object(status.grp, "getgrnam", return_value=group), \
                patch.object(status.pwd, "getpwuid", return_value=account), \
                patch.object(status.os, "getgroups", return_value=[1000]), \
                patch.object(status.os, "getegid", return_value=1000):
            report = status.shared_group_status('fixture-team')
        self.assertTrue(report["account_member"])
        self.assertFalse(report["current_process_member"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
