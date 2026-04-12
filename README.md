# Dotfiles

New machine bootstrap entry is `~/.bootstrap-dotfiles.sh`, and `yadm bootstrap` now delegates to it through `~/.config/yadm/bootstrap`.

Before any networked step, configure the proxy first. The bootstrap defaults to `http://127.0.0.1:7897`, and you can override it with `DOTFILES_PROXY_URL` or `DOTFILES_PROXY_HOST` plus `DOTFILES_PROXY_PORT`.

Typical flow after `yadm clone`:

```zsh
yadm alt
yadm bootstrap
```

The bootstrap will:

- configure shell and git proxy first
- apply yadm alternate files
- install `oh-my-zsh`, `powerlevel10k`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `fzf-tab`
- run the existing tmux bootstrap
- reload kitty when possible
- load or restart `com.yifan.yadm-daily-backup`

![nvim-startuptime](https://picture-suyifan.oss-cn-shenzhen.aliyuncs.com/uPic/QKCmiJ.png)
