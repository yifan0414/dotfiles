#!/usr/bin/env bash

cache_file="${TMPDIR:-/tmp}/tmux-macos-appearance"

if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  appearance="dark"
  theme_file="$HOME/.tmux/themes/dark.conf"
else
  appearance="light"
  theme_file="$HOME/.tmux/themes/light.conf"
fi

current=""
if [[ -r "$cache_file" ]]; then
  current="$(<"$cache_file")"
fi

if [[ "$current" != "$appearance" ]]; then
  printf '%s' "$appearance" >| "$cache_file"
  tmux source-file "$theme_file" >/dev/null 2>&1
  tmux set-environment -g TMUX_APPEARANCE "$appearance" >/dev/null 2>&1
  tmux refresh-client -S >/dev/null 2>&1
fi

printf ''
