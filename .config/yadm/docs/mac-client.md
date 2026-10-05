# mac-client：Mac 终端与 SSH 工作机

适用于用户自己的 Mac，主要用于 SSH 连接 Linux 深度学习服务器，同时保留已有 GUI 工作方式。先按 [machine-setup.md](machine-setup.md) 盘点并补齐基础工具，再检查以下项目。

## 配置要求

- 使用本机实际可用的 Homebrew，读取 `brew --prefix`；兼容 Apple Silicon 和 Intel，不将另一台机器的安装前缀写死到配置中。
- 保留现有 Homebrew GUI 清单中的 **ghostty、kitty、squirrel**。`mac-client` 默认安装这份清单，显式 `DOTFILES_INSTALL_GUI_APPS=0` 只跳过本次 GUI 安装；不卸载既有软件。
- 保留现有 SSH 配置、已知主机记录和密钥，使用已有别名与认证方式；不生成共享私钥，不把服务器地址、个人密钥或认证输出提交到 yadm。
- 检查新 shell 的终端工具、Node 和 agent 路径；继承当前网络设置，按本机需要显式启用代理。不要假设 Mac 一定运行某个固定端口的代理。
- 用被忽略的 `~/.config/yadm/local/` 保存本机设置和检查记录。SSH 配置继续使用本机已有的组织方式，无需建立公共服务器地址表。

Mac 不采用服务器的多用户 Conda/pip 共享缓存约定。用户没有提出本机深度学习任务时，不为 SSH 客户端用途安装 CUDA 或创建实验环境。

## 验收

1. `brew --prefix` 与当前架构匹配；新开的 zsh 能使用基础工具和已安装的 agent，终端启动无报错。
2. 基础工具盘点通过。检查 ghostty、kitty、squirrel 的现有安装或 bootstrap 安装结果，保留用户原有 GUI 配置。
3. Codex 能读取 `$setup-machine`；实际模型调用需要登录时，记录登录完成情况，不只根据命令存在判断可用。
4. 用户提供并授权 SSH 目标后，用其已有别名或地址验证登录和远端 shell。未提供目标时仅检查本机 SSH 客户端与配置，报告“远端连通性未验证”。
5. 明确列出需要手动操作的 GUI 授权、输入法启用或登录步骤；尚未完成时不标为已验证。

验证 SSH 登录不包含修改远端用户、权限、驱动或实验环境。需要安装服务器时，在对应服务器独立执行 `dl-server` 流程。
