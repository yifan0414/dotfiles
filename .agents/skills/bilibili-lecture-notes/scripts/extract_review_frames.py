#!/usr/bin/env python3
"""Preview semantic frame anchors and promote selected frames into note images."""

from __future__ import annotations

import argparse
import json
import math
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


RUNTIME_ROOT = Path.home() / ".agents" / "envs" / "bilibili-lecture-notes"
MEDIA_IGNORED = {".json", ".srt", ".vtt", ".ass", ".lrc", ".txt", ".part", ".ytdl"}
SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def run(cmd: list[str], *, capture: bool = False) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        cmd,
        check=False,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if result.returncode:
        if capture and result.stdout:
            print(result.stdout)
        if capture and result.stderr:
            print(result.stderr)
        raise subprocess.CalledProcessError(result.returncode, cmd)
    return result


def require_runtime_file(path: Path) -> str:
    if not path.is_file():
        raise SystemExit(f"Skill 固定运行环境不完整，缺少：{path}")
    return str(path)


def find_media(output: Path) -> Path:
    candidates = [
        path
        for path in output.glob("source.*")
        if path.is_file() and path.suffix.lower() not in MEDIA_IGNORED
    ]
    if not candidates:
        raise SystemExit(f"未找到视频：{output}/source.*")
    return max(candidates, key=lambda path: path.stat().st_size)


def media_duration(media: Path, ffprobe: str) -> float:
    result = run(
        [
            ffprobe,
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(media),
        ],
        capture=True,
    )
    return float(result.stdout.strip())


def parse_timestamp(value: str) -> float:
    value = value.strip()
    if re.fullmatch(r"\d+(?:\.\d+)?", value):
        return float(value)
    parts = value.split(":")
    if len(parts) not in {2, 3}:
        raise argparse.ArgumentTypeError(f"无效时间：{value}")
    try:
        numbers = [float(part) for part in parts]
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"无效时间：{value}") from exc
    if len(numbers) == 2:
        minutes, seconds = numbers
        hours = 0.0
    else:
        hours, minutes, seconds = numbers
    if minutes >= 60 or seconds >= 60:
        raise argparse.ArgumentTypeError(f"无效时间：{value}")
    return hours * 3600 + minutes * 60 + seconds


def hms(seconds: float) -> str:
    total = max(0, int(seconds))
    return f"{total // 3600:02d}:{(total % 3600) // 60:02d}:{total % 60:02d}"


def stamp(seconds: float) -> str:
    return hms(seconds).replace(":", "-")


def clamp(seconds: float, duration: float) -> float:
    return min(max(0.0, seconds), max(0.0, duration - 0.1))


def extract_preview_frame(
    media: Path, destination: Path, ffmpeg: str, seconds: float
) -> None:
    run(
        [
            ffmpeg,
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-ss",
            f"{seconds:.3f}",
            "-i",
            str(media),
            "-frames:v",
            "1",
            "-vf",
            (
                "scale=w=640:h=360:force_original_aspect_ratio=decrease,"
                "pad=640:360:(ow-iw)/2:(oh-ih)/2:black"
            ),
            "-q:v",
            "3",
            str(destination),
        ]
    )


def stack_preview(frames: list[Path], destination: Path, ffmpeg: str) -> None:
    if len(frames) == 1:
        shutil.copy2(frames[0], destination)
        return
    command = [ffmpeg, "-hide_banner", "-loglevel", "error", "-y"]
    for frame in frames:
        command.extend(["-i", str(frame)])
    layout = "|".join(f"{index * 640}_0" for index in range(len(frames)))
    command.extend(
        [
            "-filter_complex",
            f"xstack=inputs={len(frames)}:layout={layout}:fill=black",
            "-frames:v",
            "1",
            "-q:v",
            "3",
            str(destination),
        ]
    )
    run(command)


def preview_anchors(
    output: Path,
    media: Path,
    ffmpeg: str,
    duration: float,
    anchors: list[float],
    window: float,
) -> None:
    review_dir = output / "frame-review"
    review_dir.mkdir(exist_ok=True)
    for old in review_dir.glob("anchor-*.jpg"):
        old.unlink()

    records: list[dict[str, object]] = []
    for anchor_index, raw_anchor in enumerate(anchors, start=1):
        anchor = clamp(raw_anchor, duration)
        candidate_times: list[float] = []
        for value in (anchor - window, anchor, anchor + window):
            seconds = round(clamp(value, duration), 3)
            if not candidate_times or not math.isclose(
                seconds, candidate_times[-1], abs_tol=0.05
            ):
                candidate_times.append(seconds)

        name = f"anchor-{anchor_index:03d}-{stamp(anchor)}.jpg"
        destination = review_dir / name
        with tempfile.TemporaryDirectory(prefix=".anchor-", dir=review_dir) as raw_temp:
            temp_dir = Path(raw_temp)
            frames: list[Path] = []
            for cell, seconds in enumerate(candidate_times, start=1):
                frame = temp_dir / f"cell-{cell:02d}.jpg"
                extract_preview_frame(media, frame, ffmpeg, seconds)
                frames.append(frame)
            stack_preview(frames, destination, ffmpeg)

        records.append(
            {
                "anchor_seconds": round(anchor, 3),
                "anchor_timestamp": hms(anchor),
                "preview_path": f"frame-review/{name}",
                "cells": [
                    {
                        "cell": cell,
                        "seconds": seconds,
                        "timestamp": hms(seconds),
                    }
                    for cell, seconds in enumerate(candidate_times, start=1)
                ],
            }
        )

    index = {
        "version": 1,
        "purpose": "字幕语义锚点的低成本三联预览；不要直接用于最终讲义",
        "window_seconds": window,
        "anchors": records,
    }
    (review_dir / "index.json").write_text(
        json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"已生成 {len(records)} 个语义锚点预览：{review_dir}")
    print("先查看三联预览和 index.json；只把选中的准确秒数提升为最终图片。")


def select_frame(
    output: Path,
    media: Path,
    ffmpeg: str,
    duration: float,
    seconds: float,
    name: str,
) -> None:
    seconds = clamp(seconds, duration)
    images = output / "images"
    images.mkdir(exist_ok=True)
    filename = f"{name}-{stamp(seconds)}.jpg"
    destination = images / filename
    run(
        [
            ffmpeg,
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-ss",
            f"{seconds:.3f}",
            "-i",
            str(media),
            "-frames:v",
            "1",
            "-q:v",
            "2",
            str(destination),
        ]
    )

    manifest_path = output / "selected-frames.json"
    existing: dict[str, object] = {"version": 1, "frames": []}
    if manifest_path.is_file():
        loaded = json.loads(manifest_path.read_text(encoding="utf-8"))
        if isinstance(loaded, dict) and isinstance(loaded.get("frames"), list):
            existing = loaded
    frames = [
        item
        for item in existing["frames"]
        if isinstance(item, dict) and item.get("path") != f"images/{filename}"
    ]
    frames.append(
        {
            "path": f"images/{filename}",
            "seconds": round(seconds, 3),
            "timestamp": hms(seconds),
        }
    )
    frames.sort(key=lambda item: float(item["seconds"]))
    existing["frames"] = frames
    manifest_path.write_text(
        json.dumps(existing, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"已选择最终图片：{destination}")


def inspect_frame(
    output: Path,
    media: Path,
    ffmpeg: str,
    duration: float,
    seconds: float,
) -> None:
    seconds = clamp(seconds, duration)
    review_dir = output / "frame-review"
    review_dir.mkdir(exist_ok=True)
    destination = review_dir / f"inspect-{stamp(seconds)}.png"
    run(
        [
            ffmpeg,
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-ss",
            f"{seconds:.3f}",
            "-i",
            str(media),
            "-frames:v",
            "1",
            str(destination),
        ]
    )
    print(f"已生成原分辨率核验帧：{destination}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="按字幕语义锚点生成三联预览，或将选中时间点提升为最终讲义图片。"
    )
    parser.add_argument("output_dir", type=Path, help="prepare_bilibili.py 的输出目录")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--anchor",
        action="append",
        type=parse_timestamp,
        help="生成 t-window、t、t+window 三联预览；可重复传入",
    )
    mode.add_argument("--inspect", type=parse_timestamp, help="提取原分辨率 PNG 供证据核验")
    mode.add_argument("--select", type=parse_timestamp, help="选择一个准确时间点")
    parser.add_argument("--window", type=float, default=2, help="预览前后窗口秒数")
    parser.add_argument("--name", help="--select 模式的 ASCII 小写连字符名称")
    args = parser.parse_args()

    if not 0.25 <= args.window <= 10:
        parser.error("--window 必须在 0.25 到 10 秒之间")
    if args.select is not None:
        if not args.name:
            parser.error("--select 模式必须提供 --name")
        if not SLUG.fullmatch(args.name):
            parser.error("--name 只接受小写字母、数字和单连字符")
    elif args.name:
        parser.error("--name 只用于 --select 模式")

    output = args.output_dir.expanduser().resolve()
    if not output.is_dir():
        parser.error(f"输出目录不存在：{output}")
    media = find_media(output)
    ffmpeg = require_runtime_file(RUNTIME_ROOT / "bin" / "ffmpeg")
    ffprobe = require_runtime_file(RUNTIME_ROOT / "bin" / "ffprobe")
    duration = media_duration(media, ffprobe)

    if args.anchor:
        preview_anchors(output, media, ffmpeg, duration, args.anchor, args.window)
    elif args.inspect is not None:
        inspect_frame(output, media, ffmpeg, duration, args.inspect)
    else:
        select_frame(output, media, ffmpeg, duration, args.select, args.name)


if __name__ == "__main__":
    main()
