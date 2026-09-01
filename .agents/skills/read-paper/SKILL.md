---
name: read-paper
description: Read and digest an arXiv paper from an arXiv URL by downloading the /src archive, traversing the LaTeX project, capturing key experimental tables as high-resolution PDF screenshots, extracting the main pipeline figure, and writing or overwriting one Obsidian-compatible Markdown note. Use when asked to read, summarize, analyze, or make an Obsidian note for an arXiv paper.
---

# Read arXiv Paper (TeX-first) → Obsidian Note

## Inputs

- arXiv URL (abs/pdf/id forms). Example (any equivalent form ok):
  - https://arxiv.org/abs/XXXX.XXXXX
  - https://arxiv.org/pdf/XXXX.XXXXX.pdf
- Optional:
  - output_note_path (if provided, MUST update that note; do not create another)
  - output_dir default: /Users/yifan/Library/Mobile Documents/iCloud~md~obsidian/Documents/iCSNote/Paper/raw/
  - tag/slug: optional; default arxiv_{id}

### Paper Name / Folder Naming

- use_title_as_filename (default: true)
- filename_max_len (default: 80)
- filename_case (default: "kebab") # kebab|snake|preserve
- reserved_char_replacement (default: "-")
- folder_layout (default: "paper_dir") # always: md + assets under same folder

**Sanitize rules (paper_name):**

1. Prefer title from TeX (`\title{...}`); fallback to `arxiv_{id}` if title not found or use_title_as_filename=false.
2. Strip simple LaTeX commands (`\textbf{}`, `\emph{}`, etc.) and math (`$...$`) best-effort.
3. Replace forbidden characters: `\/:*?"<>|` and control chars with `reserved_char_replacement`.
4. Collapse whitespace/separators to single `-` (kebab) or `_` (snake).
5. Trim leading/trailing `-`, `_`, `.`, and spaces.
6. Truncate to `filename_max_len` characters.
7. If result becomes empty -> `arxiv_{id}`.

### Derived Paths (single source of truth)

If `output_note_path` is NOT provided:

- paper_dir = {output_dir}/{paper_name}
- note_path = {paper_dir}/{paper_name}.md
- assets_dir = {paper_dir}/assets

If `output_note_path` IS provided:

- note_path = output_note_path (MUST write/update exactly this file)
- paper_dir = dirname(output_note_path)
- assets_dir = {paper_dir}/assets

> All generated assets go under `assets_dir` unless explicitly overridden.

After `arxiv_id` is available:

- safe_arxiv_id = arxiv_id with `/` replaced by `_` for filenames
- pdf_asset_path = {assets_dir}/paper_{safe_arxiv_id}.pdf
- pdf_asset_link = [[assets/paper_{safe_arxiv_id}.pdf]]

### Optional — Pipeline Figure Extraction

- extract_pipeline_figure (default: true)
- max_pipeline_figures (default: 1)
- figure_keywords (default:
  ["pipeline","framework","overview","architecture","method","model","proposed",
  "system","approach","workflow","diagram",
  "框架","总体","架构","方法","流程","系统","概览"])
- figure_output_dir (default: assets_dir) # unified default
- figure_fallback_pdf (default: true)
- figure_raster_dpi (default: 350)
- figure_min_width_px (default: 800)

### Experimental Table Screenshots

- extract_experiment_tables (default: true)
- experiment_table_raster_dpi (default: 350)
- experiment_table_min_width_px (default: 1600)
- experiment_table_output_dir (default: assets_dir)
- experiment_table_keywords (default:
  ["main result","comparison","benchmark","ablation","analysis","efficiency",
  "performance","state-of-the-art","sota","evaluation","experiment"])


## 1) Normalize URL → arxiv_id (+ version)

- Extract arxiv_id, allow vN suffix if present.
- Support both new-style (XXXX.XXXXX) and old-style (e.g., cs/0601001) IDs.
- Build canonical:
  - abs_url: https://arxiv.org/abs/{arxiv_id}
  - pdf_url: https://arxiv.org/pdf/{arxiv_id}.pdf
  - src_url: https://arxiv.org/src/{arxiv_id}

## 2) Download source archive and PDF with cache

Source cache file:
  - ~/.cache/arxiv/src/{arxiv_id}.tar.gz
- If exists, reuse.
- Otherwise download from src_url.
- If /src is unavailable, fallback to PDF-only reading (last resort).

PDF cache and asset copy:

- PDF cache file:
  - ~/.cache/arxiv/pdf/{safe_arxiv_id}.pdf
- If the PDF cache file does not exist, download from pdf_url.
- Ensure `assets_dir` exists, then copy the cached PDF into `pdf_asset_path`.
- If `pdf_asset_path` already exists, reuse it unless the user explicitly asks to refresh assets.
- Record `pdf_asset_link` for the Obsidian note frontmatter.

## 3) Unpack source

- Unpack to:
  - ~/.cache/arxiv/src/{arxiv_id}/
- Keep directory for incremental reads.
- Use safe extraction: prevent path traversal (e.g., disallow `../` escaping target dir).

## 4) Find LaTeX entrypoint (robust)

Heuristics:

- Prefer file defining \title / \author / \begin{document}
- Common names: main.tex, paper.tex, manuscript.tex
- If multiple candidates, choose the one with \begin{document} and the most \input/\include.

## 4.1 Extract Title → paper_name and create output folders

- Extract raw_title from TeX entrypoint `\title{...}` (best-effort).
- If `use_title_as_filename=true` and raw_title exists:
  - paper_name = sanitize_title(raw_title)
  - else paper_name = `arxiv_{arxiv_id}`
- Derive paths using **Derived Paths (single source of truth)** above.
- Ensure directories exist:
  - mkdir -p {paper_dir}
  - mkdir -p {assets_dir}
- Set:
  - figure_output_dir defaults to assets_dir (unless explicitly provided)

## 5) Recursively read TeX project

- Parse entrypoint, recursively inline:
  - \input{...}, \include{...}
- Ignore figures/binaries unless needed.
- Capture:
  - problem statement, contributions
  - method & training details (data, objectives, architecture, compute)
  - evaluation setup (datasets, metrics, baselines)
  - locations and captions of key result tables (without transcribing scores), limitations, open questions

## 6) Capture experimental result tables as high-resolution images

Do not transcribe, normalize, rank, reformat, or rebuild experimental result tables as Markdown. Do not calculate deltas or restyle best/second-best values. Preserve the table exactly as the paper presents it by embedding a high-resolution crop from the PDF.

### 6.1 Identify candidate result tables from TeX

- Locate `table` / `table*` environments referenced from experiment, evaluation, results, analysis, or ablation sections.
- Capture each candidate's table number, caption, label, source TeX file, and document order.
- Prefer tables reporting main benchmark comparisons, ablations, analysis, robustness, or efficiency results.
- Skip tables that only contain dataset statistics, prompt templates, notation, or hyperparameters unless they are essential to understanding the evaluation.
- Use TeX only to identify and label candidates; use the rendered paper PDF as the visual source for screenshots.

### 6.2 Locate and crop each table in the PDF

1. Search the PDF for the table number, caption, or a distinctive caption phrase to locate its page.
2. Determine the bounding box containing the complete table, including its table number/caption, column headers, all rows, legends, and table-specific footnotes.
3. Render and crop from the PDF at `experiment_table_raster_dpi`. Prefer a tight crop with modest padding; exclude unrelated body text and neighboring figures.
4. If a table spans pages or is split into labeled parts, capture every part and keep their document order.
5. If automatic bounding-box detection is unreliable, render the page at high resolution and crop it after visual inspection. Use a full-page render only as an internal localization aid; do not embed it. If a reliable table crop cannot be produced, omit that screenshot rather than adding provenance text or reconstructing a Markdown table.

### 6.3 Export and embed in Obsidian

- Save lossless PNG files under `experiment_table_output_dir` using stable names:
  - `experiment_table_{safe_arxiv_id}_t{table_number}.png`
  - add `_part2`, `_part3`, etc. for split tables
  - add `_2`, `_3`, etc. if a target name already exists; do not overwrite existing assets unless the user explicitly asks to refresh them
- Ensure the exported crop is at least `experiment_table_min_width_px` when the source resolution permits.
- Under `Experiments`, embed each screenshot in document order using the same presentation style as the pipeline figure:

```markdown
### Main Results — Table 1
![[assets/experiment_table_XXXX.XXXXX_t1.png]]
```

- Because the crop already includes the original table number and caption, do not repeat the caption as Markdown text below the screenshot.
- Do not emit visible source/provenance text for screenshots, including PDF page numbers, TeX paths, labels, asset export paths, crop methods, or DPI.
- A short Chinese evaluation-setup paragraph may name datasets, metrics, and baselines directly reported by the paper. Do not reproduce score values, make numeric comparisons, or infer rankings in prose.
- Elsewhere in the note, avoid derived quantitative claims. If a qualitative performance claim is important, attribute it to the authors and point the reader to the corresponding screenshot.

## 7) Extract pipeline/framework figure (TeX-first, PDF fallback)

### 7.1 TeX-first extraction (preferred)

Goal: locate the paper’s main “pipeline/framework/overview” figure from TeX source assets.

1. Collect candidate figures

- Scan recursively-read TeX content for `\begin{figure}` / `\begin{figure*}` blocks.
- For each block, extract:
  - caption_text from `\caption{...}` (best-effort)
  - label_text from `\label{...}` (optional)
  - include_paths from `\includegraphics[...] {path}` (may omit extension)

2. Resolve image file paths

- For each include path, attempt to resolve to an existing file in the unpacked source tree by trying extensions:
  - `.pdf`, `.png`, `.jpg`, `.jpeg`, `.eps`, `.svg`
- If the include path is relative, resolve against:
  - the directory of the TeX file that contains it
  - project root as fallback

3. Score candidates (pick pipeline-like figure)

- Score:
  - +5 for each keyword match in caption_text (case-insensitive)
  - +3 for each keyword match in label_text
  - +2 for each keyword match in filename
  - +2 if caption contains “overview/framework/architecture” (or 中文同义词)
  - -5 if caption suggests unrelated (e.g., “dataset”, “qualitative results”, “attention map”) unless also matches pipeline keywords
- Prefer larger images when possible:
  - If you can read image width, add + (width_px / 1000) capped at +3
- Discard candidates too small (width < figure_min_width_px) unless nothing else exists.

4. Export to Obsidian assets

- If `extract_pipeline_figure=false`, skip this entire section.
- Ensure `figure_output_dir` exists.
- Choose up to `max_pipeline_figures` top-scoring candidates.
- Copy into:
  - `{figure_output_dir}/pipeline_{arxiv_id}.{ext}`
- If target exists, do NOT overwrite; add suffix `_2`, `_3`, etc.

5. Optional: Convert vector to PNG for Obsidian

- If chosen asset is `.pdf/.eps/.svg` and conversion tools are available, export:
  - `{figure_output_dir}/pipeline_{arxiv_id}.png` using `figure_raster_dpi`
- For PDF figure conversion, render using the PDF's visible page/crop bounds (e.g. `pdftoppm -cropbox`) so the PNG matches the PDF figure size instead of the full MediaBox.
- If conversion not possible, keep original and embed as-is.

6. Record figure metadata

- figure_path (relative to note, e.g., `assets/pipeline_XXXX.XXXXX.png`)
- figure_caption (caption_text if any)
- cover (Obsidian internal link to the pipeline figure, e.g., `[[assets/pipeline_XXXX.XXXXX.png]]`; leave empty if no reliable pipeline figure exists)

### 7.2 PDF fallback extraction

Trigger fallback when:

- no suitable TeX figure found OR included image files missing,
  AND `figure_fallback_pdf=true`.

1. Ensure PDF is available

- Download `{pdf_url}` to cache if needed.
- Reuse the cached PDF from step 2 and ensure the PDF asset copy exists in `assets_dir`.

2. Try image extraction from PDF (best-effort)

- Extract embedded images; filter out tiny ones using `figure_min_width_px`.
- Pick the largest / most pipeline-like (keyword-based if possible; otherwise size-based).
- Save as:
  - `{figure_output_dir}/pipeline_{arxiv_id}.png` (or jpg if extracted)

3. If extraction fails, render likely page(s) to PNG

- Search PDF text for “Figure” + any `figure_keywords`.
- Render matching page(s) and crop to the pipeline figure before embedding:
  - `{figure_output_dir}/pipeline_{arxiv_id}_p{page}.png`
- If a reliable figure crop cannot be produced, omit the pipeline figure instead of embedding a whole-page render.

4. Record metadata

- figure_caption = best-effort

## 8) Write Obsidian note with YAML frontmatter (single destination)

**Write/update EXACTLY `note_path`** (derived above).
Default behavior: **full rewrite** (strong overwrite) for stability.

Optional preservation rule (only if you implement it):

- If the existing note contains:
  - `<!-- USER_NOTES_START -->` ... `<!-- USER_NOTES_END -->`
    preserve that block verbatim when rewriting; otherwise overwrite everything.

### Output language style

- The generated Markdown note body MUST be primarily Chinese.
- Preserve key English terms when they are the paper’s own terminology or common technical names, including model names, method names, dataset names, benchmark names, metric names, loss/objective names, module names, code identifiers, and field names.
- Do not translate proper nouns or widely used research terms awkwardly; use Chinese explanation around the original English term.
- Section headings MUST remain in English for consistency with existing Obsidian notes.
- Table column names may remain English for scanability; explanatory prose and notes around tables should be Chinese.
- Keep citations, BibTeX, URLs, file paths, and YAML field names in their original English form.
- Mathematical formulas MUST use Obsidian/Markdown LaTeX math delimiters, not inline code or fenced code blocks. Use `$...$` for short inline formulas inside prose, and use `$$...$$` for standalone, multi-line, or important display equations:
  inline example: `$L_{\text{task}}$`
  $$
  L = L_{\text{task}} + \lambda L_{\text{reg}}
  $$

Frontmatter fields (suggested):

- title: "..."
- authors: ["...", "..."]
- conference: "" # conference/journal name, e.g. CVPR; leave empty if not listed on the paper page
- year:
- arxiv_url: "..."
- pdf_link: "[[assets/paper_{safe_arxiv_id}.pdf]]"
- cover: ""
- updated: YYYY-MM-DD
- tags: ["paper/arxiv", "video-qa", "long-video"]
- status: "unread"
- priority:
- rating:
- topics: ["Video Understanding"] # exactly one primary topic from the taxonomy below
- code: ""

For Obsidian Bases consistency:

- `status` should use one of: `"unread"`, `"reading"`, `"read"`, `"archived"`.
- Do not duplicate `status` or the primary `topics` value inside `tags`.
- Keep `tags` as a YAML list containing `"paper/arxiv"` plus relevant secondary tags from the taxonomy below.
- `priority` and `rating` should be numbers from 1 to 5, or empty if not assigned.
- `year` should be a number, not a string.
- `conference` should be a short conference/journal label such as `"CVPR"`; leave it empty if not listed on the paper page.
- `topics` MUST contain exactly one primary topic. If a paper overlaps multiple areas, choose the dominant contribution area.
- `pdf_link` should be an Obsidian internal link to the local PDF asset.
- `cover` should be an Obsidian internal link to the pipeline figure when one is available; keep it empty otherwise so the Base can fall back gracefully.

### Topic and secondary tag taxonomy

Pick exactly one primary topic for `topics` from this list:

- `LLM`
- `MLLM`
- `Video Understanding`
- `Efficient AI`
- `Generative AI`
- `Representation Learning`
- `Reinforcement Learning`
- `Dataset & Benchmark`
- `Trustworthy AI`
- `AI for Science`
- `Embodied AI`
- `Systems for AI`

Put secondary tags in YAML `tags` alongside `"paper/arxiv"`. Use only tags supported by the paper, and prefer these topic-specific tags:

- `LLM`: `reasoning`, `agent`, `alignment`, `rag`, `long-context`
- `MLLM`: `vlm`, `video-llm`, `image-text`, `audio-visual`
- `Video Understanding`: `video-qa`, `long-video`, `temporal-reasoning`, `question-aware`, `option-aware`, `token-pruning`, `video-llm`, `benchmark`
- `Efficient AI`: `pruning`, `distillation`, `quantization`, `efficient-inference`
- `Generative AI`: `diffusion`, `text-to-image`, `text-to-video`, `3d-generation`
- `Representation Learning`: `self-supervised`, `contrastive-learning`, `pretraining`
- `Reinforcement Learning`: `rlhf`, `rlaif`, `policy-optimization`, `rl-reasoning`
- `Dataset & Benchmark`: `benchmark`, `dataset`, `evaluation`, `leaderboard`
- `Trustworthy AI`: `safety`, `robustness`, `privacy`, `xai`, `fairness`
- `AI for Science`: `bio-ai`, `medical-ai`, `protein`, `weather`
- `Embodied AI`: `robotics`, `autonomous-driving`, `embodied-agent`
- `Systems for AI`: `training-system`, `serving`, `cuda`, `distributed-training`

Frontmatter for pipeline figure (best-effort):

- cover: "[[assets/pipeline_{arxiv_id}.png]]"

Do not add separate YAML fields for the pipeline figure path, caption, or source. In the `Pipeline Figure` body section, show only the embedded image and its original caption. Do not emit visible provenance such as TeX commands/files, figure labels, export paths, PDF pages, crop methods, or DPI.

Body sections (strict order):

1. TL;DR (3-6 bullets)
2. Key Contributions
3. Method (with compact pseudocode or pipeline bullets)
4. Pipeline Figure
   - If a pipeline figure exists:
     - `![[{figure_path}]]`
     - Caption: {figure_caption}
5. Experiments
   - Brief evaluation setup in Chinese (no reconstructed result tables)
   - High-resolution screenshots of main-result tables
   - High-resolution screenshots of ablation/analysis tables, if present
6. Limitations & Caveats
7. Concrete Implementation Ideas (2-5 actionable ideas)
8. Open Questions / Follow-ups
9. Citation (bibtex if available or arXiv cite line)

## 9) Safety and quality checks

- Do not transcribe experimental scores into Markdown tables or prose.
- Do not calculate improvements, rank methods, or infer best values from result tables.
- Preserve experimental tables visually through PDF screenshots; do not “clean” or restyle their content.
- Before finalizing the note, scan for formulas wrapped in backticks or code fences and rewrite them as `$...$` for inline formulas or `$$...$$` for display equations. Keep code fences only for actual pseudocode, BibTeX, or raw LaTeX/table fallback content.
- For pipeline figure:
  - Do not claim it is the pipeline figure unless caption/keywords strongly indicate it.
  - Do not embed a whole-page render as the pipeline figure; crop to the figure region or omit it.
  - If a PDF figure was converted to PNG, verify it was rendered with the PDF's visible crop bounds rather than the full MediaBox.
  - Confirm the note contains no visible extraction provenance, source line, TeX path, label, export path, rendering method, or DPI.
- For experimental table screenshots:
  - Inspect every exported PNG at full size before finalizing the note.
  - Confirm headers, all rows, caption, legends, and footnotes are readable and not clipped.
  - Confirm the crop corresponds to the intended table and that the recorded PDF page is correct.
  - Confirm no standalone caption text is repeated below a screenshot that already contains its caption.
  - Confirm the `Experiments` section contains no reconstructed Markdown result tables or transcribed score comparisons.
