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

    def test_page_prototype_rejects_undefined_css_variable(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            css_path = root / "docs" / "design" / "patterns" / "samples" / "_app-shell.css"
            css_path.write_text(
                css_path.read_text(encoding="utf-8").replace(
                    "--layout-app-bar-height",
                    "--layout-appbar-height",
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"未定义 CSS 自定义属性.*--layout-appbar-height",
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

    def test_mail_prototype_requires_all_inbox_states(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            prototype = root / "docs" / "design" / "patterns" / "samples" / "app-shell.html"
            prototype.write_text(
                prototype.read_text(encoding="utf-8").replace(
                    'data-mail-state-panel="empty"',
                    'data-mail-state-panel="missing-empty"',
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"邮箱原型缺少收件箱状态：empty",
            ):
                validate_design_system(root)

    def test_info_prototype_requires_all_feed_and_filter_states(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            prototype = root / "docs" / "design" / "patterns" / "samples" / "app-shell.html"
            prototype.write_text(
                prototype.read_text(encoding="utf-8").replace(
                    'data-info-state-panel="empty"',
                    'data-info-state-panel="missing-empty"',
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"资讯原型缺少信息流状态：empty",
            ):
                validate_design_system(root)

    def test_academic_prototype_requires_uncovered_coordination_states(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            prototype = root / "docs" / "design" / "patterns" / "samples" / "app-shell.html"
            prototype.write_text(
                prototype.read_text(encoding="utf-8").replace(
                    'data-academic-state-panel="credentials-required"',
                    'data-academic-state-panel="missing-credentials"',
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"教务原型缺少状态：credentials-required",
            ):
                validate_design_system(root)

    def test_academic_prototype_requires_deterministic_state_setter(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            prototype_js = root / "docs" / "design" / "patterns" / "samples" / "_app-shell.js"
            prototype_js.write_text(
                prototype_js.read_text(encoding="utf-8").replace(
                    "setAcademicState",
                    "missingAcademicState",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"页面原型缺少确定性状态接口 setAcademicState",
            ):
                validate_design_system(root)

    def test_info_prototype_requires_deterministic_state_setters(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            prototype_js = root / "docs" / "design" / "patterns" / "samples" / "_app-shell.js"
            prototype_js.write_text(
                prototype_js.read_text(encoding="utf-8").replace(
                    "setInfoFilterState",
                    "missingInfoFilterState",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"页面原型缺少确定性状态接口 setInfoFilterState",
            ):
                validate_design_system(root)

    def test_campus_card_prototype_requires_home_and_detail_states(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            prototype = root / "docs" / "design" / "patterns" / "samples" / "app-shell.html"
            prototype.write_text(
                prototype.read_text(encoding="utf-8").replace(
                    'data-campus-card-detail-state="empty"',
                    'data-campus-card-detail-state="missing-empty"',
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"校园卡详情原型缺少状态：empty",
            ):
                validate_design_system(root)

    def test_campus_card_prototype_requires_deterministic_state_setters(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            prototype_js = root / "docs" / "design" / "patterns" / "samples" / "_app-shell.js"
            prototype_js.write_text(
                prototype_js.read_text(encoding="utf-8").replace(
                    "setCampusCardDetailState",
                    "missingCampusCardDetailState",
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"页面原型缺少确定性状态接口 setCampusCardDetailState",
            ):
                validate_design_system(root)

    def test_links_prototype_requires_external_confirmation_boundary(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            prototype = root / "docs" / "design" / "patterns" / "samples" / "app-shell.html"
            prototype.write_text(
                prototype.read_text(encoding="utf-8").replace(
                    'data-screen="link-confirmation"',
                    'data-screen="missing-confirmation"',
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"快捷入口原型缺少外部网页确认页",
            ):
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

    def test_opacity_token_drift_reports_flutter_field(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            theme_target = root / "lib" / "design" / "qingyuan" / "theme" / "yh_theme.dart"
            theme_target.parent.mkdir(parents=True)
            shutil.copy2(PROJECT_ROOT / theme_target.relative_to(root), theme_target)
            theme_target.write_text(
                theme_target.read_text(encoding="utf-8").replace(
                    "this.domainTint = 0.14",
                    "this.domainTint = 0.12",
                    1,
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignSystemValidationError,
                r"opacity\.domainTint.*YhOpacityTokens\.domainTint",
            ):
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

    def test_visual_manifest_requires_per_image_090_threshold(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            manifest = root / "docs" / "design" / "resources" / "visual-manifest.json"
            payload = json.loads(manifest.read_text(encoding="utf-8"))
            payload["meta"]["applicationThreshold"] = 0.89
            manifest.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"应用自绘阈值必须为 0.90"):
                validate_design_system(root)

    def test_visual_manifest_requires_interaction_acceptance_checks(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            manifest = root / "docs" / "design" / "resources" / "visual-manifest.json"
            payload = json.loads(manifest.read_text(encoding="utf-8"))
            payload["meta"]["interactionChecks"] = ["inline-retry"]
            manifest.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"交互验收必须覆盖"):
                validate_design_system(root)

    def test_visual_manifest_scenario_states_cannot_conflict_with_six_states(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            manifest = root / "docs" / "design" / "resources" / "visual-manifest.json"
            payload = json.loads(manifest.read_text(encoding="utf-8"))
            payload["meta"]["scenarioStates"].append("error")
            manifest.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"场景态.*不与统一六态冲突"):
                validate_design_system(root)

    def test_visual_manifest_requires_external_regions_by_state(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            manifest = root / "docs" / "design" / "resources" / "visual-manifest.json"
            payload = json.loads(manifest.read_text(encoding="utf-8"))
            target = next(
                surface for surface in payload["surfaces"] if surface["id"] == "external.pdf"
            )
            target.pop("externalRegionStates")
            manifest.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"external.pdf.*逐区域声明外部状态"):
                validate_design_system(root)

    def test_reference_catalog_requires_every_visual_surface(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            catalog = root / "docs" / "design" / "resources" / "reference-catalog.json"
            payload = json.loads(catalog.read_text(encoding="utf-8"))
            payload["surfaces"] = [
                entry for entry in payload["surfaces"] if entry["id"] != "external.system-auth"
            ]
            catalog.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"全状态参考目录缺少界面.*external.system-auth"):
                validate_design_system(root)

    def test_reference_catalog_states_must_match_visual_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(PROJECT_ROOT / "docs" / "design", root / "docs" / "design")
            shutil.copy2(PROJECT_ROOT / "DESIGN.md", root / "DESIGN.md")
            catalog = root / "docs" / "design" / "resources" / "reference-catalog.json"
            payload = json.loads(catalog.read_text(encoding="utf-8"))
            target = next(entry for entry in payload["surfaces"] if entry["id"] == "mail.inbox")
            target["states"].remove("error")
            catalog.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

            with self.assertRaisesRegex(DesignSystemValidationError, r"mail.inbox.*状态不一致"):
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
