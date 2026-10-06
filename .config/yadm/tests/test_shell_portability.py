"""Check shell modules in temporary homes; never source the live shell config."""
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PROXY = ROOT / '.config/yadm/shell/proxy.zsh'
LINUX = ROOT / '.zshrc##os.Linux'
MAC = ROOT / '.zshrc##os.Darwin'


class ShellPortability(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='yadm-shell-')
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name) / 'home with spaces'
        self.home.mkdir()
        self.env = {key: value for key, value in os.environ.items()
                    if not key.startswith(('GIT_', 'DOTFILES_', 'HOMEBREW_', 'ZDOTDIR'))
                    and key.lower() not in ('http_proxy', 'https_proxy', 'all_proxy', 'no_proxy')
                    and key not in ('HF_ENDPOINT', 'HF_XET_LOG_DIR')}
        self.env.update(HOME=str(self.home), GIT_CONFIG_NOSYSTEM='1',
                        GIT_CONFIG_GLOBAL=str(self.home / '.gitconfig'))
        self.global_config = self.home / '.gitconfig'
        self.global_text = '[http]\n\tproxy = http://saved-global:8080\n'
        self.global_config.write_text(self.global_text)
        self.module = self.home / '.config/yadm/shell/proxy.zsh'
        self.module.parent.mkdir(parents=True)
        shutil.copyfile(PROXY, self.module)
        shutil.copyfile(ROOT / '.zshenv', self.home / '.zshenv')

    def run_shell(self, code, env=None, source_proxy=True, shells=('bash', 'zsh')):
        prefix = 'set -eu\n'
        if source_proxy:
            prefix += 'source "$HOME/.config/yadm/shell/proxy.zsh"\n'
        for shell in shells:
            executable = shutil.which(shell)
            if not executable:
                continue
            with self.subTest(shell=shell):
                options = ['--noprofile', '--norc'] if shell == 'bash' else ['-d']
                result = subprocess.run([executable, *options, '-c', prefix + code],
                                        env=env or self.env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stdout + result.stderr, '')
                self.assertEqual(self.global_config.read_text(), self.global_text)

    def test_inherit_preserves_environment_and_global_git(self):
        env = dict(self.env, https_proxy='http://existing:8080', NO_PROXY='internal.example',
                   GIT_CONFIG_COUNT='1', GIT_CONFIG_KEY_0='test.keep', GIT_CONFIG_VALUE_0='kept')
        self.run_shell('''
          [[ "$https_proxy" == http://existing:8080 && "$NO_PROXY" == internal.example ]]
          [[ "$GIT_CONFIG_COUNT" == 1 && "$GIT_CONFIG_VALUE_0" == kept ]]
          [[ "$(git config http.proxy)" == http://saved-global:8080 ]]
        ''', env)

    def test_explicit_inherit_does_not_enable_an_endpoint(self):
        env = dict(self.env, DOTFILES_PROXY_MODE='inherit',
                   DOTFILES_PROXY_URL='http://explicit:8081')
        self.run_shell('[[ -z "${http_proxy+x}${GIT_CONFIG_COUNT+x}" ]]', env)

    def test_explicit_endpoint_enables_shell_only_git_proxy(self):
        env = dict(self.env, DOTFILES_PROXY_URL='http://explicit:8081',
                   DOTFILES_GIT_PROXY_URL='http://git-endpoint:8082',
                   GIT_CONFIG_COUNT='1', GIT_CONFIG_KEY_0='test.keep', GIT_CONFIG_VALUE_0='kept')
        self.run_shell('''
          [[ "$http_proxy" == http://explicit:8081 && "$HTTPS_PROXY" == "$http_proxy" ]]
          [[ "$GIT_CONFIG_COUNT" == 2 && "$GIT_CONFIG_KEY_0" == test.keep ]]
          [[ "$(git config test.keep)" == kept ]]
          [[ "$(git config http.proxy)" == http://git-endpoint:8082 ]]
        ''', env)

    def test_off_clears_proxy_environment_and_overrides_git_without_writes(self):
        env = dict(self.env, DOTFILES_PROXY_MODE='off', NO_PROXY='internal.example',
                   GIT_CONFIG_COUNT='2', GIT_CONFIG_KEY_0='test.keep', GIT_CONFIG_VALUE_0='kept',
                   GIT_CONFIG_KEY_1='http.proxy', GIT_CONFIG_VALUE_1='http://inherited:8080')
        env.update({key: 'http://old:8080' for key in
                    ('http_proxy', 'https_proxy', 'all_proxy', 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY')})
        self.run_shell('''
          [[ -z "${http_proxy+x}${https_proxy+x}${all_proxy+x}${HTTP_PROXY+x}${HTTPS_PROXY+x}${ALL_PROXY+x}" ]]
          [[ "$NO_PROXY" == internal.example && "$GIT_CONFIG_COUNT" == 3 ]]
          [[ "$GIT_CONFIG_VALUE_1" == http://inherited:8080 ]]
          [[ "$(git config test.keep)" == kept && -z "$(git config http.proxy)" ]]
        ''', env)

    def test_manual_helpers_reuse_their_git_slot_and_preserve_other_entries(self):
        env = dict(self.env, GIT_CONFIG_COUNT='1', GIT_CONFIG_KEY_0='test.keep',
                   GIT_CONFIG_VALUE_0='kept')
        self.run_shell('''
          proxy_on; proxy_on
          [[ "$GIT_CONFIG_COUNT" == 2 && "$http_proxy" == "$proxy_url" ]]
          proxy_toggle
          [[ "$GIT_CONFIG_COUNT" == 2 && -z "${http_proxy+x}" ]]
          proxy_toggle
          [[ "$GIT_CONFIG_COUNT" == 2 && "$http_proxy" == "$proxy_url" ]]
          proxy_off
          [[ "$GIT_CONFIG_COUNT" == 2 && "$(git config test.keep)" == kept ]]
          [[ -z "$(git config http.proxy)" ]]
        ''', env)

    def test_local_shell_file_loads_quietly_with_spaces(self):
        local = self.home / '.config/yadm/local/shell.zsh'
        local.parent.mkdir(parents=True)
        local.write_text('export TASK_LOCAL_PATH="$HOME/a path with spaces"\n'
                         'export DOTFILES_PROXY_MODE=inherit\n')
        self.run_shell('[[ "$TASK_LOCAL_PATH" == "$HOME/a path with spaces" ]]',
                       source_proxy=False, shells=('zsh',))

    def test_missing_local_shell_file_is_quiet(self):
        self.run_shell('[[ -z "${TASK_LOCAL_PATH+x}" ]]', source_proxy=False, shells=('zsh',))

    def test_homebrew_paths_are_resolved_from_the_available_brew(self):
        prefix = self.home / 'brew prefix with spaces'
        (prefix / 'bin').mkdir(parents=True)
        (prefix / 'opt/llvm/bin').mkdir(parents=True)
        brew = prefix / 'bin/brew'
        brew.write_text('#!/bin/sh\nprintf "%s\\n" "$TEST_BREW_PREFIX"\n')
        brew.chmod(0o755)
        code = MAC.read_text().split('prepend_path "$HOME/.local/bin"', 1)[1]
        code = 'prepend_path "$HOME/.local/bin"' + code.split('if [[ -d "/Applications/Xcode.app" ]]', 1)[0]
        env = dict(self.env, PATH=str(prefix / 'bin') + ':' + self.env['PATH'],
                   TEST_BREW_PREFIX=str(prefix), LDFLAGS='existing-linker-flag')
        self.run_shell('prepend_path() { [[ ! -d "$1" ]] || export PATH="$1:$PATH"; }\n' +
                       code + '''
          [[ "$PATH" == "$TEST_BREW_PREFIX/bin:"* ]]
          [[ "$LDFLAGS" == "existing-linker-flag -L$TEST_BREW_PREFIX/opt/llvm/lib" ]]
        ''', env, source_proxy=False)

    def conda_initialization(self):
        code = LINUX.read_text().split('### Conda integration for interactive shells. ###', 1)[1]
        code = code.split('for __conda_root', 1)[1]
        return 'for __conda_root' + code.split('#########################################', 1)[0]

    def test_custom_conda_root_initializes_activation_without_entering_base(self):
        prefix = self.home / 'custom conda root'
        initializer = prefix / 'etc/profile.d/conda.sh'
        initializer.parent.mkdir(parents=True)
        initializer.write_text('export TASK_CONDA_LOADED="$DOTFILES_CONDA_ROOT"\n'
                               'conda() { [[ "$1" == activate ]]; }\n')
        env = dict(self.env, DOTFILES_CONDA_ROOT=str(prefix))
        env.pop('CONDA_PREFIX', None)
        self.run_shell(self.conda_initialization() + '''
          [[ "$TASK_CONDA_LOADED" == "$DOTFILES_CONDA_ROOT" ]]
          [[ -z "${CONDA_PREFIX+x}" ]]
          conda activate
        ''', env, source_proxy=False)

    def test_relative_conda_override_cannot_source_an_initializer_from_cwd(self):
        initializer = self.home / 'relative-root/etc/profile.d/conda.sh'
        initializer.parent.mkdir(parents=True)
        initializer.write_text('exit 99\n')
        env = dict(self.env, DOTFILES_CONDA_ROOT='relative-root')
        # Guard source so fallback discovery never executes a live initializer.
        code = '''
          cd "$HOME"
          source() { [[ "$1" != "$DOTFILES_CONDA_ROOT/etc/profile.d/conda.sh" ]]; }
        ''' + self.conda_initialization()
        self.run_shell(code, env, source_proxy=False)

    def test_actual_shell_files_have_valid_syntax(self):
        zsh = shutil.which('zsh')
        if not zsh:
            self.skipTest('zsh is required to check the platform alternates')
        for path in (ROOT / '.zshenv', PROXY, MAC, LINUX):
            with self.subTest(path=path.name):
                result = subprocess.run([zsh, '-n', str(path)], env=self.env,
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main(verbosity=2)
