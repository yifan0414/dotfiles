---
name: bilibili-lecture-notes
description: 将长篇 B 站讲座或课程视频转换为经过模型逐段复核、带关键截图和可回看时间戳的 Markdown 讲义。适用于用户提供 bilibili.com 或 b23.tv 链接并希望跳过观看、获得完整图文笔记的任务；不用于剪辑视频或搬运受版权保护的内容。
---

# Bilibili Lecture Notes

把讲座整理成可独立阅读的讲义，而不是只生成短摘要。处理期间生成原始字幕、审校稿、修改记录、视觉索引和源视频等中间产物；全部验证完成后清理它们，最终输出目录只保留 `notes.md` 和 `images/`。

## 准备素材

1. 从用户取得 B 站视频链接；若未指定输出目录，先用技能固定运行环境查询标题，再在当前工作目录创建一个以视频主题命名的目录：

   ```bash
   python3 <skill-dir>/scripts/get_bilibili_title.py '<url>' --browser chrome
   ```

   所有 `yt-dlp` 操作只通过随附脚本执行；不要探测、调用或安装 PATH 中的全局命令。
2. 运行随附脚本：

   ```bash
   python3 <skill-dir>/scripts/prepare_bilibili.py '<url>' --output '<output-dir>' --browser chrome
   ```

   此用户已允许在本机处理 B 站视频时通过 `yt-dlp --cookies-from-browser chrome` 使用 Chrome 登录会话。只把浏览器会话用于用户提供的 B 站链接；不得导出 Cookie 文件、打印 Cookie 内容或把登录信息写进产物。若用户明确要求不使用登录会话，传入 `--no-cookies`。

3. 脚本优先采用站内中文字幕；没有可用字幕时使用 `faster-whisper`（`large-v3-turbo`、CPU `int8`、批量转录和 VAD）。不要因转录耗时而跳过。逐字稿按约 12 分钟分块；视觉索引默认包含 32 帧和两张 2560×1440 的 4×4 总览图，仅用于导航。如准备失败，先修复依赖或访问问题，不得凭标题臆造内容。

## 模型监督校正（必做）

在撰写讲义前完整执行 [review protocol](references/review-protocol.md)：保留原始字幕，逐块生成 `reviewed/` 审校稿，并把实质修改与未决项记录到 `corrections.md`。然后运行：

```bash
python3 <skill-dir>/scripts/assemble_reviewed.py '<output-dir>'
```

## 视觉索引与渐进选帧（必做）

1. 准备完成后先读 `frames.json`，只查看 `overview.sheets` 列出的两张全局联系表。每张按从左到右、从上到下对应其 `cells`；它们只用于了解视频的视觉类型和大致分布，小字不得据此定稿。
2. 审校时先从语义确定核验时间点，再用场景变化标记辅助定位；场景切换不等于内容重要。对语义锚点生成 `t-2s / t / t+2s` 三联预览：

   ```bash
   python3 <skill-dir>/scripts/extract_review_frames.py '<output-dir>' \
     --anchor 00:31:25 --anchor 01:10:31
   ```

   查看 `frame-review/index.json` 与联系图；只有看不清关键文字时才提取原分辨率 PNG：

   ```bash
   python3 <skill-dir>/scripts/extract_review_frames.py '<output-dir>' \
     --inspect 00:31:25
   ```

3. 完成字幕审校和内容大纲后再选最终图片。通常每个主要章节 1–2 张、全篇 8–16 张，不为凑数重复幻灯片；完整查看的全尺寸候选通常不超过最终数量的两倍，关键歧义核验除外。把选定帧提升到 `images/`：

   ```bash
   python3 <skill-dir>/scripts/extract_review_frames.py '<output-dir>' \
     --select 00:31:25 --name intent-spec-impl
   ```

   `images/` 只放最终图片；`notes.md` 不得引用 `frame-index/` 或 `frame-review/`。

## 编写讲义

仅以 `transcript.reviewed.md` 和复核过的画面为依据。逐块提取主题、关键概念、论证、例子、数字/公式、结论和未决转录，合并内容大纲后再生成最终图片。

把分块笔记二次整合到 `notes.md`：

- 开头写视频标题、讲者/来源（仅在元数据或讲座中明确出现时）、原链接、时长和一段讲座概览。
- 按内容逻辑组织章节，解释论证链并保留有价值的案例与结论，不机械按字幕分块写作，也不保留口头重复和寒暄。
- 关键陈述附可点击的 B 站时间链接，例如 `[00:18:35](<https://www.bilibili.com/video/BV...?t=1115>)`；若原链接已有查询参数，使用 `&t=`。图片下方写对应时间点。
- 使用相对图片路径，例如 `![讲者展示的系统架构](images/slide-014-00-42-10.jpg)`，并为图片写有意义的替代文本。
- 明确区分讲者观点、引用观点与讲义整理者的归纳。
- 结尾提供“核心结论”和“延伸问题”；除非用户要求，不添加讲座没有支持的外部事实。

推荐的正文密度是每小时视频约 2,000–4,000 个中文字，并通常保留 8–16 张真正有用的截图；根据内容密度调整，不为凑数填充。

## 验证

确认正文可脱离视频阅读、时间戳与语义相符且没有把识别错误当作事实，然后运行验证与最终整理：

```bash
python3 <skill-dir>/scripts/validate_notes.py '<output-dir>/notes.md' --finalize
```

命令仅在完整验证通过后删除中间产物，并输出字幕来源、修正数和未决项数。成功后目录只保留 `notes.md` 和 `images/`；此时才交付 `notes.md` 的绝对路径并报告统计。
