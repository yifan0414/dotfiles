#!/usr/bin/env bash

set -euo pipefail

TPM_DIR="$HOME/.tmux/plugins/tpm"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is not installed" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is not installed" >&2
  exit 1
fi

mkdir -p "$HOME/.tmux/plugins"

if [[ ! -d "$TPM_DIR/.git" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

"$TPM_DIR/bin/install_plugins"

if tmux start-server >/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf"
  echo "tmux plugins bootstrapped and config reloaded"
else
  echo "tmux plugins bootstrapped"
  echo "start tmux and run: tmux source-file ~/.tmux.conf"
fi
