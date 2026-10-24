"""Exercise Frost installation with local archives and temporary homes."""

import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import setup_fcitx5 as setup


class Fcitx5SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="fcitx5-setup-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.rime = self.home / ".local/share/fcitx5/rime"
        self.archive = self.root / "frost.zip"
        with zipfile.ZipFile(self.archive, "w") as bundle:
            for name, content in {
                "rime_frost.schema.yaml": "schema:\n  schema_id: rime_frost\n",
                "rime_frost.dict.yaml": "name: rime_frost\n",
                "cn_dicts/base.dict.yaml": "name: base\n",
                "lua/example.lua": "return {}\n",
                "default.yaml": "schema_list:\n  - schema: rime_frost\n",
                "custom_phrase.txt": "上游示例短语\tsy\t1\n",
                "default.custom.yaml": "upstream custom\n",
                "build/stale.bin": "upstream build\n",
            }.items():
                bundle.writestr("rime-frost-master/" + name, content)
        self.command = patch.object(setup.subprocess, "run", side_effect=self.run_command)
        self.run = self.command.start()
        self.addCleanup(self.command.stop)

    def run_command(self, args, **kwargs):
        if args[0] != "curl":
            raise AssertionError(f"Unexpected command: {args}")
        self.assertEqual(args[-1], setup.FROST_URL)
        shutil.copyfile(self.archive, args[args.index("-o") + 1])
        return subprocess.CompletedProcess(args, 0)

    def compiled(self):
        build = self.rime / "build"
        build.mkdir(exist_ok=True)
        for name in ("rime_frost.schema.yaml", "rime_frost.table.bin", "rime_frost.prism.bin"):
            (build / name).touch()
        (build / "default.yaml").write_text("schema_list:\n  - schema: rime_frost\n")

    def test_first_install_prepares_frost_and_seven_candidates(self):
        result = setup.apply(self.home)
        self.assertTrue(result["changed"])
        self.assertEqual(result["deployment"], "pending")
        self.assertTrue(result["configuration"]["frost_dictionary_present"])
        self.assertTrue((self.rime / "lua/example.lua").is_file())
        self.assertEqual((self.rime / "default.custom.yaml").read_text(), setup.DEFAULT_PATCH)
        self.assertFalse((self.rime / "build/stale.bin").exists())
        self.assertTrue((self.home / ".cache/yadm/fcitx5/rime-frost.zip").is_file())
        self.assertEqual(self.run.call_count, 1)

    def test_repeat_reuses_source_and_keeps_customizations_and_learned_data(self):
        setup.apply(self.home)
        self.compiled()
        custom = self.rime / "default.custom.yaml"
        custom.write_text(setup.DEFAULT_PATCH.replace("size: 7", "size: 9"))
        database = self.rime / "rime_frost.userdb/000001.log"
        database.parent.mkdir()
        database.write_bytes(b"learned words")
        (self.rime / "user.yaml").write_text("installation_id: local\n")
        before = {path: path.read_bytes() for path in self.rime.rglob("*") if path.is_file()}
        self.run.reset_mock()
        result = setup.apply(self.home)
        self.assertFalse(result["changed"])
        self.assertEqual(result["deployment"], "ready")
        self.assertEqual(before, {path: path.read_bytes() for path in before})
        self.run.assert_not_called()

    def test_incomplete_source_is_filled_while_preserving_local_data(self):
        self.rime.mkdir(parents=True)
        custom = self.rime / "default.custom.yaml"
        custom.write_text("patch:\n  menu/page_size: 9\n")
        learned = self.rime / "custom_phrase.txt"
        learned.write_text("自定义短语\tzdydy\t1\n")
        schema = self.rime / "rime_frost.schema.yaml"
        schema.write_text("local scheme customization\n")
        self.assertTrue(setup.install_scheme(self.home))
        self.assertEqual(custom.read_text(), "patch:\n  menu/page_size: 9\n")
        self.assertEqual(learned.read_text(), "自定义短语\tzdydy\t1\n")
        self.assertEqual(schema.read_text(), "local scheme customization\n")
        self.assertTrue((self.rime / "cn_dicts/base.dict.yaml").is_file())

    def test_download_failure_leaves_local_scheme_and_customization_intact(self):
        self.rime.mkdir(parents=True)
        custom = self.rime / "default.custom.yaml"
        custom.write_text("local custom\n")
        self.run.side_effect = subprocess.CalledProcessError(22, ["curl"])
        with self.assertRaises(subprocess.CalledProcessError):
            setup.install_scheme(self.home)
        self.assertEqual(custom.read_text(), "local custom\n")
        self.assertFalse((self.rime / "rime_frost.schema.yaml").exists())

    def test_existing_rime_receives_native_deployment_request(self):
        setup.install_scheme(self.home)
        self.run.reset_mock()
        self.run.side_effect = None
        self.run.return_value = subprocess.CompletedProcess([], 0, "{}", "")
        with patch.object(setup, "configuration", return_value={"rime_engine_present": True}), \
                patch.object(setup.Path, "is_file", return_value=True):
            self.assertEqual(setup.deploy_scheme(self.home), "requested")
            args = self.run.call_args.args[0]
            self.assertEqual(args[1], "/config/addon/rime/deploy")
            self.assertEqual(args[-4:], ["-X", "POST", "-d", "{}"])
            self.run.return_value = subprocess.CompletedProcess([], 7, "", "not running")
            self.assertEqual(setup.deploy_scheme(self.home), "pending")


if __name__ == "__main__":
    unittest.main(verbosity=2)
