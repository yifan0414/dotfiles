#!/usr/bin/env python3
"""Prepare a Bilibili lecture for agent-authored illustrated Markdown notes."""

from __future__ import annotations

import argparse
import json
import math
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlparse


SRT_BLOCK = re.compile(
    r"(?:^|\n)\s*(?:\d+\s*\n)?"
    r"(?P<start>\d{1,2}:\d{2}:\d{2}[,.]\d{3})\s*-->\s*"
    r"(?P<end>\d{1,2}:\d{2}:\d{2}[,.]\d{3})[^\n]*\n"
    r"(?P<text>.*?)(?=\n\s*\n|\Z)",
    re.DOTALL,
)

RUNTIME_ROOT = Path.home() / ".agents" / "envs" / "bilibili-lecture-notes"
MODEL_ROOT = Path.home() / ".agents" / "models" / "faster-whisper"

OVERVIEW_CELL_WIDTH = 640
OVERVIEW_CELL_HEIGHT = 360
OVERVIEW_MAX_COLUMNS = 4


@dataclass
class Cue:
    start: float
    end: float
    text: str


def run(cmd: list[str], *, capture: bool = False) -> subprocess.CompletedProcess[str]:
    shown = " ".join(repr(part) if " " in part else part for part in cmd)
    print(f"+ {shown}", flush=True)
    result = subprocess.run(
        cmd,
        check=False,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if result.returncode:
        if capture:
            if result.stdout:
                print(result.stdout, file=sys.stderr)
            if result.stderr:
                print(result.stderr, file=sys.stderr)
        raise subprocess.CalledProcessError(result.returncode, cmd)
    return result


def require_runtime_file(path: Path) -> str:
    if not path.is_file():
        raise SystemExit(f"Skill 固定运行环境不完整，缺少：{path}")
    return str(path)


def validate_url(raw_url: str) -> None:
    parsed = urlparse(raw_url)
    host = (parsed.hostname or "").lower().rstrip(".")
    allowed = host in {"b23.tv", "bilibili.com"} or host.endswith(".bilibili.com")
    if parsed.scheme not in {"http", "https"} or not allowed:
        raise SystemExit("只接受 bilibili.com 或 b23.tv 的 HTTP(S) 链接。")


def find_media(output: Path) -> Path:
    ignored = {".json", ".srt", ".vtt", ".ass", ".lrc", ".txt", ".part", ".ytdl"}
    candidates = [
        path
        for path in output.glob("source.*")
        if path.is_file() and path.suffix.lower() not in ignored
    ]
    if not candidates:
        raise SystemExit("未找到下载后的视频文件 source.*。")
    return max(candidates, key=lambda path: path.stat().st_size)


def subtitle_rank(path: Path) -> tuple[int, int]:
    name = path.name.lower()
    if any(token in name for token in ("zh-hans", "zh-cn", ".zh.")):
        language_rank = 0
    elif "zh" in name or "ai-zh" in name:
        language_rank = 1
    elif "en" in name:
        language_rank = 2
    else:
        language_rank = 3
    return language_rank, len(name)


def choose_subtitle(output: Path) -> Path | None:
    candidates = sorted(output.glob("source*.srt"), key=subtitle_rank)
    return candidates[0] if candidates else None


def hms(seconds: float) -> str:
    total = max(0, int(seconds))
    return f"{total // 3600:02d}:{(total % 3600) // 60:02d}:{total % 60:02d}"


def parse_time(value: str) -> float:
    hours, minutes, tail = value.replace(",", ".").split(":")
    return int(hours) * 3600 + int(minutes) * 60 + float(tail)


def clean_caption(text: str) -> str:
    text = re.sub(r"<[^>]+>", "", text)
    text = text.replace("&nbsp;", " ").replace("&amp;", "&")
    lines = [re.sub(r"\s+", " ", line).strip() for line in text.splitlines()]
    return " ".join(line for line in lines if line)


def read_cues(path: Path) -> list[Cue]:
    raw = path.read_text(encoding="utf-8-sig", errors="replace").replace("\r\n", "\n")
    cues: list[Cue] = []
    for match in SRT_BLOCK.finditer(raw):
        text = clean_caption(match.group("text"))
        if not text:
            continue
        cue = Cue(parse_time(match.group("start")), parse_time(match.group("end")), text)
        if cues and cues[-1].text == cue.text and cue.start - cues[-1].end < 2:
            cues[-1].end = max(cues[-1].end, cue.end)
        else:
            cues.append(cue)
    if not cues:
        raise SystemExit(f"无法从字幕解析任何文本：{path}")
    return cues


def write_transcript_materials(
    cues: list[Cue], output: Path, chunk_minutes: int, transcript_source: str
) -> None:
    (output / "transcript.txt").write_text(
        "\n".join(f"[{hms(cue.start)}] {cue.text}" for cue in cues) + "\n",
        encoding="utf-8",
    )

    chunks_dir = output / "chunks"
    chunks_dir.mkdir(exist_ok=True)
    for old in chunks_dir.glob("chunk-*.md"):
        old.unlink()

    chunk_seconds = chunk_minutes * 60
    buckets: dict[int, list[Cue]] = {}
    for cue in cues:
        buckets.setdefault(int(cue.start // chunk_seconds), []).append(cue)

    index_lines = ["# Transcript chunks", ""]
    for bucket, items in sorted(buckets.items()):
        start = bucket * chunk_seconds
        end = max(item.end for item in items)
        filename = f"chunk-{bucket + 1:03d}.md"
        body = [f"# {hms(start)}–{hms(end)}", ""]
        body.extend(f"[{hms(item.start)}] {item.text}" for item in items)
        (chunks_dir / filename).write_text("\n".join(body) + "\n", encoding="utf-8")
        index_lines.append(f"- [{filename}]({filename}) — {hms(start)}–{hms(end)}")
    (chunks_dir / "index.md").write_text("\n".join(index_lines) + "\n", encoding="utf-8")

    source_manifest = {
        "source": transcript_source,
        "segment_count": len(cues),
        "segments": [
            {
                "index": index,
                "start": round(cue.start, 3),
                "end": round(cue.end, 3),
                "timestamp": hms(cue.start),
                "text": cue.text,
            }
            for index, cue in enumerate(cues, start=1)
        ],
    }
    (output / "transcript.segments.json").write_text(
        json.dumps(source_manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    diagnostic_path = output / "transcript.faster-whisper.json"
    flagged: list[dict[str, object]] = []
    if diagnostic_path.is_file():
        diagnostic = json.loads(diagnostic_path.read_text(encoding="utf-8"))
        diagnostic_segments = diagnostic.get("segments", [])
        if isinstance(diagnostic_segments, list):
            flagged = [item for item in diagnostic_segments if item.get("flagged")]
    queue = [
        "# Automated review signals",
        "",
        "这些信号只用于安排复核优先级；无标记不代表识别正确，全部字幕分块仍须由模型审校。",
        "",
    ]
    if flagged:
        queue.extend(
            [
                "| 时间 | 原始文本 | 信号 |",
                "| --- | --- | --- |",
            ]
        )
        for item in flagged:
            text = str(item.get("text", "")).replace("|", "\\|")
            reasons = ", ".join(str(reason) for reason in item.get("flag_reasons", []))
            queue.append(f"| {hms(float(item['start']))} | {text} | {reasons} |")
    else:
        queue.append("当前没有可用的低置信度自动标记；仍需做完整的语义与画面复核。")
    (output / "review_queue.md").write_text("\n".join(queue) + "\n", encoding="utf-8")


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


def transcribe(
    media: Path,
    transcript: Path,
    runtime_python: str,
    helper: Path,
    model: str,
    batch_size: int,
    cpu_threads: int,
    initial_prompt: str | None,
) -> None:
    command = [
        runtime_python,
        str(helper),
        str(media),
        "--output",
        str(transcript),
        "--model",
        model,
        "--device",
        "cpu",
        "--compute-type",
        "int8",
        "--batch-size",
        str(batch_size),
        "--cpu-threads",
        str(cpu_threads),
        "--language",
        "zh",
        "--download-root",
        str(MODEL_ROOT),
        "--local-files-only",
    ]
    if initial_prompt:
        command.extend(["--initial-prompt", initial_prompt])
    run(command)


def parse_showinfo(stderr: str) -> list[float]:
    return [float(value) for value in re.findall(r"pts_time:([0-9]+(?:\.[0-9]+)?)", stderr)]


def scene_timestamps(media: Path, ffmpeg: str, threshold: float) -> list[float]:
    """Return scene-change timestamps without retaining model-visible images."""
    video_filter = f"select=eq(n\\,0)+gt(scene\\,{threshold}),showinfo"
    result = run(
        [
            ffmpeg,
            "-hide_banner",
            "-loglevel",
            "info",
            "-i",
            str(media),
            "-map",
            "0:v:0",
            "-vf",
            video_filter,
            "-an",
            "-f",
            "null",
            "-",
        ],
        capture=True,
    )
    return parse_showinfo(result.stderr)


def uniform_timestamps(duration: float, count: int) -> list[float]:
    if count <= 1:
        return [0.0]
    end = max(0.0, duration - 0.5)
    return [round(index * end / (count - 1), 3) for index in range(count)]


def evenly_limit_values(items: list[float], maximum: int) -> list[float]:
    if len(items) <= maximum:
        return items
    indices = sorted({round(i * (len(items) - 1) / (maximum - 1)) for i in range(maximum)})
    return [items[index] for index in indices]


def spaced_timestamps(items: list[float], minimum_gap: float) -> list[float]:
    selected: list[float] = []
    for seconds in sorted(items):
        if not selected or seconds - selected[-1] >= minimum_gap:
            selected.append(seconds)
    return selected


def limit_scene_markers(
    items: list[float],
    *,
    chunk_seconds: int,
    maximum_per_chunk: int,
    maximum_total: int,
) -> list[float]:
    buckets: dict[int, list[float]] = {}
    for seconds in items:
        buckets.setdefault(int(seconds // chunk_seconds), []).append(seconds)
    selected: list[float] = []
    for bucket in sorted(buckets):
        selected.extend(evenly_limit_values(buckets[bucket], maximum_per_chunk))
    return evenly_limit_values(sorted(selected), maximum_total)


def extract_thumbnail(media: Path, destination: Path, ffmpeg: str, seconds: float) -> None:
    run(
        [
            ffmpeg,
            "-hide_banner",
            "-loglevel",
            "error",
            "-ss",
            f"{seconds:.3f}",
            "-i",
            str(media),
            "-frames:v",
            "1",
            "-vf",
            (
                f"scale=w={OVERVIEW_CELL_WIDTH}:h={OVERVIEW_CELL_HEIGHT}:"
                "force_original_aspect_ratio=decrease,"
                f"pad={OVERVIEW_CELL_WIDTH}:{OVERVIEW_CELL_HEIGHT}:"
                "(ow-iw)/2:(oh-ih)/2:black"
            ),
            "-q:v",
            "3",
            str(destination),
        ]
    )


def create_contact_sheet(
    thumbnails: list[Path], destination: Path, ffmpeg: str
) -> tuple[int, int]:
    columns = min(
        OVERVIEW_MAX_COLUMNS, max(1, math.ceil(math.sqrt(len(thumbnails))))
    )
    rows = math.ceil(len(thumbnails) / columns)
    command = [ffmpeg, "-hide_banner", "-loglevel", "error"]
    for thumbnail in thumbnails:
        command.extend(["-i", str(thumbnail)])
    layout = "|".join(
        f"{(index % columns) * OVERVIEW_CELL_WIDTH}_"
        f"{(index // columns) * OVERVIEW_CELL_HEIGHT}"
        for index in range(len(thumbnails))
    )
    command.extend(
        [
            "-filter_complex",
            f"xstack=inputs={len(thumbnails)}:layout={layout}:fill=black",
            "-frames:v",
            "1",
            "-q:v",
            "3",
            str(destination),
        ]
    )
    run(command)
    return columns, rows


def build_frame_index(
    media: Path,
    output: Path,
    ffmpeg: str,
    ffprobe: str,
    threshold: float,
    overview_count: int,
    scene_min_gap: float,
    scene_markers_per_chunk: int,
    max_scene_markers: int,
    chunk_minutes: int,
) -> dict[str, object]:
    """Build a cheap visual index; final note images are selected later."""
    (output / "images").mkdir(exist_ok=True)
    index_dir = output / "frame-index"
    index_dir.mkdir(exist_ok=True)
    (index_dir / "overview.jpg").unlink(missing_ok=True)
    for old in index_dir.glob("overview-*.jpg"):
        old.unlink()

    duration = media_duration(media, ffprobe)
    overview_times = uniform_timestamps(duration, overview_count)
    overview_sheets: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix=".frame-work-", dir=output) as raw_temp:
        temp_dir = Path(raw_temp)
        thumbnails: list[Path] = []
        for index, seconds in enumerate(overview_times, start=1):
            thumbnail = temp_dir / f"uniform-{index:03d}.jpg"
            extract_thumbnail(media, thumbnail, ffmpeg, seconds)
            thumbnails.append(thumbnail)
        for sheet_index, start in enumerate(range(0, len(thumbnails), 16), start=1):
            sheet_thumbnails = thumbnails[start : start + 16]
            name = f"overview-{sheet_index:03d}.jpg"
            destination = index_dir / name
            columns, rows = create_contact_sheet(sheet_thumbnails, destination, ffmpeg)
            sheet_times = overview_times[start : start + len(sheet_thumbnails)]
            overview_sheets.append(
                {
                    "sheet": sheet_index,
                    "path": f"frame-index/{name}",
                    "frame_count": len(sheet_times),
                    "columns": columns,
                    "rows": rows,
                    "width": columns * OVERVIEW_CELL_WIDTH,
                    "height": rows * OVERVIEW_CELL_HEIGHT,
                    "cell_width": OVERVIEW_CELL_WIDTH,
                    "cell_height": OVERVIEW_CELL_HEIGHT,
                    "cells": [
                        {
                            "cell": cell,
                            "global_index": start + cell,
                            "row": (cell - 1) // columns + 1,
                            "column": (cell - 1) % columns + 1,
                            "seconds": round(seconds, 3),
                            "timestamp": hms(seconds),
                        }
                        for cell, seconds in enumerate(sheet_times, start=1)
                    ],
                }
            )

    raw_scene_times = scene_timestamps(media, ffmpeg, threshold)
    spaced_scene_times = spaced_timestamps(raw_scene_times, scene_min_gap)
    scene_times = limit_scene_markers(
        spaced_scene_times,
        chunk_seconds=chunk_minutes * 60,
        maximum_per_chunk=scene_markers_per_chunk,
        maximum_total=max_scene_markers,
    )

    markers = [
        {
            "seconds": round(seconds, 3),
            "timestamp": hms(seconds),
        }
        for seconds in scene_times
    ]
    frame_index: dict[str, object] = {
        "version": 2,
        "strategy": "progressive-disclosure",
        "overview": {
            "frame_count": len(overview_times),
            "frames_per_sheet": 16,
            "sheet_count": len(overview_sheets),
            "sheets": overview_sheets,
        },
        "scene_changes": {
            "threshold": threshold,
            "raw_count": len(raw_scene_times),
            "minimum_gap_seconds": scene_min_gap,
            "maximum_per_transcript_chunk": scene_markers_per_chunk,
            "markers": markers,
        },
        "usage": {
            "purpose": "导航与定位，不是最终讲义图片",
            "open_overview_sheets_first": True,
            "do_not_bulk_open_candidates": True,
            "select_final_images_after_transcript_review": True,
        },
    }
    (output / "frames.json").write_text(
        json.dumps(frame_index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return frame_index


def load_metadata(output: Path, raw_url: str, media: Path, duration: float) -> dict[str, object]:
    info_files = sorted(output.glob("source*.info.json"))
    raw: dict[str, object] = {}
    if info_files:
        raw = json.loads(info_files[0].read_text(encoding="utf-8"))
    reported_duration = raw.get("duration") or duration
    return {
        "title": raw.get("title") or media.stem,
        "uploader": raw.get("uploader") or raw.get("channel"),
        "source_url": raw.get("webpage_url") or raw_url,
        "duration_seconds": reported_duration,
        "duration": hms(float(reported_duration)),
        "media_file": media.name,
    }


def download(raw_url: str, output: Path, yt_dlp: str, browser: str | None) -> None:
    command = [
        yt_dlp,
        "--no-playlist",
        "--continue",
        "--no-overwrites",
        "--write-info-json",
        "--write-subs",
        "--write-auto-subs",
        "--sub-langs",
        "zh-Hans,zh-CN,zh.*,ai-zh.*,en.*",
        "--convert-subs",
        "srt",
        "-f",
        "bv*+ba/b",
        "-S",
        "res:1080",
        "--merge-output-format",
        "mp4",
        "-o",
        str(output / "source.%(ext)s"),
    ]
    if browser:
        command.extend(["--cookies-from-browser", browser])
    command.append(raw_url)
    run(command)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="下载 B 站讲座，取得字幕或 faster-whisper 转录并建立渐进视觉索引。"
    )
    parser.add_argument("url", help="bilibili.com 或 b23.tv 视频链接")
    parser.add_argument("--output", required=True, type=Path, help="讲义输出目录")
    cookie_group = parser.add_mutually_exclusive_group()
    cookie_group.add_argument("--browser", default="chrome", help="yt-dlp Cookie 浏览器来源")
    cookie_group.add_argument("--no-cookies", action="store_true", help="不读取浏览器 Cookie")
    parser.add_argument("--chunk-minutes", type=int, default=12, help="字幕分块时长")
    parser.add_argument("--scene-threshold", type=float, default=0.28, help="场景变化阈值")
    parser.add_argument(
        "--overview-frames",
        type=int,
        default=32,
        help="均匀总览帧数；每 16 帧生成一张 4×4 联系表",
    )
    parser.add_argument(
        "--scene-min-gap",
        type=float,
        default=8,
        help="场景变化时间标记的最小间隔秒数",
    )
    parser.add_argument(
        "--scene-markers-per-chunk",
        type=int,
        default=4,
        help="每个字幕分块最多保留的场景变化时间标记",
    )
    parser.add_argument(
        "--max-scene-markers",
        type=int,
        default=48,
        help="frames.json 中最多保留的场景变化时间标记",
    )
    parser.add_argument("--max-frames", type=int, help=argparse.SUPPRESS)
    parser.add_argument("--whisper-model", default="large-v3-turbo")
    parser.add_argument("--whisper-batch-size", type=int, default=4)
    parser.add_argument("--whisper-cpu-threads", type=int, default=0)
    parser.add_argument("--whisper-initial-prompt")
    args = parser.parse_args()

    if not 1 <= args.chunk_minutes <= 60:
        parser.error("--chunk-minutes 必须在 1 到 60 之间")
    if not 0.01 <= args.scene_threshold <= 1:
        parser.error("--scene-threshold 必须在 0.01 到 1 之间")
    if not 16 <= args.overview_frames <= 64 or args.overview_frames % 16:
        parser.error("--overview-frames 必须是 16 到 64 之间的 16 倍数")
    if not 0 <= args.scene_min_gap <= 600:
        parser.error("--scene-min-gap 必须在 0 到 600 之间")
    if not 1 <= args.scene_markers_per_chunk <= 20:
        parser.error("--scene-markers-per-chunk 必须在 1 到 20 之间")
    if args.max_frames is not None:
        args.max_scene_markers = args.max_frames
    if not 4 <= args.max_scene_markers <= 200:
        parser.error("--max-scene-markers 必须在 4 到 200 之间")
    if not 1 <= args.whisper_batch_size <= 64:
        parser.error("--whisper-batch-size 必须在 1 到 64 之间")
    if args.whisper_cpu_threads < 0:
        parser.error("--whisper-cpu-threads 不能小于 0")

    validate_url(args.url)
    ffmpeg = require_runtime_file(RUNTIME_ROOT / "bin" / "ffmpeg")
    ffprobe = require_runtime_file(RUNTIME_ROOT / "bin" / "ffprobe")
    runtime_python = require_runtime_file(RUNTIME_ROOT / "bin" / "python")
    yt_dlp = require_runtime_file(RUNTIME_ROOT / "bin" / "yt-dlp")

    output = args.output.expanduser().resolve()
    output.mkdir(parents=True, exist_ok=True)
    browser = None if args.no_cookies else args.browser
    download(args.url, output, yt_dlp, browser)
    media = find_media(output)

    transcript = output / "transcript.srt"
    subtitle = choose_subtitle(output)
    if subtitle:
        transcript_source = "site-subtitle"
        if subtitle.resolve() != transcript.resolve():
            shutil.copy2(subtitle, transcript)
    elif transcript.exists() and transcript.stat().st_size > 0:
        transcript_source = "existing-transcript"
    else:
        transcript_source = "faster-whisper"
        helper = Path(__file__).with_name("transcribe_faster_whisper.py")
        transcribe(
            media,
            transcript,
            runtime_python,
            helper,
            args.whisper_model,
            args.whisper_batch_size,
            args.whisper_cpu_threads,
            args.whisper_initial_prompt,
        )

    cues = read_cues(transcript)
    write_transcript_materials(cues, output, args.chunk_minutes, transcript_source)
    frame_index = build_frame_index(
        media,
        output,
        ffmpeg,
        ffprobe,
        args.scene_threshold,
        args.overview_frames,
        args.scene_min_gap,
        args.scene_markers_per_chunk,
        args.max_scene_markers,
        args.chunk_minutes,
    )
    duration = media_duration(media, ffprobe)
    metadata = load_metadata(output, args.url, media, duration)
    metadata.update(
        {
            "transcript_source": transcript_source,
            "transcript_cues": len(cues),
            "candidate_frames": (
                int(frame_index["overview"]["frame_count"])
                + len(frame_index["scene_changes"]["markers"])
            ),
            "frame_index": {
                "strategy": frame_index["strategy"],
                "overview_frames": frame_index["overview"]["frame_count"],
                "overview_sheets": [
                    sheet["path"] for sheet in frame_index["overview"]["sheets"]
                ],
                "scene_markers": len(frame_index["scene_changes"]["markers"]),
            },
        }
    )
    (output / "manifest.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"\n素材准备完成：{output}")
    print(f"字幕来源：{transcript_source}")
    print(
        f"字幕片段：{len(cues)}；视觉总览：{frame_index['overview']['sheet_count']} 张联系表 / "
        f"{frame_index['overview']['frame_count']} 格；"
        f"场景时间标记：{len(frame_index['scene_changes']['markers'])}"
    )
    print("自动视觉索引只用于导航；最终图片须在字幕审校后按语义锚点选择。")


if __name__ == "__main__":
    main()
