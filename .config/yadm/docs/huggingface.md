# Hugging Face 多用户管理

本组件管理公共 Hub 缓存、个人环境变量和 HF 命令入口。机器参数、生成配置和安装副本的关系为：

```text
machines/<hostname>.json
    └── huggingface/deploy.py
         ├── yifan 的 .zshrc.local hostname 候选中的 HF 标记块
         ├── 其他共享组用户 .zshrc 中的 HF 标记块
         └── <prefix>/lib/huggingface/{hf_runtime.py,site.json}
                    ↑ <prefix>/bin/hf、hf-public、hf-private
```

## 机器参数

在目标机器核对共享根目录、账户、组和已有 Python/工具安装后，填写 `~/.config/yadm/machines/<hostname>.json`。顶层字段由机器盘点和部署共用：

| 字段 | 用途 |
|---|---|
| `hostname` | 目标机器名称；部署时核对当前主机 |
| `shared_root` | 本机已经挂载的共享资源根目录 |
| `shared_group` | 参与共享的本机用户组 |
| `dotfiles_user` | 使用 yadm hostname alternate 的用户 |
| `huggingface.prefix` | HF 入口与运行模块的安装前缀 |
| `huggingface.tools_root` | 独立 HF CLI Python 环境 |
| `huggingface.python` | 创建上述工具环境时使用的已有解释器 |
| `huggingface.endpoint` | 公共下载端点 |

可参考已核对的 [nlp4090-8.json](../machines/nlp4090-8.json)，按目标机器填写路径。例如共享根为 `/ssd_2t/shared`，公共缓存就派生为 `/ssd_2t/shared/huggingface/hub`。脚本使用参数生成个人配置和安装副本，修改共享路径只修改机器参数文件。

## 配置与权限

`dotfiles_user`（当前为 yifan）的环境变量直接写入 `.zshrc.local##hostname.<主机名>`，由 `~/.zshrc.local` 加载；其他共享组用户直接写入各自的 `~/.zshrc`。部署只替换 HF 标记块，保留其余内容。生成块随仓库跟踪，用于普通 shell 启动；参数变化后由部署命令重新生成。

| 用途 | 默认路径与权限 |
|---|---|
| 公共原始下载 | `<shared_root>/huggingface/hub`，`root:<shared_group>`、`2775`、SGID 与默认 ACL |
| 个人凭据与配置 | `$HOME/.cache/huggingface`，`700`；令牌文件 `600` |
| 个人处理缓存 | `$HF_HOME/datasets`、`$HF_HOME/xet`、`$HF_HOME/assets` |
| 私有和受限资源 | `$HF_HOME/private-hub`，`700` |

`HF_PUBLIC_HUB_CACHE` 保存本机公共下载目录，`HF_HUB_CACHE` 默认引用它；项目可以显式覆盖个人缓存和普通 SDK 默认值。`datasets/`、`models/` 保存整理后的资源，Hub 缓存独立存放。既有个人缓存保留原位置；迁移前先确认其内容可以共享。

## 检查与部署

先完成 yadm shell alternate 选择，确保主 `.zshrc` 会加载 `.zshrc.local`。部署入口默认只检查；使用 sudo 是为了读取其他用户的私有目录及配置。

```sh
sudo /usr/bin/python3 ~/.config/huggingface/deploy.py --check
sudo /usr/bin/python3 ~/.config/huggingface/deploy.py --apply
```

首次安装缺少独立 CLI 环境时，使用 `--apply --install-tools`。它通过机器参数中的已有 Python 创建 venv，并安装组件 `requirements.txt`；已存在的环境仅在显式传入该选项时安装依赖。共享缓存权限需要系统提供 `getfacl` 和 `setfacl`。

`--apply` 更新入口、运行模块、个人 HF 配置和权限，变更前备份到 `/var/backups/huggingface-<时间>/`。重复部署无差异时不改文件、不新增备份。`--check` 比较实际文件、链接、权限、ACL 和 CLI 依赖版本：一致返回 0，有差异返回 1，配置或执行错误返回 2。不会读取令牌内容。

修改机器参数或组件源文件后重新执行 `--apply` 和 `--check`。新 Zsh 终端自动加载；当前终端中 yifan 执行 `source ~/.zshrc.local`，其他用户执行 `source ~/.zshrc`。

## 使用

```sh
hf-public hf download Qwen/Qwen3.5-4B
hf-public python evaluate.py
hf-private hf auth login
hf-private python private_inference.py
```

`hf-public` 使用公共缓存及本机公共端点，在子进程中移除个人令牌环境变量并禁用令牌文件。`hf-private` 使用官方端点和个人缓存，为该任务设置 `umask 077`；可用 `HF_PRIVATE_HUB_CACHE` 指定个人 SSD 目录。受限资源使用个人任务入口。

全局 `hf` 使用独立 CLI 环境，认证子命令自动采用个人配置。激活项目环境后可继续用两个任务入口包装项目的 `hf` 或 Python。独立的 cron、systemd 和调度任务直接调用这些入口，它们从部署生成的组件参数取得默认值，无需加载交互式 `.zshrc`。

## 验证

仓库离线测试覆盖不同磁盘路径、配置覆盖、个人凭据隔离、认证路由、重复部署和安装副本差异。部署后执行 `--check`，并以两个普通组成员验证首次下载、本地缓存复用及 SDK 下载锁竞争；新 shell 的环境变量应与任务入口一致。检查报告留在 `~/.config/yadm/local/`。
