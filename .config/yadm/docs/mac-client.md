# mac-client：Mac 终端与 SSH 工作机

适用于用户自己的 Mac，主要用于 SSH 连接 Linux 深度学习服务器，同时保留已有 GUI 工作方式。先按 [machine-setup.md](machine-setup.md) 盘点并补齐基础工具，再检查以下项目。

## 配置要求

- 使用本机实际可用的 Homebrew，读取 `brew --prefix`；兼容 Apple Silicon 和 Intel，不将另一台机器的安装前缀写死到配置中。
- GUI 默认安装 **kitty、fcitx5、Zotero**；`DOTFILES_GUI_APPS` 选择其中的应用，`DOTFILES_INSTALL_GUI_APPS=0` 跳过整个步骤。Kitty 同时安装配置所需的 Maple Mono CN 字体。Fcitx5 使用[官方安装器](https://github.com/fcitx-contrib/fcitx5-macos-installer)的拼音版，下载到 `~/.cache/yadm/` 后打开；需手动完成安装，首次安装后注销登录并在键盘设置中启用。已安装 Fcitx5 时跳过，不重装或替换插件。
- 选择 Zotero 后，agent 按 [Zotero 安装与科研工作流](zotero.md) 执行插件准备、原生激活与验收；Homebrew 安装成功本身不代表插件和会议 badge 已配置。已有 Zotero 时保留数据目录、账户与文库。
- 保留现有 SSH 配置、已知主机记录和密钥，使用已有别名与认证方式；不生成共享私钥，不把服务器地址、个人密钥或认证输出提交到 yadm。
- 检查新 shell 的终端工具、Node 和 agent 路径；继承当前网络设置，按本机需要显式启用代理。不要假设 Mac 一定运行某个固定端口的代理。
- 用被忽略的 `~/.config/yadm/local/` 保存本机设置和检查记录。SSH 配置继续使用本机已有的组织方式，无需建立公共服务器地址表。
- 小企鹅 Fcitx5 的 `~/.config/fcitx5/config`、`profile` 和 `conf/*.conf` 纳入 yadm，保留拼音、快捷键和外观设置。键盘布局缓存、`~/.local/share/fcitx5/` 用户词库及 `~/Library/fcitx5/` 插件资源留在本机；新机器的拼音版安装器包含 chinese-addons，完成图形安装并在系统设置中启用输入法。

Mac 不采用服务器的多用户 Conda/pip 共享缓存约定。用户没有提出本机深度学习任务时，不为 SSH 客户端用途安装 CUDA 或创建实验环境。

Mac 默认使用 Homebrew Python，公共 `.zshrc` 不初始化 Conda，也不加入固定的 Miniconda/Miniforge 路径。以后确需 Conda 时再在本机 shell 片段显式启用。PATH、LLVM 的 LDFLAGS/CPPFLAGS 可重复加载而不累积相同条目。

## 验收

1. `brew --prefix` 与当前架构匹配；在真实终端或 PTY 中检查新开的交互式 zsh，基础工具和 agent 路径正确，启动无报错。
2. 基础工具盘点通过，按用户选择检查 GUI 应用和字体。Neovim 初始化通过，插件锁文件没有因安装而改变；等待后台安装结束再退出。
3. Codex 能读取 `$setup-machine`；实际模型调用需要登录时，记录登录完成情况，不只根据命令存在判断可用。
4. 用户提供并授权 SSH 目标后，用其已有别名或地址验证登录和远端 shell。未提供目标时仅检查本机 SSH 客户端与配置，报告“远端连通性未验证”。
5. 明确列出需要手动操作的 GUI 授权、输入法启用或登录步骤；尚未完成时不标为已验证。
6. `machine-status.py` 的 `fcitx5_configuration` 分别检查 chinese-addons、拼音引擎文件和输入法列表中的拼音；系统键盘设置中的输入源启用状态仍需人工确认。

验证 SSH 登录不包含修改远端用户、权限、驱动或实验环境。需要安装服务器时，在对应服务器独立执行 `dl-server` 流程。
