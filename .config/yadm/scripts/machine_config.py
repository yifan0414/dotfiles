"""Read non-secret machine data shared by inspection and component deployers."""

import json
from pathlib import Path


def config_path(home, hostname):
    if Path(hostname).name != hostname or hostname in ('.', '..'):
        raise ValueError('Invalid hostname')
    return Path(home) / '.config/yadm/machines' / (hostname + '.json')


def load_machine(path):
    path = Path(path)
    try:
        data = json.loads(path.read_text())
    except (OSError, ValueError) as error:
        raise ValueError(f'Cannot read machine configuration: {path}') from error
    if not isinstance(data, dict):
        raise ValueError('Machine configuration must be an object')
    for key in ('hostname', 'shared_root', 'shared_group', 'dotfiles_user'):
        if not isinstance(data.get(key), str) or not data[key].strip():
            raise ValueError(f'Missing machine setting: {key}')
    if not Path(data['shared_root']).is_absolute() or data['shared_root'] == '/':
        raise ValueError('shared_root must be an absolute directory below /')
    return data
