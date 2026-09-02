#!/usr/bin/env python3
"""Prepare an arXiv TeX project and stable Obsidian paths."""

from __future__ import annotations

import argparse
import gzip
import json
import os
import re
import shutil
import tarfile
import tempfile
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath


DEFAULT_OUTPUT_DIR = (
    Path.home()
    / "Library/Mobile Documents/iCloud~md~obsidian/Documents/iCSNote/Paper/raw"
)
DEFAULT_CACHE_ROOT = Path.home() / ".cache/arxiv"
USER_AGENT = "read-paper-skill/2.0 (+https://arxiv.org/)"
MAX_DOWNLOAD_BYTES = 2 * 1024 * 1024 * 1024
MAX_ARCHIVE_MEMBERS = 50_000
MAX_UNPACKED_BYTES = 4 * 1024 * 1024 * 1024
NEW_STYLE_ID = re.compile(r"\d{4}\.\d{4,5}(?:v\d+)?", re.IGNORECASE)
OLD_STYLE_ID = re.compile(
    r"[A-Za-z][A-Za-z0-9.-]*/\d{7}(?:v\d+)?", re.IGNORECASE
)
VERSION = re.compile(r"v\d+$", re.IGNORECASE)
GENERATED_START = "<!-- READ_PAPER_GENERATED_START -->"
GENERATED_END = "<!-- READ_PAPER_GENERATED_END -->"
TITLE_DROP_COMMANDS = {
    "authornote",
    "footnote",
    "footnotetext",
    "hspace",
    "label",
    "thanks",
    "titlenote",
    "vspace",
}
OBSIDIAN_FORBIDDEN = re.compile(r'[\\/:*?"<>|\[\]#^\x00-\x1f\x7f]')
WINDOWS_RESERVED_BASENAMES = {
    "CON",
    "PRN",
    "AUX",
    "NUL",
    *(f"COM{index}" for index in range(1, 10)),
    *(f"LPT{index}" for index in range(1, 10)),
}


def normalize_arxiv_id(raw: str) -> str:
    value = urllib.parse.unquote(raw.strip())
    parsed = urllib.parse.urlparse(value)
    if parsed.scheme or parsed.netloc:
        host = (parsed.hostname or "").lower().rstrip(".")
        if host not in {"arxiv.org", "www.arxiv.org", "export.arxiv.org"}:
            raise ValueError("只接受 arxiv.org URL 或 arXiv ID。")
        value = parsed.path.strip("/")
        for prefix in ("abs/", "pdf/", "src/", "e-print/"):
            if value.startswith(prefix):
                value = value[len(prefix) :]
                break
    value = value.split("?", 1)[0].split("#", 1)[0].strip("/")
    if value.lower().endswith(".pdf"):
        value = value[:-4]
    if NEW_STYLE_ID.fullmatch(value) or OLD_STYLE_ID.fullmatch(value):
        return value
    raise ValueError(f"无法识别 arXiv ID：{raw}")


def safe_id(arxiv_id: str) -> str:
    return arxiv_id.replace("/", "_")


def canonical_urls(arxiv_id: str) -> dict[str, str]:
    quoted = urllib.parse.quote(arxiv_id, safe="/.")
    return {
        "abs_url": f"https://arxiv.org/abs/{quoted}",
        "pdf_url": f"https://arxiv.org/pdf/{quoted}.pdf",
        "src_url": f"https://arxiv.org/src/{quoted}",
    }


def download_atomic(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(destination.name + ".part")
    temporary.unlink(missing_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=90) as response, temporary.open(
            "wb"
        ) as output:
            declared = response.headers.get("Content-Length")
            if declared and int(declared) > MAX_DOWNLOAD_BYTES:
                raise RuntimeError(f"下载内容超过 {MAX_DOWNLOAD_BYTES} 字节上限：{url}")
            total = 0
            while chunk := response.read(1024 * 1024):
                total += len(chunk)
                if total > MAX_DOWNLOAD_BYTES:
                    raise RuntimeError(
                        f"下载内容超过 {MAX_DOWNLOAD_BYTES} 字节上限：{url}"
                    )
                output.write(chunk)
        if temporary.stat().st_size == 0:
            raise RuntimeError(f"下载结果为空：{url}")
        os.replace(temporary, destination)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise


def ensure_download(url: str, destination: Path, refresh: bool) -> str:
    if destination.is_file() and destination.stat().st_size > 0 and not refresh:
        return "reused"
    try:
        download_atomic(url, destination)
        return "downloaded"
    except Exception:
        if destination.is_file() and destination.stat().st_size > 0:
            return "stale-cache"
        raise


def validate_archive_member(member: tarfile.TarInfo) -> None:
    name = PurePosixPath(member.name)
    if name.is_absolute() or ".." in name.parts:
        raise RuntimeError(f"源码包包含越界路径：{member.name}")
    if member.issym() or member.islnk() or member.isdev():
        raise RuntimeError(f"源码包包含不允许的链接或设备项：{member.name}")


def unpack_source(archive: Path, destination: Path) -> str:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = Path(
        tempfile.mkdtemp(prefix=f".{destination.name}-", dir=destination.parent)
    )
    archive_format = "tar"
    try:
        try:
            with tarfile.open(archive, mode="r:*") as bundle:
                members = bundle.getmembers()
                if len(members) > MAX_ARCHIVE_MEMBERS:
                    raise RuntimeError("源码包文件数量超过安全上限。")
                unpacked_size = sum(member.size for member in members if member.isfile())
                if unpacked_size > MAX_UNPACKED_BYTES:
                    raise RuntimeError("源码包解压后大小超过安全上限。")
                for member in members:
                    validate_archive_member(member)
                bundle.extractall(temporary, members=members, filter="data")
        except tarfile.ReadError:
            archive_format = "single-tex"
            raw = archive.read_bytes()
            try:
                raw = gzip.decompress(raw)
            except (gzip.BadGzipFile, EOFError):
                pass
            if b"\\documentclass" not in raw and b"\\begin{document}" not in raw:
                raise RuntimeError("arXiv /src 既不是安全 tar 包，也不是可识别的 TeX 文件。")
            (temporary / "main.tex").write_bytes(raw)
        if destination.exists():
            shutil.rmtree(destination)
        os.replace(temporary, destination)
        return archive_format
    except Exception:
        shutil.rmtree(temporary, ignore_errors=True)
        raise


def read_tex(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def entrypoint_score(path: Path, text: str) -> tuple[int, int, str]:
    lowered = path.name.lower()
    score = 0
    if "\\begin{document}" in text:
        score += 100
    if "\\documentclass" in text:
        score += 40
    if re.search(r"\\title\s*(?:\[[^]]*\]\s*)?\{", text):
        score += 25
    score += min(30, 3 * len(re.findall(r"\\(?:input|include)\s*\{", text)))
    if lowered in {"main.tex", "paper.tex", "manuscript.tex"}:
        score += 15
    return score, len(text), str(path)


def find_entrypoint(project_dir: Path) -> Path:
    candidates: list[tuple[tuple[int, int, str], Path]] = []
    for path in project_dir.rglob("*.tex"):
        if not path.is_file():
            continue
        text = read_tex(path)
        candidates.append((entrypoint_score(path, text), path))
    if not candidates:
        raise RuntimeError("源码项目中没有找到 .tex 文件。")
    candidates.sort(key=lambda item: item[0], reverse=True)
    selected = candidates[0][1]
    if "\\begin{document}" not in read_tex(selected):
        raise RuntimeError("无法找到包含 \\begin{document} 的可靠 TeX 入口。")
    return selected


def extract_braced_command(text: str, command: str) -> str | None:
    match = re.search(rf"\\{re.escape(command)}\s*(?:\[[^]]*\]\s*)?\{{", text)
    if not match:
        return None
    start = match.end() - 1
    depth = 0
    escaped = False
    for index in range(start, len(text)):
        char = text[index]
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start + 1 : index]
    return None


def balanced_group_end(
    text: str, start: int, opener: str = "{", closer: str = "}"
) -> int | None:
    if start >= len(text) or text[start] != opener:
        return None
    depth = 0
    index = start
    while index < len(text):
        char = text[index]
        if char == "\\":
            index += 2
            continue
        if char == opener:
            depth += 1
        elif char == closer:
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    return None


def drop_braced_commands(value: str, commands: set[str]) -> str:
    pattern = re.compile(
        r"\\(?:" + "|".join(sorted(map(re.escape, commands))) + r")\*?"
        r"(?![A-Za-z@])"
    )
    pieces: list[str] = []
    cursor = 0
    search_from = 0
    while match := pattern.search(value, search_from):
        argument_start = match.end()
        while argument_start < len(value) and value[argument_start].isspace():
            argument_start += 1
        while argument_start < len(value) and value[argument_start] == "[":
            option_end = balanced_group_end(value, argument_start, "[", "]")
            if option_end is None:
                break
            argument_start = option_end
            while argument_start < len(value) and value[argument_start].isspace():
                argument_start += 1
        if argument_start >= len(value) or value[argument_start] != "{":
            search_from = match.end()
            continue
        argument_end = balanced_group_end(value, argument_start)
        if argument_end is None:
            search_from = match.end()
            continue
        pieces.extend((value[cursor : match.start()], " "))
        cursor = argument_end
        search_from = argument_end
    pieces.append(value[cursor:])
    return "".join(pieces)


def plain_tex(value: str) -> str:
    text = re.sub(r"(?<!\\)%.*", " ", value)
    text = re.sub(r"\$[^$]*\$", " ", text)
    text = drop_braced_commands(text, TITLE_DROP_COMMANDS)
    text = re.sub(r"\\\\(?:\s*\[[^]]*\])?", " ", text)
    text = re.sub(r"\\(?:newline|linebreak|par)\b(?:\s*\[[^]]*\])?", " ", text)
    for _ in range(6):
        updated = re.sub(
            r"\\(?:textbf|textit|emph|textrm|textsf|texttt|mathrm|mathbf)\s*"
            r"\{([^{}]*)\}",
            r"\1",
            text,
        )
        if updated == text:
            break
        text = updated
    text = re.sub(r"\\[A-Za-z@]+\*?(?:\[[^]]*\])?", " ", text)
    text = text.replace("{", " ").replace("}", " ").replace("~", " ")
    text = re.sub(r"\s+", " ", text).strip()
    return re.sub(r"\s+([,.;:!?])", r"\1", text)


def truncate_utf8(value: str, maximum_bytes: int) -> str:
    encoded = value.encode("utf-8")
    if len(encoded) <= maximum_bytes:
        return value
    clipped = encoded[:maximum_bytes]
    while clipped:
        try:
            return clipped.decode("utf-8").rstrip("-_. ")
        except UnicodeDecodeError:
            clipped = clipped[:-1]
    return ""


def obsidian_title(title: str, fallback: str) -> str:
    value = unicodedata.normalize("NFKC", title).strip()
    value = OBSIDIAN_FORBIDDEN.sub(" - ", value)
    value = re.sub(r"\s+", " ", value)
    value = re.sub(r"(?:\s*-\s*){2,}", " - ", value).strip(" .-")
    value = truncate_utf8(value, 180).rstrip(" .-")
    if not value or value in {".", ".."}:
        return fallback
    if value.upper() in WINDOWS_RESERVED_BASENAMES:
        return f"{value} - paper"
    return value


def existing_paper_dir(output_dir: Path, safe_base_id: str) -> Path | None:
    manifest_name = f".read-paper-{safe_base_id}.json"
    matches = sorted(
        manifest.parent
        for manifest in output_dir.glob(f"*/{manifest_name}")
        if manifest.is_file()
    )
    if len(matches) > 1:
        raise RuntimeError(
            f"同一 arXiv ID 对应多个输出目录，请先人工确认：{', '.join(str(path) for path in matches)}"
        )
    return matches[0] if matches else None


def select_paper_dir(
    output_dir: Path, safe_title: str, safe_base_id: str
) -> Path:
    existing = existing_paper_dir(output_dir, safe_base_id)
    if existing is not None:
        return existing
    candidate = output_dir / safe_title
    if candidate.exists() and (
        not candidate.is_dir() or any(candidate.iterdir())
    ):
        raise RuntimeError(
            "目标标题目录已存在且不属于当前 arXiv 论文；"
            "请使用 --output-note-path 明确指定其他位置："
            f"{candidate}"
        )
    return candidate


def note_state(note_path: Path) -> str:
    if not note_path.exists():
        return "new"
    if not note_path.is_file():
        return "unmanaged-existing"
    text = note_path.read_text(encoding="utf-8", errors="replace")
    if not text.strip():
        return "new"
    if text.count(GENERATED_START) == 1 and text.count(GENERATED_END) == 1:
        return "managed"
    return "unmanaged-existing"


def copy_atomic(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(destination.name + ".part")
    temporary.unlink(missing_ok=True)
    try:
        shutil.copy2(source, temporary)
        os.replace(temporary, destination)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise


def write_json_atomic(path: Path, data: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".part")
    temporary.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    os.replace(temporary, path)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="下载并安全展开 arXiv TeX 源码，生成稳定的 Obsidian 输出路径。"
    )
    parser.add_argument("arxiv", help="arXiv abs/pdf/src URL 或 ID")
    output = parser.add_mutually_exclusive_group()
    output.add_argument("--output-note-path", type=Path)
    output.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--cache-root", type=Path, default=DEFAULT_CACHE_ROOT)
    parser.add_argument("--refresh", action="store_true", help="强制刷新版本化缓存")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    try:
        arxiv_id = normalize_arxiv_id(args.arxiv)
    except ValueError as exc:
        raise SystemExit(str(exc)) from exc

    base_id = VERSION.sub("", arxiv_id)
    safe_arxiv_id = safe_id(arxiv_id)
    safe_base_id = safe_id(base_id)
    urls = canonical_urls(arxiv_id)
    cache_root = args.cache_root.expanduser().resolve()
    source_archive = cache_root / "src-archives" / f"{safe_arxiv_id}.src"
    pdf_cache = cache_root / "pdf" / f"{safe_arxiv_id}.pdf"
    project_dir = cache_root / "src" / safe_arxiv_id
    is_versioned = bool(VERSION.search(arxiv_id))
    refresh = args.refresh or not is_versioned
    warnings: list[str] = []

    try:
        source_cache_status = ensure_download(urls["src_url"], source_archive, refresh)
    except (OSError, RuntimeError, urllib.error.URLError) as exc:
        print(
            "SOURCE_UNAVAILABLE: arXiv /src 无法取得；请改用 $read-paper-mineru。\n"
            f"原因：{exc}"
        )
        raise SystemExit(2) from exc
    if source_cache_status == "stale-cache":
        warnings.append("无法刷新源码，正在使用已有缓存。")

    needs_unpack = source_cache_status == "downloaded" or not project_dir.is_dir()
    try:
        if needs_unpack:
            archive_format = unpack_source(source_archive, project_dir)
        else:
            archive_format = "cached-project"
        entrypoint = find_entrypoint(project_dir)
    except RuntimeError as exc:
        print(
            "SOURCE_UNAVAILABLE: arXiv /src 无法形成可靠 TeX 项目；"
            "请改用 $read-paper-mineru。\n"
            f"原因：{exc}"
        )
        raise SystemExit(2) from exc
    raw_title = extract_braced_command(read_tex(entrypoint), "title") or ""
    title = plain_tex(raw_title)
    fallback_title = f"arxiv-{safe_base_id}"
    safe_title = obsidian_title(title, fallback_title)

    try:
        pdf_cache_status = ensure_download(urls["pdf_url"], pdf_cache, refresh)
    except (OSError, RuntimeError, urllib.error.URLError) as exc:
        raise SystemExit(f"PDF 下载失败：{exc}") from exc
    with pdf_cache.open("rb") as handle:
        pdf_magic = handle.read(4)
    if pdf_magic != b"%PDF":
        raise SystemExit(f"缓存文件不是有效 PDF：{pdf_cache}")
    if pdf_cache_status == "stale-cache":
        warnings.append("无法刷新 PDF，正在使用已有缓存。")

    if args.output_note_path is not None:
        note_path = args.output_note_path.expanduser().resolve()
        paper_dir = note_path.parent
    else:
        output_dir = args.output_dir.expanduser().resolve()
        output_dir.mkdir(parents=True, exist_ok=True)
        try:
            paper_dir = select_paper_dir(output_dir, safe_title, safe_base_id)
        except RuntimeError as exc:
            raise SystemExit(str(exc)) from exc
        note_path = paper_dir / f"{safe_title}.md"
    assets_dir = paper_dir / "assets"
    paper_dir.mkdir(parents=True, exist_ok=True)
    assets_dir.mkdir(parents=True, exist_ok=True)
    pdf_asset_path = assets_dir / f"paper_{safe_base_id}.pdf"
    copy_atomic(pdf_cache, pdf_asset_path)
    manifest_path = paper_dir / f".read-paper-{safe_base_id}.json"

    manifest: dict[str, object] = {
        "version": 2,
        "prepared_at": datetime.now(timezone.utc).isoformat(),
        "input": args.arxiv,
        "arxiv_id": arxiv_id,
        "base_id": base_id,
        "safe_arxiv_id": safe_arxiv_id,
        "safe_base_id": safe_base_id,
        **urls,
        "title": title,
        "raw_title": raw_title,
        "obsidian_title": safe_title,
        "paper_dir": str(paper_dir),
        "note_path": str(note_path),
        "assets_dir": str(assets_dir),
        "pdf_asset_path": str(pdf_asset_path),
        "pdf_asset_link": f"[[assets/{pdf_asset_path.name}]]",
        "manifest_path": str(manifest_path),
        "cache_root": str(cache_root),
        "source_archive": str(source_archive),
        "pdf_cache": str(pdf_cache),
        "project_dir": str(project_dir),
        "entrypoint": str(entrypoint),
        "source_cache_status": source_cache_status,
        "pdf_cache_status": pdf_cache_status,
        "archive_format": archive_format,
        "note_state": note_state(note_path),
        "warnings": warnings,
    }
    write_json_atomic(manifest_path, manifest)
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
