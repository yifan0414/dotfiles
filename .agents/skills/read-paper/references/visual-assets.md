# Visual asset extraction

Read this reference only when selecting and exporting the pipeline figure or experimental tables. TeX identifies candidates; the rendered paper PDF is the truth for table appearance.

## Pipeline figure

Prefer a source asset referenced by a figure whose caption or surrounding text explicitly presents the method overview, pipeline, framework, architecture, system, or workflow.

Candidate evidence, strongest first:

1. caption and nearby prose identify it as the overall method;
2. label or filename contains a specific overview/framework term;
3. the figure visibly contains the major modules and their data/control flow.

Generic words such as “model”, image dimensions, or being Figure 1 are not sufficient by themselves. Reject qualitative examples, dataset illustrations, attention maps, and result plots unless the paper explicitly uses them as the method overview.

Resolve `\includegraphics` paths relative to the containing TeX file, then the project root, trying `.pdf`, `.png`, `.jpg`, `.jpeg`, `.svg`, and `.eps`. Prefer the original source asset. Convert vector files to a readable PNG when possible; do not embed EPS directly. For PDF figures, render the visible crop bounds rather than the full MediaBox.

If source extraction fails, locate the figure in the paper PDF and crop it. Never embed a full page as the pipeline figure. If confidence remains low, omit the figure and leave `cover` empty.

Use a stable filename such as:

```text
assets/pipeline_{safe_base_id}.png
```

## Experimental tables

Select tables that materially support the paper's conclusions:

- main benchmark comparisons;
- core ablations;
- robustness, scaling, efficiency, or error analyses central to the argument.

Skip dataset statistics, notation, prompt templates, and hyperparameter inventories unless essential to understanding the evaluation.

For each retained table:

1. use TeX to identify its number, caption, label, and document order;
2. locate the rendered table in the PDF;
3. crop the complete table, including number/caption, headers, all rows, legends, and table-specific footnotes;
4. exclude neighboring body text and unrelated figures;
5. inspect the exported image at full resolution.

After locating a page, render it once without `--bbox` for internal localization, then rerun with a pixel crop in the same DPI coordinate system:

```bash
python3 <skill-dir>/scripts/crop_pdf_region.py '<paper.pdf>' \
  --page 5 --dpi 350 --output '<work-page.png>'

python3 <skill-dir>/scripts/crop_pdf_region.py '<paper.pdf>' \
  --page 5 --dpi 350 --bbox X Y WIDTH HEIGHT \
  --min-width 1600 --output '<assets/experiment_table_safe-id_t1.png>'
```

The full-page render is only a localization aid and must not be embedded in the note.

Use lossless PNG at about 350 DPI and target at least 1600 px width when the source permits. Split multi-page or separately labeled parts into ordered images rather than shrinking them until unreadable.

Stable names:

```text
assets/experiment_table_{safe_base_id}_t{table_number}.png
assets/experiment_table_{safe_base_id}_t{table_number}_part2.png
```

Reuse a verified asset for the same paper version. When the source version changes or the user requests refresh, overwrite only the corresponding skill-managed filename; do not accumulate `_2`, `_3` duplicates.

## Experiments prose

Do not reconstruct complete result tables in Markdown. Do not calculate new deltas, average scores, or rankings. It is acceptable to state:

- evaluation setup, datasets, metrics, and baselines reported by the paper;
- exact numbers or comparisons explicitly stated by the authors, after checking the relevant text/table;
- a cautious qualitative synthesis attributed to the authors and linked to the screenshot.

## Final visual checks

- Every embedded asset exists under `assets/` and opens correctly.
- Text is readable at full size; no headers, rows, legends, captions, or footnotes are clipped.
- A table screenshot is the intended table and appears in document order.
- The note does not repeat a caption already visible inside a table crop.
- No visible extraction diagnostics, TeX paths, crop coordinates, renderer settings, or DPI are added to the note.
