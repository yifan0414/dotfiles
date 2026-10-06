"""Offline tests of machine selection, installed entrypoints and repeatable deployment."""

import importlib.util
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import types
import unittest

SOURCE = Path(__file__).resolve().parents[2] / 'huggingface'
sys.path.insert(0, str(SOURCE))
from hf_runtime import environment, merge_shell, shell_block, site_settings
SPEC = importlib.util.spec_from_file_location('hf_deploy', SOURCE / 'deploy.py')
deploy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(deploy)


class HuggingFaceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='hf deployment ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / 'personal home'
        self.home.mkdir()
        self.prefix = self.root / 'installation prefix'
        self.machine = {'hostname': 'fixture-server', 'shared_root': str(self.root / 'shared disk'),
                        'shared_group': 'fixture-group', 'dotfiles_user': 'fixture-user',
                        'huggingface': {'prefix': str(self.prefix), 'tools_root': str(self.root / 'tools'),
                                        'python': sys.executable, 'endpoint': 'https://mirror.example'}}
        self.site = site_settings(self.machine)
        self.account = types.SimpleNamespace(pw_name='fixture-user', pw_dir=str(self.home),
                                            pw_uid=os.getuid(), pw_gid=os.getgid())
        (self.home / '.zshrc').write_text('source "$HOME/.zshrc.local"\n')
        candidate = self.home / '.zshrc.local##hostname.fixture-server'
        candidate.write_text('export KEEP_EXISTING=present\n')
        self.env = {'HOME': str(self.home), 'PATH': os.environ['PATH']}
        self.probe = 'import json,os; print(json.dumps({k:v for k,v in os.environ.items() if k.startswith("HF_")}))'

    def deploy_fixture(self):
        plan = deploy.file_plan(self.machine, [self.account], system_ids=(os.getuid(), os.getgid()))
        backup = self.root / 'backup'
        backup.mkdir(exist_ok=True)
        return plan, deploy.apply_files(plan, backup)

    def command(self, name, args, env=None):
        return subprocess.run([str(self.prefix / 'bin' / name), *args],
                              env=env or self.env, cwd=self.root, text=True, capture_output=True, timeout=10)

    def test_public_removes_credentials_and_uses_the_machine_cache(self):
        original = dict(self.env, HF_TOKEN='fixture-secret', HUGGING_FACE_HUB_TOKEN='fixture-secret',
                        HF_HUB_CACHE='/previous/private-cache', TRANSFORMERS_CACHE='/previous/private-cache',
                        HF_DATASETS_CACHE='/project/processed')
        public = environment('public', original, self.site)
        self.assertNotIn('HF_TOKEN', public)
        self.assertNotIn('HUGGING_FACE_HUB_TOKEN', public)
        self.assertEqual(public['HF_TOKEN_PATH'], '/dev/null')
        self.assertEqual(public['HF_HUB_CACHE'], self.site['public_cache'])
        self.assertEqual(public['TRANSFORMERS_CACHE'], self.site['public_cache'])
        self.assertEqual(public['HF_DATASETS_CACHE'], '/project/processed')
        self.assertEqual(original['HF_TOKEN'], 'fixture-secret')

    def test_private_uses_official_endpoint_and_per_user_storage(self):
        private = environment('private', dict(self.env, HF_TOKEN='fixture-secret'), self.site)
        self.assertEqual(private['HF_ENDPOINT'], 'https://huggingface.co')
        self.assertEqual(private['HF_HUB_CACHE'], str(self.home / '.cache/huggingface/private-hub'))
        self.assertEqual(private['HF_TOKEN'], 'fixture-secret')
        self.assertEqual(private['HF_TOKEN_PATH'], str(self.home / '.cache/huggingface/token'))

    def test_cli_preserves_project_overrides(self):
        custom = dict(self.env, HF_HOME='/project/personal', HF_HUB_CACHE='/project/cache',
                      HF_ENDPOINT='https://huggingface.co')
        result = environment('cli', custom, self.site)
        self.assertEqual(result['HF_HOME'], custom['HF_HOME'])
        self.assertEqual(result['HF_HUB_CACHE'], custom['HF_HUB_CACHE'])
        self.assertEqual(result['HF_ENDPOINT'], custom['HF_ENDPOINT'])

    @unittest.skipUnless(shutil.which('zsh'), 'zsh is required')
    def test_shell_and_job_use_same_site_with_spaces_and_shell_metacharacters(self):
        self.machine['shared_root'] = str(self.root / "disk ' $(touch NEVER_CREATED)")
        self.site = site_settings(self.machine)
        self.deploy_fixture()
        cmd = 'source "$HOME/.zshrc.local"; ' + shlex.join([sys.executable, '-c', self.probe])
        shell = subprocess.run(['zsh', '-d', '-c', cmd], env=self.env,
                               cwd=self.root, capture_output=True, text=True, check=True)
        job = self.command('hf-public', [sys.executable, '-c', self.probe])
        self.assertEqual(job.returncode, 0, job.stderr)
        for result in (shell, job):
            self.assertEqual(json.loads(result.stdout)['HF_HUB_CACHE'], self.site['public_cache'])
        self.assertFalse((self.root / 'NEVER_CREATED').exists())

    def test_deployment_is_idempotent_and_detects_installed_drift(self):
        plan, changes = self.deploy_fixture()
        self.assertTrue(changes)
        self.assertTrue(all(deploy.file_matches(p) for p in plan))
        candidate = self.home / '.zshrc.local##hostname.fixture-server'
        self.assertIn('KEEP_EXISTING=present', candidate.read_text())
        self.assertEqual(self.deploy_fixture()[1], [])
        installed = self.prefix / 'lib/huggingface/hf_runtime.py'
        installed.write_text('# changed installation\n')
        drift = [p['path'] for p in plan if not deploy.file_matches(p)]
        self.assertEqual(drift, [installed])
        self.assertEqual(self.deploy_fixture()[1], [str(installed)])

    def test_machine_change_updates_shell_and_job_together(self):
        self.deploy_fixture()
        self.machine['shared_root'] = str(self.root / 'another shared disk')
        self.deploy_fixture()
        result = self.command('hf-public', [sys.executable, '-c', self.probe])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['HF_HUB_CACHE'], self.machine['shared_root'] + '/huggingface/hub')
        self.assertIn(self.machine['shared_root'], (self.home / '.zshrc.local').read_text())

    def test_private_process_creates_owner_only_files(self):
        self.deploy_fixture()
        code = 'import pathlib,os,json; p=pathlib.Path(os.environ["HF_HOME"])/"fixture"; p.write_text("fixture"); print(json.dumps(p.stat().st_mode & 0o777))'
        result = self.command('hf-private', [sys.executable, '-c', code])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), 0o600)

    def test_auth_uses_private_environment_with_configured_backend(self):
        tools = Path(self.site['tools_root']) / 'bin'
        tools.mkdir(parents=True)
        backend = tools / 'hf'
        backend.write_text('#!/usr/bin/env python3\n' + self.probe + '\n')
        backend.chmod(0o755)
        self.deploy_fixture()
        result = self.command('hf', ['auth', 'whoami'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['HF_ENDPOINT'], 'https://huggingface.co')
        self.assertEqual(self.command('hf-public', ['hf', 'auth', 'login']).returncode, 2)

    def test_other_users_get_inline_exports_without_changing_existing_content(self):
        other_home = self.root / 'second user'
        other_home.mkdir()
        rc = other_home / '.zshrc'
        rc.write_text('export EXISTING_OTHER=present\n')
        other = types.SimpleNamespace(pw_name='other', pw_dir=str(other_home), pw_uid=os.getuid(), pw_gid=os.getgid())
        plan = deploy.file_plan(self.machine, [self.account, other], system_ids=(os.getuid(), os.getgid()))
        backup = self.root / 'backup'
        backup.mkdir()
        deploy.apply_files(plan, backup)
        self.assertTrue(rc.read_text().startswith('export EXISTING_OTHER=present\n'))
        self.assertIn('export HF_HUB_CACHE=', rc.read_text())

    def test_ambiguous_markers_and_external_user_symlinks_are_rejected(self):
        with self.assertRaises(ValueError):
            merge_shell('# BEGIN managed Hugging Face settings\n', shell_block(self.site))
        candidate = self.home / '.zshrc.local##hostname.fixture-server'
        candidate.unlink()
        candidate.symlink_to(self.root / 'outside-user-home')
        with self.assertRaises(ValueError):
            deploy.file_plan(self.machine, [self.account])

    def test_entrypoints_cannot_overwrite_the_native_cli(self):
        self.machine['huggingface']['tools_root'] = self.machine['huggingface']['prefix']
        with self.assertRaises(ValueError):
            site_settings(self.machine)


if __name__ == '__main__':
    unittest.main()
