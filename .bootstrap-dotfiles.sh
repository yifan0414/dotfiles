#!/bin/zsh

set -euo pipefail

log() {
  printf '[dotfiles] %s\n' "$1"
}

die() {
  printf '[dotfiles] error: %s\n' "$1" >&2
  exit 1
}

warn() {
  printf '[dotfiles] warning: %s\n' "$1" >&2
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

PROXY_HOST="${DOTFILES_PROXY_HOST:-127.0.0.1}"
PROXY_PORT="${DOTFILES_PROXY_PORT:-7897}"
PROXY_SCHEME="${DOTFILES_PROXY_SCHEME:-http}"
PROXY_URL="${DOTFILES_PROXY_URL:-${PROXY_SCHEME}://${PROXY_HOST}:${PROXY_PORT}}"
GIT_PROXY_URL="${DOTFILES_GIT_PROXY_URL:-$PROXY_URL}"

require_supported_os() {
  case "$(uname -s)" in
    Darwin | Linux)
      return 0
      ;;
    *)
      die "unsupported OS: $(uname -s). This bootstrap only supports macOS and Linux."
      ;;
  esac
}

require_cmd() {
  local cmd="$1"
  local help_message="$2"

  if ! need_cmd "$cmd"; then
    die "$help_message"
  fi
}

configure_proxy() {
  export http_proxy="$PROXY_URL"
  export https_proxy="$PROXY_URL"
  export all_proxy="$PROXY_URL"
  export HTTP_PROXY="$PROXY_URL"
  export HTTPS_PROXY="$PROXY_URL"
  export ALL_PROXY="$PROXY_URL"

  if need_cmd git; then
    git config --global http.proxy "$GIT_PROXY_URL"
    git config --global https.proxy "$GIT_PROXY_URL"
  else
    warn "git is unavailable; skipped global git proxy setup"
  fi

  log "proxy configured: $PROXY_URL"

  if need_cmd nc; then
    if nc -z "$PROXY_HOST" "$PROXY_PORT" >/dev/null 2>&1; then
      log "proxy endpoint reachable: ${PROXY_HOST}:${PROXY_PORT}"
    else
      warn "proxy endpoint ${PROXY_HOST}:${PROXY_PORT} is not reachable yet"
    fi
  fi
}

require_dotfiles_checkout() {
  local required_paths=(
    "$HOME/.bootstrap-dotfiles.sh"
    "$HOME/.config/yadm/bootstrap"
    "$HOME/.tmux.conf"
    "$HOME/.tmux/scripts/bootstrap.sh"
  )
  local missing_path

  for missing_path in "${required_paths[@]}"; do
    if [[ ! -e "$missing_path" ]]; then
      die "dotfiles are not checked out under $HOME yet. Install yadm, run 'yadm clone <repo>', then rerun 'yadm bootstrap'."
    fi
  done

  require_cmd yadm "yadm is required before bootstrap. Install yadm, run 'yadm clone <repo>', then rerun 'yadm bootstrap'."

  if ! yadm list >/dev/null 2>&1; then
    die "yadm is installed, but the dotfiles repository is not initialized. Run 'yadm clone <repo>' first."
  fi
}

ensure_git_checkout() {
  local repo_url="$1"
  local target_dir="$2"
  local ref="${3:-}"

  if ! need_cmd git; then
    warn "git is unavailable; skipped checkout for $target_dir"
    return 0
  fi

  if [[ -d "$target_dir/.git" ]]; then
    log "found $(basename "$target_dir")"
    return 0
  fi

  mkdir -p "$(dirname "$target_dir")"
  log "cloning $repo_url -> $target_dir"
  if [[ -n "$ref" ]]; then
    git clone --depth 1 --branch "$ref" "$repo_url" "$target_dir"
  else
    git clone --depth 1 "$repo_url" "$target_dir"
  fi
}

apply_yadm_alternates() {
  if need_cmd yadm; then
    log "applying yadm alternates"
    yadm alt
  else
    warn "yadm is unavailable; skipped alternate processing"
  fi
}

verify_alternates() {
  if [[ "$(uname -s)" == "Darwin" || "$(uname -s)" == "Linux" ]]; then
    if [[ ! -f "$HOME/.zshrc" ]]; then
      die "yadm alternates did not produce ~/.zshrc. Check your alternate files before continuing."
    fi
  fi
}

bootstrap_zsh_runtime() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  ensure_git_checkout "https://github.com/ohmyzsh/ohmyzsh.git" "$HOME/.oh-my-zsh"
  ensure_git_checkout "https://github.com/romkatv/powerlevel10k.git" "$zsh_custom/themes/powerlevel10k"
  ensure_git_checkout "https://github.com/zsh-users/zsh-autosuggestions" "$zsh_custom/plugins/zsh-autosuggestions"
  ensure_git_checkout "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$zsh_custom/plugins/fast-syntax-highlighting"
  ensure_git_checkout "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$zsh_custom/plugins/zsh-syntax-highlighting"
  ensure_git_checkout "https://github.com/Aloxaf/fzf-tab" "$zsh_custom/plugins/fzf-tab"
}

bootstrap_tmux() {
  if [[ -f "$HOME/.tmux/scripts/bootstrap.sh" ]]; then
    if need_cmd tmux; then
      log "bootstrapping tmux"
      "$HOME/.tmux/scripts/bootstrap.sh"
    else
      warn "tmux is unavailable; skipped tmux bootstrap"
    fi
  else
    log "skip tmux bootstrap: ~/.tmux/scripts/bootstrap.sh not found"
  fi
}

reload_kitty_if_possible() {
  if [[ ! -f "$HOME/.config/kitty/kitty.conf" ]]; then
    log "skip kitty bootstrap: ~/.config/kitty/kitty.conf not found"
    return 0
  fi

  if ! need_cmd kitty; then
    warn "kitty is unavailable; skipped config reload"
    return 0
  fi

  if [[ -S /tmp/kitty ]]; then
    if kitty @ --to unix:/tmp/kitty load-config "$HOME/.config/kitty/kitty.conf" >/dev/null 2>&1; then
      log "kitty config reloaded"
    else
      warn "kitty socket found but reload failed; restart kitty manually"
    fi
  else
    log "kitty is not listening on /tmp/kitty; restart kitty to pick up config changes"
  fi
}

bootstrap_launch_agent() {
  local plist="$HOME/Library/LaunchAgents/com.yifan.yadm-daily-backup.plist"
  local label="com.yifan.yadm-daily-backup"
  local gui_domain="gui/$(id -u)"

  if [[ "$(uname)" != "Darwin" ]]; then
    return 0
  fi

  if [[ ! -f "$plist" ]]; then
    log "skip launch agent bootstrap: $plist not found"
    return 0
  fi

  if ! need_cmd launchctl; then
    warn "launchctl is unavailable; skipped LaunchAgent bootstrap"
    return 0
  fi

  if launchctl print "${gui_domain}/${label}" >/dev/null 2>&1; then
    if launchctl kickstart -k "${gui_domain}/${label}" >/dev/null 2>&1; then
      log "LaunchAgent restarted: $label"
    else
      warn "failed to restart LaunchAgent: $label"
    fi
  else
    if launchctl bootstrap "$gui_domain" "$plist" >/dev/null 2>&1; then
      log "LaunchAgent loaded: $label"
    else
      warn "failed to load LaunchAgent: $label"
    fi
  fi
}

main() {
  configure_proxy
  require_supported_os
  require_cmd git "git is required before bootstrap. Install git, then rerun this script."
  require_dotfiles_checkout
  apply_yadm_alternates
  verify_alternates
  bootstrap_zsh_runtime
  bootstrap_tmux
  reload_kitty_if_possible
  bootstrap_launch_agent
  log "bootstrap complete"
}

main "$@"
