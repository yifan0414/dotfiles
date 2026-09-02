# Acquisition and TeX traversal

Read this reference after `prepare_arxiv.py` succeeds. The generated `.read-paper-{safe_base_id}.json` is authoritative; do not recalculate paths independently.

## Identity and paths

- The note filename uses a human-readable, Obsidian-safe paper title: spaces and Unicode are preserved, while cross-platform path characters and Obsidian link-reserved characters are replaced. Layout commands and title footnotes are excluded before naming.
- `arxiv_id` may include `vN`; `base_id` never does.
- `safe_arxiv_id` and `safe_base_id` replace `/` with `_` and are the only ID forms allowed in filenames.
- The default paper folder and note filename both use the Obsidian-safe title exactly; no arXiv ID suffix is appended.
- Reruns locate an existing paper folder through its hidden `.read-paper-{safe_base_id}.json` manifest. If a new paper's title directory is already non-empty, preparation stops instead of overwriting it.
- When `output_note_path` is supplied, write only that note and place assets in its sibling `assets/` directory.
- Never use raw old-style IDs such as `cs/0601001` in a filename.

The preparer stores versioned inputs under versioned cache keys. An unversioned input represents “latest” and is refreshed on each preparation attempt; if refresh fails but a complete cache exists, the manifest reports stale-cache reuse.

## Safe source handling

`prepare_arxiv.py` performs atomic downloads and rejects archive entries that are absolute, escape the extraction directory, or are links/devices. It also handles a gzip-compressed single-TeX source. Do not bypass the preparer with ad hoc `curl | tar` commands.

If `/src` is unavailable and no valid cached source exists, use `$read-paper-mineru` on the PDF. Do not continue with a partially extracted project.

## TeX project traversal

Start from manifest `entrypoint` and follow `\input{}` and `\include{}` recursively. Resolve includes relative to the containing TeX file first, then the project root. Prevent cycles and record missing includes rather than inventing their contents.

Read all substantive files in document order, including appendices when they contain method, experiment, proof, or limitation details. Treat `.sty`, generated tables, and bibliography files as supporting evidence only when needed to interpret commands, citations, or metadata.

Capture:

- title and authors from TeX, cross-checked against the arXiv abstract page;
- abstract, introduction, related framing, method, experiments, limitations, conclusion, and substantive appendices;
- model/data/training/inference configuration and compute only when explicitly stated;
- every candidate result-table and pipeline-figure caption, label, source file, and include path;
- bibliography entry or arXiv cite line for the final citation.

Do not assume that the largest TeX file is the entrypoint or that a filename such as `main.tex` is correct when the manifest selected another file.

## Evidence discipline

Use evidence in this order:

1. paper TeX and equations;
2. rendered PDF for visual layout, tables, and figure composition;
3. arXiv abstract-page metadata;
4. explicitly linked code or project pages, only when the user asks or the note's `code` field needs a directly stated URL.

Distinguish author claims from your synthesis. Do not add performance explanations, limitations, implementation facts, or causal interpretations that the paper does not support.

## Existing-note state

The manifest reports one of:

- `new`: the note does not exist;
- `managed`: the note contains `READ_PAPER_GENERATED` markers and may be safely updated within those boundaries;
- `unmanaged-existing`: the note exists without markers. Do not overwrite it without explicit user direction.

The PDF and skill-managed image assets may be refreshed atomically for the same paper. Do not delete or overwrite unrelated files in `assets/`.
