# 多用户深度学习服务器的 Conda 与 pip 管理约定

适用场景：多个用户共用一台 Linux 深度学习服务器。目标是共享 Conda 安装、Conda 包缓存和 pip 下载缓存，让每个用户独立维护实验依赖，默认不自动激活 base。

在其他机器实施 Conda 或 pip 配置时，agent 应先读取本文，检查目标机器的实际安装路径、配置来源和权限，再应用这些约定。Conda 路径以 `/opt/miniforge3` 为例；已有 Miniconda 或其他安装时，按实际安装根目录替换，保留已有环境和软件源配置。跨机器统一使用 `/var/cache/pip` 作为 pip 共享缓存路径。

## 设计原则

1. **默认不自动激活 base。** Shell 初始化只让 `conda activate` 可用。用户需要某个环境时手动激活，base 沿用机器现有的安装和权限设置。
2. **环境默认个人优先。** 每个项目的 PyTorch、CUDA 运行时和其他 Python 依赖由该环境的使用者维护，避免其他人的升级改变实验依赖。
3. **两种包缓存分别配置、共同复用。** Conda 缓存默认共享优先，pip 缓存统一使用 `/var/cache/pip`。个人环境仍可以复用缓存中兼容的下载和构建结果；环境位置和缓存位置分别配置。
4. **共享环境按需使用。** 确实需要共同维护的环境，可以显式创建在共享环境目录，由项目成员协调依赖更新。已有环境不因目录顺序调整而迁移。
5. **安装使用 Conda 默认链接策略。** 按默认行为复用缓存中的文件，不设置强制复制，也不要求分离已有硬链接。

## 目录与权限

| 用途 | 示例路径 | 管理方式 |
|---|---|---|
| Conda 安装和 base | `/opt/miniforge3` | 使用机器现有安装和权限，默认不自动激活 base |
| 个人环境 | `~/.conda/envs` | 用户自己维护，默认创建环境的位置 |
| 共享环境 | `/opt/miniforge3/envs` | `root:datausers`、`2775`，仅按需创建公共环境 |
| Conda 共享包缓存 | `/opt/miniforge3/pkgs` | `root:datausers`、`2775`，组成员共同下载和复用包 |
| Conda 个人包缓存 | `~/.conda/pkgs` | 共享缓存不可写时的后备位置 |
| pip 共享缓存 | `/var/cache/pip` | 顶层 `root:datausers`、`2775`，所有参与账户共用 |
| pip 系统配置 | `/etc/pip.conf` | `root:root`、`644`，设置全局缓存路径 |

共享目录的组写权限应用于 Conda 的 `envs`、`pkgs` 子树及 `/var/cache/pip`。

共享目录中的子目录应设置 SGID，使新建内容继承 `datausers` 属组；同时配置默认 ACL，让新建内容继承组访问权限。已有共享文件也应具备所需的组读写权限，已有共享目录应具备组读、写和执行权限。不能只修改顶层目录：例如缓存中的 `urls.txt` 和索引目录也必须可写。

## Conda 配置约定

下面是目标配置片段。合并到实际配置中，保留已有软件源、镜像和其他机器设置。

```yaml
# 新建命名环境优先进入个人目录。
envs_dirs:
  - ~/.conda/envs
  - /opt/miniforge3/envs

# 下载和安装时优先复用共享缓存。
pkgs_dirs:
  - /opt/miniforge3/pkgs
  - ~/.conda/pkgs

auto_activate_base: false
```

服务器默认配置位于安装根目录的 `.condarc`，个人配置位于 `~/.condarc`。检查 `conda config --show-sources` 和最终生效值，避免个人配置、环境配置或环境变量改变预期顺序。每个账户是否关闭自动激活都需要核对，不能从一个账户推断所有账户。

目录顺序的含义：

- `conda activate NAME` 按 `envs_dirs` 查找；同名环境优先使用前面的目录。`base` 对应安装根目录。
- `conda create -n NAME` 创建新环境时，选择第一个可写的环境目录；本设计默认使用个人目录。
- 显式指定路径可以创建共享环境，例如 `conda create -p /opt/miniforge3/envs/PROJECT python=3.11`。
- 新下载的软件包进入第一个可写的 `pkgs_dirs`。共享缓存可写时，大家的新包进入共同缓存；仅配置了只读共享缓存时，新包进入个人缓存。
- Conda 的包缓存与 pip 的下载缓存分别管理；此处的 `pkgs_dirs` 不配置 pip 缓存。

## pip 共享缓存约定

Linux 上 pip 的默认缓存位于用户自己的 `~/.cache/pip`。本规范显式选择 `/var/cache/pip` 供多个用户共用；这是服务器的部署约定，不是 pip 的默认路径。

Conda 缓存保存 Conda 包及其索引，pip 缓存保存 HTTP 下载响应和本地构建的 wheel。两者使用各自的目录和管理命令，不把 pip 缓存放进 Conda 的 `pkgs` 目录。缓存共享不改变软件包安装位置：使用实验环境的 `python -m pip`，包仍安装进该环境。

### pip 版本要求

需要跨用户共享新下载的 HTTP 缓存时，使用缓存的每个 Python 解释器都应配备 **pip 25.0 或更高版本**。从 pip 25.0 起，网络缓存文件才会继承缓存目录的读写权限；更早版本可能把文件写成 `600`，即使目录已设置 SGID、默认 ACL 或 `umask 0002`，其他用户仍无法读取这些新文件。见 [pip 25.0 官方更新记录](https://pip.pypa.io/en/stable/news/#v25-0)。

分别检查安装根目录和各实验环境的 `python -m pip --version`，不能只检查 base。需要更新时，选择与现有 Python 兼容、经过验证的固定 pip 版本；例如 pip 25.0.1 支持 Python 3.8。先记录版本并备份 pip 工具本身，再用 `--no-deps` 仅更新 pip，保留 Python、PyTorch 等实验依赖版本。旧版 pip 留下的 `600` 缓存文件仍需修复已有权限。

### 系统配置与权限

在每台机器的 `/etc/pip.conf` 中合并以下配置，保留已有镜像、索引等其他设置：

```ini
[global]
cache-dir = /var/cache/pip
```

参与共享的账户应属于 `datausers` 组。组名在机器之间保持一致，数字 GID 使用各机器的实际值；新增组成员后重新登录，使用 `id` 确认当前进程已获得该组。

共享目录的要求：

- 顶层目录由 `root:datausers` 管理，权限 `2775`。
- 子目录保留 SGID，默认 ACL 赋予 `datausers` 组读、写和执行权限。
- 新缓存文件的属主可以是实际下载用户，属组继承 `datausers`；文件通常为 `664`，组成员可以共同读写。
- 验证已有缓存内容的组访问权限；只修改顶层目录无法修复已有子目录和文件的权限。

`2775` 目录和 `664` 文件允许组外用户读取缓存，但不允许组外写入。`datausers` 组成员可以修改、清理彼此的缓存，这是本规范采用的协作权限。

对于新建的共享目录，下面是参考设置步骤。先确认目标路径和组，已有目录及配置应先检查、备份，再合并所需设置：

```sh
getent group datausers
sudo install -d -o root -g datausers -m 2775 /var/cache/pip
sudo setfacl -m g:datausers:rwx,d:u::rwx,d:g::rwx,d:g:datausers:rwx,d:m::rwx,d:o::rx /var/cache/pip
# 替换为目标机器实际可用的 Python 路径。
sudo /opt/miniforge3/bin/python -m pip config --global set global.cache-dir /var/cache/pip
```

`setfacl` 和 `getfacl` 由 ACL 工具包提供。按目标机器的发行版检查并准备这些工具。

### 配置优先级与缓存行为

pip 的命令行参数、环境变量，以及用户或环境级配置可能覆盖系统默认值。实施时检查 `PIP_CACHE_DIR`、`PIP_NO_CACHE_DIR`、`PIP_CONFIG_FILE` 和各层 `pip.conf`，再通过每个账户和实验环境的 `python -m pip cache dir` 核对最终目录。`--no-cache-dir` 会关闭缓存。

pip 使用一个缓存目录，没有 Conda `pkgs_dirs` 那样的目录后备列表。参与共享的账户需要对共享目录有写权限；无法使用共享目录的账户可以明确选择自己的缓存目录。

缓存复用遵循 pip 的版本、平台兼容性和 HTTP 缓存策略。共享缓存可以减少重复下载和构建，但不保证完全离线安装。切换目录不会自动搬迁旧个人缓存；保留旧缓存，按需迁移。

## Agent 在目标机器上的实施顺序

1. 确认实际安装根目录、现有环境、Conda 与 pip 的有效配置、各解释器的 pip 版本、`datausers` 成员及目录权限；识别会被 shell 加载的 Conda 初始化代码。
2. 备份将修改的配置和共享目录权限，保留既有环境、项目文件、个人缓存和软件源设置。
3. 对共享环境和两种缓存目录设置属组、组写权限、SGID 和默认 ACL。
4. 设置 Conda 环境个人优先、缓存共享优先和关闭自动激活 base；安装链接方式使用 Conda 默认行为。Shell 中不再额外执行自动激活命令。
5. 在 `/etc/pip.conf` 合并共享缓存路径，检查用户、环境配置及环境变量的覆盖情况；需要跨用户共享新缓存的解释器应使用兼容的 pip 25.0 或更高版本，必要时仅更新 pip 工具。
6. 检查最终配置，用创建预演验证 Conda 环境位置，用两个普通账户验证 pip 的实际缓存复用和权限继承。

## 验证

初始化 Conda 后检查配置；路径按目标机器替换：

```sh
conda info --base
conda config --show-sources
conda config --show envs_dirs pkgs_dirs auto_activate_base
stat -c '%U:%G %a %n' /opt/miniforge3 /opt/miniforge3/envs /opt/miniforge3/pkgs
getfacl -cp /opt/miniforge3/envs /opt/miniforge3/pkgs
```

预演创建一个唯一名称的空环境，无需下载 Python 或 GPU 依赖：

```sh
conda_policy_check_name="conda-policy-check-$(date +%s)"
conda create -n "$conda_policy_check_name" --dry-run --offline --no-default-packages --json
```

应确认：

- 预演的 `PREFIX` 位于当前用户的 `~/.conda/envs`，没有实际创建该环境。
- 共享缓存排在个人缓存之前，`datausers` 成员对共享缓存及其写入所需的元数据有写权限。
- 另一个普通组成员能够访问和维护按需创建的共享环境。
- 一个新开的 shell 没有自动进入 base，`conda activate` 仍然可用。新版本可能把有效配置键显示为 `auto_activate: false`。

pip 使用当前实验环境的 Python 检查；没有激活环境时，使用已有 Conda 安装中的 Python 完成缓存验证。默认不激活 base 时，裸 `python` 命令可能不存在，或指向系统 Python，因此以下示例先选定实际解释器路径：

```sh
pip_policy_conda_root="$(conda info --base)"
pip_policy_python="${CONDA_PREFIX:-$pip_policy_conda_root}/bin/python"
"$pip_policy_python" -m pip --version
"$pip_policy_python" -m pip cache dir
"$pip_policy_python" -m pip cache info
# debug 可能显示索引或认证配置，输出仅供本机检查，不直接写入共享文档。
"$pip_policy_python" -m pip config debug
stat -c '%U:%G %a %n' /var/cache/pip /etc/pip.conf
getfacl -cp /var/cache/pip
```

应确认不同普通组成员的 `cache dir` 都是 `/var/cache/pip`，新缓存目录和文件继承 `datausers` 属组及组访问权限。

延用上面选定的解释器，使用小型纯 Python wheel 做实际下载验证，例如：

```sh
pip_policy_download_dir="$(mktemp -d -t pip-policy-check.XXXXXXXX)"
"$pip_policy_python" -m pip download --no-deps --only-binary=:all: --disable-pip-version-check --dest "$pip_policy_download_dir" packaging==25.0
```

第一个账户下载完成后，第二个账户使用自己的临时下载目录重复下载相同版本，确认 wheel 下载输出显示 `Using cached`，并比较文件校验和。验证完成后清理各自创建的临时下载目录，不安装测试包。

`pip cache list` 主要列出 wheel 构建缓存，不能用它判断所有 HTTP 下载缓存是否存在。跨账户实际复用和 `pip cache info` 应共同作为验证依据。

## 当前机器记录

2026-10-04 在 `nlp4090-8` 上核对：

- 安装根目录为 `/opt/miniforge3`，根目录 `root:root`、`755`。
- 共享环境和缓存目录为 `root:datausers`、`2775`，已配置 SGID 和默认 ACL。
- 系统默认和 yifan 的个人配置都采用环境个人优先、缓存共享优先。
- 系统默认和 yifan 的个人配置都关闭自动激活 base，安装使用 Conda 默认链接策略。
- 创建预演确认环境路径位于 `/home/yifan/.conda/envs`。
- `/etc/pip.conf` 已设置 `cache-dir = /var/cache/pip`；共享目录顶层为 `root:datausers`、`2775`，已配置 SGID 和默认 ACL。
- yifan 和 qipeng 的 pip 都识别 `/var/cache/pip`。以 yifan 下载 `packaging==25.0` 后，qipeng 成功复用 HTTP 元数据和 wheel 下载缓存，文件校验和一致。
- pip 新缓存子目录为 `yifan:datausers`、`2775`，新缓存文件为 `yifan:datausers`、`664`。权限检查通过，临时下载目录已清理，没有安装测试包。

该记录用于核对已落地状态；其他机器应按前述原则适配实际路径和账户，不能直接假定状态相同。

## yadm 管理范围

yadm 跟踪本文和 README 中的入口。Conda 安装、实际环境、Conda 包缓存和 pip 缓存不加入 dotfiles 仓库；本机 `~/.condarc`、安装根目录的配置和 `/etc/pip.conf` 需在每台机器按实际情况应用。

跨机器同步的是设计约定，各机器的缓存数据保持本地。当前 `yadm bootstrap` 不安装或迁移 Conda，也不会自动实施本文的 Conda 或 pip 权限与配置约定。在目标机器执行配置任务时，由 agent 按本文检查并落实。

参考：[Conda 官方目录配置说明](https://docs.conda.io/projects/conda/en/stable/user-guide/configuration/custom-env-and-pkg-locations.html)、[pip 缓存说明](https://pip.pypa.io/en/stable/topics/caching/)、[pip 配置说明](https://pip.pypa.io/en/stable/topics/configuration/)。个人环境优先、组成员共同写入两种独立缓存和默认不激活 base 是本仓库采用的具体约定。
