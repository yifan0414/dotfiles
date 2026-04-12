# New Machine Setup

这份文档描述如何在一台新的 macOS 或 Linux 机器上，用 `yadm` 恢复这套 dotfiles。

## 原则

1. 在任何网络操作之前，先手动配置代理。
2. 第一次 `yadm clone` 之前，不能依赖仓库里的 bootstrap 脚本，因为脚本本身还没被 clone 下来。
3. clone 完成后，优先使用 `yadm clone --bootstrap <repo>`，避免无交互环境里额外的 bootstrap 确认提示。
4. bootstrap 设计成幂等脚本，可以重复执行。

默认代理地址：

```zsh
http://127.0.0.1:7897
```

## 标准流程

统一流程只有两段：

1. 手动准备最小环境：代理、`git`、`yadm`
2. 执行 `yadm clone --bootstrap <repo>`

clone 之后，bootstrap 会继续负责：

- 再次设置 shell 和 git 代理
- 安装系统级软件
- 用 `curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh` 安装 `zoxide`
- 执行 `yadm alt`
- 安装 `oh-my-zsh`、`powerlevel10k` 和 zsh 插件
- 安装 tmux TPM 插件
- 按条件 reload kitty
- 按条件加载 macOS LaunchAgent
- 输出一份自检摘要，说明哪些项目已配置、已安装、已存在、已跳过或失败

## macOS

### 1. 手动配置代理

```zsh
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export all_proxy=http://127.0.0.1:7897

git config --global http.proxy http://127.0.0.1:7897
git config --global https.proxy http://127.0.0.1:7897
```

### 2. 安装最小前置

```zsh
xcode-select --install
```

安装 Homebrew：

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Apple Silicon:

```zsh
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Intel Mac:

```zsh
eval "$(/usr/local/bin/brew shellenv)"
```

安装 `git` 和 `yadm`：

```zsh
brew install git yadm
```

### 3. clone 并自动 bootstrap

```zsh
yadm clone --bootstrap <repo-url>
```

### 4. 可选：安装 GUI 软件

默认 bootstrap 只装 CLI 软件。如果要一起装 GUI 软件：

```zsh
DOTFILES_INSTALL_GUI_APPS=1 yadm bootstrap
```

当前 GUI manifest 在：

- `.config/yadm/packages/homebrew/gui.Brewfile`

### 5. 重进 shell

```zsh
exec zsh
```

## Linux

### 1. 手动配置代理

```zsh
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export all_proxy=http://127.0.0.1:7897

git config --global http.proxy http://127.0.0.1:7897
git config --global https.proxy http://127.0.0.1:7897
```

### 2. 安装最小前置

Ubuntu / Debian:

```zsh
sudo apt update
sudo apt install -y git yadm
```

Fedora:

```zsh
sudo dnf install -y git yadm
```

Arch Linux:

```zsh
sudo pacman -Sy --noconfirm git yadm
```

### 3. clone 并自动 bootstrap

```zsh
yadm clone --bootstrap <repo-url>
```

### 4. 可选：切换默认 shell 到 zsh

```zsh
chsh -s "$(command -v zsh)"
exec zsh
```

## bootstrap 的系统包安装逻辑

### macOS

如果检测到 `brew`，会安装：

- `.config/yadm/packages/homebrew/core.Brewfile`

当前清单包含：

- `git`
- `yadm`
- `tmux`
- `neovim`
- `ripgrep`
- `fzf`
- `fd`
- `eza`
- `llvm`
- `yazi`

`zoxide` 不走 Homebrew manifest，而是由 bootstrap 单独用官方安装脚本安装到 `~/.local/bin`。

### Linux

如果检测到支持的包管理器，会安装对应清单：

- `apt-get` -> `.config/yadm/packages/linux/apt.txt`
- `dnf` -> `.config/yadm/packages/linux/dnf.txt`
- `pacman` -> `.config/yadm/packages/linux/pacman.txt`

默认安装的是核心 CLI 组件，比如：

- `curl`
- `git`
- `zsh`
- `tmux`
- `neovim`
- `ripgrep`
- `fzf`
- `fd` / `fd-find`
- `python3`

`zoxide` 不走 Linux 包清单，而是由 bootstrap 单独用官方安装脚本安装到 `~/.local/bin`。

## 允许重复执行的命令

下面这些命令都可以重复执行：

```zsh
yadm bootstrap
DOTFILES_INSTALL_GUI_APPS=1 yadm bootstrap
DOTFILES_SKIP_SYSTEM_PACKAGES=1 yadm bootstrap
```

如果不想打印结尾的自检摘要：

```zsh
DOTFILES_SELF_CHECK=0 yadm bootstrap
```

如果不想要颜色输出：

```zsh
NO_COLOR=1 yadm bootstrap
```

可覆盖代理：

```zsh
DOTFILES_PROXY_URL=http://127.0.0.1:7897 yadm bootstrap
```

也可以拆开写：

```zsh
DOTFILES_PROXY_HOST=127.0.0.1 DOTFILES_PROXY_PORT=7897 yadm bootstrap
```

## 跳过与容错策略

bootstrap 不会因为某个可选组件缺失就整体失败。

- 缺包管理器：跳过系统包安装
- Linux 没有 `sudo`：跳过系统包安装
- 缺 `curl`：跳过 `zoxide` 官方安装脚本
- 缺 `tmux`：跳过 tmux bootstrap
- 缺 `kitty`：跳过 kitty reload
- 缺 LaunchAgent 文件：跳过 LaunchAgent 加载
- 某个包安装失败：记录 warning，继续尝试后续步骤

但以下情况会直接阻塞退出：

- dotfiles 还没有通过 `yadm clone` 检出到 `$HOME`
- `yadm` 未安装或仓库未初始化
- 当前系统不是 macOS 或 Linux

## 故障排查

### `yadm clone` 之前就想运行 bootstrap

不支持。先手动安装 `git`、`yadm`，再：

```zsh
yadm clone --bootstrap <repo-url>
```

### `yadm clone <repo>` 卡在是否执行 bootstrap 的确认

在无交互环境里改用：

```zsh
yadm clone --bootstrap <repo-url>
```

### 代理端口不通

先确认本机代理已经启动：

```zsh
nc -z 127.0.0.1 7897
```

如果不是 `7897`，用环境变量覆盖：

```zsh
DOTFILES_PROXY_URL=http://127.0.0.1:<port> yadm bootstrap
```

### 想跳过系统级安装，只做 dotfiles 恢复

```zsh
DOTFILES_SKIP_SYSTEM_PACKAGES=1 yadm bootstrap
```

## 最短可执行版本

macOS:

```zsh
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export all_proxy=http://127.0.0.1:7897
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install git yadm
yadm clone --bootstrap <repo-url>
exec zsh
```

Linux:

```zsh
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export all_proxy=http://127.0.0.1:7897
sudo apt update && sudo apt install -y git yadm
yadm clone --bootstrap <repo-url>
exec zsh
```
