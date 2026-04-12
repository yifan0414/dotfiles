# Dotfiles

New machine bootstrap entry is `~/.bootstrap-dotfiles.sh`, and `yadm bootstrap` now delegates to it through `~/.config/yadm/bootstrap`.

This script is intentionally a post-clone bootstrap, not a pre-clone installer. If the dotfiles repo has not been cloned into `$HOME` through `yadm` yet, the script now exits immediately with a clear error instead of continuing with partial setup.

Because the script itself lives inside the dotfiles repo, the very first `yadm clone` still needs proxy to be configured manually if your network requires it. After the repo is present under `$HOME`, `yadm bootstrap` takes over and enforces proxy-first for the rest of the setup.

Before any networked step, configure the proxy first. The bootstrap defaults to `http://127.0.0.1:7897`, and you can override it with `DOTFILES_PROXY_URL` or `DOTFILES_PROXY_HOST` plus `DOTFILES_PROXY_PORT`.

Required first:

```zsh
# install git and yadm first
yadm clone <repo>
```

Then run:

```zsh
yadm bootstrap
```

The bootstrap will:

- configure shell and git proxy first
- fail fast if the dotfiles checkout is not present under `$HOME`
- apply yadm alternate files
- install `oh-my-zsh`, `powerlevel10k`, `zsh-autosuggestions`, `fast-syntax-highlighting`, `zsh-syntax-highlighting`, and `fzf-tab`
- run the existing tmux bootstrap
- reload kitty when possible
- load or restart `com.yifan.yadm-daily-backup`

![nvim-startuptime](https://picture-suyifan.oss-cn-shenzhen.aliyuncs.com/uPic/QKCmiJ.png)
