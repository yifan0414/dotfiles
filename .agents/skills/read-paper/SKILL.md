---
name: read-paper
description: Read and digest an ML/AI arXiv paper from an arXiv URL or ID using its TeX source, preserve key result tables as PDF screenshots, extract one verified pipeline figure, and create or safely update one Chinese Obsidian note. Use for arXiv paper summaries, analyses, and Obsidian notes; use read-paper-mineru for local PDFs, non-arXiv PDFs, or arXiv papers whose source is unavailable.
---

# Read arXiv Paper → Obsidian Note

Produce one independently readable note from the paper itself. Use TeX as the primary semantic source and the rendered PDF as the visual source for result tables. Do not create a second note when the user supplies an output path.

## Inputs and routing

- Accept an arXiv `abs`, `pdf`, or raw ID, including version suffixes and old-style IDs.
- Optional `output_note_path` must be honored exactly.
- Otherwise use `/Users/yifan/Library/Mobile Documents/iCloud~md~obsidian/Documents/iCSNote/Paper/raw/`.
- For a non-ML/AI paper, a local PDF, a non-arXiv PDF URL, or unavailable `/src`, switch to `$read-paper-mineru`; do not improvise a second workflow here.

## 1. Prepare deterministic inputs

Run the bundled preparer:

```bash
python3 <skill-dir>/scripts/prepare_arxiv.py '<arxiv-url-or-id>' \
  [--output-note-path '<path>' | --output-dir '<dir>']
```

It normalizes the ID, refreshes unversioned cache entries, safely extracts the source, finds the TeX entrypoint, creates human-readable Obsidian-safe paths with collision checks, copies the PDF asset, and prints manifest metadata including `manifest_path`. Treat that `.read-paper-{safe_base_id}.json` manifest as the single source of truth for `paper_dir`, `note_path`, `assets_dir`, `project_dir`, `entrypoint`, URLs, and safe IDs.

If preparation reports unavailable source, invoke `$read-paper-mineru` with the paper PDF and stop this workflow. For acquisition details and TeX traversal rules, read [acquisition](references/acquisition.md) after preparation.

## 2. Read the paper completely

Starting from the manifest entrypoint, follow the TeX include graph and read every substantive section. Extract only paper-supported content:

- problem, motivation, assumptions, and contributions;
- method, objectives, architecture, training/inference details, and compute when stated;
- datasets, metrics, baselines, main results, ablations, limitations, and open questions;
- captions and locations of candidate tables and figures.

Use the arXiv abstract page for bibliographic metadata when TeX is ambiguous. Do not replace the authors' claims with outside knowledge.

## 3. Build visual assets

Read [visual assets](references/visual-assets.md) before extracting figures or tables.

- Select at most one main pipeline/framework figure, and include it only when caption and context establish its role.
- Capture main-result and useful ablation/analysis tables as tight, high-resolution PNG crops from the paper PDF.
- Do not reconstruct full result tables in Markdown, calculate unstated deltas, or infer rankings. You may summarize exact values or comparisons explicitly stated by the authors after verifying them against the paper.
- Inspect every final crop at full size. Omit an unreliable crop rather than substituting a whole page or guessed reconstruction.

All generated assets stay under the manifest `assets_dir` and use `safe_base_id`, never the raw arXiv ID, in filenames.

## 4. Write or safely update the note

Read [Obsidian note format](references/obsidian-note.md) before writing.

- Write exactly the manifest `note_path`.
- New notes contain `READ_PAPER_GENERATED` and `USER_NOTES` markers.
- On rerun, replace only the managed generated block and managed metadata; preserve user notes, unknown YAML keys, and the existing `status`, `priority`, and `rating` values.
- If a non-empty existing note has no managed markers, do not overwrite it. Stop and ask whether to migrate or replace it.
- Write primarily in Chinese with English section headings and original technical terms.
- Use `$...$` and `$$...$$` for mathematics; code fences are only for code, pseudocode, BibTeX, or raw LaTeX.

## 5. Validate and deliver

After visually checking the selected images, run:

```bash
python3 <skill-dir>/scripts/validate_note.py '<note_path>' \
  --manifest '<manifest_path printed by prepare_arxiv.py>'
```

Fix every validation failure. Warnings require judgment but must not be ignored silently. Deliver the absolute `note_path` only after validation passes, and report whether the source was TeX-first, which visual assets were retained, and whether an existing note was updated or a new note was created.
