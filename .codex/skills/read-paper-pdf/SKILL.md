---
name: read-paper-pdf
description: Read and digest a research paper from a local PDF file or direct PDF URL, including non-arXiv PDFs, conference PDFs, OpenReview PDFs, author-hosted PDFs, and downloaded paper files. Use when asked to read, summarize, analyze, extract tables/figures from, or create/update an Obsidian-compatible Markdown note for a PDF paper. For normal arXiv abs/id links, prefer the TeX-first read-paper skill unless the user explicitly requests PDF-only processing or arXiv source is unavailable.
---

# Read PDF Paper (PDF-only) -> Obsidian Note

## Inputs

- Local PDF path, absolute or relative.
- Direct PDF URL, including non-arXiv sources such as conference sites, OpenReview, author pages, GitHub releases, or institutional repositories.
- Optional:
  - output_note_path (if provided, MUST update that note; do not create another)
  - output_dir default: /Users/yifan/Library/Mobile Documents/iCloud~md~obsidian/Documents/iCSNote/Paper/raw/
  - title/authors/year/conference/code overrides when PDF metadata is missing or unreliable
  - tag/slug: optional; default derived from title, filename, URL, DOI, or arXiv ID if present
  - refresh_assets: optional; default false

Use this skill only for PDF-only reading. If the user gives an arXiv abs URL or arXiv ID and does not ask for PDF-only processing, switch to `read-paper` so the TeX-first workflow can extract source tables and figures more faithfully.

### Paper Name / Folder Naming

- use_title_as_filename (default: true)
- filename_max_len (default: 80)
- filename_case (default: "kebab") # kebab|snake|preserve
- reserved_char_replacement (default: "-")
- folder_layout (default: "paper_dir") # always: md + assets under same folder

**Sanitize rules (paper_name):**

1. Prefer a reliable title from PDF metadata, first-page title text, DOI landing metadata, or user override.
2. Fallback to the source filename stem, URL path stem, DOI, arXiv ID, or `pdf_paper_{short_hash}`.
3. Strip simple LaTeX commands and math best-effort.
4. Replace forbidden characters: `\/:*?"<>|` and control chars with `reserved_char_replacement`.
5. Collapse whitespace/separators to single `-` (kebab) or `_` (snake).
6. Trim leading/trailing `-`, `_`, `.`, and spaces.
7. Truncate to `filename_max_len` characters.
8. If result becomes empty -> `pdf_paper_{short_hash}`.

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

After `source_key` is available:

- source_key = stable identifier from DOI, arXiv ID, URL hash, or file hash; replace unsafe characters with `_`
- pdf_asset_path = {assets_dir}/paper_{source_key}.pdf
- pdf_asset_link = [[assets/paper_{source_key}.pdf]]

### Optional - Pipeline Figure Extraction

- extract_pipeline_figure (default: true)
- max_pipeline_figures (default: 1)
- figure_keywords (default:
  ["pipeline","framework","overview","architecture","method","model","proposed",
  "system","approach","workflow","diagram",
  "框架","总体","架构","方法","流程","系统","概览"])
- figure_output_dir (default: assets_dir)
- figure_raster_dpi (default: 250)
- figure_min_width_px (default: 800)

## 1) Normalize PDF Source -> source_key

For local PDFs:

- Resolve the path to an absolute path.
- Verify that it exists and has a `.pdf` extension or PDF header.
- source_kind = `local_pdf`
- source_url = empty unless user also provides one.
- source_pdf = original absolute path.
- source_key = DOI/arXiv ID if discovered in the PDF, otherwise filename stem plus short file hash.

For PDF URLs:

- Follow redirects and record the final URL.
- Confirm the response is PDF-like by content type, extension, or PDF header.
- source_kind = `pdf_url`
- source_url = final URL.
- source_pdf = final URL.
- source_key = DOI/arXiv ID if discovered, otherwise URL filename stem plus short URL/content hash.

If the source is an arXiv PDF URL, this skill may proceed only when the user specifically asked for PDF-only handling. Otherwise use `read-paper`.

## 2) Acquire PDF with cache and asset copy

PDF cache:

- For URL inputs, download to:
  - ~/.cache/papers/pdf/{source_key}.pdf
- Reuse cache if present unless `refresh_assets=true`.
- Prefer `curl -L` or another redirect-aware downloader.

Asset copy:

- Ensure `assets_dir` exists.
- Copy the cached or local PDF into `pdf_asset_path`.
- If `pdf_asset_path` already exists, reuse it unless `refresh_assets=true`.
- Record `pdf_asset_link` for the Obsidian note frontmatter.

## 3) Extract PDF text and metadata

Prefer structured PDF extraction over ad hoc screenshots.

Recommended extraction order:

1. Metadata:
   - PDF document metadata (`Title`, `Author`, creation date)
   - first page title/authors/affiliations
   - DOI, arXiv ID, conference/journal labels, code URLs, project URLs
2. Text:
   - `pdftotext -layout` when available
   - PyMuPDF, pdfplumber, or another PDF parser when helpful
   - preserve page numbers for evidence and figure/table references
3. OCR fallback:
   - If pages have little or no embedded text, try OCR only if tools are available.
   - If OCR is unavailable or poor, state the limitation in the note and final response.

Capture:

- problem statement and motivation
- key contributions
- method details (architecture, objectives, training, inference, data, compute)
- evaluation setup (datasets, metrics, baselines)
- key results, ablations, limitations, and open questions

## 4) Section-aware PDF reading

Use headings and page structure to recover the paper outline:

- Title / Abstract
- Introduction
- Related Work / Background
- Method / Approach / Framework / Model
- Experiments / Evaluation
- Ablation / Analysis
- Limitations / Discussion
- Conclusion
- References / Appendix

If two-column extraction interleaves text, retry with a layout-aware tool or page-by-page parsing. When extraction remains ambiguous, quote or paraphrase only what can be confidently attributed to the PDF and include page references in prose notes.

## 5) Extract "relevant data" into Markdown tables

### 5.1 Identify candidate tables in PDF

- Search extracted text for table captions (`Table 1`, `Tab.`, `表`) and nearby rows.
- Try PDF table extraction with pdfplumber, Camelot, Tabula, or equivalent tools if available.
- For image-based or complex tables, render the table page and manually transcribe only values that are legible.
- Preserve table captions and page numbers when available.
- If conversion fails, include a short note such as "PDF table extraction was unreliable; values below are manually reconstructed from page N" or omit the table if values are not reliable.

### 5.2 Normalize experiment info into paper-style tables

Create these tables if information exists:

1. Datasets / Benchmarks
   | Dataset | Task | Split | Metric(s) | Notes |
2. Main Results
   Prefer a 2D paper-style matrix over one-dimensional rows:
   | Method | Model / Setting | Dataset A acc. (%) | Dataset B acc. (%) | Dataset C metric |
   | --- | --- | ---: | ---: | ---: |
   | Baseline | ... | 12.3 | 45.6 | 78.9 |
   | ProposedMethod | ... | **13.4** | **47.0** | **80.1** |
   - Rows should be methods, model variants, or ablation settings.
   - Columns should be datasets, benchmarks, or dataset-metric pairs.
   - Preserve useful columns such as model size, base model, frame length, training setting, or inference budget before metric columns when reported.
   - If the paper groups rows, preserve the grouping with a short italic separator row or a note immediately above the table.
   - Bold the reported numeric results for the paper's proposed method / experimental method row(s). Also bold the method name if the source table emphasizes it.
   - Do not bold unrelated baselines, section labels, missing values, or invented best scores.
   - Use `Dataset | Metric | Baseline | Ours | Delta` only when the paper reports a single dataset/metric and there is no meaningful method-by-dataset matrix to reconstruct.
3. Ablations / Analysis (if present)
   Use the same 2D style:
   | Variant / Setting | Dataset A metric | Dataset B metric | Notes |
   | --- | ---: | ---: | --- |
   Bold only the full/proposed method row's reported numeric results, not every local maximum unless the paper itself marks those values.
4. Training / Compute (if reported)
   | Item | Value |

## 6) Extract pipeline/framework figure from PDF

Goal: locate the paper's main "pipeline/framework/overview" figure from the PDF.

1. Find candidate captions:
   - Search PDF text for `Figure`, `Fig.`, `图`, and `figure_keywords`.
   - Score captions by keyword matches and proximity to method/approach sections.
   - Penalize captions that clearly describe datasets, qualitative examples, attention maps, or unrelated results unless they also match pipeline keywords.
2. Find candidate pages:
   - Use caption page numbers when available.
   - If caption extraction fails, scan early method pages and pages with large diagrams.
3. Extract or render:
   - Prefer extracting the embedded image if it is clearly the pipeline figure and has width >= `figure_min_width_px`.
   - Otherwise render the likely page or crop the figure region if a reliable crop can be made.
   - Save as `{figure_output_dir}/pipeline_{source_key}.png`; if target exists, add suffix `_2`, `_3`, etc.
4. Record metadata:
   - figure_path relative to note, e.g. `assets/pipeline_{source_key}.png`
   - figure_caption best-effort
   - figure_source, e.g. `PDF page 4 render`, `PDF embedded image`, or `PDF cropped figure`
   - cover as `[[assets/pipeline_{source_key}.png]]` only when the figure is reliable

Do not claim a rendered page is the pipeline figure unless caption/keywords strongly indicate it. If only a whole-page render is available, explicitly say it is a page render.

## 7) Write Obsidian note with YAML frontmatter

**Write/update EXACTLY `note_path`** (derived above).
Default behavior: **full rewrite** for stability.

Optional preservation rule:

- If the existing note contains:
  - `<!-- USER_NOTES_START -->` ... `<!-- USER_NOTES_END -->`
    preserve that block verbatim when rewriting; otherwise overwrite everything.

### Output language style

- The generated Markdown note body MUST be primarily Chinese.
- Preserve key English terms when they are the paper's own terminology or common technical names, including model names, method names, dataset names, benchmark names, metric names, loss/objective names, module names, code identifiers, and field names.
- Do not translate proper nouns or widely used research terms awkwardly; use Chinese explanation around the original English term.
- Section headings MUST remain in English for consistency with existing Obsidian notes.
- Table column names may remain English for scanability; explanatory prose and notes around tables should be Chinese.
- Keep citations, BibTeX, URLs, file paths, and YAML field names in their original English form.
- Mathematical formulas MUST use Obsidian/Markdown LaTeX math delimiters, not inline code or fenced code blocks. Use `$...$` for short inline formulas inside prose, and use `$$...$$` for standalone, multi-line, or important display equations.

Frontmatter fields:

- title: "..."
- authors: ["...", "..."]
- conference: "" # conference/journal name, e.g. CVPR; leave empty if not listed
- year:
- paper_url: "" # final PDF URL or paper landing page if known
- source_pdf: "" # original local PDF path or final PDF URL
- pdf_link: "[[assets/paper_{source_key}.pdf]]"
- cover: ""
- updated: YYYY-MM-DD
- tags: ["paper/pdf"]
- status: "unread"
- priority:
- rating:
- topics: ["..."] # exactly one primary topic from the taxonomy below
- code: ""

For Obsidian Bases consistency:

- `status` should use one of: `"unread"`, `"reading"`, `"read"`, `"archived"`.
- Do not duplicate `status` or the primary `topics` value inside `tags`.
- Keep `tags` as a YAML list containing `"paper/pdf"` plus relevant secondary tags from the taxonomy below. If the PDF is an arXiv PDF processed in PDF-only mode, use `"paper/arxiv"` instead of `"paper/pdf"`.
- `priority` and `rating` should be numbers from 1 to 5, or empty if not assigned.
- `year` should be a number, not a string.
- `conference` should be a short conference/journal label such as `"CVPR"`; leave it empty if not listed.
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

Put secondary tags in YAML `tags` alongside `"paper/pdf"` or `"paper/arxiv"`. Use only tags supported by the paper, and prefer these topic-specific tags:

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

Do not add separate YAML fields for the pipeline figure path, caption, or source. Put those details in the `Pipeline Figure` body section only.

Body sections (strict order):

1. TL;DR (3-6 bullets)
2. Key Contributions
3. Method (with compact pseudocode or pipeline bullets)
4. Pipeline Figure
   - If a pipeline figure exists:
     - `![[{figure_path}]]`
     - Caption: {figure_caption}
     - Source: {figure_source}
   - If no reliable pipeline figure exists, write one concise sentence explaining why.
5. Experiments
   - Datasets table
   - Main results table(s)
   - Ablations/Analysis tables (if present)
   - Mention PDF page numbers for manually reconstructed tables when useful.
6. Limitations & Caveats
7. Concrete Implementation Ideas (2-5 actionable ideas)
8. Open Questions / Follow-ups
9. Citation (BibTeX if recoverable; otherwise DOI, URL, or a concise citation line)

## 8) Safety and quality checks

- Do not hallucinate numbers: only include metrics that appear in the PDF or reliable metadata.
- When unsure, mark as "not reported", "unclear in PDF extraction", or omit the value.
- Keep tables faithful; avoid "cleaning" that changes meaning.
- Preserve page references for important claims when PDF extraction is fragile.
- Before finalizing the note, scan for formulas wrapped in backticks or code fences and rewrite them as `$...$` for inline formulas or `$$...$$` for display equations. Keep code fences only for actual pseudocode, BibTeX, or raw table fallback content.
- If text extraction, table extraction, OCR, or figure extraction is unreliable, state the limitation in the relevant section rather than filling gaps from guesswork.
- For pipeline figures, do not claim an image is the pipeline/framework figure unless caption/keywords strongly indicate it.
