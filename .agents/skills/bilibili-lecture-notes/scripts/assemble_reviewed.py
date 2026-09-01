#!/usr/bin/env python3
"""Verify and combine all model-reviewed transcript chunks."""

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="校验并合并模型审校后的字幕分块。")
    parser.add_argument("output_dir", type=Path, help="讲义输出目录")
    args = parser.parse_args()

    output = args.output_dir.expanduser().resolve()
    raw_dir = output / "chunks"
    reviewed_dir = output / "reviewed"
    raw = sorted(raw_dir.glob("chunk-*.md"))
    reviewed = sorted(reviewed_dir.glob("chunk-*.md"))
    raw_names = [path.name for path in raw]
    reviewed_names = [path.name for path in reviewed]

    if not raw:
        raise SystemExit(f"没有原始字幕分块：{raw_dir}/chunk-*.md")
    if raw_names != reviewed_names:
        missing = sorted(set(raw_names) - set(reviewed_names))
        extra = sorted(set(reviewed_names) - set(raw_names))
        messages = ["审校分块与原始分块不一致。"]
        if missing:
            messages.append("缺少：" + ", ".join(missing))
        if extra:
            messages.append("多出：" + ", ".join(extra))
        raise SystemExit("\n".join(messages))

    parts = ["# 模型审校逐字稿", ""]
    for path in reviewed:
        text = path.read_text(encoding="utf-8").strip()
        if not text:
            raise SystemExit(f"审校分块为空：{path}")
        parts.extend([text, ""])

    destination = output / "transcript.reviewed.md"
    destination.write_text("\n".join(parts).rstrip() + "\n", encoding="utf-8")
    print(f"已合并 {len(reviewed)} 个审校分块：{destination}")


if __name__ == "__main__":
    main()
