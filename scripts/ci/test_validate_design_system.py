#!/usr/bin/env python3
"""清源设计契约校验器的行为测试。"""

from __future__ import annotations

import shutil
import tempfile
import unittest
from pathlib import Path

from validate_design_system import DesignSystemValidationError, validate_design_system


PROJECT_ROOT = Path(__file__).resolve().parents[2]


class DesignSystemValidatorTest(unittest.TestCase):
    def test_repository_contract_is_valid(self) -> None:
        validate_design_system(PROJECT_ROOT)

    def test_css_token_drift_reports_the_semantic_token(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            css_path = root / "docs" / "design" / "components" / "samples" / "_qingyuan.css"
            css_path.write_text(
                css_path.read_text(encoding="utf-8").replace("--brand-strong: #478384", "--brand-strong: #000000", 1),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"color\.brand\.strong.*--brand-strong"):
                validate_design_system(root)

    def test_broken_relative_markdown_link_reports_source_and_target(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            readme = root / "docs" / "design" / "README.md"
            readme.write_text(readme.read_text(encoding="utf-8") + "\n[缺失](./missing.md)\n", encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"docs.design.README\.md.*missing\.md"):
                validate_design_system(root)

    def test_missing_component_sample_reports_component_name(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            (root / "docs" / "design" / "components" / "samples" / "button.html").unlink()

            with self.assertRaisesRegex(DesignSystemValidationError, r"button.*HTML 样例"):
                validate_design_system(root)

    def test_incomplete_component_spec_reports_missing_section(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            spec = root / "docs" / "design" / "components" / "button.md"
            spec.write_text(spec.read_text(encoding="utf-8").replace("## Token 映射", "## 令牌", 1), encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"button.*Token 映射"):
                validate_design_system(root)

if __name__ == "__main__":
    unittest.main()
