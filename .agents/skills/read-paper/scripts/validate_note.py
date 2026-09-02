#!/usr/bin/env python3
"""Validate a read-paper Obsidian note and its local assets."""

from __future__ import annotations

import argparse
import ast
import json
import re
import struct
from pathlib import Path


GENERATED_START = "<!-- READ_PAPER_GENERATED_START -->"
GENERATED_END = "<!-- READ_PAPER_GENERATED_END -->"
USER_START = "<!-- USER_NOTES_START -->"
USER_END = "<!-- USER_NOTES_END -->"
REQUIRED_FIELDS = {
    "title",
    "authors",
    "conference",
    "year",
    "arxiv_url",
    "pdf_link",
    "cover",
    "updated",
    "tags",
    "status",
    "priority",
    "rating",
    "topics",
    "code",
}
ALLOWED_STATUS = {"unread", "reading", "read", "archived"}
ALLOWED_TOPICS = {
    "LLM",
    "MLLM",
    "Video Understanding",
    "Efficient AI",
    "Generative AI",
    "Representation Learning",
    "Reinforcement Learning",
    "Dataset & Benchmark",
    "Trustworthy AI",
    "AI for Science",
    "Embodied AI",
    "Systems for AI",
}
REQUIRED_HEADINGS = [
    "TL;DR",
    "Key Contributions",
    "Method",
    "Experiments",
    "Limitations & Caveats",
    "Open Questions / Follow-ups",
    "Citation",
]
WIKILINK = re.compile(r"\[\[([^\]|#]+)(?:#[^\]|]+)?(?:\|[^\]]+)?\]\]")
EMBED = re.compile(r"!\[\[([^\]|#]+)(?:#[^\]|]+)?(?:\|[^\]]+)?\]\]")


def unquote(value: str) -> str:
    stripped = value.strip()
    if len(stripped) >= 2 and stripped[0] == stripped[-1] and stripped[0] in {'"', "'"}:
        try:
            parsed = ast.literal_eval(stripped)
            return str(parsed)
        except (ValueError, SyntaxError):
            return stripped[1:-1]
    return stripped


def parse_list(value: str) -> list[object] | None:
    try:
        parsed = ast.literal_eval(value.strip())
    except (ValueError, SyntaxError):
        return None
    return parsed if isinstance(parsed, list) else None


def parse_frontmatter(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        raise ValueError("缺少 YAML frontmatter 起始分隔线")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("缺少 YAML frontmatter 结束分隔线")
    raw = text[4:end]
    fields: dict[str, str] = {}
    for line_number, line in enumerate(raw.splitlines(), start=2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):(?:\s*(.*))?$", line)
        if not match:
            raise ValueError(f"frontmatter 第 {line_number} 行不是受支持的单行字段：{line}")
        key, value = match.group(1), match.group(2) or ""
        if key in fields:
            raise ValueError(f"frontmatter 字段重复：{key}")
        fields[key] = value
    return fields, text[end + 5 :]


def resolve_local(note: Path, raw_path: str) -> Path:
    target = (note.parent / raw_path).resolve()
    try:
        target.relative_to(note.parent.resolve())
    except ValueError as exc:
        raise ValueError(f"资源路径越出论文目录：{raw_path}") from exc
    return target


def wikilink_target(value: str) -> str | None:
    match = WIKILINK.fullmatch(unquote(value))
    return match.group(1) if match else None


def png_dimensions(path: Path) -> tuple[int, int] | None:
    try:
        with path.open("rb") as handle:
            header = handle.read(24)
    except OSError:
        return None
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", header[16:24])


def section(text: str, heading: str) -> str:
    match = re.search(
        rf"^##\s+{re.escape(heading)}\s*$\n(?P<body>.*?)(?=^##\s+|\Z)",
        text,
        re.MULTILINE | re.DOTALL,
    )
    return match.group("body") if match else ""


def validate_markers(body: str, failures: list[str]) -> None:
    for marker in (GENERATED_START, GENERATED_END, USER_START, USER_END):
        if body.count(marker) != 1:
            failures.append(f"受管标记必须恰好出现一次：{marker}")
    if all(marker in body for marker in (GENERATED_START, GENERATED_END)):
        if body.index(GENERATED_START) >= body.index(GENERATED_END):
            failures.append("READ_PAPER_GENERATED 标记顺序错误")
    if all(marker in body for marker in (USER_START, USER_END)):
        if body.index(USER_START) >= body.index(USER_END):
            failures.append("USER_NOTES 标记顺序错误")


def validate_frontmatter(
    fields: dict[str, str], note: Path, failures: list[str], warnings: list[str]
) -> None:
    missing = sorted(REQUIRED_FIELDS - fields.keys())
    if missing:
        failures.append("frontmatter 缺少字段：" + ", ".join(missing))
    if not unquote(fields.get("title", "")):
        failures.append("title 不能为空")

    authors = parse_list(fields.get("authors", ""))
    if not authors or not all(isinstance(item, str) and item.strip() for item in authors):
        failures.append("authors 必须是非空字符串列表")

    year = fields.get("year", "").strip()
    if not re.fullmatch(r"\d{4}", year):
        failures.append("year 必须是四位数字")

    status = unquote(fields.get("status", ""))
    if status not in ALLOWED_STATUS:
        failures.append("status 必须是 unread/reading/read/archived 之一")

    for key in ("priority", "rating"):
        value = unquote(fields.get(key, ""))
        if value and (not value.isdigit() or not 1 <= int(value) <= 5):
            failures.append(f"{key} 必须为空或 1–5 的整数")

    tags = parse_list(fields.get("tags", ""))
    if tags is None or not all(isinstance(item, str) for item in tags):
        failures.append("tags 必须是字符串列表")
    elif "paper/arxiv" not in tags:
        failures.append("tags 必须包含 paper/arxiv")

    topics = parse_list(fields.get("topics", ""))
    if topics is None or len(topics) != 1 or topics[0] not in ALLOWED_TOPICS:
        failures.append("topics 必须恰好包含一个允许的 ML/AI 主主题")

    arxiv_url = unquote(fields.get("arxiv_url", ""))
    if not re.match(r"^https://arxiv\.org/abs/", arxiv_url):
        failures.append("arxiv_url 必须是规范的 arxiv.org/abs URL")

    pdf_target = wikilink_target(fields.get("pdf_link", ""))
    if not pdf_target:
        failures.append("pdf_link 必须是 Obsidian 内部链接")
    else:
        try:
            pdf_path = resolve_local(note, pdf_target)
        except ValueError as exc:
            failures.append(str(exc))
        else:
            if not pdf_path.is_file():
                failures.append(f"本地 PDF 不存在：{pdf_target}")

    cover_value = unquote(fields.get("cover", ""))
    if cover_value:
        cover_target = wikilink_target(fields.get("cover", ""))
        if not cover_target:
            failures.append("cover 必须为空或 Obsidian 内部链接")
        else:
            try:
                cover_path = resolve_local(note, cover_target)
            except ValueError as exc:
                failures.append(str(exc))
            else:
                if not cover_path.is_file():
                    failures.append(f"cover 资源不存在：{cover_target}")

    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", unquote(fields.get("updated", ""))):
        failures.append("updated 必须使用 YYYY-MM-DD")

    if tags and topics and topics[0] in tags:
        warnings.append("主 topic 不应在 tags 中重复")


def validate_body(
    body: str, note: Path, failures: list[str], warnings: list[str]
) -> None:
    validate_markers(body, failures)
    generated = body
    if body.count(GENERATED_START) == 1 and body.count(GENERATED_END) == 1:
        start = body.index(GENERATED_START) + len(GENERATED_START)
        end = body.index(GENERATED_END)
        if start < end:
            generated = body[start:end]
    headings = [
        match.group(1).strip()
        for match in re.finditer(r"^##\s+(.+?)\s*$", generated, re.MULTILINE)
    ]
    last_index = -1
    for required in REQUIRED_HEADINGS:
        if required not in headings:
            failures.append(f"缺少正文节：## {required}")
            continue
        index = headings.index(required)
        if index <= last_index:
            failures.append("正文节顺序不符合规范")
            break
        last_index = index

    experiments = section(generated, "Experiments")
    if re.search(
        r"(?m)^\s*\|.*\|\s*$\n^\s*\|(?:\s*:?-+:?\s*\|)+\s*$", experiments
    ):
        failures.append("Experiments 中出现重建的 Markdown 结果表")

    embedded = EMBED.findall(generated)
    for raw_path in embedded:
        try:
            target = resolve_local(note, raw_path)
        except ValueError as exc:
            failures.append(str(exc))
            continue
        if not target.is_file():
            failures.append(f"嵌入资源不存在：{raw_path}")
            continue
        if target.name.startswith("experiment_table_"):
            dimensions = png_dimensions(target)
            if dimensions is None:
                failures.append(f"实验表格不是有效 PNG：{raw_path}")
            elif dimensions[0] < 1600:
                warnings.append(
                    f"实验表格宽度低于建议的 1600 px：{raw_path} ({dimensions[0]} px)"
                )

    if not any(Path(path).name.startswith("experiment_table_") for path in embedded):
        warnings.append("笔记未嵌入实验表格截图；请确认论文是否确实没有必要表格")

    cjk = len(re.findall(r"[\u3400-\u9fff]", generated))
    if cjk < 100:
        warnings.append("中文正文少于 100 个汉字，可能不是完整中文讲义")

    suspicious_math = re.findall(
        r"`([^`\n]*(?:\\[A-Za-z]+|[_^]\{)[^`\n]*)`", generated
    )
    if suspicious_math:
        warnings.append("发现疑似用反引号包裹的公式，请改用 $...$ 或 $$...$$")


def load_manifest(path: Path) -> dict[str, object]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"无法读取 manifest：{path}: {exc}") from exc
    if not isinstance(raw, dict) or raw.get("version") != 2:
        raise ValueError("manifest 版本无效")
    return raw


def main() -> None:
    parser = argparse.ArgumentParser(description="验证 read-paper 生成的 Obsidian 笔记。")
    parser.add_argument("note", type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()

    note = args.note.expanduser().resolve()
    manifest_path = args.manifest.expanduser().resolve()
    failures: list[str] = []
    warnings: list[str] = []
    if not note.is_file():
        raise SystemExit(f"笔记不存在：{note}")

    try:
        manifest = load_manifest(manifest_path)
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc
    manifest_note = Path(str(manifest.get("note_path", ""))).expanduser().resolve()
    if manifest_note != note:
        failures.append(f"note_path 与 manifest 不一致：{manifest_note}")

    text = note.read_text(encoding="utf-8", errors="replace")
    try:
        fields, body = parse_frontmatter(text)
    except ValueError as exc:
        failures.append(str(exc))
        fields, body = {}, text
    if fields:
        validate_frontmatter(fields, note, failures, warnings)
    validate_body(body, note, failures, warnings)

    if failures:
        print("验证未通过：")
        for failure in failures:
            print(f"- {failure}")
        for warning in warnings:
            print(f"提示：{warning}")
        raise SystemExit(1)

    print(f"验证通过：{note}")
    for warning in warnings:
        print(f"提示：{warning}")
    generated_body = body
    if body.count(GENERATED_START) == 1 and body.count(GENERATED_END) == 1:
        start = body.index(GENERATED_START) + len(GENERATED_START)
        end = body.index(GENERATED_END)
        if start < end:
            generated_body = body[start:end]
    heading_count = len(re.findall(r"^##\s+", generated_body, re.MULTILINE))
    print(
        f"正文节：{heading_count}；"
        f"嵌入资源：{len(EMBED.findall(generated_body))}"
    )


if __name__ == "__main__":
    main()
