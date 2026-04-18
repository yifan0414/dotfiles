# Dotfiles

完整的新机配置流程见 [NEW_MACHINE.md](/Users/yifan/NEW_MACHINE.md)。

New machine bootstrap entry is `~/.config/yadm/bootstrap`, and `yadm bootstrap` executes that file directly.

This script is intentionally a post-clone bootstrap, not a pre-clone installer. If the dotfiles repo has not been cloned into `$HOME` through `yadm` yet, the script now exits immediately with a clear error instead of continuing with partial setup.

Because the script itself lives inside the dotfiles repo, the very first `yadm clone` still needs proxy to be configured manually if your network requires it. After the repo is present under `$HOME`, `yadm bootstrap` takes over and enforces proxy-first for the rest of the setup.

Before any networked step, configure the proxy first. The bootstrap defaults to `http://127.0.0.1:7897`, and you can override it with `DOTFILES_PROXY_URL` or `DOTFILES_PROXY_HOST` plus `DOTFILES_PROXY_PORT`.

Required first:

```zsh
# install git and yadm first
yadm clone --bootstrap <repo>
```

Then run:

```zsh
# if you skipped --bootstrap during clone, run it manually
yadm bootstrap
```

The bootstrap will:

- configure shell and git proxy first
- fail fast if the dotfiles checkout is not present under `$HOME`
- install repo-required base CLI software first when a supported package manager is available
- apply yadm alternate files
- install `oh-my-zsh`, `powerlevel10k`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `fzf-tab`
- run the existing tmux bootstrap
- reload kitty when possible
- load or restart `com.yifan.yadm-daily-backup`
- print a self-check summary at the end showing what was configured, installed, present, skipped, or failed, including the base CLI toolset required by this repo

System package behavior:

- macOS: if `brew` exists, install CLI packages from `.config/yadm/packages/homebrew/core.Brewfile`
  - current core set: `curl`, `git`, `yadm`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fzf`, `fd`, `eza`, `llvm`, `yazi`, `zoxide`
- macOS GUI apps: install `kitty`, `ghostty`, `squirrel` only when `DOTFILES_INSTALL_GUI_APPS=1`
- Linux: if `apt-get`, `dnf`, or `pacman` exists, install core CLI packages from the matching manifest under `.config/yadm/packages/linux/`
  - current core set: `curl`, `git`, `yadm`, `zsh`, `neovim`, `ripgrep`, `fzf`, `fd`/`fd-find`, `python3`, `xclip`
  - on Ubuntu/Debian, bootstrap also installs tmux build packages (`libevent-dev`, `ncurses-dev`, `build-essential`, `bison`, `pkg-config`) and compiles tmux from the official release tarball into `~/.local`
- if package installation fails or no supported package manager exists, bootstrap continues and skips dependent runtime steps where needed
- set `DOTFILES_SKIP_SYSTEM_PACKAGES=1` to disable system package installation entirely
- set `DOTFILES_SKIP_TMUX_SOURCE_BUILD=1` to keep the distro tmux package path on apt-based Linux systems
- set `DOTFILES_TMUX_VERSION=3.6a` or another release tag to override the tmux source version used on apt-based Linux systems
- set `DOTFILES_SELF_CHECK=0` to disable the final self-check summary
- color output is terminal-aware; set `NO_COLOR=1` to force plain text

Operational note:

- plain `yadm clone <repo>` will still auto-apply alternates
- plain `yadm clone <repo>` may prompt whether to execute bootstrap; in headless or non-interactive environments, prefer `yadm clone --bootstrap <repo>`

Private local files:

- `~/.picgo/config.json` is intentionally local-only and ignored by Git; use `.picgo/config.example.json` as the template.
- `.config/yadm/encrypt` already marks `~/.picgo/config.json` as a private file for `yadm encrypt` if you later decide to sync it securely.
- runtime files like `nvim.log`, `picgo.log`, kitty `__pycache__`, and any local `~/.local/bin/zoxide` copy are intentionally ignored so backup commits stay clean.
- when `~/.local/share/yadm/archive` exists, `~/.local/bin/yadm-daily-backup` stages it automatically.

![nvim-startuptime](https://picture-suyifan.oss-cn-shenzhen.aliyuncs.com/uPic/QKCmiJ.png)
