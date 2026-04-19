#!/usr/bin/env bash

set -euo pipefail

resolve_appearance() {
  case "$(uname -s)" in
    Darwin)
      if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
        printf 'dark'
      else
        printf 'light'
      fi
      ;;
    *)
      if [[ "${TMUX_APPEARANCE_OVERRIDE:-}" == "dark" || "${TMUX_APPEARANCE_OVERRIDE:-}" == "light" ]]; then
        printf '%s' "$TMUX_APPEARANCE_OVERRIDE"
      else
        printf 'light'
      fi
      ;;
  esac
}

appearance="$(resolve_appearance)"
theme_file="$HOME/.tmux/themes/${appearance}.conf"

# The old cache-only check skipped sourcing on a fresh tmux server if the
# cached macOS appearance matched, which left tmux's default green status line.
current_theme="$(tmux show-options -gqv @appearance_theme 2>/dev/null || printf '')"

if [[ "$current_theme" != "$appearance" ]]; then
  tmux source-file "$theme_file" >/dev/null 2>&1
  tmux refresh-client -S >/dev/null 2>&1
fi

printf ''
