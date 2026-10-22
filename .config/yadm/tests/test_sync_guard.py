"""Exercise index scanning and encryption receipts in disposable repositories."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / '.config/yadm/scripts/sync-guard.py'
spec = importlib.util.spec_from_file_location('sync_guard', SCRIPT)
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class SyncGuardTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='yadm-sync-guard-')
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name).resolve() / 'home with spaces'
        self.home.mkdir()
        self.repo = self.home / '.git'
        self.env = {k: v for k, v in os.environ.items()
                    if not k.startswith(('GIT_', 'YADM_', 'XDG_'))}
        self.env.update(HOME=str(self.home), GIT_CONFIG_GLOBAL=os.devnull,
                        GIT_CONFIG_NOSYSTEM='1')
        self.git('init')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        (self.home / 'config').write_text('safe\n')
        self.git('add', 'config')
        self.git('commit', '-m', 'fixture')

    def git(self, *args):
        return subprocess.run(['git', '-C', str(self.home), *args], env=self.env,
                              text=True, capture_output=True, check=True)

    def run_guard(self, mode, **extra):
        return subprocess.run(['python3', str(SCRIPT), mode, '--home', str(self.home),
                               '--repo', str(self.repo)], env=dict(self.env, **extra),
                              capture_output=True, text=True)

    def private_files(self):
        config = self.home / '.config/yadm'
        config.mkdir(parents=True)
        (config / 'encrypt').write_text('.pi/agent/auth.json\n')
        auth = self.home / '.pi/agent/auth.json'
        auth.parent.mkdir(parents=True)
        auth.write_text('fixture-private-value')
        archive = self.home / '.local/share/yadm/archive'
        archive.parent.mkdir(parents=True)
        archive.write_bytes(b'fixture ciphertext')
        return auth, archive

    def test_staged_secret_is_rejected_even_if_worktree_is_cleaned(self):
        secret = 'sk-' + 'a' * 32
        path = self.home / 'models.json'
        path.write_text(json.dumps({'apiKey': secret}))
        self.git('add', 'models.json')
        path.write_text('{}')
        result = self.run_guard('staged')
        self.assertEqual(result.returncode, 1)
        self.assertIn('models.json', result.stderr)
        self.assertNotIn(secret, result.stderr + result.stdout)
        self.assertEqual(self.run_guard('backup').returncode, 1)

    def test_unstaged_secret_is_checked_before_backup(self):
        path = self.home / 'config'
        path.write_text('sk-' + 'b' * 32)
        self.assertEqual(self.run_guard('backup').returncode, 1)
        self.assertEqual(self.run_guard('staged').returncode, 0)

    def test_environment_and_command_references_are_allowed(self):
        path = self.home / 'models.json'
        for value in ('DEEPSEEK_API_KEY', '!credential-helper deepseek'):
            path.write_text(json.dumps({'apiKey': value}))
            self.git('add', 'models.json')
            self.assertEqual(self.run_guard('staged').returncode, 0)
        path.write_text(json.dumps({'apiKey': 'a-literal-provider-credential'}))
        self.git('add', 'models.json')
        self.assertEqual(self.run_guard('staged').returncode, 1)

    def test_known_private_file_cannot_be_committed(self):
        auth, _ = self.private_files()
        self.git('add', str(auth))
        self.assertEqual(self.run_guard('staged').returncode, 1)

    def test_receipt_detects_private_changes_even_with_preserved_mtime(self):
        auth, archive = self.private_files()
        self.assertEqual(self.run_guard('backup').returncode, 1)
        self.assertEqual(self.run_guard('before-encrypt').returncode, 0)
        self.assertEqual(self.run_guard('after-encrypt').returncode, 0)
        self.assertEqual(self.run_guard('backup').returncode, 0)
        previous = auth.stat()
        auth.write_text('new-private-value')
        os.utime(auth, ns=(previous.st_atime_ns, previous.st_mtime_ns))
        self.assertEqual(self.run_guard('backup').returncode, 1)
        self.assertEqual(self.run_guard('after-encrypt').returncode, 1)
        # Successful decrypt establishes the received archive's local receipt.
        self.assertEqual(self.run_guard('after-decrypt').returncode, 0)
        self.assertEqual(self.run_guard('backup').returncode, 0)
        archive.write_bytes(b'new remote ciphertext')
        self.assertEqual(self.run_guard('backup').returncode, 1)

    def test_missing_file_and_failed_encryption_cannot_bless_archive(self):
        auth, _ = self.private_files()
        self.assertEqual(self.run_guard('before-encrypt').returncode, 0)
        self.assertEqual(self.run_guard('after-encrypt', YADM_HOOK_EXIT='1').returncode, 0)
        self.assertEqual(self.run_guard('backup').returncode, 1)
        self.assertEqual(self.run_guard('after-decrypt', YADM_HOOK_FULL_COMMAND='decrypt -l').returncode, 0)
        self.assertEqual(self.run_guard('backup').returncode, 1)
        auth.unlink()
        self.assertEqual(self.run_guard('before-encrypt').returncode, 1)

    @unittest.skipUnless(shutil.which('yadm'), 'real yadm required for encryption hook integration')
    def test_real_yadm_encryption_and_decryption_hooks(self):
        auth, archive = self.private_files()
        config = self.home / '.config/yadm'
        data = self.home / '.local/share/yadm'
        shutil.copytree(ROOT / '.config/yadm/hooks', config / 'hooks')
        (config / 'scripts').mkdir()
        shutil.copyfile(SCRIPT, config / 'scripts/sync-guard.py')
        fake_gpg = self.home.parent / 'fixture-gpg'
        # Identity transform for a disposable fixture only; never used for live credentials.
        fake_gpg.write_text('''#!/bin/sh
if [ "$1" = -d ]; then cat "$2"; exit; fi
while [ "$#" -gt 0 ]; do
  if [ "$1" = --output ]; then shift; cat > "$1"; exit; fi
  shift
done
exit 1
''')
        fake_gpg.chmod(0o755)
        (config / 'config').write_text('[yadm]\n gpg-program = ' + str(fake_gpg) + '\n')
        self.git('add', str(archive))  # Suppress yadm's interactive add-archive prompt.
        self.git('commit', '-m', 'fixture archive')
        def yadm(*args):
            return subprocess.run(['yadm', '--yadm-dir', str(config), '--yadm-data', str(data),
                                   '--yadm-repo', str(self.repo), *args], env=self.env,
                                  cwd=self.home, text=True, capture_output=True)
        result = yadm('encrypt')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.run_guard('backup').returncode, 0)
        auth.write_text('changed fixture value')
        self.assertEqual(self.run_guard('backup').returncode, 1)
        self.assertEqual(yadm('decrypt', '-l').returncode, 0)
        self.assertEqual(self.run_guard('backup').returncode, 1)
        result = yadm('decrypt')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(auth.read_text(), 'fixture-private-value')
        self.assertEqual(self.run_guard('backup').returncode, 0)

    @unittest.skipUnless(shutil.which('yadm'), 'real yadm required for hook integration')
    def test_real_yadm_commit_runs_pre_commit_hook(self):
        config = self.home / '.config/yadm'
        shutil.copytree(ROOT / '.config/yadm/hooks', config / 'hooks')
        (config / 'scripts').mkdir()
        shutil.copyfile(SCRIPT, config / 'scripts/sync-guard.py')
        path = self.home / 'models.json'
        path.write_text(json.dumps({'apiKey': 'sk-' + 'c' * 32}))
        self.git('add', 'models.json')
        result = subprocess.run(['yadm', '--yadm-dir', str(config), '--yadm-repo', str(self.repo),
                                 'commit', '-m', 'must fail'], env=self.env,
                                cwd=self.home, text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Possible plaintext credentials', result.stderr)


if __name__ == '__main__':
    unittest.main()
