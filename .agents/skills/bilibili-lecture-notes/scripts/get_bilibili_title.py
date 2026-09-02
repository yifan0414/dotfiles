#!/usr/bin/env python3
"""Read one Bilibili video title with the skill's pinned yt-dlp runtime."""

from __future__ import annotations

import argparse

from prepare_bilibili import RUNTIME_ROOT, require_runtime_file, run, validate_url


def main() -> None:
    parser = argparse.ArgumentParser(
        description="使用技能固定环境中的 yt-dlp 查询单个 B 站视频标题。"
    )
    parser.add_argument("url", help="bilibili.com 或 b23.tv 视频链接")
    cookie_group = parser.add_mutually_exclusive_group()
    cookie_group.add_argument("--browser", default="chrome", help="Cookie 浏览器来源")
    cookie_group.add_argument("--no-cookies", action="store_true", help="不读取浏览器 Cookie")
    args = parser.parse_args()

    validate_url(args.url)
    yt_dlp = require_runtime_file(RUNTIME_ROOT / "bin" / "yt-dlp")
    command = [
        yt_dlp,
        "--no-playlist",
        "--skip-download",
        "--print",
        "%(title)s",
    ]
    if not args.no_cookies:
        command.extend(["--cookies-from-browser", args.browser])
    command.append(args.url)
    result = run(command, capture=True)
    title = result.stdout.strip()
    if not title:
        raise SystemExit("yt-dlp 未返回视频标题。")
    print(title)


if __name__ == "__main__":
    main()
