#!/usr/bin/env python3
"""Opt into DeepSeek conference lookup; update saved Actions & Tags rules while Zotero is closed."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone

spec = importlib.util.spec_from_file_location("zotero_setup", Path(__file__).with_name("setup-zotero.py"))
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)

MANUAL = 'if (!items?.length) return; const Z=require("Zotero"); if (!Z.ConferenceAI?.runSelected) throw new Error("Restart Zotero to activate AI lookup."); return await Z.ConferenceAI.runSelected(items);'


def configure(home, profile, queue_keys=(), probe_keys=()):
    # Never edit a live profile: its next preference flush would overwrite this file.
    processes = subprocess.run(["ps", "-A", "-o", "comm="], check=True, capture_output=True, text=True).stdout
    if any(re.search(r"Zotero\.app/Contents/MacOS/zotero$", line, re.I) for line in processes.splitlines()):
        raise ValueError("Quit Zotero normally before applying this configuration")
    auth = json.loads((home / ".pi/agent/auth.json").read_text()).get("deepseek", {})
    if auth.get("type") != "api_key" or not isinstance(auth.get("key"), str) or not auth["key"].strip():
        raise ValueError("Pi does not have a DeepSeek API key; configure Pi first")
    del auth
    prefs = setup.read_preferences(profile)
    rule_list = json.loads(prefs.get("extensions.actionsTags.rules", "[]"))
    startup_key = "extensions.actionsTags.rules.conference-year-tags-startup-v1"
    if startup_key not in prefs:
        raise ValueError("Install the base Zotero workflow first")
    changes = {}
    startup = json.loads(prefs[startup_key])
    startup["data"] = (home / ".config/zotero/conference-tags.js").read_text()
    changes[startup_key] = json.dumps(startup, ensure_ascii=False)
    for suffix, name, event, data in [
        ("startup-v1", "AI 会议查询：启动监听", 9, (home / ".config/zotero/conference-ai.js").read_text()),
        ("selected-v1", "AI 查询会议信息", 0, MANUAL),
    ]:
        key = "conference-ai-" + suffix
        rule = {"name": name, "event": event, "operation": 4, "data": data, "shortcut": "", "enabled": True,
                "menu": name if event == 0 else "", "showInMenu": {"item": event == 0, "collection": False,
                "tools": False, "reader": False, "readerAnnotation": False}}
        changes["extensions.actionsTags.rules." + key] = json.dumps(rule, ensure_ascii=False)
        if key not in rule_list:
            rule_list.append(key)
    changes["extensions.actionsTags.rules"] = json.dumps(rule_list)
    changes["extensions.actionsTags.conferenceAI.enabled"] = True
    changes["extensions.zotero.arxiv-workflow.downloadJournalPDF"] = False
    if queue_keys:
        changes["extensions.actionsTags.conferenceAI.pendingKeys"] = json.dumps(list(queue_keys))
    if probe_keys:
        changes["extensions.actionsTags.conferenceAI.probeKeys"] = json.dumps(list(probe_keys))
    original = (profile / "prefs.js").read_text()
    lines = []
    for line in original.splitlines():
        match = re.fullmatch(r"user_pref\((.*)\);", line)
        if match:
            try:
                key, _ = json.loads("[" + match[1] + "]")
                if key in changes:
                    continue
            except (ValueError, TypeError):
                pass
        lines.append(line)
    lines.extend("user_pref(" + json.dumps(k) + ", " + json.dumps(v, ensure_ascii=True) + ");" for k, v in changes.items())
    backups = home / ".config/yadm/local/zotero/backups"
    backups.mkdir(parents=True, exist_ok=True, mode=0o700)
    backup = backups / ("prefs-before-ai-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ") + ".js")
    shutil.copy2(profile / "prefs.js", backup)
    os.chmod(backup, 0o600)
    with tempfile.NamedTemporaryFile(mode="w", dir=profile, delete=False) as handle:
        temp = Path(handle.name)
        handle.write("\n".join(lines) + "\n")
    try:
        os.chmod(temp, (profile / "prefs.js").stat().st_mode & 0o777)
        temp.replace(profile / "prefs.js")
    finally:
        temp.unlink(missing_ok=True)
    return {"configured": True, "profile": str(profile), "credential_source": "Pi auth.json (read at request time)",
            "backup": str(backup), "queued_item_keys": list(queue_keys)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", required=True, action="store_true")
    parser.add_argument("--profile")
    parser.add_argument("--queue", action="append", default=[], help="Explicit item key to query after restart")
    parser.add_argument("--probe", action="append", default=[], help="Read-only lookup test for an explicit item key")
    args = parser.parse_args()
    try:
        if any(not re.fullmatch(r"[A-Z0-9]{8}", key) for key in args.queue + args.probe):
            raise ValueError("Invalid Zotero item key")
        home = Path.home()
        profile = setup.find_profile(home, args.profile)
        if not profile:
            raise ValueError("Initialize Zotero and the base workflow first")
        print(json.dumps(configure(home, profile, args.queue, args.probe), ensure_ascii=False, indent=2))
        return 0
    except (ValueError, OSError, subprocess.CalledProcessError):
        # Never print malformed credential contents or full preference parsing errors.
        print("Unable to configure: quit Zotero and check the profile, base rules, and Pi DeepSeek credential.")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
