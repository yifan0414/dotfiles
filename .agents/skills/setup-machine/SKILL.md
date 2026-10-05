---
name: setup-machine
description: Configure or reconcile the current Mac SSH workstation or Linux deep-learning server using this yadm checkout.
---

# 使用 yadm 配置当前机器

适用于 macOS/Linux，要求同一套 yadm checkout 位于当前用户的主目录中。

在同一套 dotfiles 下完成 `mac-client` 或 `dl-server` 配置，并以实际验收结果报告完成状态。维护这些规则或脚本本身时，只修改和检查所请求的源文件，安装不是维护任务的副作用。

## 入口与角色

- 读取 `~/.config/yadm/AGENTS.md` 和 [机器安装入口](references/machine-setup.md)。确认当前操作的是用户指定的目标机器。
- 基础工具可用后，运行 `python3 ~/.config/yadm/scripts/machine-status.py --profile auto`。用户明确指定角色时传入该角色；OS 与角色不匹配时先解决输入或目标错误。
- 角色按本次明确输入、`DOTFILES_MACHINE_PROFILE`、本机 `local.class`、实际 OS 选择。`local.class` 保存在本机 yadm Git 配置中，不提交到共享规则。
- Python 或 agent 运行环境尚未准备好时，按入口文档完成必要的 bootstrap。基础已齐备时直接处理缺口，避免无意义地重复完整安装。

## 按需加载

- `mac-client`：读取 [Mac 配置](references/mac-client.md)。保留全部现有 GUI 软件清单，配置终端与 SSH 客户端；实际服务器地址、密钥和网络参数使用本机已有配置。
- `dl-server`：读取 [Linux 服务器配置](references/dl-server.md)。配置 Conda/pip 时读取 [管理约定](references/conda-management.md)，先发现并复用实际安装；确认缺少 Conda 时按该文档使用可选安装模块，再继续 shell、共享缓存与权限配置。安装条件、固定版本和调用命令均以该文档为准。

这些参考文件链接到 `~/.config/yadm/docs/` 的同一份规则，不复制维护第二份政策。修改原文时核对两种角色的调用关系。

## 实施与完成

按当前授权的角色任务完成必要的配置与修复；保留已有环境、软件源、SSH 身份和无关改动。四台服务器分别核对路径、GID、GPU 和驱动，避免把当前机器的盘点结果当作其他机器的事实。

需要版本管理的非敏感单机配置采用 yadm 的 hostname alternate；Linux NCCL 的保存和加载方式遵循服务器文档。本机私密设置、临时设置和报告使用被忽略的 `~/.config/yadm/local/`，其中 `shell.zsh` 保留已有内容，仅合并必要的安静环境变量设置；Conda 根目录的连接方式遵循管理约定。需要改变公共行为时修改共享源文件；单机硬件参数保存在对应主机文件中，密钥和令牌留在本机。

以对应角色文档的验收条件完成任务：基础工具、agent 可用性、所请求的配置，以及具备条件的功能验证。Conda 本体、初始化、共享权限与训练环境分别验收；`machine-status.py --strict` 仅检查基础 CLI，不证明 SSH 远端、共享缓存或训练环境已通过验证。

报告当前机器的角色、实施结果、验证证据和待处理项。缺少管理员权限、模型登录、SSH 目标或第二个测试账户时明确对应缺口，继续完成不依赖该条件的工作。实际连接或配置其他机器应有用户明确提供的目标与任务。
