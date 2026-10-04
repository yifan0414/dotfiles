# Dotfiles

多用户 Linux 深度学习服务器的 Conda 与 pip 配置约定见 [Conda 与 pip 管理设计](.config/yadm/docs/conda-management.md)。在其他机器配置 Conda 或 pip 时先阅读该文档；当前 bootstrap 不自动实施这些约定。

跨机器使用时，先在每台机器安装 Git 和 yadm，再按下面的流程初始化。

New machine bootstrap entry is `~/.config/yadm/bootstrap`, and `yadm bootstrap` executes that file directly.

This script is intentionally a post-clone bootstrap, not a pre-clone installer. If the dotfiles repo has not been cloned into `$HOME` through `yadm` yet, the script now exits immediately with a clear error instead of continuing with partial setup.

Because the script itself lives inside the dotfiles repo, the very first `yadm clone` still needs proxy to be configured manually if your network requires it. After the repo is present under `$HOME`, `yadm bootstrap` uses that machine's existing network settings by default.

Proxy settings are local to each machine. Bootstrap never writes global Git proxy configuration:

- default: inherit existing shell and Git settings
- `DOTFILES_PROXY_MODE=on yadm bootstrap`: use `http://127.0.0.1:7897` for this run
- `DOTFILES_PROXY_URL=http://127.0.0.1:7890 yadm bootstrap`: use an explicit endpoint for this run
- `DOTFILES_PROXY_MODE=off yadm bootstrap`: clear proxy environment variables and override Git's default HTTP proxy for this run (URL-specific Git proxy rules still take precedence)

The current macOS `.zshrc` separately calls `proxy_on` at shell startup; change that setting on machines without the local proxy. Bootstrap's `off` mode does not permanently change shell configuration.

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

- preserve machine-specific proxy settings unless explicitly overridden
- fail fast if the dotfiles checkout is not present under `$HOME`
- install repo-required base CLI software first when a supported package manager is available
- decrypt the shared GitHub token, log in with `gh`, and configure Git HTTPS authentication
- apply yadm alternate files
- prepare `~/.vim/autoload`, `~/.vim/plugged`, and `~/.vim/undo`, install `vim-plug`, and run `PlugInstall` through `vim` or `nvim` when available
- after installing Codex, install Pi and its core plugin dependencies, then `pi-web-access` and `pi-open-tui` through `pi install`
- install `oh-my-zsh`, `powerlevel10k`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `fzf-tab`
- run the existing tmux bootstrap
- reload kitty when possible
- print a self-check summary at the end showing what was configured, installed, present, skipped, or failed, including the base CLI toolset required by this repo

System package behavior:

- macOS: detect Homebrew on PATH or in `/opt/homebrew` / `/usr/local`; if `brew` exists, install CLI packages from `.config/yadm/packages/homebrew/core.Brewfile`
  - current core set: `curl`, `git`, `gh`, `gnupg`, `yadm`, `zsh`, `tmux`, `neovim`, `ripgrep`, `fzf`, `fd`, `eza`, `llvm`, `yazi`, `zoxide`
- macOS GUI apps: install `kitty`, `ghostty`, `squirrel` only when `DOTFILES_INSTALL_GUI_APPS=1`
- Linux: if `apt-get`, `dnf`, or `pacman` exists, install core CLI packages from the matching manifest under `.config/yadm/packages/linux/`
  - current core set: `curl`, `git`, `gh`, `gnupg`, `yadm`, `zsh`, `neovim`, `ripgrep`, `fzf`, `fd`/`fd-find`, `python3`, `xclip`
  - on Ubuntu/Debian, bootstrap also installs tmux build packages (`libevent-dev`, `ncurses-dev`, `build-essential`, `bison`, `pkg-config`) and compiles tmux from the official release tarball into `~/.local`
- if package installation fails or no supported package manager exists, bootstrap continues where possible; recorded failures or missing core tools make the final exit status nonzero
- pacman refreshes and upgrades the system together (`-Syu`) to avoid partial upgrades
- set `DOTFILES_SKIP_SYSTEM_PACKAGES=1` to disable system package installation entirely
- set `DOTFILES_SKIP_TMUX_SOURCE_BUILD=1` to keep the distro tmux package path on apt-based Linux systems
- set `DOTFILES_TMUX_VERSION=3.6a` or another release tag to override the tmux source version used on apt-based Linux systems
- Each bootstrap installs the latest `@earendil-works/pi-coding-agent`, `pi-ai`, and `pi-tui`. Node.js >=22.19.0 is required. Plugin dependencies are installed by `pi install`; rerunning bootstrap retries failed installs.
- set `DOTFILES_SELF_CHECK=0` to disable the final self-check summary
- color output is terminal-aware; set `NO_COLOR=1` to force plain text

Operational note:

- bootstrap installs dependencies and applies configuration; it is not a continuous synchronization service
- automatic backup scheduling is intentionally not installed on any platform; run `~/.local/bin/yadm-daily-backup` manually when you want to sync
- daily backup commits all tracked modifications (including deletions), then syncs the configured upstream; new files need an explicit `yadm add <path>` first
- configure Git author identity and remote authentication on every machine before the first backup
- concurrent backup runs stop; conflicts or unfinished Git operations require manual resolution, with no force-push
- if a process is killed and leaves a lock directory, confirm no backup is running before removing the lock under `~/.local/state/yadm-daily-backup/`
- run `python3 ~/.config/yadm/tests/test_bootstrap.py` for isolated regression checks (no live installs, commits, or remote pushes)

- plain `yadm clone <repo>` will still auto-apply alternates
- plain `yadm clone <repo>` may prompt whether to execute bootstrap; in headless or non-interactive environments, prefer `yadm clone --bootstrap <repo>`

Private local files:

- `~/.picgo/config.json` is intentionally local-only and ignored by Git; use `.picgo/config.example.json` as the template.
- `.config/yadm/encrypt` includes `.pi/agent/auth.json` and `.config/gh-token`; only their encrypted archive belongs in Git.
- runtime files like `nvim.log`, `picgo.log`, kitty `__pycache__`, and any local `~/.local/bin/zoxide` copy are intentionally ignored so backup commits stay clean.
- `~/Library/Rime/` is intentionally untracked: its dictionaries are large and regenerable, so keep them local or sync them separately.
- when `~/.local/share/yadm/archive` exists, `~/.local/bin/yadm-daily-backup` stages it automatically.

## Shared GitHub authentication

On the source machine, export the active `github.com` token from `gh` (including
macOS Keychain), then encrypt it with the other private files:

```sh
~/.local/bin/yadm-gh-export-token
export GPG_TTY="$(tty)"
yadm encrypt
```

Use the existing archive password when updating it. Encrypt on a machine that has
all private files from `.config/yadm/encrypt`; `yadm encrypt` rebuilds the archive
from local files. If a listed file is missing, restore it with `yadm decrypt`
before exporting a new token. Never add `gh-token` or `gh/hosts.yml` to Git.

Sync the bootstrap, package manifests, helper, ignore rules, encryption manifest,
and `.local/share/yadm/archive` through yadm. The backup script syncs the archive
but does not automatically re-encrypt changed plaintext credentials.

On a new machine:

```sh
# Git and yadm must already be installed; macOS also needs Homebrew.
yadm clone --bootstrap <repo>
# Enter the archive password when GnuPG asks.
gh auth status --hostname github.com
```

Bootstrap installs `gh` and GnuPG using Homebrew, apt, dnf, or pacman (`github-cli`
on Arch). The configured distribution repositories must provide these packages.
It decrypts the existing yadm archive (including the other encrypted credentials),
imports the token through standard input, verifies access to the GitHub user API,
and runs `gh auth setup-git --hostname github.com`. It prefers the OS credential
store; on headless Linux, gh may fall back to its local `hosts.yml`, which is ignored.
The decrypted token file has mode 600.

A private dotfiles repository still requires separate authentication for its first
clone. Bootstrap cannot use a token that has not been downloaded and decrypted yet.
Unattended runs need an already available GPG key/password cache; otherwise run
bootstrap interactively. Failed decryption or authentication makes bootstrap report
failure. `DOTFILES_SKIP_GH_AUTH=1 yadm bootstrap` explicitly skips credential setup.

To rotate the shared token, log in on the source machine, export and encrypt again,
then sync. On other machines run `yadm pull` followed by `yadm bootstrap` to import
the updated token. All machines share the token's permissions and revocation.
`GH_TOKEN`/`GITHUB_TOKEN` in your own shell still override the stored gh login;
bootstrap and the export helper ignore those variables while handling this token.

![nvim-startuptime](https://picture-suyifan.oss-cn-shenzhen.aliyuncs.com/uPic/QKCmiJ.png)
