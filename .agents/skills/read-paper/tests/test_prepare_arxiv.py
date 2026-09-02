#!/usr/bin/env python3

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "prepare_arxiv.py"
SPEC = importlib.util.spec_from_file_location("prepare_arxiv", SCRIPT)
assert SPEC and SPEC.loader
prepare_arxiv = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(prepare_arxiv)


class TitleParsingTests(unittest.TestCase):
    def test_layout_commands_footnote_and_linebreak_are_removed(self) -> None:
        raw = (
            r"\vspace{-1cm}Large Language Monkeys"
            r"\footnotetext{Title inspired by \url{https://example.com}.}: "
            r"Scaling Inference Compute \\with Repeated Sampling"
        )
        self.assertEqual(
            prepare_arxiv.plain_tex(raw),
            "Large Language Monkeys: Scaling Inference Compute with Repeated Sampling",
        )

    def test_text_formatting_is_preserved_but_title_notes_are_removed(self) -> None:
        raw = r"\textbf{Useful} \emph{Title}\thanks{Equal contribution}"
        self.assertEqual(prepare_arxiv.plain_tex(raw), "Useful Title")

    def test_obsidian_title_is_human_readable_and_cross_platform_safe(self) -> None:
        title = "Large Language Monkeys: Scaling Inference Compute with Repeated Sampling"
        self.assertEqual(
            prepare_arxiv.obsidian_title(title, "fallback"),
            "Large Language Monkeys - Scaling Inference Compute with Repeated Sampling",
        )
        forbidden = r'\/:*?"<>|[]#^'
        self.assertFalse(
            any(
                character in prepare_arxiv.obsidian_title(forbidden, "fallback")
                for character in forbidden
            )
        )

    def test_windows_reserved_basename_is_avoided(self) -> None:
        self.assertEqual(prepare_arxiv.obsidian_title("CON", "fallback"), "CON - paper")


class OutputPathTests(unittest.TestCase):
    def test_default_directory_is_exact_safe_title_without_arxiv_suffix(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output_dir = Path(temporary)
            selected = prepare_arxiv.select_paper_dir(
                output_dir, "Readable Paper Title", "2407.21787"
            )
            self.assertEqual(selected, output_dir / "Readable Paper Title")

    def test_existing_directory_is_found_by_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output_dir = Path(temporary)
            paper_dir = output_dir / "Readable Paper Title"
            paper_dir.mkdir()
            (paper_dir / ".read-paper-2407.21787.json").write_text(
                "{}", encoding="utf-8"
            )
            self.assertEqual(
                prepare_arxiv.select_paper_dir(
                    output_dir, "Changed Paper Title", "2407.21787"
                ),
                paper_dir,
            )

    def test_nonempty_same_title_directory_is_not_overwritten(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output_dir = Path(temporary)
            paper_dir = output_dir / "Readable Paper Title"
            paper_dir.mkdir()
            (paper_dir / "unrelated.md").write_text("user data", encoding="utf-8")
            with self.assertRaises(RuntimeError):
                prepare_arxiv.select_paper_dir(
                    output_dir, "Readable Paper Title", "2407.21787"
                )


if __name__ == "__main__":
    unittest.main()
