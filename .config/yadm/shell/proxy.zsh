# Share proxy behavior across macOS and Linux; default to this machine's settings.
proxy_host="${DOTFILES_PROXY_HOST:-127.0.0.1}"
proxy_port="${DOTFILES_PROXY_PORT:-7897}"
proxy_scheme="${DOTFILES_PROXY_SCHEME:-http}"
proxy_url="${DOTFILES_PROXY_URL:-${proxy_scheme}://${proxy_host}:${proxy_port}}"
git_proxy_url="${DOTFILES_GIT_PROXY_URL:-$proxy_url}"

_dotfiles_proxy_git() {
  local count="${GIT_CONFIG_COUNT:-0}"
  if [[ ! "$count" =~ ^[0-9]+$ ]]; then
    printf '[dotfiles] invalid GIT_CONFIG_COUNT; proxy settings unchanged\n' >&2
    return 1
  fi
  if [[ -z "${_dotfiles_proxy_git_index:-}" ]] || [[ "$_dotfiles_proxy_git_index" -ge "$count" ]]; then
    _dotfiles_proxy_git_index="$count"
    export GIT_CONFIG_COUNT=$((count + 1))
  fi
  export "GIT_CONFIG_KEY_${_dotfiles_proxy_git_index}=http.proxy"
  export "GIT_CONFIG_VALUE_${_dotfiles_proxy_git_index}=$1"
}

proxy_on() {
  _dotfiles_proxy_git "$git_proxy_url" || return
  export http_proxy="$proxy_url" https_proxy="$proxy_url" all_proxy="$proxy_url"
  export HTTP_PROXY="$proxy_url" HTTPS_PROXY="$proxy_url" ALL_PROXY="$proxy_url"
}

proxy_off() {
  _dotfiles_proxy_git "" || return
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
}

proxy_toggle() {
  if [[ "${http_proxy:-${HTTP_PROXY:-}}" == "$proxy_url" || "${https_proxy:-${HTTPS_PROXY:-}}" == "$proxy_url" ]]; then
    proxy_off
  else
    proxy_on
  fi
}

_dotfiles_proxy_init() {
  local mode="${DOTFILES_PROXY_MODE:-inherit}"
  if [[ -z "${DOTFILES_PROXY_MODE:-}" && -n "${DOTFILES_PROXY_URL:-}${DOTFILES_PROXY_HOST:-}${DOTFILES_PROXY_PORT:-}${DOTFILES_GIT_PROXY_URL:-}" ]]; then
    mode=on
  fi
  case "$mode" in
    inherit) ;;
    on) proxy_on ;;
    off) proxy_off ;;
    *) printf '[dotfiles] DOTFILES_PROXY_MODE must be inherit, on, or off\n' >&2; return 1 ;;
  esac
}

_dotfiles_proxy_init
