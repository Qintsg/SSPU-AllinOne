#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
校验清源设计系统的机器真源和镜像契约。
@Project : SSPU-AllinOne
@File : validate_design_system.py
@Author : Qintsg
@Date : 2026-08-14
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

from validate_design_manifests import (
    DesignSystemValidationError,
    validate_component_manifest,
    validate_qingyuan_runtime,
    validate_reference_catalog,
    validate_visual_manifest,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]
TOKENS_PATH = Path("docs/design/resources/tokens.json")
SAMPLE_CSS_PATH = Path("docs/design/components/samples/_qingyuan.css")
FLUTTER_THEME_PATH = Path("lib/design/qingyuan/theme/yh_theme.dart")
PAGE_PROTOTYPE_PATH = Path("docs/design/patterns/samples/app-shell.html")
PAGE_PROTOTYPE_CSS_PATH = Path("docs/design/patterns/samples/_app-shell.css")
HOME_PROTOTYPE_CSS_PATH = Path("docs/design/patterns/samples/_home-dashboard.css")
MARKDOWN_LINK_PATTERN = re.compile(r"\[[^\]]*\]\(([^)]+)\)")


def _load_tokens(project_root: Path) -> dict[str, Any]:
    token_path = project_root / TOKENS_PATH
    try:
        loaded = json.loads(token_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise DesignSystemValidationError(f"{TOKENS_PATH} 无法解析：{error}") from error
    if not isinstance(loaded, dict):
        raise DesignSystemValidationError(f"{TOKENS_PATH} 顶层必须是对象。")
    return loaded


def _css_declarations(css: str, selector: str) -> dict[str, str]:
    match = re.search(rf"{re.escape(selector)}\s*\{{(?P<body>.*?)\}}", css, re.DOTALL)
    if match is None:
        raise DesignSystemValidationError(f"{SAMPLE_CSS_PATH} 缺少 {selector} token 块。")
    return {
        name: " ".join(value.split())
        for name, value in re.findall(r"--([a-z0-9-]+)\s*:\s*([^;]+);", match.group("body"))
    }


def _color_css_name(group: str, name: str) -> str:
    overrides = {
        ("brand", "base"): "brand",
        ("brand", "onBrand"): "on-brand",
        ("structural", "base"): "structural",
        ("structural", "fg"): "on-structural",
        ("effect", "scrim"): "scrim",
    }
    if (group, name) in overrides:
        return overrides[(group, name)]
    kebab = re.sub(r"(?<!^)(?=[A-Z])", "-", name).lower()
    if group == "brand":
        return f"brand-{kebab}"
    return f"service-{kebab}" if group == "service" else kebab


def _validate_css_tokens(project_root: Path, tokens: dict[str, Any]) -> None:
    css = (project_root / SAMPLE_CSS_PATH).read_text(encoding="utf-8")
    light = _css_declarations(css, ":root")
    dark = _css_declarations(css, '[data-theme="dark"]')
    errors: list[str] = []

    for group, values in tokens["color"].items():
        for name, themes in values.items():
            css_name = _color_css_name(group, name)
            path = f"color.{group}.{name}"
            for theme_name, declarations in (("light", light), ("dark", dark)):
                actual = declarations.get(css_name)
                expected = themes[theme_name]
                if actual != expected:
                    errors.append(f"{path} 与 --{css_name} {theme_name} 漂移：期望 {expected}，实际 {actual}")

    numeric_groups = {
        "spacing": "space",
        "radius": "radius",
        "breakpoint": "breakpoint",
    }
    for group, prefix in numeric_groups.items():
        for name, value in tokens[group].items():
            normalized_name = name.replace("xl2", "2xl")
            kebab = re.sub(r"(?<!^)(?=[A-Z])", "-", normalized_name).lower()
            css_name = f"{prefix}-{kebab}"
            expected = f"{value:g}px"
            if light.get(css_name) != expected:
                errors.append(f"{group}.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    for name, value in tokens["opacity"].items():
        kebab = re.sub(r"(?<!^)(?=[A-Z])", "-", name).lower()
        css_name = f"opacity-{kebab}"
        expected = f"{value:g}"
        if light.get(css_name) != expected:
            errors.append(f"opacity.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    for name, value in tokens["progress"].items():
        kebab = re.sub(r"(?<!^)(?=[A-Z])", "-", name).lower()
        css_name = f"progress-{kebab}"
        expected = f"{value:g}"
        if light.get(css_name) != expected:
            errors.append(f"progress.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    for name, value in tokens["responsive"].items():
        kebab = re.sub(r"(?<!^)(?=[A-Z])", "-", name).lower()
        css_name = f"responsive-{kebab}"
        expected = (
            f"{value:g}fr"
            if name.endswith("Flex")
            else f"{value:g}vh"
            if name.endswith("HeightViewportPercent")
            else f"{value:g}vw"
        )
        if light.get(css_name) != expected:
            errors.append(f"responsive.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    for name, value in tokens["typography"]["letterSpacing"].items():
        css_name = f"letter-spacing-{name}"
        expected = f"{value:g}px"
        if light.get(css_name) != expected:
            errors.append(f"typography.letterSpacing.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    control_names = {"compact": "control-compact", "regular": "control-regular", "touch": "control-touch", "minimumTarget": "minimum-target"}
    focus_names = {"ringWidth": "focus-ring-width", "ringGap": "focus-ring-gap"}
    for group, names in (("control", control_names), ("focus", focus_names)):
        for name, css_name in names.items():
            expected = f"{tokens[group][name]:g}px"
            if light.get(css_name) != expected:
                errors.append(f"{group}.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    for name, value in tokens["layout"].items():
        kebab = re.sub(r"(?<!^)(?=[A-Z])", "-", name).lower()
        css_name = f"layout-{kebab}"
        expected = f"{value:g}px"
        if light.get(css_name) != expected:
            errors.append(f"layout.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    for name, value in tokens["duration"].items():
        expected = f"{value:g}ms"
        if light.get(f"duration-{name}") != expected:
            errors.append(f"duration.{name} 与 --duration-{name} 漂移：期望 {expected}，实际 {light.get(f'duration-{name}')}")

    pressed_scale = f"{tokens['interaction']['pressedScale']:g}"
    if light.get("pressed-scale") != pressed_scale:
        errors.append(f"interaction.pressedScale 与 --pressed-scale 漂移：期望 {pressed_scale}，实际 {light.get('pressed-scale')}")

    for name, value in tokens["typography"]["scale"].items():
        expected = f"{value:g}px"
        if light.get(f"type-{name}") != expected:
            errors.append(f"typography.scale.{name} 与 --type-{name} 漂移：期望 {expected}，实际 {light.get(f'type-{name}')}")

    for name, value in tokens["typography"]["weight"].items():
        expected = f"{value:g}"
        if light.get(f"weight-{name}") != expected:
            errors.append(f"typography.weight.{name} 与 --weight-{name} 漂移：期望 {expected}，实际 {light.get(f'weight-{name}')}")

    for name, value in tokens["typography"]["lineHeight"].items():
        expected = f"{value:g}"
        if light.get(f"line-height-{name}") != expected:
            errors.append(f"typography.lineHeight.{name} 与 --line-height-{name} 漂移：期望 {expected}，实际 {light.get(f'line-height-{name}')}")

    family_names = {
        "fontFamilyDisplay": "font-family-display",
        "fontFamilyBody": "font-family-body",
        "fontFamilyMono": "font-family-mono",
    }
    for name, css_name in family_names.items():
        expected = f"'{tokens['typography'][name]}'"
        if light.get(css_name) != expected:
            errors.append(f"typography.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    for name, value in tokens["elevation"].items():
        css_name = f"shadow-{name[1:]}"
        for theme_name, declarations in (("light", light), ("dark", dark)):
            expected = " ".join(value[theme_name].split())
            if declarations.get(css_name) != expected:
                errors.append(f"elevation.{name} 与 --{css_name} {theme_name} 漂移：期望 {expected}，实际 {declarations.get(css_name)}")

    curve = tokens["curve"]
    expected_curve = "cubic-bezier(" + ", ".join(f"{curve[key]:g}" for key in ("x1", "y1", "x2", "y2")) + ")"
    if light.get("curve") != expected_curve:
        errors.append(f"curve 与 --curve 漂移：期望 {expected_curve}，实际 {light.get('curve')}")

    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def _validate_css_variable_references(project_root: Path) -> None:
    css_paths = (
        SAMPLE_CSS_PATH,
        PAGE_PROTOTYPE_CSS_PATH,
        HOME_PROTOTYPE_CSS_PATH,
    )
    combined = "\n".join(
        (project_root / path).read_text(encoding="utf-8") for path in css_paths
    )
    definitions = set(re.findall(r"(--[a-z0-9-]+)\s*:", combined))
    references = set(re.findall(r"var\(\s*(--[a-z0-9-]+)", combined))
    # CourseBlock 通过元素内联样式为每个课程实例注入业务域颜色。
    dynamic_variables = {"--domain"}
    unresolved = sorted(references - definitions - dynamic_variables)
    if unresolved:
        raise DesignSystemValidationError(
            "页面原型引用了未定义 CSS 自定义属性：" + ", ".join(unresolved)
        )


def _validate_markdown_links(project_root: Path) -> None:
    files = [project_root / "DESIGN.md", *(project_root / "docs" / "design").rglob("*.md")]
    errors: list[str] = []
    for file_path in files:
        text = file_path.read_text(encoding="utf-8")
        for match in MARKDOWN_LINK_PATTERN.finditer(text):
            target = match.group(1).split("#", 1)[0]
            if not target or target.startswith(("http://", "https://", "mailto:")):
                continue
            if target == "./samples/component-name.html":
                continue
            resolved = (file_path.parent / target).resolve()
            if not resolved.exists():
                relative = file_path.relative_to(project_root).as_posix()
                errors.append(f"{relative} 引用了不存在的 {target}")
    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def _dart_color(value: str) -> str:
    if value.startswith("#"):
        return "FF" + value[1:].upper()
    match = re.fullmatch(r"rgba\(0,0,0,([0-9.]+)\)", value)
    if match is None:
        raise DesignSystemValidationError(f"无法转换 Flutter 颜色：{value}")
    alpha = int(float(match.group(1)) * 255 + 0.5)
    return f"{alpha:02X}000000"


def _validate_flutter_colors(project_root: Path, tokens: dict[str, Any]) -> None:
    theme_path = project_root / FLUTTER_THEME_PATH
    if not theme_path.exists():
        return
    source = theme_path.read_text(encoding="utf-8")
    blocks: dict[str, dict[str, str]] = {}
    for theme_name in ("light", "dark"):
        match = re.search(rf"static const {theme_name} = YhColorTokens\((.*?)\n  \);", source, re.DOTALL)
        if match is None:
            raise DesignSystemValidationError(f"{FLUTTER_THEME_PATH} 缺少 YhColorTokens.{theme_name}。")
        blocks[theme_name] = dict(re.findall(r"(\w+): Color\(0x([0-9A-Fa-f]{8})\)", match.group(1)))

    field_overrides = {
        ("neutral", "bg"): "background", ("neutral", "fg"): "foreground",
        ("brand", "base"): "brand", ("brand", "onBrand"): "onBrand", ("structural", "base"): "structural",
        ("structural", "fg"): "onStructural", ("status", "warn"): "warning",
        ("status", "warnTint"): "warningTint", ("service", "secondclass"): "serviceSecondClass",
        ("service", "quicklink"): "serviceQuickLink", ("effect", "scrim"): "scrim",
    }
    errors: list[str] = []
    for group, values in tokens["color"].items():
        for name, themes in values.items():
            field = field_overrides.get((group, name))
            if field is None:
                prefix = "service" if group == "service" else "brand" if group == "brand" else ""
                field = prefix + name[0].upper() + name[1:] if prefix else name
            path = f"color.{group}.{name}"
            for theme_name in ("light", "dark"):
                expected = _dart_color(themes[theme_name])
                actual = blocks[theme_name].get(field)
                if actual != expected:
                    errors.append(f"{path} 与 Flutter {field} {theme_name} 漂移：期望 {expected}，实际 {actual}")
    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def _validate_flutter_scalars(project_root: Path, tokens: dict[str, Any]) -> None:
    theme_path = project_root / FLUTTER_THEME_PATH
    if not theme_path.exists():
        return
    source = theme_path.read_text(encoding="utf-8")
    errors: list[str] = []

    groups = {
        "spacing": "YhSpacingTokens",
        "radius": "YhRadiusTokens",
        "opacity": "YhOpacityTokens",
        "progress": "YhProgressTokens",
        "breakpoint": "YhBreakpointTokens",
        "responsive": "YhResponsiveTokens",
        "control": "YhControlTokens",
        "layout": "YhLayoutTokens",
        "focus": "YhFocusTokens",
    }
    for group, class_name in groups.items():
        constructor_match = re.search(
            rf"class {class_name}\s*\{{.*?const {class_name}\(\{{(.*?)\n  \}}\);",
            source,
            re.DOTALL,
        )
        constructor = constructor_match.group(1) if constructor_match else ""
        for name, value in tokens[group].items():
            pattern = rf"this\.{re.escape(name)}\s*=\s*{re.escape(f'{value:g}')}\b"
            if re.search(pattern, constructor) is None:
                errors.append(f"{group}.{name} 与 Flutter {class_name}.{name} 漂移：期望 {value:g}")

    for name, value in tokens["duration"].items():
        pattern = rf"this\.{name}\s*=\s*const Duration\(milliseconds:\s*{value:g}\)"
        if re.search(pattern, source) is None:
            errors.append(f"duration.{name} 与 Flutter YhMotionTokens.{name} 漂移：期望 {value:g}ms")

    pressed_scale = tokens["interaction"]["pressedScale"]
    if re.search(rf"this\.pressedScale\s*=\s*{re.escape(f'{pressed_scale:g}')}\b", source) is None:
        errors.append(f"interaction.pressedScale 与 Flutter YhMotionTokens.pressedScale 漂移：期望 {pressed_scale:g}")

    curve = tokens["curve"]
    curve_values = r"\s*,\s*".join(re.escape(f"{curve[key]:g}") for key in ("x1", "y1", "x2", "y2"))
    if re.search(rf"this\.curve\s*=\s*const Cubic\({curve_values}\)", source) is None:
        errors.append("curve 与 Flutter YhMotionTokens.curve 漂移")

    typography_blocks: dict[str, str] = {}
    for name in tokens["typography"]["scale"]:
        match = re.search(rf"{name}:\s*TextStyle\((.*?)\n    \),", source, re.DOTALL)
        typography_blocks[name] = match.group(1) if match else ""

    for name, value in tokens["typography"]["scale"].items():
        if re.search(rf"fontSize:\s*{value:g},", typography_blocks[name]) is None:
            errors.append(f"typography.scale.{name} 与 Flutter YhTypographyTokens.{name} 漂移：期望 {value:g}")

    for name, value in tokens["typography"]["weight"].items():
        if re.search(rf"fontWeight:\s*FontWeight\.w{value:g},", typography_blocks[name]) is None:
            errors.append(f"typography.weight.{name} 与 Flutter YhTypographyTokens.{name} 漂移：期望 {value:g}")

    for name, value in tokens["typography"]["letterSpacing"].items():
        if re.search(rf"letterSpacing:\s*{value:g},", typography_blocks[name]) is None:
            errors.append(f"typography.letterSpacing.{name} 与 Flutter YhTypographyTokens.{name} 漂移：期望 {value:g}")

    for name, value in tokens["typography"]["lineHeight"].items():
        if name == "compact":
            if re.search(rf"compactLineHeight\s*=\s*{value:.1f}", source) is None:
                errors.append(f"typography.lineHeight.compact 与 Flutter YhTypographyTokens.compactLineHeight 漂移：期望 {value:g}")
            continue
        if re.search(rf"height:\s*{value:g},", typography_blocks[name]) is None:
            errors.append(f"typography.lineHeight.{name} 与 Flutter YhTypographyTokens.{name} 漂移：期望 {value:g}")

    family_names = {"fontFamilyDisplay": "fontFamilyDisplay", "fontFamilyBody": "fontFamilyBody", "fontFamilyMono": "fontFamilyMono"}
    for token_name, field in family_names.items():
        expected = tokens["typography"][token_name]
        if re.search(rf"{field}\s*=\s*'{re.escape(expected)}'", source) is None:
            errors.append(f"typography.{token_name} 与 Flutter {field} 漂移：期望 {expected}")

    for theme_name in ("light", "dark"):
        for token_name, shadow in tokens["elevation"].items():
            match = re.fullmatch(r"0 (\d+)px (\d+)px rgba\(0,0,0,([0-9.]+)\)", shadow[theme_name])
            if match is None:
                errors.append(f"elevation.{token_name}.{theme_name} 格式无法映射 Flutter")
                continue
            offset, blur, alpha = match.groups()
            color = f"{int(float(alpha) * 255 + 0.5):02X}000000"
            block_match = re.search(rf"static const {theme_name} = YhElevationTokens\((.*?)\n  \);", source, re.DOTALL)
            block = block_match.group(1) if block_match else ""
            shadow_pattern = rf"{token_name}:\s*\[\s*BoxShadow\(\s*color:\s*Color\(0x{color}\),\s*blurRadius:\s*{blur},\s*offset:\s*Offset\(0,\s*{offset}\)"
            if re.search(shadow_pattern, block, re.DOTALL) is None:
                errors.append(f"elevation.{token_name}.{theme_name} 与 Flutter YhElevationTokens.{token_name} 漂移")

    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def _validate_component_samples(project_root: Path) -> None:
    components = project_root / "docs" / "design" / "components"
    documents = [path for path in components.glob("*.md") if path.name not in {"README.md", "_template.md"}]
    document_names = {path.stem for path in documents}
    sample_names = {path.stem for path in (components / "samples").glob("*.html")}
    errors = [f"{name} 缺少对应 HTML 样例" for name in sorted(document_names - sample_names)]
    errors.extend(f"{name} HTML 样例缺少对应组件规格" for name in sorted(sample_names - document_names))
    required_sections = ("## 概述", "## 解剖", "## 状态", "## Token 映射", "## Flutter API", "## Do & Don't", "## 可交互样例", "## 无障碍")
    for document in documents:
        text = document.read_text(encoding="utf-8")
        for section in required_sections:
            if section not in text:
                errors.append(f"{document.stem} 组件规格缺少 {section.removeprefix('## ')}")
    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def _validate_document_contract(project_root: Path) -> None:
    design_root = project_root / "docs" / "design"
    components = design_root / "components"
    documents = [path for path in components.glob("*.md") if path.name not in {"README.md", "_template.md"}]
    errors: list[str] = []
    for document in documents:
        text = document.read_text(encoding="utf-8")
        relative = document.relative_to(project_root).as_posix()
        if re.search(r"\bIcons\.", text):
            errors.append(f"{relative} 直接引用 Material Icons.*，应使用 YhIcons 门面")
        if re.search(r"44(?:×44)?dp", text):
            errors.append(f"{relative} 仍使用 44dp 触控区，清源最小目标为 48dp")

    legacy_rules = {
        design_root / "foundations" / "color.md": "颜色单一真源",
        design_root / "foundations" / "typography.md": "w550",
    }
    for document, legacy_text in legacy_rules.items():
        if legacy_text in document.read_text(encoding="utf-8"):
            relative = document.relative_to(project_root).as_posix()
            errors.append(f"{relative} 仍包含过期契约：{legacy_text}")
    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def _validate_page_prototype(project_root: Path) -> None:
    required_documents = (
        Path("docs/design/patterns/application-map.md"),
        Path("docs/design/patterns/states-and-flows.md"),
        PAGE_PROTOTYPE_PATH,
        PAGE_PROTOTYPE_CSS_PATH,
        Path("docs/design/patterns/samples/_app-shell.js"),
    )
    if (project_root / ".git").exists():
        required_documents += (
            Path("scripts/design/verify_design_prototype.py"),
            Path("scripts/design/verify_design_prototype_core.py"),
            Path("scripts/design/verify_design_prototype_surfaces.py"),
            Path("scripts/design/README.md"),
            Path(".github/requirements/design-prototype.txt"),
        )
    errors = [f"页面设计缺少 {path.as_posix()}" for path in required_documents if not (project_root / path).exists()]
    if errors:
        raise DesignSystemValidationError("\n".join(errors))

    prototype = (project_root / PAGE_PROTOTYPE_PATH).read_text(encoding="utf-8")
    required_screens = {"home", "academic", "schedule", "info", "mail", "links", "settings"}
    screens = set(re.findall(r'data-screen="([a-z-]+)"', prototype))
    destinations = set(re.findall(r'data-page="([a-z-]+)"', prototype))
    missing_screens = sorted(required_screens - screens)
    missing_destinations = sorted(required_screens - destinations)
    if missing_screens:
        errors.append(f"页面原型缺少主页面：{', '.join(missing_screens)}")
    if missing_destinations:
        errors.append(f"页面原型缺少导航目的地：{', '.join(missing_destinations)}")

    required_mail_states = {"initial", "loading", "empty", "error"}
    mail_states = set(re.findall(r'data-mail-state-panel="([a-z-]+)"', prototype))
    missing_mail_states = sorted(required_mail_states - mail_states)
    if missing_mail_states:
        errors.append(f"邮箱原型缺少收件箱状态：{', '.join(missing_mail_states)}")
    for marker, label in (
        ("mail-stale-banner", "stale 缓存提示"),
        ("data-mail-compose-panel", "撰写面板"),
        ("mail-compose-error", "撰写错误状态"),
    ):
        if marker not in prototype:
            errors.append(f"邮箱原型缺少{label}")

    required_info_states = {"initial", "loading", "empty", "error"}
    info_states = set(re.findall(r'data-info-state-panel="([a-z-]+)"', prototype))
    missing_info_states = sorted(required_info_states - info_states)
    if missing_info_states:
        errors.append(f"资讯原型缺少信息流状态：{', '.join(missing_info_states)}")
    for marker, label in (
        ("info-stale-banner", "stale 缓存提示"),
        ('data-info-filter-panel="empty"', "筛选无结果状态"),
        ("data-info-search", "搜索入口"),
    ):
        if marker not in prototype:
            errors.append(f"资讯原型缺少{label}")

    required_campus_card_home_states = {
        "loading",
        "content",
        "empty",
        "stale",
        "error",
        "operation-locked",
    }
    campus_card_home_states = set(
        re.findall(r'data-campus-card-home-state="([a-z-]+)"', prototype)
    )
    missing_campus_card_home_states = sorted(
        required_campus_card_home_states - campus_card_home_states
    )
    if missing_campus_card_home_states:
        errors.append(
            "首页校园卡原型缺少状态："
            + ", ".join(missing_campus_card_home_states)
        )
    required_home_states = {"initial", "loading", "error"}
    home_states = set(re.findall(r'data-home-state-panel="([a-z-]+)"', prototype))
    missing_home_states = sorted(required_home_states - home_states)
    if missing_home_states:
        errors.append("首页原型缺少状态：" + ", ".join(missing_home_states))
    if "home-stale-banner" not in prototype:
        errors.append("首页原型缺少 stale 缓存提示")
    required_campus_card_detail_states = {"empty", "error"}
    campus_card_detail_states = set(
        re.findall(r'data-campus-card-detail-state="([a-z-]+)"', prototype)
    )
    missing_campus_card_detail_states = sorted(
        required_campus_card_detail_states - campus_card_detail_states
    )
    if missing_campus_card_detail_states:
        errors.append(
            "校园卡详情原型缺少状态："
            + ", ".join(missing_campus_card_detail_states)
        )
    for marker, label in (
        ('data-screen="campus-card-detail"', "详情页"),
        ("data-campus-card-detail-content", "详情内容态"),
        ("data-campus-card-detail-validation", "日期筛选错误态"),
        ("data-campus-card-stale", "详情缓存态"),
        ("data-campus-card-partial-error", "详情保留式失败态"),
        ("data-campus-card-operation", "详情操作锁定态"),
        ("data-campus-card-remote-action", "详情远端只读操作"),
    ):
        if marker not in prototype:
            errors.append(f"校园卡原型缺少{label}")

    for marker, label in (
        ('data-screen="link-confirmation"', "外部网页确认页"),
        ('data-link-confirmation-state="content"', "外部确认 content 状态"),
        ('data-link-confirmation-state="error"', "外部确认认证阻断状态"),
        ("assets/config/quick_links.yaml", "快捷入口配置位置"),
    ):
        if marker not in prototype:
            errors.append(f"快捷入口原型缺少{label}")

    academic_states = set(
        re.findall(r'data-academic-state-panel="([^"]+)"', prototype)
    )
    required_academic_states = {
        "initial",
        "loading",
        "empty",
        "error",
        "credentials-required",
    }
    missing_academic_states = sorted(required_academic_states - academic_states)
    if missing_academic_states:
        errors.append("教务原型缺少状态：" + ", ".join(missing_academic_states))
    for marker, label in (
        ("academic-stale-banner", "陈旧快照提示"),
        ("academic-partial-banner", "部分失败提示"),
        ("academic-locked-banner", "协同刷新锁定提示"),
        ("data-academic-route", "详情导航互斥标记"),
    ):
        if marker not in prototype:
            errors.append(f"教务原型缺少{label}")

    for marker, label in (
        ('aria-label="显示第二课堂"', "第二课堂辅助坞开关"),
        ('aria-label="显示常用入口"', "常用入口辅助坞开关"),
        ('统一身份认证，外部链接，将打开外部应用', "首页快捷入口外链语义"),
    ):
        if marker not in prototype:
            errors.append(f"设置原型缺少{label}")

    prototype_js = (project_root / "docs/design/patterns/samples/_app-shell.js").read_text(encoding="utf-8")
    for setter in (
        "setHomeState",
        "setAcademicState",
        "setCampusCardHomeState",
        "setCampusCardDetailState",
        "setInfoState",
        "setInfoFilterState",
        "setMailState",
        "setMailComposeState",
        "setLinkConfirmationState",
    ):
        if setter not in prototype_js:
            errors.append(f"页面原型缺少确定性状态接口 {setter}")
    verifier_paths = (
        project_root / "scripts/design/verify_design_prototype.py",
        project_root / "scripts/design/verify_design_prototype_core.py",
        project_root / "scripts/design/verify_design_prototype_surfaces.py",
    )
    existing_verifier_paths = [path for path in verifier_paths if path.exists()]
    if existing_verifier_paths:
        verifier = "\n".join(path.read_text(encoding="utf-8") for path in existing_verifier_paths)
        for surface in (
            "home.dashboard",
            "home.campus-card",
            "home.campus-card-detail",
            "academic.overview",
            "info.feed",
            "info.filters",
            "mail.inbox",
            "mail.compose",
            "links.external-confirmation",
        ):
            if surface not in verifier:
                errors.append(f"浏览器核验未采集 {surface} 多状态参考稿")

    prototype_css = (project_root / PAGE_PROTOTYPE_CSS_PATH).read_text(encoding="utf-8")
    if re.search(r"#[0-9A-Fa-f]{3,8}\b", prototype_css):
        errors.append(f"{PAGE_PROTOTYPE_CSS_PATH} 包含裸颜色值，应复用清源 token")
    reusable_raw_value = re.search(
        r"(?:gap|padding(?:-(?:top|right|bottom|left))?|margin(?:-(?:top|right|bottom|left))?|font-size)\s*:[^;{}]*-?\d+(?:\.\d+)?px",
        prototype_css,
    )
    if reusable_raw_value:
        errors.append(f"页面原型包含裸间距或字号：{reusable_raw_value.group(0)}")
    if "prefers-reduced-motion: reduce" not in prototype_css:
        errors.append(f"{PAGE_PROTOTYPE_CSS_PATH} 缺少减少动态适配")
    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def validate_design_system(project_root: Path) -> None:
    """通过公开仓库目录校验清源设计契约。"""
    tokens = _load_tokens(project_root)
    if tokens.get("meta", {}).get("version") != "0.4.0":
        raise DesignSystemValidationError("tokens.json meta.version 必须是 0.4.0。")
    _validate_css_tokens(project_root, tokens)
    _validate_css_variable_references(project_root)
    _validate_flutter_colors(project_root, tokens)
    _validate_flutter_scalars(project_root, tokens)
    _validate_component_samples(project_root)
    _validate_document_contract(project_root)
    _validate_page_prototype(project_root)
    validate_visual_manifest(project_root)
    validate_reference_catalog(project_root)
    validate_component_manifest(project_root)
    validate_qingyuan_runtime(project_root)
    _validate_markdown_links(project_root)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=PROJECT_ROOT)
    args = parser.parse_args()
    try:
        validate_design_system(args.root.resolve())
    except DesignSystemValidationError as error:
        parser.exit(1, f"Design system validation failed:\n{error}\n")
    print("Qingyuan design system contract is valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
