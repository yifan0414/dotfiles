# Hugging Face 多用户管理

由 agent 根据目标机器的实际情况配置，并按本文验收。机器记录位于 `~/.config/yadm/machines/<hostname>.json`；日常运行工具的源码位于 `~/.config/huggingface/`。

## 盘点

读取本机记录，核对共享根目录、共享组及成员、各用户 shell、已有 HF 环境变量和 CLI 安装。记录不存在时先调查实际状态再填写；已有记录与现场不符时先确认归属。`shared_root`、`shared_group`、`dotfiles_user` 分别记录共享根目录、共享组和使用 yadm 的用户；`huggingface` 中记录 `prefix`、`tools_root`、`python`、`endpoint`，用于定位命令安装、独立 CLI 环境、创建该环境的解释器和公共端点。

可参考 [nlp4090-8.json](../machines/nlp4090-8.json) 的字段，具体路径按本机填写。使用已有 Python 和工具环境；缺少独立 CLI 环境时，按 Conda/pip 管理约定准备解释器，在 `tools_root` 创建 venv 并安装组件的 `requirements.txt`。

## 配置目标

yifan 的 HF 环境变量直接合并到 `.zshrc.local##hostname.<主机名>`，由 `~/.zshrc.local` 加载；其他共享组用户沿用当前 Shell：Zsh 合并到各自的 `~/.zshrc`，Fish 使用个人 `~/.config/fish/conf.d/huggingface.fish`。修改前备份，保留原有内容和项目显式覆盖。

Shell 只显式设置个人根目录、共享缓存路径、镜像端点和访问策略，保留项目已有覆盖：

| 变量 | 默认值 |
|---|---|
| `HF_HOME` | `$HOME/.cache/huggingface` |
| `HF_HUB_CACHE` | `<本机 shared_root>/huggingface/hub`；已有旧名称 `HUGGINGFACE_HUB_CACHE` 可作回退 |
| `HF_ENDPOINT` | 本机约定的公共端点 |
| `HF_HUB_DISABLE_IMPLICIT_TOKEN` | `1` |

处理缓存、Xet 缓存、辅助缓存和令牌路径沿用 HF 基于 `HF_HOME` 的默认值，不重复导出；无需指定 Xet 日志路径。公共任务入口从下面的 `site.json` 取得公共缓存和端点，不在 shell 中重复定义 `HF_PUBLIC_*`。旧工具确需兼容变量时按实际依赖补充。

公共缓存使用 `root:<shared_group>`、`2775`、SGID 和默认 ACL，让子目录及下载锁继承组内读写权限。每人的 `HF_HOME`、处理缓存和 `$HF_HOME/private-hub` 使用本人所有、`700`；令牌文件使用 `600`。使用 `stat` / `getfacl` 核对模式、所有者和 ACL，沿用已有内容，仅调整必要的权限。

`datasets/`、`models/` 保存整理后的资源，Hub 缓存独立存放。既有个人缓存迁入公共目录前先确认内容可以共享。路径变化时由 agent 同步更新本机记录、个人 shell 设置和下面的运行工具参数。

## 日常运行工具

`hf_runtime.py` 仅负责运行命令。三个入口 `hf`、`hf-public`、`hf-private` 链接到同一运行文件，由入口名选择模式。

agent 在确认的 `prefix` 下维护以下文件；变更前备份，更新后比较源码和安装副本：

- `lib/huggingface/hf_runtime.py`：从组件源码复制，所有者 root、权限 `755`。
- `lib/huggingface/site.json`：root 所有、`644`，三个字段为 `public_cache`（公共 Hub 缓存绝对路径）、`endpoint`（公共端点）、`tools_root`（独立 CLI 环境绝对路径）。
- `bin/hf`、`bin/hf-public`、`bin/hf-private`：指向 `../lib/huggingface/hf_runtime.py` 的链接。安装前确认入口位置与独立 CLI 环境不同。

```sh
hf-public hf download Qwen/Qwen3.5-4B
hf-public python evaluate.py
hf-private hf auth login
hf-private python private_inference.py
```

`hf-public` 使用公共缓存及本机公共端点，在子进程中移除个人令牌环境变量并禁用令牌文件。`hf-private` 使用官方端点和个人缓存，为该任务设置 `umask 077`；可用 `HF_PRIVATE_HUB_CACHE` 指定个人 SSD 目录。受限资源使用个人任务入口。

全局 `hf` 使用独立 CLI 环境，认证子命令自动采用个人配置。两个任务入口也可以包装项目环境里的 `hf` 或 Python。独立后台任务直接调用入口，从 `site.json` 取得本机默认值。

## 验收

1. 运行只读盘点 `python3 ~/.config/yadm/scripts/machine-status.py --profile auto`，检查 `huggingface_paths` 的路径和权限。该工具只报告元数据，`--strict` 仍只检查基础 CLI；配置内容与默认 ACL 由 agent 核对。
2. 核对运行文件与源码一致、命令链接正确，`site.json` 与本机记录和 shell 默认值一致；确认独立 CLI 可用、依赖满足 `requirements.txt`。
3. 新开各用户当前使用的 Shell，验证共享缓存和个人缓存路径；分别验证公共、私有任务入口，确认项目覆盖有效。当前终端中 yifan 执行 `source ~/.zshrc.local`，其他 Zsh 用户执行 `source ~/.zshrc`，Fish 用户执行 `source ~/.config/fish/conf.d/huggingface.fish`。
4. 以两个普通组成员验证小型公共文件首次下载、本地缓存复用和 SDK 下载锁竞争；使用无敏感内容的临时文件验证个人目录隔离并清理。
5. 记录已验证结果和剩余问题到 `~/.config/yadm/local/`。运行工具的离线回归测试包含在仓库测试集中。
