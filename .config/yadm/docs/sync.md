# 日常同步与凭据

## 同步 dotfiles

`~/.local/bin/yadm-daily-backup`（shell 别名 `yb`）手动同步当前分支：先拉取、提交已跟踪文件的变化，再同步上游并推送。新文件先显式执行 `yadm add <path>`；可用 `-m '提交说明'` 指定消息。

每台机器配置自己的 Git 作者与远端认证。脚本使用锁避免并发，遇到冲突或未完成的 Git 操作停止；若进程被强制终止留下 `~/.local/state/yadm-daily-backup/lock`，确认无运行实例后清除。当前不安装自动备份调度。

在每台机器显式配置作者（使用自己的姓名和邮箱）：

```sh
yadm gitconfig user.name 'Your Name'
yadm gitconfig user.email 'you@example.com'
```

bootstrap 会报告是否已配置，不推断或覆盖作者身份。GitHub 认证由 `gh auth setup-git` 配置，不在共享的 yadm 配置中指定明文 `store` 助手。

`yb` 在拉取前后检查暂存区和已跟踪文件的本地变化；`yadm commit` 通过 `hooks/pre_commit` 检查实际暂存内容。发现常见 API 令牌、私钥或 JSON 明文认证字段时停止，仅输出文件名和字段类别。环境变量名及 Pi 的 `!命令` 凭据引用允许通过。检查是补充保护，不能保证识别所有格式的秘密；直接运行底层 Git 会绕过 yadm hook。

Git 同步负责配置源；需要更新实际安装副本时，由 agent 按组件文档完成并验证。新机器的初始化步骤统一见 [机器安装流程](machine-setup.md)。

## 私有文件与加密归档

同步的范围由已跟踪文件决定，忽略规则见仓库 `.gitignore`。个人配置、凭据、数据和运行缓存留在本机；需要跨机共享的凭据按 `.config/yadm/encrypt` 清单进入加密归档 `.local/share/yadm/archive`。

备份脚本会提交已存在的加密归档，但不会自动重新加密发生变化的明文。`yadm encrypt` 根据当前机器的清单文件重建归档；更新前确保清单中的所有私有文件都齐全，缺少时先从已有归档执行 `yadm decrypt` 恢复。

本仓库的加密清单使用家目录内的精确文件路径，不使用通配符。`pre_encrypt` 检查私有文件是否齐全且未被 Git 跟踪；成功加密后，`post_encrypt` 将清单、明文和归档的 SHA-256 指纹写入本机 `${XDG_STATE_HOME:-~/.local/state}/yadm-sync/`（文件权限 `600`，不参与同步）。加密期间文件变化则不生成有效回执。成功的 `yadm decrypt` 同样建立本机回执；加密/解密失败不会更新回执。

`yb` 检测到私有文件变化、收到其他机器的归档或缺少回执时会停止，避免推送过期的凭据备份。首次启用此检查需要运行一次 `yadm encrypt` 建立回执；若本机应采用远端归档中的凭据，则先备份自己的认证文件，再执行 `yadm decrypt`。这些操作可能需要归档密码，不会由备份脚本自动执行。

## GitHub 认证

在已登录 GitHub 的机器上导出当前令牌并更新归档：

```sh
~/.local/bin/yadm-gh-export-token
export GPG_TTY="$(tty)"
yadm encrypt
```

使用已有归档密码。当前清单包含 `.pi/agent/auth.json` 与 `.config/gh-token`；明文令牌、`gh/hosts.yml` 由忽略规则排除。

在接收机器上同步后执行 `yadm bootstrap`。它安装必要的 gh/GnuPG，解密归档，经标准输入导入令牌并验证 GitHub 用户 API，随后配置 Git HTTPS 认证。令牌文件权限为 `600`；gh 优先使用系统凭据存储，无桌面 Linux 上可能使用本机 `hosts.yml`。用 `gh auth status --hostname github.com` 验证登录。

私有仓库首次 clone 需要已有认证；归档解密需要交互输入密码或已有 GPG 缓存。认证失败会报告失败，显式 `DOTFILES_SKIP_GH_AUTH=1 yadm bootstrap` 跳过该步骤。轮换令牌时，在源机器重新导出、加密并同步，接收机器重新导入；共享令牌的权限和撤销会影响所有使用它的机器。

bootstrap 和导出工具处理共享令牌时会忽略调用环境中的 `GH_TOKEN` / `GITHUB_TOKEN`；普通 gh 命令仍遵循其环境变量覆盖行为。
