# mac-client：Mac 终端与 SSH 工作机

适用于用户自己的 Mac，主要用于 SSH 连接 Linux 深度学习服务器，同时保留已有 GUI 工作方式。先按 [machine-setup.md](machine-setup.md) 盘点并补齐基础工具，再检查以下项目。

## 配置要求

- 使用本机实际可用的 Homebrew，读取 `brew --prefix`；兼容 Apple Silicon 和 Intel，不将另一台机器的安装前缀写死到配置中。
- GUI 默认安装 **kitty、fcitx5、Zotero**；`DOTFILES_GUI_APPS` 选择其中的应用，`DOTFILES_INSTALL_GUI_APPS=0` 跳过整个步骤。Kitty 同时安装配置所需的 Maple Mono CN 字体。Fcitx5 默认使用中州韵版和白霜全拼，安装步骤见下文。
- 选择 Zotero 后，agent 按 [Zotero 安装与科研工作流](zotero.md) 执行插件准备、原生激活与验收；Homebrew 安装成功本身不代表插件和会议 badge 已配置。已有 Zotero 时保留数据目录、账户与文库。
- 保留现有 SSH 配置、已知主机记录和密钥，使用已有别名与认证方式；不生成共享私钥，不把服务器地址、个人密钥或认证输出提交到 yadm。
- 检查新 shell 的终端工具、Node 和 agent 路径；继承当前网络设置，按本机需要显式启用代理。不要假设 Mac 一定运行某个固定端口的代理。
- 用被忽略的 `~/.config/yadm/local/` 保存本机设置和检查记录。SSH 配置继续使用本机已有的组织方式，无需建立公共服务器地址表。
- 小企鹅 Fcitx5 的 `~/.config/fcitx5/config`、`profile` 和 `conf/*.conf` 纳入 yadm，默认输入法为 Rime。白霜方案与用户词库保存在 `~/.local/share/fcitx5/rime/`，插件资源保存在 `~/Library/fcitx5/`；这些资源和键盘布局缓存留在本机。

Mac 不采用服务器的多用户 Conda/pip 共享缓存约定。用户没有提出本机深度学习任务时，不为 SSH 客户端用途安装 CUDA 或创建实验环境。

Mac 默认使用 Homebrew Python，公共 `.zshrc` 不初始化 Conda，也不加入固定的 Miniconda/Miniforge 路径。以后确需 Conda 时再在本机 shell 片段显式启用。PATH、LLVM 的 LDFLAGS/CPPFLAGS 可重复加载而不累积相同条目。

## Fcitx5 中州韵版与白霜

1. 运行 `yadm bootstrap`。选择 `fcitx5` 后，脚本下载[白霜官方仓库](https://github.com/gaboolic/rime-frost)的 master 源码到 `~/.local/share/fcitx5/rime/`，然后打开[官方中州韵版安装器](https://github.com/fcitx-contrib/fcitx5-macos-installer/blob/master/README.zh-CN.md) `Fcitx5-Rime.zip`。中州韵版自带 Rime 插件。
2. 在安装器中完成安装。首次安装后注销并重新登录，在「系统设置 → 键盘 → 文本输入 → 编辑」中添加 Fcitx5。
3. 切换到 Fcitx5，使用 Rime 中的「白霜拼音」。首次启动时 Rime 编译方案和词库，默认每页显示 7 个候选。

重复运行时复用已有的 Rime 安装与白霜源码。`default.custom.yaml` 首次创建时指定白霜全拼和 7 个候选；后续沿用本机自定义设置与学习词库。已有 Fcitx5 但缺少 Rime 时，同样打开中州韵版安装器。

单独安装或部署白霜：

```sh
python3 ~/.config/yadm/scripts/setup_fcitx5.py --apply
```

Fcitx5 运行时脚本会请求 Rime 重新部署；尚未启动时，准备好的方案在下次启动时部署。安装器与白霜下载缓存位于 `~/.cache/yadm/`。

## 验收

1. `brew --prefix` 与当前架构匹配；在真实终端或 PTY 中检查新开的交互式 zsh，基础工具和 agent 路径正确，启动无报错。
2. 基础工具盘点通过，按用户选择检查 GUI 应用和字体。Neovim 初始化通过，插件锁文件没有因安装而改变；等待后台安装结束再退出。
3. Codex 能读取 `$setup-machine`；实际模型调用需要登录时，记录登录完成情况，不只根据命令存在判断可用。
4. 用户提供并授权 SSH 目标后，用其已有别名或地址验证登录和远端 shell。未提供目标时仅检查本机 SSH 客户端与配置，报告“远端连通性未验证”。
5. 明确列出需要手动操作的 GUI 授权、输入法启用或登录步骤；尚未完成时不标为已验证。
6. `machine-status.py` 的 `fcitx5_configuration` 检查 Rime 插件、引擎、默认输入法，以及白霜方案、词库、编译结果和启用状态；在系统键盘设置中确认 Fcitx5 输入源已启用。

验证 SSH 登录不包含修改远端用户、权限、驱动或实验环境。需要安装服务器时，在对应服务器独立执行 `dl-server` 流程。
