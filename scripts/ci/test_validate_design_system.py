#!/usr/bin/env python3
"""清源设计契约校验器的行为测试。"""

from __future__ import annotations

import json
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

    def test_css_layout_token_drift_reports_the_semantic_token(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            css_path = root / "docs" / "design" / "components" / "samples" / "_qingyuan.css"
            css_path.write_text(
                css_path.read_text(encoding="utf-8").replace(
                    "--layout-nav-rail-compact-width: 80px",
                    "--layout-nav-rail-compact-width: 88px",
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"layout\.navRailCompactWidth.*--layout-nav-rail-compact-width",
            ):
                validate_design_system(root)

    def test_css_font_family_drift_reports_the_semantic_token(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            css_path = root / "docs" / "design" / "components" / "samples" / "_qingyuan.css"
            css_path.write_text(
                css_path.read_text(encoding="utf-8").replace(
                    "--font-family-mono: 'MiSans'",
                    "--font-family-mono: 'Cascadia Mono'",
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"typography\.fontFamilyMono.*--font-family-mono",
            ):
                validate_design_system(root)

    def test_css_line_height_drift_reports_the_semantic_token(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            css_path = root / "docs" / "design" / "components" / "samples" / "_qingyuan.css"
            css_path.write_text(
                css_path.read_text(encoding="utf-8").replace(
                    "--line-height-compact: 1",
                    "--line-height-compact: 1.2",
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"typography\.lineHeight\.compact.*--line-height-compact",
            ):
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

    def test_flutter_color_token_drift_reports_theme_field(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            theme_target = root / "lib" / "design" / "qingyuan" / "theme" / "yh_theme.dart"
            theme_target.parent.mkdir(parents=True)
            shutil.copy2(PROJECT_ROOT / theme_target.relative_to(root), theme_target)
            theme_target.write_text(
                theme_target.read_text(encoding="utf-8").replace("brandStrong: Color(0xFF478384)", "brandStrong: Color(0xFF000000)", 1),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"color\.brand\.strong.*brandStrong"):
                validate_design_system(root)

    def test_flutter_scalar_token_drift_reports_theme_field(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            theme_target = root / "lib" / "design" / "qingyuan" / "theme" / "yh_theme.dart"
            theme_target.parent.mkdir(parents=True)
            shutil.copy2(PROJECT_ROOT / theme_target.relative_to(root), theme_target)
            theme_target.write_text(
                theme_target.read_text(encoding="utf-8").replace("this.m = 16", "this.m = 17", 1),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"spacing\.m.*YhSpacingTokens\.m"):
                validate_design_system(root)

    def test_material_icon_in_component_spec_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            spec = root / "docs" / "design" / "components" / "button.md"
            spec.write_text(spec.read_text(encoding="utf-8") + "\n`Icons.add`\n", encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"button\.md.*Material Icons"):
                validate_design_system(root)

    def test_page_prototype_requires_every_primary_destination(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            prototype = root / "docs" / "design" / "patterns" / "samples" / "app-shell.html"
            prototype.write_text(
                prototype.read_text(encoding="utf-8").replace('data-screen="mail"', 'data-screen="missing"', 1),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"页面原型缺少.*mail"):
                validate_design_system(root)

    def test_page_prototype_rejects_reusable_raw_spacing(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            stylesheet = root / "docs" / "design" / "patterns" / "samples" / "_app-shell.css"
            stylesheet.write_text(stylesheet.read_text(encoding="utf-8") + "\n.drift { gap: 14px; }\n", encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"页面原型.*裸间距或字号"):
                validate_design_system(root)

    def test_visual_manifest_requires_all_five_platforms(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            manifest = root / "docs" / "design" / "resources" / "visual-manifest.json"
            manifest.write_text(
                manifest.read_text(encoding="utf-8").replace('"android", ', "", 1),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"视觉清单缺少平台.*android"):
                validate_design_system(root)

    def test_visual_manifest_requires_deterministic_capture_contract(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            manifest = root / "docs" / "design" / "resources" / "visual-manifest.json"
            manifest.write_text(
                manifest.read_text(encoding="utf-8").replace('"animations": "disabled"', '"animations": "enabled"', 1),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"视觉清单必须锁定"):
                validate_design_system(root)

    def test_component_manifest_requires_all_44_flutter_components(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            manifest = root / "docs" / "design" / "resources" / "component-manifest.json"
            payload = json.loads(manifest.read_text(encoding="utf-8"))
            payload["components"].pop()
            manifest.write_text(
                json.dumps(payload, ensure_ascii=False),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"恰好包含 44 个组件"):
                validate_design_system(root)

    def test_component_manifest_rejects_missing_flutter_implementation(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            runtime = root / "lib" / "design" / "qingyuan"
            shutil.copytree(PROJECT_ROOT / "lib" / "design" / "qingyuan", runtime)
            (runtime / "components" / "yh_domain.dart").unlink()

            with self.assertRaisesRegex(DesignSystemValidationError, r"attendance-item.*缺少 Flutter 实现"):
                validate_design_system(root)

    def test_qingyuan_runtime_rejects_material_visual_imports(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            runtime = root / "lib" / "design" / "qingyuan"
            shutil.copytree(PROJECT_ROOT / "lib" / "design" / "qingyuan", runtime)
            target = runtime / "components" / "yh_button.dart"
            target.write_text(
                "import 'package:flutter/material.dart';\n" + target.read_text(encoding="utf-8"),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"yh_button\.dart.*Material"):
                validate_design_system(root)

    def test_qingyuan_runtime_rejects_direct_icon_package_imports(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            runtime = root / "lib" / "design" / "qingyuan"
            shutil.copytree(PROJECT_ROOT / "lib" / "design" / "qingyuan", runtime)
            target = runtime / "components" / "yh_button.dart"
            target.write_text(
                "import 'package:fluentui_system_icons/fluentui_system_icons.dart';\n"
                + target.read_text(encoding="utf-8"),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"yh_button\.dart.*YhIcons"):
                validate_design_system(root)

    def test_qingyuan_runtime_rejects_naked_visual_dimensions(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            runtime = root / "lib" / "design" / "qingyuan"
            shutil.copytree(PROJECT_ROOT / "lib" / "design" / "qingyuan", runtime)
            target = runtime / "components" / "yh_button.dart"
            target.write_text(
                target.read_text(encoding="utf-8") + "\nconst drift = SizedBox(width: 37);\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(DesignSystemValidationError, r"yh_button\.dart.*固定视觉尺寸"):
                validate_design_system(root)

if __name__ == "__main__":
    unittest.main()
