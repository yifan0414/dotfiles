#!/usr/bin/env python3
"""Check dotfiles without printing credentials; store encryption receipts locally."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile


TOKEN = re.compile(r"\b(?:sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b")
PRIVATE_KEY = re.compile(r"-----BEGIN (?:[A-Z]+ )?PRIVATE KEY-----")
SENSITIVE = {"apikey", "api_key", "access_token", "refresh_token", "client_secret", "password"}


def literal_secret(value):
    if not isinstance(value, str) or not value:
        return False
    # Pi supports environment variable names and shell command references.
    return not (re.fullmatch(r"[A-Z_][A-Z0-9_]*", value) or value.startswith("!")
                or value.startswith(("${", "$", "<")))


def findings(data):
    text = data.decode("utf-8", errors="replace")
    result = []
    if TOKEN.search(text):
        result.append("literal API token")
    if PRIVATE_KEY.search(text):
        result.append("private key")
    try:
        document = json.loads(text)
    except (ValueError, TypeError):
        return result

    def visit(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key.lower() in SENSITIVE and literal_secret(child):
                    # Field names from the fixed allowlist only; no user values.
                    result.append("literal credential field: " + key.lower())
                visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)
    visit(document)
    return sorted(set(result))


def git(repo, home, *args):
    return subprocess.check_output(
        ["git", "--git-dir", str(repo), "--work-tree", str(home), *args], cwd=home)


def scan(repo, home, working=False):
    names = set(git(repo, home, "diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z").split(b"\0"))
    if working:
        names.update(git(repo, home, "diff", "--name-only", "--diff-filter=ACMR", "-z").split(b"\0"))
    problems = []
    for raw in sorted(names - {b""}):
        name = os.fsdecode(raw)
        if name in (".pi/agent/auth.json", ".config/gh-token", ".config/gh/hosts.yml") or name.startswith(".ssh/"):
            problems.append(f"{name!r}: private file must not be tracked")
            continue
        for source in (["index", "working tree"] if working else ["index"]):
            if source == "index":
                data = git(repo, home, "show", ":" + name)
            else:
                path = home / name
                if not path.is_file() or path.is_symlink():
                    continue
                data = path.read_bytes()
            for kind in findings(data):
                problems.append(f"{name!r} ({source}): {kind}")
    if problems:
        raise ValueError("Possible plaintext credentials; commit/sync stopped:\n  " + "\n  ".join(problems))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def private_snapshot(home, config):
    manifest = config / "encrypt"
    if not manifest.exists():
        return {}
    result = {"manifest": digest(manifest), "files": {}}
    # This repository deliberately lists exact credential files, not globs.
    for line in manifest.read_text().splitlines():
        name = line.strip()
        if not name or name.startswith("#"):
            continue
        if any(char in name for char in "*?[]!") or Path(name).is_absolute() or ".." in Path(name).parts:
            raise ValueError("Encryption manifest must list exact paths inside the home directory.")
        path = home / name
        if not path.is_file() or path.is_symlink():
            raise ValueError(f"Private file {name!r} is missing or a symlink; restore it before encrypting or syncing.")
        result["files"][name] = digest(path)
    return result


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(data, stream, sort_keys=True)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def receipt_path(home):
    return Path(os.environ.get("XDG_STATE_HOME", home / ".local/state")) / "yadm-sync/encryption.json"


def check_archive(home, config, archive):
    manifest = config / "encrypt"
    if not manifest.exists():
        return
    snapshot = private_snapshot(home, config)
    receipt = receipt_path(home)
    if not archive.is_file() or not receipt.is_file():
        raise ValueError("Encryption receipt/archive missing. Run yadm encrypt before yb; after restoring an existing archive, yadm decrypt records a receipt too.")
    previous = json.loads(receipt.read_text())
    if previous != {"snapshot": snapshot, "archive": digest(archive)}:
        raise ValueError("Private files or encrypted archive changed. Run yadm encrypt before yb (or decrypt an archive received from another machine).")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("staged", "backup", "before-encrypt", "after-encrypt", "after-decrypt"))
    parser.add_argument("--home", type=Path, default=Path(os.environ.get("YADM_HOOK_WORK", Path.home())))
    parser.add_argument("--repo", type=Path, default=os.environ.get("YADM_HOOK_REPO"))
    args = parser.parse_args(argv)
    home = args.home.resolve()
    config = Path(os.environ.get("YADM_HOOK_DIR", home / ".config/yadm"))
    archive = Path(os.environ.get("YADM_HOOK_DATA", home / ".local/share/yadm")) / "archive"
    receipt = receipt_path(home)
    pending = receipt.with_name("before-encrypt.json")
    try:
        if args.mode == "after-decrypt" and "-l" in shlex.split(os.environ.get("YADM_HOOK_FULL_COMMAND", "")):
            return 0  # Listing an archive does not restore its credentials.
        if args.mode in ("staged", "backup"):
            if args.repo is None:
                raise ValueError("A repository path is required for commit/sync checks.")
            scan(args.repo, home, args.mode == "backup")
            if args.mode == "backup":
                check_archive(home, config, archive)
        elif args.mode == "before-encrypt":
            snapshot = private_snapshot(home, config)
            if args.repo and snapshot:
                tracked = git(args.repo, home, "ls-files", "-z", "--", *snapshot["files"]).split(b"\0")
                if any(tracked):
                    raise ValueError("A private file is tracked by Git; yadm would exclude it from encryption. Untrack it before encrypting.")
            save(pending, snapshot)
        elif os.environ.get("YADM_HOOK_EXIT", "0") == "0":
            snapshot = private_snapshot(home, config)
            if args.mode == "after-encrypt":
                if not pending.exists() or json.loads(pending.read_text()) != snapshot:
                    raise ValueError("Private files changed during encryption; run yadm encrypt again.")
            save(receipt, {"snapshot": snapshot, "archive": digest(archive)})
            pending.unlink(missing_ok=True)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        # Never include arbitrary exception messages containing file contents.
        message = str(error) if isinstance(error, ValueError) and not isinstance(error, json.JSONDecodeError) else "Unable to verify sync state; inspect configuration paths and permissions."
        print("[yadm] " + message, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
