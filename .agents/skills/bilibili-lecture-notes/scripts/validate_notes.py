#!/usr/bin/env python3
"""Validate the basic integrity of generated illustrated Markdown notes."""

from __future__ import annotations

import argparse
import json
import re
import shutil
from pathlib import Path
from urllib.parse import urlparse


IMAGE_LINK = re.compile(r"!\[[^\]]*\]\((?:<)?([^)>]+)(?:>)?\)")
PLACEHOLDER = re.compile(r"\b(?:TODO|TBD)\b|待填写|在此插入|PLACEHOLDER", re.IGNORECASE)
FINAL_OUTPUT_NAMES = {"images", "notes.md"}


def count_corrections(text: str) -> int:
    match = re.search(r"## 已修正\s*(.*?)(?=\n## |\Z)", text, re.DOTALL)
    if not match:
        return 0
    count = 0
    for line in match.group(1).splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if not cells or cells[0] in {"时间", "---", "无"}:
            continue
        if re.fullmatch(r"-+", cells[0]):
            continue
        count += 1
    return count


def finalize_output(notes: Path, image_paths: list[str]) -> tuple[int, str]:
    output = notes.parent.resolve()
    filesystem_root = Path(output.anchor).resolve()
    if output in {filesystem_root, Path.home().resolve()} or len(output.parts) < 3:
        raise SystemExit(f"拒绝清理过于宽泛的目录：{output}")

    images = output / "images"
    if not images.is_dir() or images.is_symlink():
        raise SystemExit("整理失败：images/ 不存在、不是普通目录或是符号链接")

    manifest = output / "manifest.json"
    if not manifest.is_file() or manifest.is_symlink():
        raise SystemExit("整理失败：缺少普通文件 manifest.json，无法确认讲义输出目录")
    try:
        manifest_data = json.loads(manifest.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"整理失败：manifest.json 不是有效 JSON：{exc}") from exc
    source_url = str(manifest_data.get("source_url", ""))
    host = (urlparse(source_url).hostname or "").lower().rstrip(".")
    if host not in {"b23.tv", "bilibili.com"} and not host.endswith(".bilibili.com"):
        raise SystemExit("整理失败：manifest.json 不能确认这是 B 站讲义输出目录")

    images_root = images.resolve()
    for raw_path in image_paths:
        if re.match(r"^[a-z]+://", raw_path, re.IGNORECASE):
            continue
        path_only = raw_path.split("#", 1)[0].split("?", 1)[0]
        target = (output / path_only).resolve()
        try:
            target.relative_to(images_root)
        except ValueError as exc:
            raise SystemExit(
                f"整理失败：讲义引用的本地图片不在 images/ 中：{raw_path}"
            ) from exc

    removable = [path for path in output.iterdir() if path.name not in FINAL_OUTPUT_NAMES]
    for path in removable:
        if path.is_symlink() or path.is_file():
            path.unlink()
        elif path.is_dir():
            shutil.rmtree(path)
        else:
            path.unlink()
    remaining = {path.name for path in output.iterdir()}
    if remaining != FINAL_OUTPUT_NAMES:
        raise SystemExit(f"整理后目录内容不符合预期：{sorted(remaining)}")
    return len(removable), str(manifest_data.get("transcript_source", "unknown"))


def main() -> None:
    parser = argparse.ArgumentParser(description="检查图文讲义 Markdown 的基本完整性。")
    parser.add_argument("notes", type=Path, help="notes.md 路径")
    parser.add_argument(
        "--finalize",
        action="store_true",
        help="验证通过后清理中间产物，只保留 notes.md 与 images/",
    )
    args = parser.parse_args()

    notes = args.notes.expanduser().resolve()
    if not notes.is_file():
        raise SystemExit(f"不存在：{notes}")
    text = notes.read_text(encoding="utf-8")
    failures: list[str] = []
    warnings: list[str] = []

    if len(re.sub(r"\s+", "", text)) < 1000:
        failures.append("正文少于 1000 个非空白字符，可能不是完整讲义")
    if PLACEHOLDER.search(text):
        failures.append("发现未清理的占位符")
    if len(re.findall(r"^##?\s+", text, re.MULTILINE)) < 3:
        failures.append("章节标题少于 3 个")

    image_paths = IMAGE_LINK.findall(text)
    if not image_paths:
        failures.append("没有 Markdown 图片")
    elif not 8 <= len(image_paths) <= 16:
        warnings.append(f"当前引用 {len(image_paths)} 张图片；通常建议 8–16 张")
    for raw_path in image_paths:
        if re.match(r"^[a-z]+://", raw_path, re.IGNORECASE):
            continue
        path_only = raw_path.split("#", 1)[0].split("?", 1)[0]
        if Path(path_only).parts and Path(path_only).parts[0] in {
            "frame-index",
            "frame-review",
        }:
            failures.append(f"讲义引用了视觉索引或预览图，而非最终图片：{raw_path}")
        target = (notes.parent / path_only).resolve()
        if not target.is_file():
            failures.append(f"图片不存在：{raw_path}")

    timestamp_links = list(
        re.finditer(
            r"\[(?P<hours>\d{2}):(?P<minutes>\d{2}):(?P<seconds>\d{2})\]"
            r"\(<https?://[^>]+[?&]t=(?P<target>\d+)[^>]*>\)",
            text,
        )
    )
    if not timestamp_links:
        failures.append("没有可点击的视频时间戳链接")
    for match in timestamp_links:
        label_seconds = (
            int(match.group("hours")) * 3600
            + int(match.group("minutes")) * 60
            + int(match.group("seconds"))
        )
        target_seconds = int(match.group("target"))
        if label_seconds != target_seconds:
            failures.append(
                "时间标签与链接秒数不一致："
                f"{match.group(0)}（标签={label_seconds}，t={target_seconds}）"
            )

    selected_manifest = notes.parent / "selected-frames.json"
    if selected_manifest.is_file():
        try:
            selected_data = json.loads(selected_manifest.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            failures.append(f"selected-frames.json 不是有效 JSON：{exc}")
        else:
            selected = selected_data.get("frames") if isinstance(selected_data, dict) else None
            if not isinstance(selected, list):
                failures.append("selected-frames.json 缺少 frames 列表")
            else:
                selected_paths = {
                    str(item.get("path"))
                    for item in selected
                    if isinstance(item, dict) and item.get("path")
                }
                for selected_path in selected_paths:
                    if not (notes.parent / selected_path).is_file():
                        failures.append(f"selected-frames.json 中图片不存在：{selected_path}")
                local_note_images = {
                    raw_path.split("#", 1)[0].split("?", 1)[0]
                    for raw_path in image_paths
                    if not re.match(r"^[a-z]+://", raw_path, re.IGNORECASE)
                }
                untracked = sorted(local_note_images - selected_paths)
                if untracked:
                    warnings.append(
                        "以下讲义图片未记录在 selected-frames.json："
                        + ", ".join(untracked)
                    )

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
    corrections_text = ""
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
    for warning in warnings:
        print(f"提示：{warning}")
    pending = len(re.findall(r"\[转录待核[:：]", reviewed_text))
    print(
        f"图片：{len(image_paths)}；时间戳链接：{len(timestamp_links)}；"
        f"审校分块：{len(reviewed_chunks)}；待核项：{pending}"
    )
    correction_total = count_corrections(corrections_text)
    if args.finalize:
        removed_count, transcript_source = finalize_output(notes, image_paths)
        print(
            f"交付统计：字幕来源={transcript_source}；"
            f"模型修正={correction_total}；未决项={pending}"
        )
        print(
            f"整理完成：删除 {removed_count} 个中间项；"
            "最终目录仅保留 notes.md 与 images/"
        )


if __name__ == "__main__":
    main()
