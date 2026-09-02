# Obsidian note format

Read this reference immediately before creating or updating the note.

## Safe update contract

Write exactly the manifest `note_path` and nowhere else.

New notes must contain:

```markdown
<!-- READ_PAPER_GENERATED_START -->
...generated body...
<!-- READ_PAPER_GENERATED_END -->

<!-- USER_NOTES_START -->
<!-- USER_NOTES_END -->
```

On rerun, replace only the generated block. Preserve the user-notes block verbatim. Preserve unknown YAML keys and the existing values of `status`, `priority`, and `rating`. Update only paper-derived metadata and skill-managed links. If a non-empty note lacks managed markers, stop for user direction instead of overwriting it.

## Frontmatter

Use YAML frontmatter with these keys:

```yaml
title: "..."
authors: ["...", "..."]
conference: ""
year: 2026
arxiv_url: "https://arxiv.org/abs/..."
pdf_link: "[[assets/paper_{safe_base_id}.pdf]]"
cover: ""
updated: 2026-01-31
tags: ["paper/arxiv"]
status: "unread"
priority:
rating:
topics: ["LLM"]
code: ""
```

Rules:

- `year` is numeric; `priority` and `rating` are empty or integers 1–5.
- `status` is one of `unread`, `reading`, `read`, or `archived`; preserve it on updates.
- `conference` is a short venue label only when supported by the paper or arXiv metadata.
- `pdf_link` points to the local PDF asset; `cover` points to the verified pipeline image or remains empty.
- `tags` always contains `paper/arxiv` plus only paper-supported secondary tags. Do not use video-specific tags as defaults.
- `topics` contains exactly one dominant ML/AI topic from the taxonomy below.
- `code` contains a directly supported project/repository URL or remains empty.

Primary topics:

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

Preferred secondary tags:

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

## Body

The body is primarily Chinese. Preserve original English model, method, dataset, benchmark, metric, loss, module, and code names. Use English headings in this order; omit a conditional section instead of leaving it empty:

1. `## TL;DR` — 3–6 bullets
2. `## Key Contributions`
3. `## Method`
4. `## Pipeline Figure` — only when verified
5. `## Experiments`
6. `## Limitations & Caveats`
7. `## Concrete Implementation Ideas` — only when genuinely useful
8. `## Open Questions / Follow-ups`
9. `## Citation`

Embed assets with Obsidian links, for example:

```markdown
![[assets/pipeline_XXXX.XXXXX.png]]
```

Do not show PDF page numbers, TeX paths, labels, export paths, crop methods, or DPI in visible prose. A pipeline caption may be repeated beneath the figure; do not repeat a table caption already contained in its crop.

Use `$...$` for inline mathematics and `$$...$$` for display mathematics. Never wrap formulas in backticks or code fences. Code fences are reserved for code, compact pseudocode, BibTeX, or raw LaTeX needed for implementation.

## Content quality

- Explain the problem, mechanism, assumptions, and evidence rather than paraphrasing the abstract section by section.
- Separate author claims, quoted prior work, and your synthesis.
- Include limitations stated by the authors and additional caveats only when logically supported by the paper.
- Implementation ideas must be concrete, paper-grounded, and conditional where evidence is incomplete.
- The note must remain useful without opening the paper, while screenshots retain exact experimental presentation.
