"""Exercise Frost installation with local archives and temporary homes."""

import hashlib
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
                "melt_eng.dict.yaml": "---\nname: melt_eng\nimport_tables:\n  - en_dicts/en_ext\n  - en_dicts/en\n...\n",
                "custom_phrase.txt": "上游示例短语\tsy\t1\n",
                "default.custom.yaml": "upstream custom\n",
                "build/stale.bin": "upstream build\n",
            }.items():
                bundle.writestr("rime-frost-master/" + name, content)
        self.font_archives = {}
        for filename, members in setup.FONT_PACKAGES.items():
            archive = self.root / filename
            with zipfile.ZipFile(archive, "w") as bundle:
                for member in members:
                    bundle.writestr(member, "OTF " + member)
                bundle.writestr("unused/Other.ttf", "not a requested OTF")
            self.font_archives[filename] = archive
        digest = patch.object(setup, "FONT_SHA256", hashlib.sha256(archive.read_bytes()).hexdigest())
        digest.start()
        self.addCleanup(digest.stop)
        self.command = patch.object(setup.subprocess, "run", side_effect=self.run_command)
        self.run = self.command.start()
        self.addCleanup(self.command.stop)

    def run_command(self, args, **kwargs):
        if args[0] != "curl":
            raise AssertionError(f"Unexpected command: {args}")
        if args[-1] == setup.FROST_URL:
            archive = self.archive
        else:
            self.assertTrue(args[-1].startswith(setup.FONT_URL))
            archive = self.font_archives[args[-1].removeprefix(setup.FONT_URL)]
        shutil.copyfile(archive, args[args.index("-o") + 1])
        return subprocess.CompletedProcess(args, 0)

    def compiled(self):
        build = self.rime / "build"
        build.mkdir(exist_ok=True)
        for name in ("rime_frost.schema.yaml", "rime_frost.table.bin", "rime_frost.prism.bin",
                     "melt_eng.table.bin", "melt_eng.prism.bin"):
            (build / name).touch()
        (build / "default.yaml").write_text("schema_list:\n  - schema: rime_frost\n")

    def test_first_install_prepares_frost_and_seven_candidates(self):
        result = setup.apply(self.home)
        self.assertTrue(result["changed"])
        self.assertEqual(result["deployment"], "pending")
        self.assertTrue(result["configuration"]["frost_dictionary_present"])
        self.assertTrue(result["configuration"]["plangothic_fonts_installed"])
        self.assertTrue((self.rime / "lua/example.lua").is_file())
        self.assertTrue(result["configuration"]["ai_ml_dictionary_enabled"])
        self.assertEqual((self.rime / "en_dicts/ai_ml.dict.yaml").read_bytes(),
                         setup.AI_DICTIONARY.read_bytes())
        self.assertEqual((self.rime / "default.custom.yaml").read_text(), setup.DEFAULT_PATCH)
        self.assertFalse((self.rime / "build/stale.bin").exists())
        self.assertTrue((self.home / ".cache/yadm/fcitx5/rime-frost.zip").is_file())
        self.assertEqual(self.run.call_count, 2)

    def test_font_install_reuses_cache_and_preserves_installed_fonts(self):
        fonts = self.home / "Library/Fonts"
        fonts.mkdir(parents=True)
        regular = fonts / "PlangothicP1-Regular.otf"
        regular.write_bytes(b"existing font")
        self.assertTrue(setup.install_fonts(self.home))
        self.assertEqual(regular.read_bytes(), b"existing font")
        self.assertEqual(len(list(fonts.iterdir())), 2)
        rare = fonts / "PlangothicP2-Regular.otf"
        expected = f"OTF Plangothic-OTF-{setup.FONT_VERSION}/PlangothicP2-Regular.otf"
        self.assertEqual(rare.read_text(), expected)
        self.run.reset_mock()
        self.assertFalse(setup.install_fonts(self.home))
        self.run.assert_not_called()
        rare.unlink()
        self.assertTrue(setup.install_fonts(self.home))
        self.assertEqual(rare.read_text(), expected)
        self.run.assert_not_called()

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

    def test_ai_dictionary_updates_without_replacing_other_english_imports(self):
        setup.install_scheme(self.home)
        english = self.rime / "melt_eng.dict.yaml"
        english.write_text(english.read_text().replace(
            "import_tables:", "import_tables: # local configuration\n  - en_dicts/personal"))
        self.assertTrue(setup.install_ai_dictionary(self.home))
        once = english.read_text()
        self.assertIn("  - en_dicts/personal", once)
        self.assertIn("  - en_dicts/en_ext", once)
        self.assertEqual(once.count("en_dicts/ai_ml"), 1)
        self.assertFalse(setup.install_ai_dictionary(self.home))
        target = self.rime / "en_dicts/ai_ml.dict.yaml"
        target.write_text("old research vocabulary\n")
        self.assertTrue(setup.install_ai_dictionary(self.home))
        self.assertEqual(target.read_bytes(), setup.AI_DICTIONARY.read_bytes())
        self.assertEqual(english.read_text(), once)

    def test_pending_english_compilation_is_retried_without_redownloading(self):
        setup.apply(self.home)
        self.compiled()
        self.assertTrue(setup.configuration(self.home)["ai_ml_dictionary_compiled"])
        (self.rime / "build/melt_eng.table.bin").unlink()
        self.run.reset_mock()
        with patch.object(setup, "deploy_scheme", return_value="requested") as deploy:
            result = setup.apply(self.home)
        self.assertFalse(result["changed"])
        self.assertEqual(result["deployment"], "requested")
        deploy.assert_called_once_with(self.home)
        self.run.assert_not_called()

    def test_ai_import_uses_the_existing_yaml_list_indentation(self):
        setup.install_scheme(self.home)
        english = self.rime / "melt_eng.dict.yaml"
        english.write_text("---\nname: melt_eng\nimport_tables:\n# My English words\n"
                           "- en_dicts/personal\n- en_dicts/en\n...\n")
        setup.install_ai_dictionary(self.home)
        self.assertEqual(english.read_text(),
                         "---\nname: melt_eng\nimport_tables:\n"
                         "- en_dicts/ai_ml # AI/ML research vocabulary\n"
                         "# My English words\n- en_dicts/personal\n- en_dicts/en\n...\n")

    def test_ai_vocabulary_format_and_representative_research_terms(self):
        body = setup.AI_DICTIONARY.read_text().split("\n...\n", 1)[1]
        entries = set()
        words = set()
        for line in body.splitlines():
            if not line or line.startswith("#"):
                continue
            text, code, weight = line.split("\t")
            self.assertRegex(code, r"^[a-z][a-z0-9]*$")
            self.assertGreater(int(weight), 0)
            self.assertNotIn((text, code), entries)
            entries.add((text, code))
            words.add(text)
        self.assertTrue({"LLaVA", "InternVL", "SigLIP", "DINO", "Qwen", "Qwen2.5-VL",
                         "FlashAttention", "LoRA", "RMSNorm", "MMMU", "Ego4D",
                         "PyTorch", "vLLM", "NeurIPS", "CVPR", "EMNLP"} <= words)
        self.assertFalse({"Llama 2", "Llama 3", "Qwen2.5", "GPT-5",
                          "InternVL2", "InternVL3", "DINOv2", "DINOv3",
                          "FlashAttention-2", "FlashAttention-3"} & words)
        self.assertTrue({"T5", "FP16", "INT8", "3D Gaussian Splatting", "F1"} <= words)
        self.assertTrue({"Qwen2-VL", "Qwen3-Omni", "GPT-4o", "Llama 3.2 Vision"} <= words)
        self.assertIn(("Qwen2.5-VL", "qwentwofivevl"), entries)


if __name__ == "__main__":
    unittest.main(verbosity=2)
