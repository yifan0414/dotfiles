"""Run only in temporary homes/repositories; never execute the live bootstrap."""
import os
import plistlib
import shlex
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BOOTSTRAP = (ROOT / '.config/yadm/bootstrap').read_text().rsplit('main "$@"', 1)[0]
BACKUP = ROOT / '.local/bin/yadm-daily-backup'
WAKE = ROOT / '.local/bin/yadm-backup-on-wake'


class Checks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='yadm-check-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / 'home with spaces'
        self.home.mkdir()
        self.env = {k: v for k, v in os.environ.items()
                    if not k.startswith(('GIT_', 'DOTFILES_', 'XDG_', 'NVM_', 'BASH_FUNC_'))
                    and k.lower() not in ('http_proxy', 'https_proxy', 'all_proxy', 'no_proxy')}
        self.env.update(HOME=str(self.home), NO_COLOR='1', DOTFILES_SELF_CHECK='0',
                        GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull)

    def shell(self, code, check=True):
        result = subprocess.run(['/bin/bash', '-c', BOOTSTRAP + '\n' + code],
                                env=self.env, text=True, capture_output=True)
        if check:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_proxy_preserves_existing_settings(self):
        self.env['https_proxy'] = 'http://existing:8080'
        self.shell('configure_proxy; [[ "$https_proxy" == http://existing:8080 ]]; '
                   '[[ -z "${GIT_CONFIG_COUNT:-}" ]]')

    def test_proxy_explicit_is_process_local(self):
        self.env.update(DOTFILES_PROXY_URL='http://localhost:8081', GIT_CONFIG_COUNT='1',
                        GIT_CONFIG_KEY_0='test.existing', GIT_CONFIG_VALUE_0='kept')
        self.shell('configure_proxy; [[ "$https_proxy" == http://localhost:8081 ]]; '
                   '[[ "$(git config http.proxy)" == http://localhost:8081 ]]; '
                   '[[ "$(git config test.existing)" == kept ]]; [[ ! -e "$HOME/.gitconfig" ]]')

    def test_proxy_off(self):
        self.env.update(DOTFILES_PROXY_MODE='off', https_proxy='http://bad:80')
        self.shell('configure_proxy; [[ -z "${https_proxy:-}" ]]; [[ -z "$(git config http.proxy)" ]]')

    def test_failure_status_and_repeated_summary(self):
        self.shell('record_status "optional CLI tools" missing optional; '
                   '[[ "$BOOTSTRAP_FAILURES" == 0 ]]; '
                   'record_status packages failed error; '
                   'record_status "core CLI tools" missing git; '
                   '[[ "$BOOTSTRAP_FAILURES" == 2 ]]; print_summary; print_summary')

    def test_main_exits_nonzero_after_recorded_failure(self):
        result = self.shell('''
          for fn in require_supported_os require_dotfiles_checkout configure_proxy \
            bootstrap_tmux_from_source_on_apt verify_base_tooling require_cmd \
            apply_yadm_alternates verify_alternates bootstrap_vim bootstrap_nvm \
            bootstrap_codex bootstrap_zsh_runtime bootstrap_tmux \
            reload_kitty_if_possible bootstrap_launch_agent; do
            eval "$fn() { :; }"
          done
          bootstrap_system_packages() { record_status packages failed simulated; }
          main
        ''', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('1 failed checks', result.stderr)

    def test_linux_does_not_load_launch_agent(self):
        self.shell('''
          uname() { echo Linux; }
          launchctl() { exit 99; }
          bootstrap_launch_agent
          [[ "${REPORT_STATUSES[0]}" == skipped ]]
        ''')

    def test_incomplete_download_is_retried(self):
        self.shell('''
          curl() { local out; while (( $# )); do
            if [[ "$1" == -fLo ]]; then out="$2"; shift; fi; shift; done
            printf partial > "$out"; return 1;
          }
          bootstrap_vim
          [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]
          curl() { local out; while (( $# )); do
            if [[ "$1" == -fLo ]]; then out="$2"; shift; fi; shift; done
            printf complete > "$out";
          }
          bootstrap_vim
          [[ "$(cat "$HOME/.vim/autoload/plug.vim")" == complete ]]
        ''')

    def test_launch_agent_runs_under_other_home(self):
        plist = plistlib.loads((ROOT / 'Library/LaunchAgents/com.yifan.yadm-daily-backup.plist').read_bytes())
        stub = self.home / '.local/bin/yadm-backup-on-wake'
        stub.parent.mkdir(parents=True)
        stub.write_text('#!/bin/bash\nprintf ran\n')
        stub.chmod(0o755)
        subprocess.run(plist['ProgramArguments'], env=self.env, check=True)
        self.assertEqual((self.home / 'Library/Logs/yadm-daily-backup.log').read_text(), 'ran')

    def test_loaded_launch_agent_is_reloaded(self):
        self.shell('''
          uname() { echo Darwin; }
          plutil() { return 0; }
          launchctl() { printf '%s\\n' "$1" >> "$HOME/calls"; }
          mkdir -p "$HOME/Library/LaunchAgents"
          touch "$HOME/Library/LaunchAgents/com.yifan.yadm-daily-backup.plist"
          bootstrap_launch_agent
          [[ "$(cat "$HOME/calls")" == $'print\\nbootout\\nbootstrap' ]]
        ''')

    def test_wake_failure_retries(self):
        bash_env = self.root / 'env.sh'
        bash_env.write_text('ioreg() { echo \'"SleepWakeUUID" = "new"\'; }\n')
        self.env['BASH_ENV'] = str(bash_env)
        state = self.home / '.local/state/yadm-backup-on-wake'
        state.mkdir(parents=True)
        uuid = state / 'sleepwake.uuid'
        uuid.write_text('old\n')
        stub = self.home / '.local/bin/yadm-daily-backup'
        stub.parent.mkdir(parents=True)
        stub.write_text('#!/bin/bash\nexit 1\n')
        stub.chmod(0o755)
        result = subprocess.run(['/bin/bash', str(WAKE)], env=self.env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(uuid.read_text(), 'old\n')
        stub.write_text('#!/bin/bash\nexit 0\n')
        subprocess.run(['/bin/bash', str(WAKE)], env=self.env, check=True, capture_output=True)
        self.assertEqual(uuid.read_text(), 'new\n')

    def git(self, repo, *args):
        return subprocess.run(['git', '-C', str(repo), *args], env=self.env,
                              check=True, text=True, capture_output=True).stdout.strip()

    def setup_repos(self):
        remote = self.root / 'remote.git'
        subprocess.run(['git', 'init', '--bare', str(remote)], env=self.env,
                       check=True, capture_output=True)
        self.repos = []
        for name in ('mac-one', 'linux-one', 'linux-two'):
            repo = self.root / name
            self.git(self.root, 'clone', str(remote), str(repo))
            self.git(repo, 'config', 'core.worktree', str(repo))
            self.git(repo, 'config', 'user.name', 'Bootstrap Test')
            self.git(repo, 'config', 'user.email', 'bootstrap-test@example.invalid')
            self.repos.append(repo)
        first = self.repos[0]
        self.git(first, 'checkout', '-b', 'shared')
        (first / 'config').write_text('base\n')
        self.git(first, 'add', 'config')
        self.git(first, 'commit', '-m', 'test: initial configuration')
        self.git(first, 'push', '-u', 'origin', 'shared')
        for repo in self.repos[1:]:
            self.git(repo, 'fetch', 'origin')
            self.git(repo, 'checkout', '-b', 'local-name', '--track', 'origin/shared')
        bash_env = self.root / 'env.sh'
        bash_env.write_text('yadm() { command ' + shlex.quote(shutil.which('yadm')) +
                            ' --yadm-repo "$TEST_REPO/.git" --yadm-config "$TEST_REPO/.git/yadm-config" "$@"; }\n')
        self.env['BASH_ENV'] = str(bash_env)

    def backup(self, repo):
        return subprocess.run(['/bin/bash', str(BACKUP)], env=dict(self.env, TEST_REPO=str(repo)),
                              text=True, capture_output=True)

    def test_three_machine_sync_and_different_branch_names(self):
        self.setup_repos()
        for i, repo in enumerate(self.repos):
            result = self.backup(repo)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            with (repo / 'config').open('a') as file:
                file.write(f'machine {i}\n')
            result = self.backup(repo)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for repo in self.repos:
            result = self.backup(repo)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual((repo / 'config').read_text(), 'base\nmachine 0\nmachine 1\nmachine 2\n')

    def test_conflict_is_not_committed_or_pushed(self):
        self.setup_repos()
        first, second, _ = self.repos
        (first / 'config').write_text('first machine\n')
        self.assertEqual(self.backup(first).returncode, 0)
        (second / 'config').write_text('second machine\n')
        result = self.backup(second)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.git(second, 'ls-files', '-u'))
        self.assertEqual(self.git(second, 'rev-parse', 'origin/shared'), self.git(first, 'rev-parse', 'HEAD'))
        self.assertNotEqual(self.backup(second).returncode, 0)

    def test_backup_lock_stops_concurrent_run(self):
        lock = self.home / '.local/state/yadm-daily-backup/lock'
        lock.mkdir(parents=True)
        self.assertEqual(self.backup(self.home).returncode, 75)


if __name__ == '__main__':
    unittest.main(verbosity=2)
