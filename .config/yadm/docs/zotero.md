# Zotero 安装与科研工作流

用于 macOS 的 AI、多模态论文阅读。软件由 Homebrew 安装；插件通过 Zotero 原生 AddonManager 注册；自定义规则由 Actions & Tags 执行。不复制整份 Profile、prefs.js、数据库或账户凭据。

## Agent 安装流程

1. 按机器安装流程盘点，保留已有文库、账户、数据目录和其他插件。GUI 选择包含 `zotero` 时执行本流程；用户显式跳过 GUI 时，不额外安装。
2. 运行只读检查：

   ```sh
   python3 ~/.config/yadm/scripts/setup-zotero.py --check
   ```

   脚本从当前用户的 `profiles.ini` 定位默认 Profile；有歧义时使用 `--check --profile "/实际/Profile/目录"`。输出不含账号、令牌或其他偏好内容。
3. 准备安装：

   ```sh
   python3 ~/.config/yadm/scripts/setup-zotero.py --prepare
   ```

   缺少 Zotero 时调用现有 Homebrew 安装；已有应用不重装。插件固定版本和 SHA-256 在 `packages/zotero/plugins.json`，下载缓存位于 `~/.cache/yadm/zotero/`。校验失败时停止，不能忽略错误安装，也不自动取 latest。
4. 打开目标 Profile 的 Zotero。首次启动、登录、浏览器 Connector 的安装与授权由用户或 agent 按界面完成。打开“工具 → 开发者 → Run JavaScript”，勾选“作为异步函数执行”，粘贴步骤 3 JSON 输出中的 **activation_code** 并执行。

   这一步不能省略：`--prepare` 只生成本机激活文件，没有注册插件。不要把 XPI 直接复制进 Profile，也不要修改 extensions.json 或关闭插件安全检查。
5. 激活代码再次校验包，通过原生接口安装或启用 arXiv Workflow、Actions & Tags；已安装相同或更新版本则保留，不降级。仅更新三个固定 ID 的自定义动作；禁用插件首次安装附带的两个 `/unread` 示例，保留其他用户动作。当前动作配置会先备份。
6. 重新启动 Zotero。右键主列表表头，开启“会议年份”，隐藏“出版物”；按需要保留独立“年”列。启用后的列宽、位置由本机 Zotero 保存。不要覆盖整份界面配置。
7. 执行验收，不能只根据准备或激活命令成功就宣称完成。

脚本支持当前固定插件组合对应的 Zotero **10**。应用升级到其他大版本时先核对插件兼容范围，再更新清单与验证；不强行安装旧插件。

## 源文件与运行状态

纳入 yadm 的源文件：

| 文件 | 内容 |
|---|---|
| `~/.config/zotero/conference-tags.js` | 跨来源会议年份识别、手动标签优先、彩色 badge |
| `~/.config/zotero/import-arxiv-update.js` | 导入 arXiv 预印本后，合并短时间内的请求并静默查询正式发表信息 |
| `~/.config/zotero/install-conference-tags.js` | 按固定动作 ID 安装规则，可重复执行 |
| `~/.config/zotero/activate-plugins.js` | 原生插件安装与配置激活逻辑 |

安装脚本使用当前用户目录，不写死用户名或 Profile 名。源文件更新后重新执行准备与激活，再重启；Zotero 实际运行的是偏好设置中保存的脚本副本。

生成的激活文件、动作备份和验收回执放在被忽略的 `~/.config/yadm/local/zotero/`；XPI 留在缓存目录。会议自动标签的本机归属缓存不进入版本管理；另一台 Mac 会重新接管由同步带来的、与当前元数据匹配的自动标签。主题标签和人工标签保持原样。

## 工作流与手动覆盖

- arXiv：新导入的预印本约 3 秒后静默调用 Workflow。普通进度不弹窗，模糊匹配需要确认时打开窗口。关闭正式版 PDF 下载，保留原附件。外部服务限流或无发表记录时，可能无法补全；可右键手动“更新 arXiv 文章”查看详情。
- OpenReview、CVF、ECVA、ACL Anthology 和正式论文集：从导入字段及正式链接识别会议和年份。OpenReview 优先明确年份或 ICLR 届次，不将提交日期直接作为会议年份；可靠信息冲突时 badge 留空。可根据确定的正式年份纠正日期，原导入日期保存在 Extra。
- 手动在 Zotero 的“标签”中添加 `ICLR2026 Oral`、`ICLR 2026 Spotlight`、`CVPR2026 Poster` 或 `ICLR2027 UnderReview`。识别仅限预设的 25 个会议；手动指定优先，Oral 等状态不会自动推断。Under Review 为灰色虚线 badge，不改动正式发表日期。
- 同一会议和年份的状态标签优先于普通标签。两个不同的手动会议年份，或 Oral 与 Spotlight 等互斥状态同时存在时留空，先保留正确的标签。删除手动覆盖后恢复元数据识别。
- 元数据识别排除 Workshop、Findings、Demo 等条目，避免继承主会 badge。手动覆盖由用户确认，不自动删改人工标签。

## 验收

```sh
python3 ~/.config/yadm/scripts/setup-zotero.py --check --strict
```

检查应用大版本、插件启用状态和已保存的动作是否与源文件一致；该检查不证明远程查询成功或界面已正确渲染。还需实际确认：

1. 插件管理器中两插件启用；重复激活不重复增加自定义动作，其他动作保留。
2. 主列表显示会议 badge；给已确认的论文手动添加 Oral 标签能更新显示，删除后恢复自动识别。
3. 用一篇授权测试的 arXiv 论文验证导入后自动更新、静默运行和 badge。无公开发表信息、限流或模糊匹配分别报告，不能把它们当成安装失败或伪造成功。
4. 重启后规则和显示继续生效；测试条目与临时动作清理到可恢复状态。

安装流程不调整数据库同步方式，不触碰用户选择的 iCloud 数据目录。新 Mac 的数据目录、账户和附件同步按用户选择分别确认；本流程只部署软件与规则，不将运行中的数据库纳入 yadm。
