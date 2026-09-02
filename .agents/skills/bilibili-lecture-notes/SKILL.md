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

   标题查询和素材准备一律使用技能固定环境中的 `yt-dlp`。不要运行 PATH 中的裸 `yt-dlp`，不要先用 `command -v yt-dlp` 探测，也不要因为系统没有全局命令而安装或补依赖；随附脚本会直接检查并调用 `~/.agents/envs/bilibili-lecture-notes/bin/yt-dlp`。
2. 运行随附脚本：

   ```bash
   python3 <skill-dir>/scripts/prepare_bilibili.py '<url>' --output '<output-dir>' --browser chrome
   ```

   此用户已允许在本机处理 B 站视频时通过 `yt-dlp --cookies-from-browser chrome` 使用 Chrome 登录会话。只把浏览器会话用于用户提供的 B 站链接；不得导出 Cookie 文件、打印 Cookie 内容或把登录信息写进产物。若用户明确要求不使用登录会话，传入 `--no-cookies`。

3. 脚本优先采用站内中文字幕；没有可用字幕时运行 `faster-whisper`，默认使用 `large-v3-turbo`、CPU `int8`、批量转录和 VAD。不要仅因为转录耗时较长就跳过。
4. 脚本将逐字稿按约 12 分钟拆入 `chunks/`。视觉部分只建立渐进披露索引：默认均匀采样 32 帧并生成 `frame-index/overview-001.jpg`、`overview-002.jpg` 两张 2560×1440 的 4×4 全局联系表（每格 640×360）；`frames.json` 记录每格时间、联系表尺寸与经过限流的场景变化时间。它们用于导航，不是最终讲义图片。如脚本失败，先根据终端错误修复依赖或访问问题，再继续写作；不要凭视频标题臆造内容。

## 模型监督校正（必做）

在撰写讲义前，完整执行 [review protocol](references/review-protocol.md)。保留原始字幕不动，逐个审校 `chunks/chunk-*.md`，将审校分块写入 `reviewed/`；所有实质修改同步记录到 `corrections.md`。完成所有分块后运行以下命令，它会拒绝合并缺失或多出的分块：

```bash
python3 <skill-dir>/scripts/assemble_reviewed.py '<output-dir>'
```

模型必须交叉使用相邻语境、讲座结构、`transcript.faster-whisper.json` 中的 ASR 诊断信号，以及对应时间附近的原始画面。对于幻灯片文字，直接查看图片；即使另行运行 OCR，也只能把 OCR 当候选文本，不能把它当验证依据。专有名词、数字、否定词、公式和结论发生冲突时优先复核。

只有在证据足以排除原文时才改写。上下文只能支持“可能如此”时不得静默纠正，应在审校稿中标为 `[转录待核：原文]`，并在 `corrections.md` 的“未决项”记录时间戳和原因。禁止为了让语句通顺而补造讲者没有表达的事实。

## 视觉索引与渐进选帧（必做）

候选帧保存在磁盘不会占用模型上下文，实际打开图片才会。不要逐张打开自动候选，也不要在字幕尚未审校时把自动帧直接当作最终插图。

1. 准备完成后先读 `frames.json`，只查看 `overview.sheets` 列出的两张全局联系表。每张按从左到右、从上到下对应其 `cells`；它们只用于了解视频的视觉类型和大致分布，小字不得据此定稿。
2. 审校字幕时先从语义确定需要画面核验的时间点，再把附近的场景变化标记当作定位辅助。场景切换可能只是加载页或窗口切换，不代表内容重要。
3. 对语义锚点生成 `t-2s / t / t+2s` 三联预览，而不是打开一批全尺寸帧：

   ```bash
   python3 <skill-dir>/scripts/extract_review_frames.py '<output-dir>' \
     --anchor 00:31:25 --anchor 01:10:31
   ```

   查看 `frame-review/index.json` 与对应联系图。若幻灯片文字仍不足以核验，才提取单张原分辨率 PNG：

   ```bash
   python3 <skill-dir>/scripts/extract_review_frames.py '<output-dir>' \
     --inspect 00:31:25
   ```

4. 完成全部分块审校并合并内容大纲后，再决定最终图片。通常每个主要内容章节保留 1–2 张、全篇 8–16 张；没有信息量的章节可以不配图，不为凑数增加图片。完整查看的全尺寸候选通常不要超过最终目标的约两倍；专名、公式或数字核验需要更多证据时例外。
5. 把选定的准确时间点提升到 `images/`，并使用能说明内容的名称：

   ```bash
   python3 <skill-dir>/scripts/extract_review_frames.py '<output-dir>' \
     --select 00:31:25 --name intent-spec-impl
   ```

   脚本同步维护 `selected-frames.json`。`images/` 留给最终讲义图片；`frame-index/` 和 `frame-review/` 不应直接写入 `notes.md`。

## 编写讲义

仅以 `transcript.reviewed.md` 和复核过的画面作为讲义内容依据。逐一处理审校分块，为每个分块记录：主题、关键概念、论证过程、例子、数字/公式、结论和仍不确定的转录。先合并内容大纲，再用 `frames.json` 定位各章节的语义锚点并按渐进选帧流程生成最终图片。不要把相邻的重复幻灯片都放入讲义。

把分块笔记二次整合到 `notes.md`：

- 开头写视频标题、讲者/来源（仅在元数据或讲座中明确出现时）、原链接、时长和一段讲座概览。
- 按内容逻辑组织章节，不机械地按每 12 分钟分章。
- 解释重要概念和论证链，保留有价值的案例与结论，删除口头重复、寒暄和无信息停顿。
- 关键陈述附可点击的 B 站时间链接，例如 `[00:18:35](<https://www.bilibili.com/video/BV...?t=1115>)`；若原链接已有查询参数，使用 `&t=`。图片下方写对应时间点。
- 使用相对图片路径，例如 `![讲者展示的系统架构](images/slide-014-00-42-10.jpg)`，并为图片写有意义的替代文本。
- 明确区分讲者观点、引用观点与讲义整理者的归纳。专有名词、数字、公式或人名不确定时回查相邻字幕，仍无法确认则标记“转录待核”。
- 结尾提供“核心结论”和“延伸问题”；除非用户要求，不添加讲座没有支持的外部事实。

推荐的正文密度是每小时视频约 2,000–4,000 个中文字，并通常保留 8–16 张真正有用的截图；根据内容密度调整，不为凑数填充。

## 验证

完成后先确认：所有原始分块均有对应审校分块；`corrections.md` 说明复核范围、修改和未决项；正文可脱离视频阅读；所有相对图片链接存在且都指向 `images/`；时间戳落在对应内容附近；没有把识别错误当作事实。

随后运行验证与最终整理：

```bash
python3 <skill-dir>/scripts/validate_notes.py '<output-dir>/notes.md' --finalize
```

`--finalize` 只在完整验证通过后执行，并会核验目标确为 B 站讲义目录且全部本地图片位于 `images/`；随后删除源视频、字幕、审校记录、视觉索引等所有中间产物。整理后再次确认目录根部严格只剩 `notes.md` 和 `images/`。只在这些步骤全部完成后向用户交付 `notes.md` 的绝对路径，并使用整理命令输出的统计报告字幕来源、模型修正数量和未决项数量。
