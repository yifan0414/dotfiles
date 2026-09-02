#!/usr/bin/env python3
"""Render one PDF page or pixel crop to a lossless PNG with Poppler."""

from __future__ import annotations

import argparse
import os
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise RuntimeError("pdftoppm 未生成有效 PNG。")
    return struct.unpack(">II", header[16:24])


def main() -> None:
    parser = argparse.ArgumentParser(
        description="把 PDF 的一个页面或像素区域渲染为无损 PNG。"
    )
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--page", required=True, type=int, help="从 1 开始的 PDF 页码")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--dpi", type=int, default=350)
    parser.add_argument(
        "--bbox",
        type=int,
        nargs=4,
        metavar=("X", "Y", "WIDTH", "HEIGHT"),
        help="在指定 DPI 渲染坐标中的像素裁剪框；省略则渲染整页供定位",
    )
    parser.add_argument("--min-width", type=int, default=0)
    args = parser.parse_args()

    pdf = args.pdf.expanduser().resolve()
    output = args.output.expanduser().resolve()
    if not pdf.is_file():
        raise SystemExit(f"PDF 不存在：{pdf}")
    if args.page < 1:
        parser.error("--page 必须大于等于 1")
    if not 72 <= args.dpi <= 1200:
        parser.error("--dpi 必须在 72–1200 之间")
    if output.suffix.lower() != ".png":
        parser.error("--output 必须以 .png 结尾")
    if args.bbox and (
        args.bbox[0] < 0
        or args.bbox[1] < 0
        or args.bbox[2] <= 0
        or args.bbox[3] <= 0
    ):
        parser.error("--bbox 需要非负 X/Y 和正 WIDTH/HEIGHT")

    pdftoppm = shutil.which("pdftoppm")
    if not pdftoppm:
        raise SystemExit("缺少 pdftoppm；请安装 Poppler 后再裁剪 PDF。")
    output.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="read-paper-crop-") as raw:
        prefix = Path(raw) / "render"
        command = [
            pdftoppm,
            "-f",
            str(args.page),
            "-l",
            str(args.page),
            "-singlefile",
            "-png",
            "-r",
            str(args.dpi),
        ]
        if args.bbox:
            x, y, width, height = args.bbox
            command.extend(
                ["-x", str(x), "-y", str(y), "-W", str(width), "-H", str(height)]
            )
        command.extend([str(pdf), str(prefix)])
        subprocess.run(command, check=True)
        rendered = prefix.with_suffix(".png")
        width, height = png_dimensions(rendered)
        temporary = output.with_name(output.name + ".part")
        temporary.unlink(missing_ok=True)
        shutil.copy2(rendered, temporary)
        os.replace(temporary, output)

    print(f"已导出：{output} ({width}×{height}, {args.dpi} DPI)")
    if args.min_width and width < args.min_width:
        raise SystemExit(
            f"导出成功但宽度 {width}px 低于要求 {args.min_width}px；请调整裁剪框或 DPI。"
        )


if __name__ == "__main__":
    main()
