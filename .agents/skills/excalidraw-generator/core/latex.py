"""
LaTeX formula rendering for Excalidraw diagrams.

Converts LaTeX math expressions to Excalidraw elements via:
  1. matplotlib mathtext → PNG base64 → image_embed (fast path)
  2. Fallback: matplotlib usetex + amsmath → PNG (full LaTeX support)
  3. Final fallback: monospace text if rendering fails

Strategy rationale: matplotlib's mathtext supports most common LaTeX math
syntax (fractions, integrals, sums, Greek letters) but not environments
like \begin{pmatrix}. When mathtext fails, we fall back to usetex which
delegates to a system LaTeX installation with amsmath loaded.

Font selection (mathtext mode only):
  - "stix"        STIX — professional/academic style, clean
  - "cm"          Computer Modern — classic LaTeX look
  - "dejavusans"  DejaVu Sans — modern, bold
  - "dejavuserif" DejaVu Serif — serif style, slim

Note: usetex mode uses LaTeX's default Computer Modern fonts, ignoring
the fontset parameter.

Change the default globally:
  import core.latex
  core.latex.DEFAULT_FONTSET = "stix"
"""

import io
import os
import base64
import shutil
import struct
import subprocess
import tempfile
from typing import List, Optional, Tuple

from . import engine

# Default mathtext fontset. Supported: "stix", "cm", "dejavusans", "dejavuserif"
DEFAULT_FONTSET = "dejavusans"

# Default rendering DPI. Higher = sharper but larger file size.
# For export to PNG images, use dpi=300 or set scale=2.0 in formula().
DEFAULT_DPI = 300

# When True, a real LaTeX installation (pdflatex + pdftocairo) is tried first.
# It is more faithful than matplotlib mathtext (amssymb, \top, \dfrac, colors)
# and is the only working path when matplotlib is not installed.
PREFER_PDFLATEX = True

# Directories searched for pdflatex / pdftocairo when they are not on PATH.
TEX_TOOL_DIRS = (
    "/Library/TeX/texbin",  # macOS MacTeX
    "/usr/local/bin",
    "/opt/homebrew/bin",
    "/usr/local/texlive/2026/bin/universal-darwin",
    "/usr/local/texlive/2025/bin/universal-darwin",
    "/usr/bin",
)

_TEX_TIMEOUT = 120


def _find_tool(name: str) -> Optional[str]:
    """Locate an executable on PATH or in the common TeX / poppler directories."""
    found = shutil.which(name)
    if found:
        return found
    for directory in TEX_TOOL_DIRS:
        candidate = os.path.join(directory, name)
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    return None


def _strip_math_delims(latex_str: str) -> str:
    """Drop surrounding $ / $$ so the expression can be re-wrapped for LaTeX."""
    expr = latex_str.strip()
    if expr.startswith("$$"):
        expr = expr[2:]
    elif expr.startswith("$"):
        expr = expr.lstrip("$")
    if expr.endswith("$$"):
        expr = expr[:-2]
    elif expr.endswith("$"):
        expr = expr.rstrip("$")
    return expr.strip()


def _png_size(path: str) -> Optional[Tuple[int, int]]:
    """Read pixel width/height from a PNG IHDR chunk."""
    try:
        with open(path, "rb") as handle:
            head = handle.read(24)
    except OSError:
        return None
    if len(head) < 24 or head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", head[16:24])


def _render_via_pdflatex(
    latex_str: str,
    font_size: int,
    dpi: int,
    color: Optional[str] = None,
) -> Optional[Tuple[str, float, float]]:
    """Render with a real LaTeX installation (pdflatex + pdftocairo).

    Returns (base64_png, width_pt, height_pt) or None when the toolchain is
    missing or the document fails to compile. Sizes are reported in PDF points
    so 1pt of typeset math maps to 1 scene unit.
    """
    pdflatex = _find_tool("pdflatex")
    pdftocairo = _find_tool("pdftocairo")
    if not pdflatex or not pdftocairo:
        return None

    expr = _strip_math_delims(latex_str)
    if not expr:
        return None

    color_line = ""
    if isinstance(color, str) and color.startswith("#") and len(color) == 7:
        color_line = "\\color[HTML]{%s}\n" % color.lstrip("#").upper()

    document = "\n".join([
        r"\documentclass[border=1pt,varwidth=7.5in]{standalone}",
        r"\usepackage{amsmath,amssymb}",
        r"\usepackage{xcolor}",
        r"\begin{document}",
        r"\fontsize{%dpt}{%dpt}\selectfont"
        % (font_size, max(font_size + 4, int(round(font_size * 1.25)))),
        color_line + "$%s$" % expr,
        r"\end{document}",
        "",
    ])

    tmp_dir = tempfile.mkdtemp(prefix="exlatex-")
    try:
        tex_path = os.path.join(tmp_dir, "formula.tex")
        with open(tex_path, "w", encoding="utf-8") as handle:
            handle.write(document)

        compile_run = subprocess.run(
            [pdflatex, "-interaction=nonstopmode", "-halt-on-error",
             "-output-directory", tmp_dir, tex_path],
            cwd=tmp_dir, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            timeout=_TEX_TIMEOUT,
        )
        pdf_path = os.path.join(tmp_dir, "formula.pdf")
        if compile_run.returncode != 0 or not os.path.exists(pdf_path):
            return None

        raster_run = subprocess.run(
            [pdftocairo, "-png", "-r", str(dpi), "-transp", "-singlefile",
             pdf_path, os.path.join(tmp_dir, "formula")],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            timeout=_TEX_TIMEOUT,
        )
        png_path = os.path.join(tmp_dir, "formula.png")
        if raster_run.returncode != 0 or not os.path.exists(png_path):
            return None

        size = _png_size(png_path)
        if not size or size[0] == 0 or size[1] == 0:
            return None
        with open(png_path, "rb") as handle:
            img_b64 = base64.b64encode(handle.read()).decode("utf-8")

        pt_per_px = 72.0 / float(dpi)
        return img_b64, size[0] * pt_per_px, size[1] * pt_per_px
    except Exception:
        return None
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def _render_latex_to_png_base64(
    latex_str: str,
    font_size: int = 20,
    dpi: int = 150,
    fontset: str = DEFAULT_FONTSET,
    color: Optional[str] = None,
) -> Optional[Tuple[str, float, float]]:
    """Render LaTeX to PNG base64 with transparent background.

    Strategy:
      0. pdflatex + pdftocairo (PREFER_PDFLATEX) — full LaTeX, honours color
      1. matplotlib mathtext (fast, no external deps)
      2. text.usetex via matplotlib (delegates to a LaTeX installation)

    Args:
        latex_str: LaTeX math expression.
        font_size: Font size in points.
        dpi: Rendering resolution (higher = sharper but larger).
        fontset: Mathtext fontset. One of: "stix", "cm", "dejavusans",
                 "dejavuserif".
        color: Optional "#rrggbb" glyph color (pdflatex path only).

    Returns:
        (base64_string, width_pt, height_pt) or None on failure.
    """
    expr = _strip_math_delims(latex_str)
    if not expr:
        return None

    if PREFER_PDFLATEX:
        result = _render_via_pdflatex(expr, font_size, dpi, color)
        if result is not None:
            return result

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        matplotlib.rcParams["mathtext.fontset"] = fontset

        # --- Pass 1: mathtext (fast path) ---
        result = _try_render(expr=expr, font_size=font_size, dpi=dpi,
                             use_tex=False)
        if result is not None:
            return result

        # --- Pass 2: usetex (full LaTeX + amsmath) ---
        result = _try_render(expr=expr, font_size=font_size, dpi=dpi,
                             use_tex=True)
        if result is not None:
            return result

        return None
    except Exception:
        return None


def _try_render(
    expr: str,
    font_size: int,
    dpi: int,
    use_tex: bool,
) -> Optional[Tuple[str, float, float]]:
    """Render one expression with or without usetex. Returns same tuple or None."""
    import matplotlib
    import matplotlib.pyplot as plt

    matplotlib.rcParams["text.usetex"] = use_tex
    if use_tex:
        matplotlib.rcParams["text.latex.preamble"] = r"\usepackage{amsmath}"

    fig, ax = plt.subplots(figsize=(0.01, 0.01))
    ax.set_axis_off()
    try:
        text_obj = ax.text(
            0.5, 0.5, f"${expr}$",
            transform=ax.transAxes,
            fontsize=font_size,
            ha="center", va="center",
        )
        fig.canvas.draw()

        renderer = fig.canvas.get_renderer()
        bbox = text_obj.get_window_extent(renderer)
        w, h = bbox.width, bbox.height

        buf = io.BytesIO()
        fig.savefig(
            buf, format="png", dpi=dpi,
            bbox_inches="tight", pad_inches=0.05,
            transparent=True,
        )
        buf.seek(0)
        img_data = base64.b64encode(buf.read()).decode("utf-8")
        return img_data, w, h
    except Exception:
        return None
    finally:
        plt.close(fig)


def formula(
    latex_str: str,
    x: float = 0,
    y: float = 0,
    font_size: int = 20,
    stroke: str = "#1e1e1e",
    stroke_width: int = 2,
    roughness: int = 0,
    scale: float = 1.0,
    dpi: int = DEFAULT_DPI,
    fontset: Optional[str] = None,
) -> List[dict]:
    """Render a LaTeX formula as an Excalidraw image element.

    Primary strategy: matplotlib renders to transparent PNG → embedded as
    base64 image. This preserves font glyphs, superscripts, fractions, etc.

    Args:
        latex_str: LaTeX math expression (e.g. "E = mc^2").
        x: X position.
        y: Y position.
        font_size: Font size in points.
        stroke: Stroke color (unused for images, kept for API compat).
        stroke_width: Stroke width (unused for images).
        roughness: Roughness (unused for images).
        scale: Scale factor for the rendered formula.
        dpi: Rendering resolution (higher = sharper but larger).
        fontset: Mathtext fontset. One of: "stix", "cm", "dejavusans",
                 "dejavuserif". Defaults to module-level DEFAULT_FONTSET.

    Returns:
        List with a single image element dict.
        The element has a '_files' key for save_excalidraw().
    """
    if fontset is None:
        fontset = DEFAULT_FONTSET

    result = _render_latex_to_png_base64(latex_str, font_size, dpi, fontset)
    if result is not None:
        img_b64, w, h = result
        w *= scale
        h *= scale
        el, files = engine.image_embed(x, y, w, h, img_b64, mime="image/png")
        el["_files"] = files
        # Kept for Obsidian's `## Embedded Files` section so the plugin can
        # reopen the image in its LaTeX equation editor.
        el["_latex"] = latex_str
        return [el]

    # Fallback: monospace text
    return [engine.text_standalone(
        x, y, latex_str,
        fs=font_size,
        color=stroke,
        font_family=3,  # Cascadia monospace
        roughness=roughness,
    )]
