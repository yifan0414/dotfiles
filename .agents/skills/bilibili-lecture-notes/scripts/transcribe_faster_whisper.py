#!/usr/bin/env python3
"""Transcribe one media file to SRT with faster-whisper.

Run this helper in an environment that provides ``faster-whisper``. The parent
pipeline uses uv so the dependency does not modify the user's global Python.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


def srt_timestamp(seconds: float) -> str:
    milliseconds = max(0, round(seconds * 1000))
    hours, milliseconds = divmod(milliseconds, 3_600_000)
    minutes, milliseconds = divmod(milliseconds, 60_000)
    secs, milliseconds = divmod(milliseconds, 1_000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{milliseconds:03d}"


def main() -> None:
    parser = argparse.ArgumentParser(description="使用 faster-whisper 生成 SRT 字幕。")
    parser.add_argument("media", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--model", default="large-v3-turbo")
    parser.add_argument("--language", default="zh")
    parser.add_argument("--device", choices=("auto", "cpu", "cuda"), default="cpu")
    parser.add_argument("--compute-type", default="int8")
    parser.add_argument("--batch-size", type=int, default=4)
    parser.add_argument("--cpu-threads", type=int, default=0)
    parser.add_argument("--beam-size", type=int, default=5)
    parser.add_argument("--initial-prompt")
    parser.add_argument("--download-root", type=Path)
    parser.add_argument("--local-files-only", action="store_true")
    parser.add_argument("--no-vad", action="store_true", help="禁用静音过滤，主要用于诊断")
    args = parser.parse_args()

    if not args.media.is_file():
        parser.error(f"输入文件不存在：{args.media}")
    if args.batch_size < 1:
        parser.error("--batch-size 必须至少为 1")

    from faster_whisper import BatchedInferencePipeline, WhisperModel

    args.output.parent.mkdir(parents=True, exist_ok=True)
    model = WhisperModel(
        args.model,
        device=args.device,
        compute_type=args.compute_type,
        cpu_threads=args.cpu_threads,
        download_root=str(args.download_root) if args.download_root else None,
        local_files_only=args.local_files_only,
    )

    common = {
        "language": None if args.language == "auto" else args.language,
        "task": "transcribe",
        "beam_size": args.beam_size,
        "vad_filter": not args.no_vad,
        "word_timestamps": False,
        "initial_prompt": args.initial_prompt,
        "log_progress": True,
    }
    if args.batch_size > 1:
        transcriber = BatchedInferencePipeline(model=model)
        segments, info = transcriber.transcribe(
            str(args.media), batch_size=args.batch_size, **common
        )
    else:
        segments, info = model.transcribe(str(args.media), **common)

    temporary = args.output.with_name(args.output.name + ".tmp")
    segment_count = 0
    diagnostics: list[dict[str, object]] = []
    with temporary.open("w", encoding="utf-8") as handle:
        for segment in segments:
            text = " ".join(segment.text.strip().split())
            if not text:
                continue
            segment_count += 1
            avg_logprob = getattr(segment, "avg_logprob", None)
            no_speech_prob = getattr(segment, "no_speech_prob", None)
            compression_ratio = getattr(segment, "compression_ratio", None)
            reasons = []
            if avg_logprob is not None and avg_logprob < -0.7:
                reasons.append("low_avg_logprob")
            if no_speech_prob is not None and no_speech_prob > 0.4:
                reasons.append("high_no_speech_prob")
            if compression_ratio is not None and compression_ratio > 2.2:
                reasons.append("high_compression_ratio")
            if segment.end - segment.start > 8 and len(text) <= 3:
                reasons.append("very_short_text_for_duration")
            diagnostics.append(
                {
                    "index": segment_count,
                    "start": round(float(segment.start), 3),
                    "end": round(float(segment.end), 3),
                    "text": text,
                    "avg_logprob": avg_logprob,
                    "no_speech_prob": no_speech_prob,
                    "compression_ratio": compression_ratio,
                    "flagged": bool(reasons),
                    "flag_reasons": reasons,
                }
            )
            handle.write(f"{segment_count}\n")
            handle.write(f"{srt_timestamp(segment.start)} --> {srt_timestamp(segment.end)}\n")
            handle.write(text + "\n\n")
            handle.flush()

    if segment_count == 0:
        temporary.unlink(missing_ok=True)
        raise SystemExit("faster-whisper 没有生成任何有效字幕片段。")
    os.replace(temporary, args.output)

    metadata = {
        "engine": "faster-whisper",
        "model": args.model,
        "device": args.device,
        "compute_type": args.compute_type,
        "batch_size": args.batch_size,
        "language": info.language,
        "language_probability": info.language_probability,
        "duration_seconds": info.duration,
        "duration_after_vad_seconds": getattr(info, "duration_after_vad", None),
        "segment_count": segment_count,
        "flagged_segment_count": sum(1 for item in diagnostics if item["flagged"]),
        "segments": diagnostics,
    }
    args.output.with_suffix(".faster-whisper.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"已生成 {args.output}（{segment_count} 个片段）")


if __name__ == "__main__":
    main()
