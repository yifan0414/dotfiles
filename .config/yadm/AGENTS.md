# yadm 安装与维护入口

本目录管理同一套 dotfiles 在一台 Mac 和四台 Linux 深度学习服务器上的安装流程。同步规则和配置；机器角色、地址、密钥、实验环境及缓存留在各自机器。

## 先确定任务

- **维护仓库**：修改 bootstrap、文档或技能时，只完成所请求的改动和对应检查；不要顺带安装软件或配置本机。
- **配置目标机器**：先读 [machine-setup.md](docs/machine-setup.md)，确认当前机器、角色和授权范围，再按 `setup-machine` 技能实施。

## 按需读取

- `mac-client`：读 [mac-client.md](docs/mac-client.md)。保留现有 Mac GUI 软件，用于终端、SSH 和 agent。
- `dl-server`：读 [dl-server.md](docs/dl-server.md)。涉及 Conda 或 pip 时再读 [conda-management.md](docs/conda-management.md)，按目标机器的实际状态实施。

agent 先采用本次任务明确指定的角色，随后是 `DOTFILES_MACHINE_PROFILE`、本机 `yadm config local.class`、操作系统判断。bootstrap 的角色覆盖通过环境变量传入；不要把本机角色写入共享配置。

实施前检查已有配置，保留与任务无关的改动。每台服务器独立核对路径、账户、组和硬件；不要从一台的状态推断其他机器。仅连接用户明确提供并授权的远端。

`scripts/machine-status.py` 只做只读盘点；`--strict` 检查基础命令，不能代替角色文档的完整验收。报告应区分已完成、未验证和受阻事项。

Linux 和 Mac 主 `.zshrc` 管理公共初始化，稳定且不含敏感信息的主机差异使用 `.zshrc.local##hostname.<主机名>`；主配置直接自动加载 yadm 选中的 `~/.zshrc.local`。跟踪普通候选文件，不跟踪生成的链接。

仅本机设置、私密信息与检查报告放在被忽略的 `~/.config/yadm/local/`。早期初始化依赖的 Conda 根目录和代理变量继续由 `.zshenv` 读取安静的 `local/shell.zsh`；主机片段的加载顺序见 [服务器文档](docs/dl-server.md)。不得将 SSH 私钥、令牌或含认证信息的完整命令输出加入仓库。

Linux 的 NCCL 参数按 [服务器文档](docs/dl-server.md) 使用 hostname alternate，继续由 `.zshrc` 直接自动加载已获授权的配置。不同服务器独立确认参数；不要把单机参数改成公共 Linux 默认值。
