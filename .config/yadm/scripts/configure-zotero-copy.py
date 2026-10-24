#!/usr/bin/env python3
"""Install PDF clipboard actions while Zotero is closed, preserving unrelated preferences."""
import argparse
from datetime import datetime, timezone
import importlib.util
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

spec = importlib.util.spec_from_file_location("setup",Path(__file__).with_name("setup-zotero.py"))
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)

MANUAL = 'if (!items?.length) return; const Z=require("Zotero"); if (!Z.CopyPDF) throw new Error("Restart Zotero to activate PDF copy."); return await Z.CopyPDF.copySelected(items);'


def build_helper(home):
    source = home/".config/zotero/copy-pdf-macos.swift"
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    directory = home/".config/yadm/local/zotero/bin"
    directory.mkdir(parents=True,exist_ok=True)
    target = directory/"copy-pdf"
    stamp = directory/"copy-pdf.sha256"
    if target.is_file() and os.access(target,os.X_OK) and stamp.exists() and stamp.read_text()==digest:
        return target
    with tempfile.TemporaryDirectory(prefix="copy-pdf-build-",dir=directory) as temp:
        built = Path(temp)/"copy-pdf"
        subprocess.run(["/usr/bin/xcrun","swiftc","-O",str(source),"-o",str(built)],check=True,capture_output=True)
        built.chmod(0o755)
        built.replace(target)
    stamp.write_text(digest)
    return target


def configure(home, profile):
    processes = subprocess.check_output(["ps","-A","-o","comm="],text=True)
    if any(re.search(r"Zotero\.app/Contents/MacOS/zotero$",line,re.I) for line in processes.splitlines()):
        raise ValueError("Quit Zotero before installing the PDF clipboard actions")
    build_helper(home)
    prefs = setup.read_preferences(profile)
    if "extensions.actionsTags.rules" not in prefs:
        raise ValueError("Install Actions & Tags and the base workflow first")
    rule_ids = json.loads(prefs["extensions.actionsTags.rules"])
    changes = {}
    for name, event, suffix, data in [
        ("复制 PDF：阅读器按钮与快捷键",9,"startup-v1",(home/".config/zotero/copy-pdf.js").read_text()),
        ("复制 PDF 文件",0,"selected-v1",MANUAL),
    ]:
        key = "copy-pdf-" + suffix
        changes["extensions.actionsTags.rules."+key] = json.dumps({
            "name":name,"event":event,"operation":4,"data":data,"shortcut":"","enabled":True,
            "menu":name if event==0 else "", "showInMenu":{"item":event==0,"reader":event==0,
            "collection":False,"tools":False,"readerAnnotation":False}},ensure_ascii=False)
        if key not in rule_ids:
            rule_ids.append(key)
    changes["extensions.actionsTags.rules"] = json.dumps(rule_ids)
    original = profile/"prefs.js"
    lines = []
    for line in original.read_text().splitlines():
        match = re.fullmatch(r"user_pref\((.*)\);",line)
        if match:
            try:
                key,_ = json.loads("["+match[1]+"]")
                if key in changes:
                    continue
            except (ValueError,TypeError):
                pass
        lines.append(line)
    lines.extend("user_pref("+json.dumps(k)+", "+json.dumps(v)+");" for k,v in changes.items())
    directory = home/".config/yadm/local/zotero/backups"
    directory.mkdir(parents=True,exist_ok=True,mode=0o700)
    backup = directory/("prefs-before-copy-pdf-"+datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")+".js")
    shutil.copy2(original,backup)
    backup.chmod(0o600)
    with tempfile.NamedTemporaryFile(mode="w",dir=profile,delete=False) as f:
        target = Path(f.name)
        f.write("\n".join(lines)+"\n")
    try:
        target.chmod(original.stat().st_mode & 0o777)
        target.replace(original)
    finally:
        target.unlink(missing_ok=True)
    return {"configured":True,"backup":str(backup),"shortcut":"⌘⌥⇧C"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply",action="store_true")
    mode.add_argument("--build-helper",action="store_true",help="Compile the native clipboard bridge without editing Zotero preferences")
    parser.add_argument("--profile")
    args=parser.parse_args()
    try:
        home=Path.home()
        if args.build_helper:
            print(json.dumps({"helper":str(build_helper(home))}))
            return 0
        profile=setup.find_profile(home,args.profile)
        if not profile:
            raise ValueError("Initialize the Zotero profile first")
        print(json.dumps(configure(home,profile),ensure_ascii=False,indent=2))
        return 0
    except (ValueError,OSError,subprocess.CalledProcessError) as error:
        print("PDF copy setup failed: "+str(error))
        return 1


if __name__=="__main__":
    raise SystemExit(main())
