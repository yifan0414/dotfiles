# Keep this local file to quiet variable exports; zsh also loads it over SSH.
if [[ -r "$HOME/.config/yadm/local/shell.zsh" ]]; then
  source "$HOME/.config/yadm/local/shell.zsh"
fi
