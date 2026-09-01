#!/usr/bin/env python3
"""Validate the basic integrity of generated illustrated Markdown notes."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


IMAGE_LINK = re.compile(r"!\[[^\]]*\]\((?:<)?([^)>]+)(?:>)?\)")
PLACEHOLDER = re.compile(r"\b(?:TODO|TBD)\b|待填写|在此插入|PLACEHOLDER", re.IGNORECASE)


def main() -> None:
    parser = argparse.ArgumentParser(description="检查图文讲义 Markdown 的基本完整性。")
    parser.add_argument("notes", type=Path, help="notes.md 路径")
    args = parser.parse_args()

    notes = args.notes.expanduser().resolve()
    if not notes.is_file():
        raise SystemExit(f"不存在：{notes}")
    text = notes.read_text(encoding="utf-8")
    failures: list[str] = []

    if len(re.sub(r"\s+", "", text)) < 1000:
        failures.append("正文少于 1000 个非空白字符，可能不是完整讲义")
    if PLACEHOLDER.search(text):
        failures.append("发现未清理的占位符")
    if len(re.findall(r"^##?\s+", text, re.MULTILINE)) < 3:
        failures.append("章节标题少于 3 个")

    image_paths = IMAGE_LINK.findall(text)
    if not image_paths:
        failures.append("没有 Markdown 图片")
    for raw_path in image_paths:
        if re.match(r"^[a-z]+://", raw_path, re.IGNORECASE):
            continue
        path_only = raw_path.split("#", 1)[0].split("?", 1)[0]
        target = (notes.parent / path_only).resolve()
        if not target.is_file():
            failures.append(f"图片不存在：{raw_path}")

    timestamp_links = re.findall(
        r"\[\d{2}:\d{2}:\d{2}\]\(<https?://[^>]+[?&]t=\d+[^>]*>\)", text
    )
    if not timestamp_links:
        failures.append("没有可点击的视频时间戳链接")

    raw_chunks = sorted((notes.parent / "chunks").glob("chunk-*.md"))
    reviewed_chunks = sorted((notes.parent / "reviewed").glob("chunk-*.md"))
    raw_names = [path.name for path in raw_chunks]
    reviewed_names = [path.name for path in reviewed_chunks]
    if not raw_chunks:
        failures.append("没有原始字幕分块 chunks/chunk-*.md")
    elif raw_names != reviewed_names:
        failures.append("原始字幕分块与 reviewed/ 审校分块的编号不一致")
    for path in reviewed_chunks:
        reviewed_chunk_text = path.read_text(encoding="utf-8")
        if not re.search(r"\[\d{2}:\d{2}:\d{2}\]", reviewed_chunk_text):
            failures.append(f"审校分块没有保留时间戳：{path.name}")

    reviewed_transcript = notes.parent / "transcript.reviewed.md"
    if not reviewed_transcript.is_file():
        failures.append("缺少模型审校稿 transcript.reviewed.md")
        reviewed_text = ""
    else:
        reviewed_text = reviewed_transcript.read_text(encoding="utf-8")
        raw_size = sum(
            len(re.sub(r"\s+", "", path.read_text(encoding="utf-8"))) for path in raw_chunks
        )
        minimum_reviewed_size = max(100, int(raw_size * 0.5))
        if len(re.sub(r"\s+", "", reviewed_text)) < minimum_reviewed_size:
            failures.append("transcript.reviewed.md 内容过短，可能没有完成全部分块复核")

    corrections = notes.parent / "corrections.md"
    if not corrections.is_file():
        failures.append("缺少模型复核记录 corrections.md")
    else:
        corrections_text = corrections.read_text(encoding="utf-8")
        for heading in ("## 复核范围", "## 已修正", "## 未决项"):
            if heading not in corrections_text:
                failures.append(f"corrections.md 缺少章节：{heading}")
        scope = re.search(r"已复核分块[：:]\s*(\d+)\s*/\s*(\d+)", corrections_text)
        if not scope:
            failures.append("corrections.md 没有记录“已复核分块：完成数/总数”")
        elif raw_chunks and (int(scope.group(1)), int(scope.group(2))) != (
            len(raw_chunks),
            len(raw_chunks),
        ):
            failures.append("corrections.md 的复核分块数量与实际分块不一致")

    if failures:
        print("验证未通过：")
        for failure in failures:
            print(f"- {failure}")
        raise SystemExit(1)

    print(f"验证通过：{notes}")
    pending = len(re.findall(r"\[转录待核[:：]", reviewed_text))
    print(
        f"图片：{len(image_paths)}；时间戳链接：{len(timestamp_links)}；"
        f"审校分块：{len(reviewed_chunks)}；待核项：{pending}"
    )


if __name__ == "__main__":
    main()
