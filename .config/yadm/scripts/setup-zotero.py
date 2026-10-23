#!/usr/bin/env python3
"""Prepare verified Zotero plugins and a native activation script; never edit a live profile."""

import argparse
import configparser
import hashlib
import json
from pathlib import Path
import platform
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile


MANIFEST = Path(__file__).resolve().parents[1] / "packages/zotero/plugins.json"
MAX_XPI_BYTES = 8 * 1024 * 1024
RULE_SOURCES = {
    "conference-year-tags-startup-v1": "conference-tags.js",
    "arxiv-auto-update-on-import-v1": "import-arxiv-update.js",
}


def find_app(home):
    return next((path for path in (Path("/Applications/Zotero.app"), home / "Applications/Zotero.app")
                 if (path / "Contents/Info.plist").is_file()), None)


def app_version(app):
    if not app:
        return None
    with (app / "Contents/Info.plist").open("rb") as handle:
        return str(plistlib.load(handle).get("CFBundleShortVersionString", ""))


def find_profile(home, explicit=None):
    if explicit:
        path = Path(explicit).expanduser().resolve()
        if not (path / "prefs.js").is_file():
            raise ValueError("--profile must point to an initialized Zotero profile with prefs.js")
        return path
    base = home / "Library/Application Support/Zotero"
    config = configparser.ConfigParser(interpolation=None)
    config.read(base / "profiles.ini")
    profiles = []
    for section in config.sections():
        if section.startswith("Profile") and config.has_option(section, "Path"):
            path = Path(config[section]["Path"])
            if config.getboolean(section, "IsRelative", fallback=True):
                path = base / path
            if (path / "prefs.js").is_file():
                profiles.append((section, path.resolve()))
    # Firefox-style per-install defaults take precedence over ProfileN Default.
    defaults = set()
    for section in config.sections():
        if section.startswith("Install") and config.has_option(section, "Default"):
            path = Path(config[section]["Default"])
            defaults.add((base / path).resolve() if not path.is_absolute() else path.resolve())
    candidates = [path for _, path in profiles if path in defaults]
    if len(candidates) == 1:
        return candidates[0]
    candidates = [path for section, path in profiles if config.getboolean(section, "Default", fallback=False)]
    if len(candidates) == 1:
        return candidates[0]
    if len(profiles) == 1:
        return profiles[0][1]
    if profiles:
        raise ValueError("Multiple Zotero profiles; select the intended one with --profile")
    return None


def read_preferences(profile):
    result = {}
    if not profile:
        return result
    for line in (profile / "prefs.js").read_text().splitlines():
        match = re.fullmatch(r"user_pref\((.*)\);", line)
        if match:
            try:
                key, value = json.loads("[" + match[1] + "]")
                result[key] = value
            except (ValueError, TypeError):
                continue
    return result


def version_tuple(value):
    return tuple(int(part) for part in re.findall(r"\d+", str(value))[:3])


def inspect(home, profile, manifest, app):
    prefs = read_preferences(profile)
    registry = {}
    if profile and (profile / "extensions.json").exists():
        registry = {entry["id"]: entry for entry in json.loads((profile / "extensions.json").read_text())["addons"]}
    plugins = []
    for desired in manifest["plugins"]:
        installed = registry.get(desired["id"], {})
        plugins.append({"id": desired["id"], "target_version": desired["version"],
                        "installed_version": installed.get("version"),
                        "version_sufficient": bool(installed) and version_tuple(installed.get("version", "")) >= version_tuple(desired["version"]),
                        "enabled": bool(installed) and not any(installed.get(key, False)
                                                               for key in ("userDisabled", "appDisabled", "softDisabled"))})
    rules = {}
    for key, filename in RULE_SOURCES.items():
        source = home / ".config/zotero" / filename
        try:
            rule = json.loads(prefs.get("extensions.actionsTags.rules." + key, "{}"))
            rules[key] = bool(rule.get("enabled") and source.is_file() and rule.get("data") == source.read_text())
        except (ValueError, TypeError):
            rules[key] = False
    selected = json.loads(prefs.get("extensions.actionsTags.rules.conference-year-tags-selected-v1", "{}"))
    rules["conference-year-tags-selected-v1"] = bool(selected.get("enabled") and selected.get("operation") == 4)
    version = app_version(app)
    ready = bool(version and int(version.split(".")[0]) == manifest["zotero_major"] and profile
                 and all(entry["enabled"] and entry["version_sufficient"] for entry in plugins) and all(rules.values()))
    return {"app": str(app) if app else None, "version": version,
            "profile": str(profile) if profile else None, "plugins": plugins,
            "rules_current": rules, "configured": ready,
            "note": "Checks saved configuration, not live reader rendering or remote metadata services."}


def validate_xpi(path, plugin):
    if path.stat().st_size > MAX_XPI_BYTES:
        raise ValueError("Plugin archive exceeds size limit")
    if hashlib.sha256(path.read_bytes()).hexdigest() != plugin["sha256"]:
        raise ValueError("SHA-256 mismatch for " + plugin["name"])
    with zipfile.ZipFile(path) as archive:
        info = archive.getinfo("manifest.json")
        if info.file_size > 65536:
            raise ValueError("Oversized plugin manifest")
        data = json.loads(archive.read(info))
    if data["version"] != plugin["version"] or data["applications"]["zotero"]["id"] != plugin["id"]:
        raise ValueError("Plugin identity/version does not match the pinned manifest")


def download_plugin(plugin, cache):
    filename = plugin["filename"]
    if Path(filename).name != filename or not re.fullmatch(r"[a-f0-9]{64}", plugin["sha256"]):
        raise ValueError("Invalid pinned plugin manifest")
    if not plugin["url"].startswith("https://github.com/") or "/releases/download/" not in plugin["url"]:
        raise ValueError("Plugin must come from a pinned GitHub release")
    destination = cache / filename
    if destination.exists():
        validate_xpi(destination, plugin)
        return destination
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=cache, delete=False) as handle:
            temporary = Path(handle.name)
            with urllib.request.urlopen(plugin["url"], timeout=30) as response:
                total = 0
                while chunk := response.read(65536):
                    total += len(chunk)
                    if total > MAX_XPI_BYTES:
                        raise ValueError("Plugin download exceeds size limit")
                    handle.write(chunk)
        validate_xpi(temporary, plugin)
        temporary.replace(destination)
        return destination
    finally:
        if temporary and temporary.exists():
            temporary.unlink()


def prepare(home, manifest, app):
    if not app:
        brew = shutil.which("brew") or next((str(path) for path in
            (Path("/opt/homebrew/bin/brew"), Path("/usr/local/bin/brew")) if path.is_file()), None)
        if not brew:
            raise ValueError("Install Homebrew first, then retry")
        subprocess.run([brew, "install", "--cask", "zotero"], check=True)
        app = find_app(home)
    version = app_version(app)
    if not version or int(version.split(".")[0]) != manifest["zotero_major"]:
        raise ValueError("This plugin set targets Zotero 10; review compatibility before updating the manifest")
    source_dir = home / ".config/zotero"
    for filename in (*RULE_SOURCES.values(), "install-conference-tags.js", "activate-plugins.js"):
        if not (source_dir / filename).is_file():
            raise ValueError("Missing tracked source: " + str(source_dir / filename))
    cache = home / ".cache/yadm/zotero"
    cache.mkdir(parents=True, exist_ok=True)
    plugins = [dict(plugin, path=str(download_plugin(plugin, cache))) for plugin in manifest["plugins"]]
    local = home / ".config/yadm/local/zotero"
    local.mkdir(parents=True, exist_ok=True, mode=0o700)
    target = local / "activate.js"
    payload = {"zotero_major": manifest["zotero_major"], "plugins": plugins}
    target.write_text("const prepared = " + json.dumps(payload, ensure_ascii=True) + ";\n"
                      + (source_dir / "activate-plugins.js").read_text())
    command = ('const source = await Zotero.File.getContentsAsync(' + json.dumps(str(target))
               + '); const F = Object.getPrototypeOf(async function(){}).constructor; '
               + 'return await new F("Zotero", source)(Zotero);')
    print(json.dumps({"status": "prepared", "app": str(app), "activation_file": str(target),
                      "next": "In the intended Zotero profile: Tools > Developer > Run JavaScript, enable Run as async function, then execute activation_code.",
                      "activation_code": command}, ensure_ascii=False, indent=2))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="Read-only saved configuration inventory")
    mode.add_argument("--prepare", action="store_true", help="Install missing app and prepare verified native activation")
    parser.add_argument("--profile", help="Profile directory when multiple profiles exist (check only)")
    parser.add_argument("--strict", action="store_true", help="Return nonzero if --check is incomplete")
    args = parser.parse_args(argv)
    try:
        if platform.system() != "Darwin":
            raise ValueError("This installer targets macOS only")
        if args.prepare and (args.profile or args.strict):
            raise ValueError("--profile and --strict apply only to --check")
        home = Path.home()
        manifest = json.loads(MANIFEST.read_text())
        app = find_app(home)
        if args.check:
            result = inspect(home, find_profile(home, args.profile), manifest, app)
            print(json.dumps(result, ensure_ascii=False, indent=2))
            return 1 if args.strict and not result["configured"] else 0
        prepare(home, manifest, app)
        return 0
    except (ValueError, OSError, KeyError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        print("Zotero setup: " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
