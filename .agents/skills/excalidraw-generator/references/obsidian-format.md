# Obsidian Excalidraw format contract

Constraints verified against **obsidian-excalidraw-plugin v2.27.3** (the version
installed in the local vault). `save_obsidian_md()` already satisfies all of
them — do not hand-write the markdown wrapper.

## File skeleton

```
---

excalidraw-plugin: parsed
tags: [excalidraw]

---
==⚠  Switch to EXCALIDRAW VIEW in the MORE OPTIONS menu of this document. ⚠==

# Excalidraw Data

## Text Elements
label one ^e0000002

label two ^e0000004

## Element Links
e0000005: https://example.com

## Embedded Files
e0000006: $$E = mc^2$$

%%
## Drawing
```json
{ "type": "excalidraw", ... }
```
%%
```

## Rules

1. **Frontmatter key presence decides the view.** `fileShouldDefaultAsExcalidraw()`
   only checks that `excalidraw-plugin` is truthy (plus no
   `excalidraw-open-as-markdown`). Use the plugin default `parsed`; `raw`
   switches the plugin's text-element parsing mode, `locked` opens read-only.
2. **Element ids must be 8 chars** (`uid()` → `e0000001`). The loader maps the
   Text Elements section with `/\s\^(.{8})[\n]+/g` and Element Links with
   `^(.{8}):`. Ids longer than 8 chars get rewritten to a nanoid on load, which
   invalidates external `#^id` references; shorter ids are silently ignored.
3. **Every text element is followed by a blank line**: `text ^id\n\n`.
   The loader advances by a fixed 12 chars (`" ^id\n\n"`), so a single newline
   shifts the offset and the next element's text is parsed as empty.
4. **Multi-line labels are fine** (`Line1\nLine2 ^id`) — the id ends the
   paragraph and Obsidian treats the whole paragraph as the block.
5. **`## Drawing` must live inside a `%%` comment** and use a ```json fence
   (uncompressed). `DRAWING_REG` also accepts ```compressed-json```.
6. **Relative section order** is `# Excalidraw Data` → `## Text Elements` →
   `## Element Links` → `## Embedded Files` → `%%` → `## Drawing` → `%%`.
7. **LaTeX equations** are `fileId: $$latex$$` under `## Embedded Files`
   (loader regex `([\w\d]*):\s*\$\$([\s\S]*?)(\$\$\s*\n)`). `formula()` stores the
   source in `_latex`; both save functions strip it from the JSON.
8. **Don't lint the file.** The plugin explicitly warns that auto-formatting can
   corrupt Excalidraw Data (an empty line after `## Text Elements` breaks the
   first text element).

## Element-level notes

- Missing `index` / `frameId` are repaired on load
  (`restoreElements(..., {refreshDimensions, repairBindings})` +
  `syncInvalidIndices`), and text dimensions are recomputed from font metrics.
- Container-bound text uses `containerId` on the text plus
  `boundElements: [{id, type: "text"}]` on the container — `labeled_rect()` and
  `auto_labeled_rect()` do this.
- Arrows need `startBinding` / `endBinding` with
  `{elementId, focus, gap, fixedPoint}` — use `connect()` / `bind_arrow()`.
- Base64 images live in the scene-level `files` dict (`image_embed()`); no
  `## Embedded Files` entry is needed for them to render.
