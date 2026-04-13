#!/usr/bin/env bash

if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  appearance="dark"
  theme_file="$HOME/.tmux/themes/dark.conf"
else
  appearance="light"
  theme_file="$HOME/.tmux/themes/light.conf"
fi

# The old cache-only check skipped sourcing on a fresh tmux server if the
# cached macOS appearance matched, which left tmux's default green status line.
current_theme="$(tmux show-options -gqv @appearance_theme 2>/dev/null || printf '')"

if [[ "$current_theme" != "$appearance" ]]; then
  tmux source-file "$theme_file" >/dev/null 2>&1
  tmux set-environment -g TMUX_APPEARANCE "$appearance" >/dev/null 2>&1
  tmux refresh-client -S >/dev/null 2>&1
fi

printf ''
