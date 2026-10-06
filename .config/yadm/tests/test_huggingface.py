"""Offline HF runtime tests using isolated installations and personal homes."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[2] / 'huggingface'
sys.path.insert(0, str(SOURCE))
from hf_runtime import environment


class HuggingFaceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='hf runtime ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / 'personal home'
        self.home.mkdir()
        self.prefix = self.root / 'installation prefix'
        self.site = {'public_cache': str(self.root / 'shared disk/huggingface/hub'),
                     'endpoint': 'https://mirror.example', 'tools_root': str(self.root / 'CLI tools')}
        self.library = self.prefix / 'lib/huggingface'
        self.library.mkdir(parents=True)
        shutil.copyfile(SOURCE / 'hf_runtime.py', self.library / 'hf_runtime.py')
        (self.library / 'hf_runtime.py').chmod(0o755)
        self.write_site()
        (self.prefix / 'bin').mkdir()
        for name in ('hf', 'hf-public', 'hf-private'):
            (self.prefix / 'bin' / name).symlink_to('../lib/huggingface/hf_runtime.py')
        self.env = {'HOME': str(self.home), 'PATH': os.environ['PATH']}
        self.probe = 'import json,os; print(json.dumps({k:v for k,v in os.environ.items() if k.startswith("HF_")}))'

    def write_site(self):
        (self.library / 'site.json').write_text(json.dumps(self.site))

    def command(self, name, args, env=None):
        return subprocess.run([str(self.prefix / 'bin' / name), *args],
                              env=env or self.env, cwd=self.root, text=True, capture_output=True, timeout=10)

    def test_public_removes_credentials_and_uses_machine_cache(self):
        original = dict(self.env, HF_TOKEN='fixture-secret', HUGGING_FACE_HUB_TOKEN='fixture-secret',
                        HF_HUB_CACHE='/previous/private-cache', TRANSFORMERS_CACHE='/previous/private-cache',
                        HF_DATASETS_CACHE='/project/processed')
        result = environment('public', original, self.site)
        self.assertNotIn('HF_TOKEN', result)
        self.assertNotIn('HUGGING_FACE_HUB_TOKEN', result)
        self.assertEqual(result['HF_TOKEN_PATH'], '/dev/null')
        self.assertEqual(result['HF_HUB_CACHE'], self.site['public_cache'])
        self.assertEqual(result['TRANSFORMERS_CACHE'], self.site['public_cache'])
        self.assertEqual(result['HF_DATASETS_CACHE'], '/project/processed')
        self.assertEqual(original['HF_TOKEN'], 'fixture-secret')

    def test_private_uses_official_endpoint_and_personal_storage(self):
        result = environment('private', dict(self.env, HF_TOKEN='fixture-secret'), self.site)
        self.assertEqual(result['HF_ENDPOINT'], 'https://huggingface.co')
        self.assertEqual(result['HF_HUB_CACHE'], str(self.home / '.cache/huggingface/private-hub'))
        self.assertEqual(result['HF_TOKEN'], 'fixture-secret')
        self.assertEqual(result['HF_TOKEN_PATH'], str(self.home / '.cache/huggingface/token'))

    def test_cli_preserves_project_overrides(self):
        custom = dict(self.env, HF_HOME='/project/personal', HF_HUB_CACHE='/project/cache',
                      HF_ENDPOINT='https://huggingface.co')
        result = environment('cli', custom, self.site)
        for key in ('HF_HOME', 'HF_HUB_CACHE', 'HF_ENDPOINT'):
            self.assertEqual(result[key], custom[key])

    def test_runtime_reads_site_paths_without_shell_interpretation(self):
        self.site['public_cache'] = str(self.root / "disk ' $(touch NEVER_CREATED)/hub")
        self.write_site()
        result = self.command('hf-public', [sys.executable, '-c', self.probe])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['HF_HUB_CACHE'], self.site['public_cache'])
        self.assertFalse((self.root / 'NEVER_CREATED').exists())

    def test_different_machine_paths_require_no_runtime_code_change(self):
        for folder in ('first shared disk', 'another shared disk'):
            self.site['public_cache'] = str(self.root / folder / 'huggingface/hub')
            self.write_site()
            result = self.command('hf-public', [sys.executable, '-c', self.probe])
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout)['HF_HUB_CACHE'], self.site['public_cache'])

    def test_private_process_creates_owner_only_files(self):
        code = 'import pathlib,os,json; p=pathlib.Path(os.environ["HF_HOME"])/"fixture"; p.write_text("fixture"); print(json.dumps(p.stat().st_mode & 0o777))'
        result = self.command('hf-private', [sys.executable, '-c', code])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), 0o600)

    def test_auth_uses_private_environment_and_configured_backend(self):
        tools = Path(self.site['tools_root']) / 'bin'
        tools.mkdir(parents=True)
        backend = tools / 'hf'
        backend.write_text('#!/usr/bin/env python3\n' + self.probe + '\n')
        backend.chmod(0o755)
        result = self.command('hf', ['auth', 'whoami'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['HF_ENDPOINT'], 'https://huggingface.co')
        self.assertEqual(self.command('hf-public', ['hf', 'auth', 'login']).returncode, 2)

    def test_missing_site_reports_error_without_creating_personal_cache(self):
        (self.library / 'site.json').unlink()
        result = self.command('hf-public', [sys.executable, '-c', self.probe])
        self.assertEqual(result.returncode, 2)
        self.assertFalse((self.home / '.cache').exists())


if __name__ == '__main__':
    unittest.main()
