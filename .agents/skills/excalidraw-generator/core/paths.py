"""Local Obsidian output paths for this machine.

This skill is specialized for the local Obsidian vault. Diagrams are written
into the folder that the Obsidian Excalidraw plugin is configured to use
(``folder: Excalidraw`` in the plugin's ``data.json``) instead of an arbitrary
working-directory path.

Overrides (environment variables):

- ``OBSIDIAN_VAULT``   — vault root (default: the iCSNote vault)
- ``EXCALIDRAW_DIR``   — drawings folder (default: ``$OBSIDIAN_VAULT/Excalidraw``)
"""

from __future__ import annotations

import os

#: Obsidian vault used on this machine (iCloud sync).
OBSIDIAN_VAULT = os.environ.get(
    "OBSIDIAN_VAULT",
    os.path.expanduser(
        "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/iCSNote"
    ),
)

#: Folder the obsidian-excalidraw-plugin is configured to create drawings in.
EXCALIDRAW_DIR = os.environ.get("EXCALIDRAW_DIR") or os.path.join(
    OBSIDIAN_VAULT, "Excalidraw"
)

#: Obsidian-native format for this vault.
DEFAULT_EXT = ".excalidraw.md"


def output_dir(create: bool = True) -> str:
    """Return the drawings folder, creating it when needed."""
    if create:
        os.makedirs(EXCALIDRAW_DIR, exist_ok=True)
    return EXCALIDRAW_DIR


def output_path(name: str, ext: str = DEFAULT_EXT) -> str:
    """Return an absolute path inside the vault for ``name``.

    ``name`` may be a plain basename or a path relative to the drawings folder.
    ``ext`` is appended when ``name`` has no ``.excalidraw``/``.excalidraw.md``
    suffix.
    """
    name = name.strip()
    if not name.endswith((".excalidraw", ".excalidraw.md")):
        name += ext
    if os.path.isabs(name):
        return name
    return os.path.join(output_dir(), name)


def save_to_vault(name: str, elements, ext: str = DEFAULT_EXT, **kwargs):
    """Save ``elements`` into the vault and return the absolute path.

    Convenience wrapper around :func:`core.engine.save` — the Obsidian format
    (``.excalidraw.md``) is the default here.
    """
    from .engine import save

    path = output_path(name, ext)
    save(path, elements, **kwargs)
    return path
