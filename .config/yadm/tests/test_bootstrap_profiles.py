"""Exercise bootstrap policy only in temporary homes with installers stubbed."""

import json
import os
import shlex
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BOOTSTRAP = (ROOT / ".config/yadm/bootstrap").read_text().rsplit('main "$@"', 1)[0]
GIT = shutil.which("git")
NODE = shutil.which("node")
YADM = shutil.which("yadm")


class BootstrapProfileTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="yadm-policy-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home with spaces"
        self.home.mkdir()
        self.env = {key: value for key, value in os.environ.items()
                    if not key.startswith(("GIT_", "DOTFILES_", "XDG_", "NVM_", "PI_", "BASH_FUNC_"))
                    and key not in ("BASH_ENV", "ENV")}
        self.env.update(HOME=str(self.home), NO_COLOR="1", DOTFILES_SELF_CHECK="0",
                        GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        # All installer and auth entry points fail without executing anything.
        self.guards = """
          forbidden() { touch "$HOME/unexpected-installer"; return 125; }
          for fn in curl brew apt-get dnf pacman sudo npm pi codex yadm; do
            eval "$fn() { forbidden; }"
          done
        """
        if GIT:
            self.guards += "git() { if [[ \"$1\" == config ]]; then command " + shlex.quote(GIT) + \
                           " \"$@\"; else forbidden; fi; }\n"
        else:
            self.guards += "git() { forbidden; }\n"

    def shell(self, code, check=True):
        result = subprocess.run(["/bin/bash", "-c", BOOTSTRAP + "\n" + self.guards + "\n" + code],
                                env=self.env, text=True, capture_output=True)
        self.assertFalse((self.home / "unexpected-installer").exists(), result.stdout + result.stderr)
        if check:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def stored_class(self, role):
        repo = self.home / ".local/share/yadm/repo.git"
        repo.mkdir(parents=True, exist_ok=True)
        (repo / "config").write_text("[local]\n class = " + role + "\n")

    def select(self, system):
        return self.shell("uname() { printf '%s\\n' " + shlex.quote(system) + "; }; "
                          "resolve_machine_profile; "
                          "printf '%s|%s' \"$DOTFILES_MACHINE_PROFILE\" \"$DOTFILES_INSTALL_GUI_APPS\"")

    def stub_main(self):
        # Keep role resolution, failure accumulation and handoff behavior real.
        return """
          for fn in require_dotfiles_checkout configure_proxy bootstrap_gh_auth \
              bootstrap_tmux_from_source_on_apt verify_base_tooling require_cmd \
              apply_yadm_alternates verify_alternates bootstrap_vim bootstrap_nvm \
              bootstrap_codex bootstrap_pi bootstrap_zsh_runtime bootstrap_tmux \
              reload_kitty_if_possible verify_setup_skill; do
            eval "$fn() { :; }"
          done
        """

    def test_mac_linux_auto_defaults_and_explicit_gui_zero(self):
        for system, role, gui in (("Darwin", "mac-client", "1"), ("Linux", "dl-server", "0")):
            with self.subTest(system=system):
                self.env.pop("DOTFILES_INSTALL_GUI_APPS", None)
                self.assertEqual(self.select(system).stdout, role + "|" + gui)
                self.env["DOTFILES_INSTALL_GUI_APPS"] = "0"
                self.assertEqual(self.select(system).stdout, role + "|0")

    @unittest.skipUnless(GIT, "git required for real local.class fixture reads")
    def test_explicit_environment_overrides_stored_role(self):
        self.stored_class("dl-server")
        self.env["DOTFILES_MACHINE_PROFILE"] = "mac-client"
        self.assertEqual(self.select("Darwin").stdout, "mac-client|1")
        self.stored_class("unknown-stored-role")
        self.assertEqual(self.select("Darwin").stdout, "mac-client|1")

    @unittest.skipUnless(GIT and YADM, "git and yadm required for local.class API fixture")
    def test_yadm_local_class_uses_machine_local_repository_config(self):
        repo = self.home / ".local/share/yadm/repo.git"
        repo.parent.mkdir(parents=True)
        subprocess.run([GIT, "init", "--bare", str(repo)], env=self.env,
                       check=True, capture_output=True)
        config = self.home / ".config/yadm/test-config"
        config.parent.mkdir(parents=True)
        original = "[test]\n keep = unchanged\n"
        config.write_text(original)
        subprocess.run([YADM, "--yadm-repo", str(repo), "--yadm-config", str(config),
                        "config", "local.class", "dl-server"], env=self.env,
                       check=True, capture_output=True)
        stored = subprocess.run([GIT, "config", "--file", str(repo / "config"),
                                 "--get", "local.class"], env=self.env,
                                check=True, text=True, capture_output=True)
        self.assertEqual(stored.stdout.strip(), "dl-server")
        self.assertEqual(config.read_text(), original)
        absent = subprocess.run([GIT, "config", "--file", str(config), "--get", "local.class"],
                                env=self.env, capture_output=True)
        self.assertEqual(absent.returncode, 1)
        self.assertEqual(self.select("Linux").stdout, "dl-server|0")

    @unittest.skipUnless(GIT, "git required for real local.class fixture reads")
    def test_environment_auto_consults_initialized_class(self):
        self.env["DOTFILES_MACHINE_PROFILE"] = "auto"
        self.stored_class("mac-client")
        self.assertEqual(self.select("Darwin").stdout, "mac-client|1")
        self.stored_class("dl-server")
        result = self.shell("uname() { printf 'Darwin\\n'; }; resolve_machine_profile", check=False)
        self.assertNotEqual(result.returncode, 0)

    @unittest.skipUnless(GIT, "git required for real local.class fixture reads")
    def test_invalid_and_mismatched_roles_fail_before_packages(self):
        cases = (("unknown", None), ("mac-client", None),
                 ("auto", "auto"), ("auto", "unknown"), ("auto", "mac-client"))
        for environment, stored in cases:
            with self.subTest(environment=environment, stored=stored):
                self.env["DOTFILES_MACHINE_PROFILE"] = environment
                if stored:
                    self.stored_class(stored)
                result = self.shell(self.stub_main() + """
                  uname() { printf 'Linux\n'; }
                  bootstrap_system_packages() { touch "$HOME/packages-called"; }
                  main
                """, check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse((self.home / "packages-called").exists())

    @unittest.skipUnless(GIT, "git required for real local.class fixture reads")
    def test_reading_local_class_runs_neither_yadm_nor_config_hooks(self):
        self.stored_class("dl-server")
        hooks = self.home / ".config/yadm/hooks"
        hooks.mkdir(parents=True)
        for name in ("pre_config", "post_config"):
            hook = hooks / name
            hook.write_text('#!/bin/bash\ntouch "$HOME/hook-called"\n')
            hook.chmod(0o755)
        before = sorted(str(path.relative_to(self.home)) for path in self.home.rglob("*"))
        self.assertEqual(self.select("Linux").stdout, "dl-server|0")
        self.assertFalse((self.home / "hook-called").exists())
        self.assertEqual(before, sorted(str(path.relative_to(self.home)) for path in self.home.rglob("*")))

    def test_setup_skill_requires_every_reference_target(self):
        skill = self.home / ".agents/skills/setup-machine"
        (skill / "references").mkdir(parents=True)
        (skill / "SKILL.md").write_text("fixture skill\n")
        docs = self.home / ".config/yadm/docs"
        docs.mkdir(parents=True)
        targets = []
        for name in ("machine-setup.md", "mac-client.md", "dl-server.md", "conda-management.md"):
            target = docs / name
            target.write_text("fixture policy\n")
            (skill / "references" / name).symlink_to(target)
            targets.append(target)
        self.shell('verify_setup_skill; [[ "$BOOTSTRAP_FAILURES" == 0 ]]')
        for target in [skill / "SKILL.md", *targets]:
            with self.subTest(missing=target.name):
                contents = target.read_text()
                target.unlink()
                self.shell('verify_setup_skill; [[ "$BOOTSTRAP_FAILURES" == 1 ]]')
                target.write_text(contents)

    def test_main_prints_setup_handoff_despite_accumulated_failure(self):
        self.env["DOTFILES_MACHINE_PROFILE"] = "dl-server"
        result = self.shell(self.stub_main() + """
          uname() { printf 'Linux\n'; }
          bootstrap_system_packages() { record_status packages failed simulated; }
          main
        """, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Next: finish this machine as dl-server using setup-machine", result.stdout)
        self.assertIn("pi --skill", result.stdout)
        self.assertIn("--profile dl-server --strict", result.stdout)
        self.assertIn("1 failed checks", result.stderr)

    def test_occupied_nvm_directory_and_hidden_contents_are_preserved(self):
        directory = self.home / ".nvm"
        directory.mkdir()
        sentinel = directory / ".keep-this"
        sentinel.write_text("existing state\n")
        self.shell('load_nvm() { return 1; }; bootstrap_nvm; [[ "$BOOTSTRAP_FAILURES" == 1 ]]')
        self.assertEqual(sentinel.read_text(), "existing state\n")

    def test_failed_nvm_directory_inspection_does_not_remove_or_clone(self):
        directory = self.home / ".nvm"
        directory.mkdir()
        self.shell('load_nvm() { return 1; }; find() { return 1; }; '
                   'bootstrap_nvm; [[ "$BOOTSTRAP_FAILURES" == 1 ]]')
        self.assertTrue(directory.is_dir())
        self.assertEqual(list(directory.iterdir()), [])

    def test_empty_nvm_directory_can_be_populated_by_stub_installer(self):
        (self.home / ".nvm").mkdir()
        self.shell("""
          load_count=0
          load_nvm() { load_count=$((load_count + 1)); [[ "$load_count" -gt 1 ]]; }
          nvm() { [[ "$1" == --version ]]; printf 'fixture-nvm\n'; }
          git() { [[ "$1" == clone ]]; mkdir -p "$NVM_DIR/.git"; }
          bootstrap_nvm
          [[ "$BOOTSTRAP_FAILURES" == 0 && -d "$NVM_DIR/.git" ]]
        """)

    def test_codex_reuses_only_a_working_cli(self):
        self.shell("""
          ensure_node_lts() { :; }
          codex() { [[ "$1" == --version ]]; }
          bootstrap_codex
          [[ "$BOOTSTRAP_FAILURES" == 0 && "${REPORT_STATUSES[0]}" == present ]]
        """)

    def test_codex_repairs_an_existing_cli_that_cannot_run(self):
        self.shell("""
          ensure_node_lts() { :; }
          codex() { [[ "$1" == --version && -f "$HOME/codex-installed" ]]; }
          npm() { [[ "$*" == "install -g @openai/codex" ]]; touch "$HOME/codex-installed"; }
          bootstrap_codex
          [[ "$BOOTSTRAP_FAILURES" == 0 && "${REPORT_STATUSES[0]}" == installed ]]
          [[ -f "$HOME/codex-installed" ]]
        """)

    def test_codex_successful_npm_install_without_cli_is_a_failure(self):
        self.shell("""
          ensure_node_lts() { :; }
          command() {
            if [[ "$1" == -v && "$2" == codex ]]; then return 1; fi
            builtin command "$@"
          }
          npm() { [[ "$*" == "install -g @openai/codex" ]]; }
          bootstrap_codex
          [[ "$BOOTSTRAP_FAILURES" == 1 && "${REPORT_STATUSES[0]}" == failed ]]
        """)

    def test_codex_successful_npm_install_with_broken_cli_is_a_failure(self):
        self.shell("""
          ensure_node_lts() { :; }
          codex() { return 1; }
          npm() { [[ "$*" == "install -g @openai/codex" ]]; }
          bootstrap_codex
          [[ "$BOOTSTRAP_FAILURES" == 1 && "${REPORT_STATUSES[0]}" == failed ]]
        """)

    def test_explicit_codex_update_refreshes_a_working_cli(self):
        self.env["DOTFILES_UPDATE_AGENTS"] = "1"
        self.shell("""
          ensure_node_lts() { :; }
          codex() { [[ "$1" == --version ]]; }
          npm() { [[ "$*" == "install -g @openai/codex" ]]; touch "$HOME/codex-updated"; }
          bootstrap_codex
          [[ "$BOOTSTRAP_FAILURES" == 0 && "${REPORT_STATUSES[0]}" == installed ]]
          [[ -f "$HOME/codex-updated" ]]
        """)

    def pi_fixtures(self):
        npm_root = self.home / "npm-root"
        for name in ("pi-coding-agent", "pi-ai", "pi-tui"):
            package = npm_root / "@earendil-works" / name / "package.json"
            package.parent.mkdir(parents=True)
            package.write_text("{}\n")
        agent = self.home / ".pi/agent"
        agent.mkdir(parents=True)
        (agent / "settings.json").write_text(json.dumps({"packages": [
            "npm:pi-web-access", {"source": "npm:pi-open-tui"}]}))
        for name in ("pi-web-access", "pi-open-tui"):
            package = agent / "npm/node_modules" / name / "package.json"
            package.parent.mkdir(parents=True)
            package.write_text("{}\n")
        return agent, npm_root

    def pi_stubs(self):
        return """
          npm() {
            case "$*" in
              "root -g") printf '%s\n' "$HOME/npm-root" ;;
              "install -g @earendil-works/pi-coding-agent@latest @earendil-works/pi-ai@latest @earendil-works/pi-tui@latest")
                touch "$HOME/npm-installed" ;;
              *) return 1 ;;
            esac
          }
          pi() {
            case "$*" in
              --version) printf 'fixture-pi\n' ;;
              "install npm:pi-web-access") touch "$HOME/web-installed" ;;
              "install npm:pi-open-tui") touch "$HOME/tui-installed" ;;
              *) return 1 ;;
            esac
          }
        """ + "node() { case \"$1\" in -e) return 0 ;; -) command " + shlex.quote(NODE or "node") + \
               " \"$@\" ;; *) return 1 ;; esac; }\n"

    @unittest.skipUnless(NODE, "Node needed only for the real JSON fixture parser")
    def test_pi_reuses_complete_active_core_peers_and_registered_cached_plugins(self):
        self.pi_fixtures()
        self.shell(self.pi_stubs() + 'bootstrap_pi; [[ "$BOOTSTRAP_FAILURES" == 0 ]]')
        for marker in ("npm-installed", "web-installed", "tui-installed"):
            self.assertFalse((self.home / marker).exists())

    @unittest.skipUnless(NODE, "Node needed only for the real JSON fixture parser")
    def test_pi_reinstalls_only_plugin_whose_cache_is_missing(self):
        agent, _ = self.pi_fixtures()
        (agent / "npm/node_modules/pi-web-access/package.json").unlink()
        self.shell(self.pi_stubs() + 'bootstrap_pi; [[ "$BOOTSTRAP_FAILURES" == 0 ]]')
        self.assertTrue((self.home / "web-installed").exists())
        self.assertFalse((self.home / "tui-installed").exists())
        self.assertFalse((self.home / "npm-installed").exists())

    @unittest.skipUnless(NODE, "Node needed only for the real JSON fixture parser")
    def test_pi_reinstalls_cached_plugin_missing_from_registry(self):
        agent, _ = self.pi_fixtures()
        (agent / "settings.json").write_text(json.dumps({"packages": ["npm:pi-open-tui"]}))
        self.shell(self.pi_stubs() + 'bootstrap_pi; [[ "$BOOTSTRAP_FAILURES" == 0 ]]')
        self.assertTrue((self.home / "web-installed").exists())
        self.assertFalse((self.home / "tui-installed").exists())
        self.assertFalse((self.home / "npm-installed").exists())

    @unittest.skipUnless(NODE, "Node needed only for the real JSON fixture parser")
    def test_pi_missing_core_peer_requires_core_install(self):
        _, npm_root = self.pi_fixtures()
        (npm_root / "@earendil-works/pi-ai/package.json").unlink()
        self.shell(self.pi_stubs() + 'bootstrap_pi; [[ "$BOOTSTRAP_FAILURES" == 0 ]]')
        self.assertTrue((self.home / "npm-installed").exists())
        self.assertFalse((self.home / "web-installed").exists())
        self.assertFalse((self.home / "tui-installed").exists())

    @unittest.skipUnless(NODE, "Node needed only for the real JSON fixture parser")
    def test_explicit_agent_update_refreshes_core_and_both_plugins(self):
        self.pi_fixtures()
        self.env["DOTFILES_UPDATE_AGENTS"] = "1"
        self.shell(self.pi_stubs() + 'bootstrap_pi; [[ "$BOOTSTRAP_FAILURES" == 0 ]]')
        for marker in ("npm-installed", "web-installed", "tui-installed"):
            self.assertTrue((self.home / marker).exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
