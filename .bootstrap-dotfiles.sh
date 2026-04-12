#!/bin/zsh

set -euo pipefail

log() {
  printf '[dotfiles] %s\n' "$1"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '[dotfiles] missing command: %s\n' "$1" >&2
    return 1
  fi
}

need_cmd git
need_cmd tmux

if [[ -f "$HOME/.tmux/scripts/bootstrap.sh" ]]; then
  log "bootstrapping tmux"
  "$HOME/.tmux/scripts/bootstrap.sh"
else
  log "skip tmux bootstrap: ~/.tmux/scripts/bootstrap.sh not found"
fi

if [[ -f "$HOME/.config/kitty/kitty.conf" ]]; then
  log "kitty config detected"

  if [[ -S /tmp/kitty ]]; then
    if kitty @ --to unix:/tmp/kitty load-config "$HOME/.config/kitty/kitty.conf" >/dev/null 2>&1; then
      log "kitty config reloaded"
    else
      log "kitty socket found but reload failed; restart kitty manually"
    fi
  else
    log "kitty is not listening on /tmp/kitty; restart kitty to pick up config changes"
  fi
else
  log "skip kitty bootstrap: ~/.config/kitty/kitty.conf not found"
fi

log "bootstrap complete"
