#!/usr/bin/env python3
"""Check or reconcile HF tooling, shell exports and cache permissions on this host."""

import argparse
import datetime
import grp
import json
import os
from pathlib import Path
import pwd
import shutil
import socket
import subprocess
import sys
import tempfile

SOURCE = Path(__file__).resolve().parent
REPO_HOME = SOURCE.parents[1]
sys.path.insert(0, str(SOURCE))
sys.path.insert(0, str(REPO_HOME / '.config/yadm/scripts'))
from hf_runtime import merge_shell, shell_block, site_settings
from machine_config import config_path, load_machine

PUBLIC_ACL = 'u::rwx,g::rwx,m::rwx,o::rx,d:u::rwx,d:g::rwx,d:m::rwx,d:o::rx'
PUBLIC_ACL_LINES = {'user::rwx', 'group::rwx', 'mask::rwx', 'other::r-x',
                    'default:user::rwx', 'default:group::rwx', 'default:mask::rwx', 'default:other::r-x'}


def run(args):
    return subprocess.run(args, check=True, capture_output=True, text=True)


def accounts_for(machine):
    group = grp.getgrnam(machine['shared_group'])
    accounts = [p for p in pwd.getpwall() if p.pw_gid == group.gr_gid or p.pw_name in group.gr_mem]
    if machine['dotfiles_user'] not in {p.pw_name for p in accounts}:
        raise ValueError('dotfiles_user must belong to shared_group')
    return sorted(accounts, key=lambda p: p.pw_name), group.gr_gid


def own_path(path, home):
    if not path.resolve().is_relative_to(home.resolve()):
        raise ValueError(f'User configuration resolves outside its home: {path}')
    return path.resolve() if path.is_symlink() else path


def file_plan(machine, accounts, source=SOURCE, system_ids=(0, 0)):
    site = site_settings(machine)
    prefix = Path(machine['huggingface']['prefix'])
    library = prefix / 'lib/huggingface'
    plan = []
    def file(path, content, mode, ids):
        plan.append({'path': path, 'content': content, 'mode': mode, 'ids': ids})
    file(library / 'hf_runtime.py', (source / 'hf_runtime.py').read_bytes(), 0o755, system_ids)
    file(library / 'site.json', (json.dumps(site, indent=2) + '\n').encode(), 0o644, system_ids)
    for name in ('hf', 'hf-public', 'hf-private'):
        plan.append({'path': prefix / 'bin' / name, 'link': '../lib/huggingface/hf_runtime.py', 'ids': system_ids})
    block = shell_block(site)
    for account in accounts:
        home = Path(account.pw_dir)
        if not home.is_dir():
            raise ValueError(f'Account home is missing: {home}')
        if account.pw_name == machine['dotfiles_user']:
            target = home / ('.zshrc.local##hostname.' + machine['hostname'])
            link = home / '.zshrc.local'
            if (link.exists() or link.is_symlink()) and (not link.is_symlink() or link.resolve() != target.resolve()):
                raise ValueError(f'Unexpected hostname selection: {link}')
            startup = home / '.zshrc'
            if not startup.exists() or '.zshrc.local' not in startup.read_text():
                raise ValueError(f'Apply yadm shell alternates before deploying HF: {startup}')
            plan.append({'path': link, 'link': target.name, 'ids': (account.pw_uid, account.pw_gid)})
        else:
            target = home / '.zshrc'
        target = own_path(target, home)
        old = target.read_text() if target.exists() else ''
        info = target.stat() if target.exists() else None
        file(target, merge_shell(old, block).encode(), (info.st_mode & 0o777) if info else 0o644,
             (info.st_uid, info.st_gid) if info else (account.pw_uid, account.pw_gid))
    return plan


def file_matches(item):
    path = item['path']
    if 'link' in item:
        return path.is_symlink() and os.readlink(path) == item['link'] and (path.lstat().st_uid, path.lstat().st_gid) == item['ids']
    if path.is_symlink() or not path.is_file():
        return False
    s = path.stat()
    return (path.read_bytes() == item['content'] and s.st_mode & 0o777 == item['mode']
            and (s.st_uid, s.st_gid) == item['ids'])


def apply_files(plan, backup):
    changed = []
    for item in plan:
        if file_matches(item):
            continue
        path = item['path']
        if path.exists() or path.is_symlink():
            saved = backup / path.relative_to('/')
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, saved, follow_symlinks=False)
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o755)
        fd, temporary = tempfile.mkstemp(prefix='.' + path.name + '.', dir=path.parent)
        os.close(fd)
        temp = Path(temporary)
        try:
            if 'link' in item:
                temp.unlink()
                temp.symlink_to(item['link'])
                os.chown(temp, *item['ids'], follow_symlinks=False)
            else:
                temp.write_bytes(item['content'])
                temp.chmod(item['mode'])
                os.chown(temp, *item['ids'])
            temp.replace(path)
        finally:
            if temp.exists() or temp.is_symlink():
                temp.unlink()
        changed.append(str(path))
    return changed


def permission_plan(machine, accounts, gid):
    shared = Path(machine['shared_root'])
    if not shared.is_dir():
        raise ValueError(f'Confirm the mounted shared root before deployment: {shared}')
    plan = []
    for directory in (shared / 'huggingface', shared / 'huggingface/hub'):
        if directory.is_symlink() or directory.resolve() != shared.resolve() / directory.relative_to(shared):
            raise ValueError(f'Unexpected cache symlink: {directory}')
        plan.append({'path': directory, 'mode': 0o2775, 'ids': (0, gid), 'public': True})
    for account in accounts:
        home = Path(account.pw_dir)
        cache = home / '.cache'
        own_path(cache, home)
        if not cache.exists():
            plan.append({'path': cache, 'mode': 0o700, 'ids': (account.pw_uid, account.pw_gid), 'public': False})
        hf_home = cache / 'huggingface'
        for directory in (hf_home, *(hf_home / n for n in ('datasets', 'xet', 'assets', 'private-hub'))):
            own_path(directory, home)
            if directory.is_symlink():
                raise ValueError(f'Unexpected private cache symlink: {directory}')
            plan.append({'path': directory, 'mode': 0o700, 'ids': (account.pw_uid, account.pw_gid), 'public': False})
        for filename in ('token', 'stored_tokens'):
            path = hf_home / filename
            if path.is_symlink():
                raise ValueError(f'Unexpected credential symlink: {path}')
            if path.exists():
                if not path.is_file():
                    raise ValueError(f'Unexpected credential file type: {path}')
                plan.append({'path': path, 'mode': 0o600, 'ids': (account.pw_uid, account.pw_gid), 'public': False})
    return plan


def acl_lines(path):
    return set(run(['getfacl', '-cp', str(path)]).stdout.splitlines()) - {''}


def permission_matches(item):
    path = item['path']
    if not path.exists():
        return False
    s = path.stat()
    if (s.st_mode & 0o7777) != item['mode'] or (s.st_uid, s.st_gid) != item['ids']:
        return False
    acl = acl_lines(path)
    if item['public']:
        return PUBLIC_ACL_LINES.issubset(acl)
    return acl == {'user::rw-' if item['mode'] == 0o600 else 'user::rwx', 'group::---', 'other::---'}


def apply_permissions(plan):
    changed = []
    for item in plan:
        if permission_matches(item):
            continue
        path = item['path']
        if not path.exists():
            path.mkdir(mode=item['mode'])
        os.chown(path, *item['ids'])
        if item['public']:
            run(['setfacl', '-m', PUBLIC_ACL, str(path)])
        else:
            run(['setfacl', '-b', '-k', str(path)])
        path.chmod(item['mode'])
        changed.append(str(path))
    return changed


def tools_ready(machine):
    root = Path(machine['huggingface']['tools_root'])
    if not (root / 'bin/hf').is_file() or not (root / 'bin/python').is_file():
        return False
    code = '''import sys
import huggingface_hub.cli.hf
from importlib.metadata import version
from packaging.requirements import Requirement
for line in open(sys.argv[1]):
    if not line.strip() or line.lstrip().startswith('#'):
        continue
    requirement = Requirement(line.strip())
    if requirement.marker is None or requirement.marker.evaluate():
        if version(requirement.name) not in requirement.specifier:
            raise SystemExit(1)
'''
    try:
        return subprocess.run([str(root / 'bin/python'), '-c', code, str(SOURCE / 'requirements.txt')],
                              capture_output=True, timeout=20).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def install_tools(machine):
    hf = machine['huggingface']
    root = Path(hf['tools_root'])
    if not (root / 'bin/python').exists():
        if root.exists() and any(root.iterdir()):
            raise ValueError('Tools directory is nonempty but has no Python; inspect it before installing')
        run([hf['python'], '-m', 'venv', str(root)])
    # This environment is dedicated CLI tooling. Project environments are separate.
    run([str(root / 'bin/python'), '-m', 'pip', 'install', '-r', str(SOURCE / 'requirements.txt')])


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--machine-config', type=Path,
                        default=config_path(REPO_HOME, socket.gethostname()))
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--check', action='store_true', help='Read-only drift check (default)')
    modes.add_argument('--apply', action='store_true', help='Apply changes with backups; requires root')
    parser.add_argument('--install-tools', action='store_true', help='Install/repair the dedicated CLI environment during --apply')
    args = parser.parse_args(argv)
    if args.install_tools and not args.apply:
        parser.error('--install-tools requires --apply')
    machine = load_machine(args.machine_config)
    if machine['hostname'] != socket.gethostname():
        raise ValueError('Machine configuration hostname does not match this host')
    site_settings(machine)
    if not shutil.which('getfacl') or not shutil.which('setfacl'):
        raise ValueError('Install the acl package before checking/deploying shared HF caches')
    accounts, gid = accounts_for(machine)
    files = file_plan(machine, accounts)
    permissions = permission_plan(machine, accounts, gid)
    ready = tools_ready(machine)
    report = {'hostname': machine['hostname'], 'accounts': [p.pw_name for p in accounts],
              'file_drift': [str(p['path']) for p in files if not file_matches(p)],
              'permission_drift': [str(p['path']) for p in permissions if not permission_matches(p)],
              'tools_ready': ready}
    if args.apply:
        if os.geteuid() != 0:
            raise ValueError('Run --apply using sudo')
        if not ready and not args.install_tools:
            raise ValueError('CLI environment is unavailable; use --apply --install-tools to provision it')
        if args.install_tools:
            install_tools(machine)
            if not tools_ready(machine):
                raise ValueError('Installed CLI environment did not pass its import check')
        if report['file_drift'] or report['permission_drift']:
            stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
            backup = Path('/var/backups') / ('huggingface-' + stamp)
            backup.mkdir(mode=0o700)
            # Permission snapshots contain metadata only, never credential contents.
            metadata = [{'path': str(p['path']), 'mode': oct(p['path'].stat().st_mode & 0o7777),
                         'uid': p['path'].stat().st_uid, 'gid': p['path'].stat().st_gid,
                         'acl': sorted(acl_lines(p['path']))} for p in permissions if p['path'].exists()]
            (backup / 'permissions.json').write_text(json.dumps(metadata, indent=2) + '\n')
            report['backup'] = str(backup)
            report['permissions_changed'] = apply_permissions(permissions)
            report['files_changed'] = apply_files(files, backup)
        report['file_drift'] = [str(p['path']) for p in files if not file_matches(p)]
        report['permission_drift'] = [str(p['path']) for p in permissions if not permission_matches(p)]
        report['tools_ready'] = tools_ready(machine)
    print(json.dumps(report, indent=2))
    return int(bool(report['file_drift'] or report['permission_drift'] or not report['tools_ready']))


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f'HF deployment: {error}', file=sys.stderr)
        raise SystemExit(2)
