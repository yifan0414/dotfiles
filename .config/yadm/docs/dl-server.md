# dl-server：多用户 Linux 深度学习服务器

四台 Linux 服务器共用同一套 yadm 规则，每台分别盘点和配置。先按 [machine-setup.md](machine-setup.md) 盘点并补齐基础工具，再按本机实际安装完成服务器配置；Linux 不安装 Mac GUI 软件。

## 先盘点现状

记录发行版、架构、可用管理员权限、当前账户与共享组、挂载路径、Conda 安装和现有实验环境。检查 GPU、NVIDIA 驱动及项目实际使用的 PyTorch/CUDA 运行时；区分系统驱动、CUDA toolkit 和环境内运行时。

路径、用户名、UID/GID、GPU 型号及驱动版本按本机核对，不照搬另一台服务器的数字或状态。服务器上的个人文件、数据集、环境与缓存不进入 dotfiles 仓库。检查记录放在被忽略的 `~/.config/yadm/local/`，避免写入共享文档。

## 配置要求

- 保留既有实验环境、项目依赖、软件源和当前 shell 配置，先备份将修改的配置，再合并需要的设置。
- Conda、pip 的安装、路径、版本、缓存、权限和验证遵循 [conda-management.md](conda-management.md)。先发现并复用已有 Conda；确认完全缺少时，按该文档调用可选安装模块，再落实共享配置。没有管理员权限时报告共享部署缺口，不自行换成个人安装并宣称服务器完成。
- 该文档中的路径示例和单机记录不能视为四台机器的现状；发现实际安装根目录后替换示例路径，并按约定合并本机 shell 初始化设置。
- 按约定检查 `datausers` 组与需要参与共享的账户，使用本机实际 GID。组、系统配置和目录权限需要管理员权限时，先核对可用权限；缺少权限则明确报告待管理员处理项。
- 不因执行通用安装就升级 NVIDIA 驱动、CUDA、NCCL 或 PyTorch，也不重建或迁移已有环境。确需变更这些组件时应有明确任务，并针对相关项目验证兼容性。
- 不在共享 shell 配置中自动激活某个实验环境；服务器特有环境变量按本机条件应用，避免在没有相关硬件或库的机器上强行启用。

## 主机专属 shell 配置

主 `.zshrc` 管理公共设置，在基础工具初始化后、NCCL 加载前，直接自动 source yadm 按 hostname 选中的 `~/.zshrc.local`。仓库跟踪 `.zshrc.local##hostname.nlp3090-2`、`.zshrc.local##hostname.nlp3090-4` 和 `.zshrc.local##hostname.nlp4090-8` 这些普通候选文件；生成的 `.zshrc.local` 链接不跟踪。

稳定且不含敏感信息的主机差异放在相应候选文件中：两台 3090 的缓存与模型路径使用用户已确认的归属，`nlp4090-8` 的 CUDA 12.8 设置留在自己的片段中。`ics/ysyx` 项目变量保留原配置，本次未迁移。

不参与同步的实际路径、私密设置仍放在忽略的 `~/.config/yadm/local/shell.zsh`，仅使用安静的环境变量设置，由 `.zshenv` 提前读取。Conda 根目录、代理等早期初始化依赖继续使用这个入口，不移到稍后加载的主机片段。

## 主机专属 NCCL 配置

用户已授权同步的非敏感主机参数使用 yadm hostname alternate。例如 `nlp4090-8` 的参数保存在 `.config/nvidia-p2p/env.sh##hostname.nlp4090-8`；yadm 匹配本机 hostname 后，将其应用到 `.config/nvidia-p2p/env.sh`。版本管理保存普通配置文件，不保存指向本机历史目录的绝对路径链接。

迁移每台服务器前，先保存原 `env.sh` 内容及软链接指向，再建立该主机的候选文件。yadm 选择一个匹配版本，不会合并旧配置；无匹配时也不应把其他主机的参数当作本机默认值。

NCCL 继续使用独立的 hostname alternate；Linux `.zshrc` 在主机片段之后直接自动 source `~/.config/nvidia-p2p/env.sh`，保留已获授权的参数与加载方式。其他服务器先核对硬件、库路径和版本，再为各自 hostname 准备参数文件；不直接把这台机器的参数复制到公共 Linux 配置。私密设置和检查报告仍留在忽略的 `~/.config/yadm/local/`。

## Hugging Face 多用户配置

HF 环境变量的配置位置是本套 Linux 服务器的固定约定：

- yifan：直接写入 `.zshrc.local##hostname.<主机名>`，由主 `.zshrc` 自动加载 yadm 选中的 `~/.zshrc.local`；跟踪候选文件，保留生成的链接。
- 其他用户：直接合并到各自的 `~/.zshrc`，保留原有配置和显式项目覆盖；迁移前备份。
- 不将 HF 默认环境变量写入 `/etc/profile.d`、全局 Bash/Zsh 初始化文件、`BASH_ENV` 或 systemd 环境生成器。独立后台任务通过 `hf-public` / `hf-private` 显式取得任务所需的变量。

这一约定针对 HF 环境变量；Conda/pip 的系统配置继续遵循 [conda-management.md](conda-management.md)。各机共享缓存路径、用户及属组仍需独立核对。

公共模型和数据集的 Hub 原始下载缓存由 `datausers` 共用；凭据、Datasets 的 Arrow/索引、Xet 和 assets 缓存留在各自的 `HF_HOME`。个人 `HF_HOME` 及私有下载目录使用 `700`，令牌文件使用 `600`。共享缓存目录使用 `root:datausers`、`2775`、SGID 和默认 ACL，保证新建子目录及下载锁可供组内协作。

`nlp4090-8` 按上述约定使用独立标记块配置，默认值如下；其他服务器先核对磁盘和账户，不直接套用这些路径。

| 变量 | 本机默认值 |
|---|---|
| `HF_HOME` | `$HOME/.cache/huggingface` |
| `HF_HUB_CACHE` | `/ssd_4t/shared/huggingface/hub` |
| `HF_DATASETS_CACHE` | `$HF_HOME/datasets` |
| `HF_XET_CACHE` | `$HF_HOME/xet` |
| `HF_ASSETS_CACHE` | `$HF_HOME/assets` |
| `HF_ENDPOINT` | `https://hf-mirror.com` |

交互式 Zsh 直接从个人配置加载，新终端自动生效；yifan 当前终端执行 `source ~/.zshrc.local`，其他用户执行 `source ~/.zshrc`。从这些终端启动的 Bash/Python 子进程会继承导出的变量。独立的 cron、systemd、容器或调度作业使用下述任务入口取得相同默认值。系统 `/etc/profile.d`、全局 Bash/Zsh 初始化及 systemd 环境生成器均不承载本机 HF 配置。

`.config/huggingface/bin/` 中的入口安装到 `/usr/local/bin/`：

```sh
hf-public hf download Qwen/Qwen3.5-4B
hf-public python evaluate.py
hf-private hf auth login
hf-private python private_inference.py
```

`hf-public` 强制使用公共缓存及镜像，在子进程中禁用个人令牌文件和令牌环境变量。默认设置禁用隐式令牌发送；受限模型和私有仓库使用 `hf-private`，它切换至官方端点 `https://huggingface.co`，使用个人 `$HF_HOME/private-hub`，并对该任务设置 `umask 077`。可通过 `HF_PRIVATE_HUB_CACHE` 指定个人 SSD 私有目录。不要把受限资源下载到公共缓存。

全局 `hf` 来自独立的 `/opt/huggingface-tools` 工具环境（依赖记录在 `.config/huggingface/requirements.txt`），认证子命令自动采用个人配置；它不升级项目环境中的 SDK。激活项目环境后，推荐仍使用 `hf-public` / `hf-private` 前缀运行项目的 `hf` 或 Python。现有个人缓存保留原位置，未经确认不向公共缓存迁移。公共 `datasets/`、`models/` 继续提供整理后的本地资源，不作为 Hub 内部缓存。

部署后以两个普通组成员实际验证：首个用户下载一个小型公共文件，另一个用户仅使用本地缓存读取同一文件；同时验证 SDK 下载锁的权限、竞争及个人凭据目录的隔离。系统配置备份、部署报告和检查临时文件保存在本机忽略目录，不写入仓库。

## 验收

1. 基础 CLI 工具齐备，新开的 shell 能正常启动、使用 agent，实际加载的 `.zshrc.local` 与本机 hostname 匹配。分别确认 Conda 本体健康、实际根目录正确、激活命令可用且未自动进入 base。
2. Conda 有效配置及空环境创建预演符合现有管理约定；保留原有环境及项目依赖版本。
3. pip 的实际解释器版本、有效缓存目录和共享目录属组、SGID、ACL 已核对。具备两个普通组成员账户时，按 Conda/pip 文档验证跨账户缓存复用和权限继承；只有一个账户可用时标记该检查未完成。
4. GPU 检查以已有工具和环境为准：可用时检查 `nvidia-smi`，有已确认的项目环境时验证该环境的 PyTorch GPU 可用性。使用 NCCL 主机参数时核对选中的 alternate 和新 shell 的实际加载；版本或参数变更按当前任务验证。缺少工具或环境时报告现状，不为了检查而安装新的大型实验依赖。
5. 明确记录当前机器已完成、未验证与受阻项目。Conda 本体安装成功不代表共享权限或训练环境通过；`machine-status.py --strict` 通过只表示基础工具齐备，不能代替以上服务器验收。

对其余服务器重复此流程。当前服务器的管理员权限、共享缓存状态和 GPU 验证结果仅适用于当前服务器。
