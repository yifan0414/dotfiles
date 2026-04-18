#!/usr/bin/env bash

set -euo pipefail

resolve_appearance() {
  local current_theme=""

  case "$(uname -s)" in
    Darwin)
      if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
        printf 'dark'
      else
        printf 'light'
      fi
      ;;
    *)
      if [[ "${TMUX_APPEARANCE:-}" == "dark" || "${TMUX_APPEARANCE:-}" == "light" ]]; then
        printf '%s' "$TMUX_APPEARANCE"
        return 0
      fi

      current_theme="$(tmux show-options -gqv @appearance_theme 2>/dev/null || printf '')"
      if [[ "$current_theme" == "dark" || "$current_theme" == "light" ]]; then
        printf '%s' "$current_theme"
      else
        printf 'dark'
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
  tmux set-environment -g TMUX_APPEARANCE "$appearance" >/dev/null 2>&1
  tmux refresh-client -S >/dev/null 2>&1
fi

printf ''
