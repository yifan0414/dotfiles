#!/usr/bin/env python3
"""Runtime for hf, hf-public and hf-private."""

import json
import os
from pathlib import Path
import sys

PERSONAL_CACHES = {'HF_DATASETS_CACHE': 'datasets', 'HF_XET_CACHE': 'xet',
                   'HF_ASSETS_CACHE': 'assets'}


def environment(mode, original, site):
    env = dict(original)
    def default(key, value):
        if not env.get(key):
            env[key] = value
    default('HF_HOME', str(Path(env['HOME']) / '.cache/huggingface'))
    for key, suffix in PERSONAL_CACHES.items():
        default(key, str(Path(env['HF_HOME']) / suffix))
    default('HF_PUBLIC_HUB_CACHE', site['public_cache'])
    default('HF_PUBLIC_ENDPOINT', site['endpoint'])
    default('HF_HUB_CACHE', env.get('HUGGINGFACE_HUB_CACHE') or env['HF_PUBLIC_HUB_CACHE'])
    default('HUGGINGFACE_HUB_CACHE', env['HF_HUB_CACHE'])
    default('HF_TOKEN_PATH', str(Path(env['HF_HOME']) / 'token'))
    default('HF_ENDPOINT', env['HF_PUBLIC_ENDPOINT'])
    default('HF_HUB_DISABLE_IMPLICIT_TOKEN', '1')
    if mode == 'public':
        env.update(HF_CACHE_SCOPE='public', HF_HUB_CACHE=env['HF_PUBLIC_HUB_CACHE'],
                   HF_ENDPOINT=env['HF_PUBLIC_ENDPOINT'], HF_HUB_DISABLE_IMPLICIT_TOKEN='1',
                   HF_TOKEN_PATH='/dev/null')
        for key in ('HF_TOKEN', 'HUGGING_FACE_HUB_TOKEN'):
            env.pop(key, None)
    elif mode == 'private':
        env.update(HF_CACHE_SCOPE='private',
                   HF_HUB_CACHE=env.get('HF_PRIVATE_HUB_CACHE') or str(Path(env['HF_HOME']) / 'private-hub'),
                   HF_ENDPOINT='https://huggingface.co', HF_HUB_DISABLE_IMPLICIT_TOKEN='0',
                   HF_TOKEN_PATH=str(Path(env['HF_HOME']) / 'token'))
    if mode in ('public', 'private'):
        env['HUGGINGFACE_HUB_CACHE'] = env['HF_HUB_CACHE']
        if 'TRANSFORMERS_CACHE' in env:
            env['TRANSFORMERS_CACHE'] = env['HF_HUB_CACHE']
    return env


def main():
    name = Path(sys.argv[0]).name
    modes = {'hf': 'cli', 'hf-public': 'public', 'hf-private': 'private'}
    if name not in modes:
        raise ValueError('Invoke this runtime through hf, hf-public or hf-private')
    mode, args = modes[name], sys.argv[1:]
    if mode != 'cli' and not args:
        raise ValueError(f'Usage: {name} COMMAND [ARG ...]')
    is_auth = ((mode == 'cli' and args[:1] == ['auth']) or
               (mode == 'public' and len(args) > 1 and Path(args[0]).name == 'hf' and args[1] == 'auth'))
    if is_auth and (mode == 'public' or os.environ.get('HF_CACHE_SCOPE') == 'public'):
        raise ValueError('Use hf-private hf auth ... for personal authentication')
    if is_auth:
        mode = 'private'
    site = json.loads(Path(__file__).resolve().with_name('site.json').read_text())
    env = environment(mode, os.environ, site)
    old_umask = os.umask(0o077)
    Path(env['HF_HOME']).mkdir(parents=True, exist_ok=True, mode=0o700)
    if mode == 'private':
        Path(env['HF_HUB_CACHE']).mkdir(parents=True, exist_ok=True, mode=0o700)
    else:
        os.umask(old_umask)
    command = [str(Path(site['tools_root']) / 'bin/hf'), *args] if name == 'hf' else args
    os.execvpe(command[0], command, env)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        print(f'hf: {error}', file=sys.stderr)
        raise SystemExit(2)
