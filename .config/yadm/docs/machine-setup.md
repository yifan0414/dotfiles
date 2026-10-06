# 在 Mac 与 Linux 服务器上使用同一套 yadm

本流程用于一台主要通过 SSH 工作的 Mac 和四台 Linux 深度学习服务器。每台机器分别执行；yadm 同步 dotfiles 与安装规则，bootstrap 准备基础工具，agent 按机器角色检查并完成配置。

## 新机器开始

先安装 Git 和 yadm；Mac 还需要可用的 Homebrew。保留现有 dotfiles、SSH 配置和密钥，处理 clone 报告的文件冲突后再继续。网络沿用本机已有配置。

```sh
yadm clone --no-bootstrap https://github.com/yifan0414/dotfiles.git
```

默认会按系统选角色：macOS 为 `mac-client`，Linux 为 `dl-server`。也可将角色保存在本机 Git 配置中；两条命令选对应的一条执行：

```sh
# Mac
yadm config local.class mac-client
# Linux 深度学习服务器
yadm config local.class dl-server
```

接着执行基础安装。已有 yadm checkout 时跳过 clone，确认本地改动后同步仓库，再从此步继续。

```sh
yadm bootstrap
```

需要一次性指定角色时使用环境变量：

```sh
DOTFILES_MACHINE_PROFILE=dl-server yadm bootstrap
```

不要使用 `yadm bootstrap --profile ...`；角色参数通过环境变量传给脚本。角色优先级为有效的 `DOTFILES_MACHINE_PROFILE`、`yadm config local.class`、系统判断；`auto` 按本机角色与系统判断解析。

bootstrap 保留既有安装流程：基础包、加密的 GitHub 凭据、shell 和编辑器、nvm/Node、Codex 与 Pi。遇到归档解密时在终端输入已有密码；agent 的模型服务登录按该工具的实际提示单独完成。脚本结束后阅读汇总，失败项先修复再重试。凭据归档的维护与日常同步见 [同步与凭据](sync.md)。

bootstrap 不自动安装 Conda。Linux 服务器由 agent 先盘点已有安装，确实缺少时按 [Conda/pip 管理约定](conda-management.md) 使用可选模块，再完成共享配置；Mac SSH 客户端不默认安装 Conda。

基础软件清单集中在 [packages](../packages)：Mac 使用 Homebrew，Linux 使用可用的 apt、dnf 或 pacman。apt 平台默认将 tmux 从发行源码编译到 `~/.local`；pacman 使用 `-Syu` 完成整体升级。可通过下表中的环境变量调整对应步骤。

## 交给 agent 完成角色配置

bootstrap 完成后打开新的终端，或运行 `zsh -l` 进入新登录 shell，使新安装的 Node 和 agent 路径生效；随后在安装文档目录启动 Codex，并显式调用已同步的技能：

```sh
zsh -l
cd ~/.config/yadm
codex
```

向 Codex 输入：

```text
使用 $setup-machine，按本机角色检查并完成这台机器的安装配置，遵守 AGENTS.md；先盘点现状，保留已有配置和实验环境，完成后给出已验证与待处理事项。
```

技能入口是 `~/.agents/skills/setup-machine/SKILL.md`，它按角色读取本目录文档。仅修改仓库文档时，不执行上述安装或配置流程。Mac 的 SSH 客户端角色本身不授权连接或配置四台服务器；远端工作需要明确的目标和任务。

也可从本目录启动 Pi：

```sh
pi --skill ~/.agents/skills/setup-machine/SKILL.md
```

然后输入同样的安装请求。当前 Pi 也能发现 `.agents/skills`；显式参数让这次任务的技能入口更清楚。两种 agent 使用同一份规则。

## 本机设置与盘点

基础工具准备好且 Python 3 可用后，运行只读盘点：

```sh
python3 ~/.config/yadm/scripts/machine-status.py --profile auto
python3 ~/.config/yadm/scripts/machine-status.py --profile auto --strict
```

输出为 JSON。`--strict` 只根据基础 CLI 工具是否齐备给出退出状态；GPU、Conda、共享缓存、SSH 连通性和 agent 登录仍按角色文档验收。缺少检查工具或权限时报告缺口，不据此声称安装完成。

| 设置 | 用法 |
|---|---|
| 本机持久角色 | `yadm config local.class mac-client` 或 `dl-server` |
| 本次角色覆盖 | `DOTFILES_MACHINE_PROFILE=mac-client yadm bootstrap` |
| Mac GUI 软件 | `mac-client` 默认安装现有清单；显式 `DOTFILES_INSTALL_GUI_APPS=0` 跳过本次安装 |
| 网络 | `DOTFILES_PROXY_MODE=inherit` 为默认；`on` 使用本机指定代理，`off` 关闭本次代理 |
| 跳过系统包安装 | `DOTFILES_SKIP_SYSTEM_PACKAGES=1 yadm bootstrap`；仍需自行准备缺失工具 |
| 使用发行版 tmux | `DOTFILES_SKIP_TMUX_SOURCE_BUILD=1 yadm bootstrap` 跳过 apt 平台的源码构建 |
| 指定 tmux 源码版本 | `DOTFILES_TMUX_VERSION` 设置发行标签 |
| 更新 agent | 默认复用已完整安装的 Codex/Pi；需要刷新时显式 `DOTFILES_UPDATE_AGENTS=1 yadm bootstrap` |
| 输出控制 | `NO_COLOR=1` 关闭颜色；`DOTFILES_SELF_CHECK=0` 关闭末尾汇总 |

代理端点使用已有的 `DOTFILES_PROXY_URL` 或相关代理变量。新 shell 不应假设所有机器都有 `127.0.0.1:7897` 上的代理服务。

非敏感机器参数统一存放在 `~/.config/yadm/machines/<hostname>.json`。共享根目录、共享组和组件安装位置在目标机器核对后填写；agent 配置机器时参考这份记录，`machine-status.py` 用它定位检查对象。当前已确认的文件为 [nlp4090-8.json](../machines/nlp4090-8.json)，其他机器没有参数文件时，盘点会报告共享根目录尚未配置。

参数文件记录本机约定，实际配置由 agent 按主题文档合并并验证。变更路径时同步更新记录和相关实际配置；HF 的目标状态与验收方法见 [HF 管理](huggingface.md)。

Linux 和 Mac 主 `.zshrc` 管理公共设置，直接自动加载按 hostname 选中的 `~/.zshrc.local`。需要同步且不含敏感信息的稳定主机差异放在 `.zshrc.local##hostname.<主机名>` 普通候选文件中，生成的链接不跟踪。agent 将 HF 环境变量直接合并到本机片段，保留其他设置。独立 NCCL alternate 的加载顺序见 [dl-server.md](dl-server.md)。

仅本机设置、私密信息与报告放在 `~/.config/yadm/local/`，该目录不加入 yadm。不参与同步的实际路径和早期初始化依赖的 Conda 根目录、代理变量使用安静的 `local/shell.zsh`，由 `.zshenv` 提前读取；不要将 SSH 地址、端口、私钥、令牌或实验环境复制进公共规则。

## 完成条件

基础安装成功、技能能够读取并执行、所选角色的配置和检查完成，才将本机记为完成。服务器上的 Conda 本体安装、shell 初始化、共享配置和已有训练环境分别验收；安装器成功不代表共享权限或训练已通过。机器状态、权限不足或未提供 SSH 目标造成的缺口应明确列为待处理。后续重复运行先重新盘点，合并所需变化，避免重建已存在的实验环境。

Mac 的具体要求见 [mac-client.md](mac-client.md)，服务器见 [dl-server.md](dl-server.md)。每台服务器保留独立的本机验收记录；跨机同步的是约定，各机器数据与缓存留在本地。
