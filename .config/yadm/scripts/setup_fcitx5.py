#!/usr/bin/env python3
"""Install the Frost Pinyin scheme for Fcitx5 macOS."""

import argparse
import configparser
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile


FROST_URL = "https://codeload.github.com/gaboolic/rime-frost/zip/refs/heads/master"
DEFAULT_PATCH = "patch:\n  schema_list:\n    - schema: rime_frost\n  menu/page_size: 7\n"
AI_DICTIONARY = Path(__file__).resolve().parents[1] / "packages/fcitx5/ai_ml.dict.yaml"
AI_IMPORT = re.compile(r"(?m)^[ \t]*-[ \t]+['\"]?en_dicts/ai_ml['\"]?[ \t]*(?:#.*)?$")


def configuration(home):
    resources = home / "Library/fcitx5"
    rime = home / ".local/share/fcitx5/rime"
    result = {
        "rime_plugin_installed": (resources / "plugin/rime.json").is_file(),
        "rime_engine_present": (resources / "lib/fcitx5/librime.so").is_file(),
        "rime_enabled": False,
        "rime_default": False,
        "frost_scheme_present": (rime / "rime_frost.schema.yaml").is_file(),
        "frost_dictionary_present": (rime / "rime_frost.dict.yaml").is_file(),
        "frost_compiled": all((rime / "build" / name).is_file() for name in (
            "rime_frost.schema.yaml", "rime_frost.table.bin", "rime_frost.prism.bin")),
        "frost_enabled": False,
        "system_input_source_enabled": "not-checked",
    }
    profile = home / ".config/fcitx5/profile"
    if profile.is_file():
        parser = configparser.ConfigParser(interpolation=None)
        try:
            parser.read_string(profile.read_text())
            result["rime_enabled"] = any(
                section.startswith("Groups/") and "/Items/" in section
                and parser.get(section, "Name", fallback="") == "rime"
                for section in parser.sections())
            result["rime_default"] = any(
                section.startswith("Groups/") and "/Items/" not in section
                and parser.get(section, "DefaultIM", fallback="") == "rime"
                for section in parser.sections())
        except (OSError, configparser.Error):
            result["profile_state"] = "unreadable"
    compiled = rime / "build/default.yaml"
    if compiled.is_file():
        result["frost_enabled"] = bool(re.search(
            r"^\s*-\s+schema:\s*['\"]?rime_frost['\"]?\s*(?:#.*)?$",
            compiled.read_text(), re.MULTILINE))
    dictionary = rime / "en_dicts/ai_ml.dict.yaml"
    english = rime / "melt_eng.dict.yaml"
    table = rime / "build/melt_eng.table.bin"
    result["ai_ml_dictionary_present"] = dictionary.is_file()
    result["ai_ml_dictionary_enabled"] = bool(
        dictionary.is_file() and english.is_file() and AI_IMPORT.search(english.read_text()))
    result["ai_ml_dictionary_compiled"] = bool(
        result["ai_ml_dictionary_enabled"] and table.is_file()
        and (rime / "build/melt_eng.prism.bin").is_file()
        and table.stat().st_mtime_ns >= max(dictionary.stat().st_mtime_ns,
                                            english.stat().st_mtime_ns))
    return result


def copy_missing(source, destination):
    if Path(destination).exists():
        return destination
    return shutil.copy2(source, destination)


def install_scheme(home):
    rime = home / ".local/share/fcitx5/rime"
    changed = False
    if not all((rime / name).exists() for name in (
            "rime_frost.schema.yaml", "rime_frost.dict.yaml", "cn_dicts", "lua")):
        cache = home / ".cache/yadm/fcitx5"
        cache.mkdir(parents=True, exist_ok=True)
        archive = cache / "rime-frost.zip"
        partial = cache / "rime-frost.zip.part"
        subprocess.run(["curl", "-fL", "--retry", "3", "-o", str(partial), FROST_URL],
                       check=True)
        with tempfile.TemporaryDirectory(prefix="frost-", dir=cache) as stage:
            with zipfile.ZipFile(partial) as bundle:
                for name in bundle.namelist():
                    if Path(name).is_absolute() or ".." in Path(name).parts:
                        raise ValueError("Invalid archive path")
                bundle.extractall(stage)
            source = Path(stage) / "rime-frost-master"
            if not (source / "rime_frost.schema.yaml").is_file():
                raise ValueError("Frost archive is missing rime_frost.schema.yaml")
            shutil.copytree(source, rime, dirs_exist_ok=True, copy_function=copy_missing,
                            ignore=shutil.ignore_patterns(
                                ".github", ".git", "*.custom.yaml", "*.userdb", "user.yaml", "build"))
        partial.replace(archive)
        changed = True
    custom = rime / "default.custom.yaml"
    if not custom.exists():
        custom.write_text(DEFAULT_PATCH)
        changed = True
    return changed


def install_ai_dictionary(home):
    rime = home / ".local/share/fcitx5/rime"
    english = rime / "melt_eng.dict.yaml"
    original = english.read_text()
    updated = original
    if not AI_IMPORT.search(original):
        header = re.search(r"(?m)^import_tables:[ \t]*(?:#.*)?$", original)
        if not header:
            raise ValueError("melt_eng.dict.yaml has no import_tables list")
        item = re.search(r"(?m)^([ \t]*)-[ \t]+", original[header.end():])
        indent = item[1] if item else "  "
        updated = (original[:header.end()] + "\n" + indent
                   + "- en_dicts/ai_ml # AI/ML research vocabulary" + original[header.end():])
    target = rime / "en_dicts/ai_ml.dict.yaml"
    content = AI_DICTIONARY.read_bytes()
    changed = not target.is_file() or target.read_bytes() != content
    if changed:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
    if updated != original:
        english.write_text(updated)
        changed = True
    return changed


def deploy_scheme(home):
    if not configuration(home)["rime_engine_present"]:
        return "pending"
    apps = (Path("/Library/Input Methods/Fcitx5.app"),
            home / "Library/Input Methods/Fcitx5.app")
    cli = next((app / "Contents/bin/fcitx5-curl" for app in apps
                if (app / "Contents/bin/fcitx5-curl").is_file()), None)
    if cli is None:
        return "pending"
    result = subprocess.run([
        str(cli), "/config/addon/rime/deploy", "-f", "--max-time", "10",
        "-X", "POST", "-d", "{}"], capture_output=True, text=True)
    return "requested" if result.returncode == 0 else "pending"


def apply(home):
    changed = install_scheme(home)
    changed = install_ai_dictionary(home) or changed
    state = configuration(home)
    deployment = "ready"
    if changed or not (state["frost_compiled"] and state["frost_enabled"]
                       and state["ai_ml_dictionary_compiled"]):
        deployment = deploy_scheme(home)
    return {"scheme": "rime_frost", "changed": changed,
            "deployment": deployment, "configuration": configuration(home)}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Install and deploy Frost Pinyin")
    parser.add_argument("--home", type=Path, default=Path.home())
    args = parser.parse_args(argv)
    try:
        home = args.home.expanduser().absolute()
        result = apply(home) if args.apply else configuration(home)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, configparser.Error, zipfile.BadZipFile,
            subprocess.CalledProcessError) as error:
        print(json.dumps({"error": str(error)}, ensure_ascii=False))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
