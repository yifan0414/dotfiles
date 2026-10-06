# 日常同步与凭据

## 同步 dotfiles

`~/.local/bin/yadm-daily-backup`（shell 别名 `yb`）手动同步当前分支：先拉取、提交已跟踪文件的变化，再同步上游并推送。新文件先显式执行 `yadm add <path>`；可用 `-m '提交说明'` 指定消息。

每台机器配置自己的 Git 作者与远端认证。脚本使用锁避免并发，遇到冲突或未完成的 Git 操作停止；若进程被强制终止留下 `~/.local/state/yadm-daily-backup/lock`，确认无运行实例后清除。当前不安装自动备份调度。

组件安装副本的更新由各组件部署入口完成；Git 同步负责配置源。新机器的初始化步骤统一见 [机器安装流程](machine-setup.md)。

## 私有文件与加密归档

同步的范围由已跟踪文件决定，忽略规则见仓库 `.gitignore`。个人配置、凭据、数据和运行缓存留在本机；需要跨机共享的凭据按 `.config/yadm/encrypt` 清单进入加密归档 `.local/share/yadm/archive`。

备份脚本会提交已存在的加密归档，但不会自动重新加密发生变化的明文。`yadm encrypt` 根据当前机器的清单文件重建归档；更新前确保清单中的所有私有文件都齐全，缺少时先从已有归档执行 `yadm decrypt` 恢复。

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
