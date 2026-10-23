"""Exercise temporary profiles and fake plugin packages; never mutate the real library."""

import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock
import zipfile


ROOT = Path(__file__).resolve().parents[3]
SCRIPTS = ROOT / ".config/zotero"
spec = importlib.util.spec_from_file_location("zotero_setup", ROOT / ".config/yadm/scripts/setup-zotero.py")
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class ZoteroSetupTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="zotero-setup-")
        self.addCleanup(temp.cleanup)
        self.home = Path(temp.name).resolve() / "another Mac user"
        self.home.mkdir()
        self.base = self.home / "Library/Application Support/Zotero"
        self.profile = self.base / "Profiles/random.default"
        self.profile.mkdir(parents=True)
        (self.profile / "prefs.js").write_text('user_pref("unrelated.setting", "keep");\n')
        (self.base / "profiles.ini").write_text("[Profile0]\nName=default\nIsRelative=1\nPath=Profiles/random.default\nDefault=1\n")
        self.app = self.home / "Applications/Zotero.app"
        (self.app / "Contents").mkdir(parents=True)
        with (self.app / "Contents/Info.plist").open("wb") as handle:
            plistlib.dump({"CFBundleShortVersionString": "10.0.6"}, handle)
        self.sources = self.home / ".config/zotero"
        self.sources.mkdir(parents=True)
        for path in SCRIPTS.glob("*.js"):
            if path.name in {*setup.RULE_SOURCES.values(), "install-conference-tags.js", "activate-plugins.js"}:
                shutil.copyfile(path, self.sources / path.name)
        self.archive = self.home / "fixture.xpi"
        with zipfile.ZipFile(self.archive, "w") as archive:
            archive.writestr("manifest.json", json.dumps({"version": "1.2.3", "applications": {"zotero": {"id": "test@example.com"}}}))
        self.plugin = {"name": "Fixture", "id": "test@example.com", "version": "1.2.3",
                       "filename": "fixture-1.2.3.xpi", "url": "https://github.com/example/plugin/releases/download/v1.2.3/fixture.xpi",
                       "sha256": hashlib.sha256(self.archive.read_bytes()).hexdigest()}
        self.manifest = {"zotero_major": 10, "plugins": [self.plugin]}
        self.network = mock.patch.object(setup.urllib.request, "urlopen", side_effect=AssertionError("unexpected network"))
        self.network.start()
        self.addCleanup(self.network.stop)

    def test_profile_discovery_handles_other_username_and_multiple_profiles(self):
        self.assertEqual(setup.find_profile(self.home), self.profile)
        other = self.base / "Profiles/second.default"
        other.mkdir()
        (other / "prefs.js").write_text("")
        (self.base / "profiles.ini").write_text("[Profile0]\nPath=Profiles/random.default\n[Profile1]\nPath=Profiles/second.default\n")
        with self.assertRaisesRegex(ValueError, "Multiple"):
            setup.find_profile(self.home)
        self.assertEqual(setup.find_profile(self.home, str(other)), other)
        with (self.base / "profiles.ini").open("a") as handle:
            handle.write("[InstallABC]\nDefault=Profiles/second.default\n")
        self.assertEqual(setup.find_profile(self.home), other)

    def test_read_only_check_never_installs_or_changes_preferences(self):
        before = (self.profile / "prefs.js").read_bytes()
        with mock.patch.object(setup.platform, "system", return_value="Darwin"), \
             mock.patch.object(setup.Path, "home", return_value=self.home), \
             mock.patch.object(setup, "find_app", return_value=self.app), \
             mock.patch.object(setup.subprocess, "run", side_effect=AssertionError("unexpected process")), \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(setup.main(["--check", "--strict"]), 1)
        self.assertEqual((self.profile / "prefs.js").read_bytes(), before)
        self.assertFalse((self.home / ".cache").exists())

    def test_verified_cache_is_reused_and_tampered_cache_rejected(self):
        cache = self.home / "cache"
        cache.mkdir()
        target = cache / self.plugin["filename"]
        shutil.copyfile(self.archive, target)
        self.assertEqual(setup.download_plugin(self.plugin, cache), target)
        target.write_bytes(b"tampered")
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            setup.download_plugin(self.plugin, cache)

    def test_manifest_identity_is_checked_even_with_matching_digest(self):
        with self.assertRaisesRegex(ValueError, "identity"):
            setup.validate_xpi(self.archive, dict(self.plugin, id="wrong@example.com"))

    def test_prepare_is_repeatable_and_leaves_profile_untouched(self):
        cache = self.home / ".cache/yadm/zotero"
        cache.mkdir(parents=True)
        shutil.copyfile(self.archive, cache / self.plugin["filename"])
        before = (self.profile / "prefs.js").read_bytes()
        with contextlib.redirect_stdout(io.StringIO()):
            setup.prepare(self.home, self.manifest, self.app)
            first = (self.home / ".config/yadm/local/zotero/activate.js").read_text()
            setup.prepare(self.home, self.manifest, self.app)
        self.assertEqual(first, (self.home / ".config/yadm/local/zotero/activate.js").read_text())
        self.assertIn(str(cache), first)
        self.assertEqual((self.profile / "prefs.js").read_bytes(), before)

    def test_status_detects_stale_source_and_preserves_newer_plugin(self):
        rule_values = {}
        for key, filename in setup.RULE_SOURCES.items():
            rule_values["extensions.actionsTags.rules." + key] = json.dumps({"enabled": True, "data": (self.sources / filename).read_text()})
        rule_values["extensions.actionsTags.rules.conference-year-tags-selected-v1"] = json.dumps({"enabled": True, "operation": 4})
        (self.profile / "prefs.js").write_text("\n".join("user_pref(" + json.dumps(key) + ", " + json.dumps(value) + ");" for key, value in rule_values.items()))
        registry = {"addons": [{"id": self.plugin["id"], "version": "2.0.0", "userDisabled": False}]}
        (self.profile / "extensions.json").write_text(json.dumps(registry))
        self.assertTrue(setup.inspect(self.home, self.profile, self.manifest, self.app)["configured"])
        (self.sources / "conference-tags.js").write_text("changed")
        self.assertFalse(setup.inspect(self.home, self.profile, self.manifest, self.app)["configured"])

    @unittest.skipUnless(shutil.which("node"), "Node required for native-action fixture")
    def test_native_rule_install_is_portable_and_idempotent(self):
        fixture = r'''
const fs=require('fs'),assert=require('assert/strict');
(async()=>{
const source=fs.readFileSync(process.argv[1],'utf8');
const rules=new Map([['unrelated',{data:'keep me',enabled:true}],['default0',{data:'/unread',enabled:true}]]);
const writes=[];
global.PathUtils={homeDir:'/Users/another Mac user',join:(...parts)=>parts.join('/')};
global.IOUtils={makeDirectory:async()=>{}};
const Z={ActionsTags:{data:{actions:{map:rules}},api:{actionManager:{updateAction:(rule,key)=>rules.set(key,rule)}}},
 File:{getContentsAsync:async path=>path.endsWith('conference-tags.js')?"return 'fixture ready';":"return;",
 putContentsAsync:async(path,data)=>writes.push({path,data})}};
const F=Object.getPrototypeOf(async function(){}).constructor;
for(let i=0;i<2;i++)assert.equal(await new F('Zotero',source)(Z),'fixture ready');
assert.equal(rules.size,5);
assert.equal(rules.get('unrelated').data,'keep me');assert.equal(rules.get('default0').enabled,false);
assert.ok(writes.every(entry=>entry.path.startsWith('/Users/another Mac user/.config/yadm/local/zotero/backups/')));
assert.equal(rules.get('arxiv-auto-update-on-import-v1').event,1);
console.log('portable native action install passed');
})().catch(error=>{console.error(error);process.exit(1)});
'''
        result = subprocess.run([shutil.which("node"), "-e", fixture, str(SCRIPTS / "install-conference-tags.js")], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
