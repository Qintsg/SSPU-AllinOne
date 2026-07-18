#!/usr/bin/env python3
"""校验清源设计系统的机器真源和镜像契约。"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]
TOKENS_PATH = Path("docs/design/resources/tokens.json")
SAMPLE_CSS_PATH = Path("docs/design/components/samples/_qingyuan.css")
FLUTTER_THEME_PATH = Path("lib/design/qingyuan/theme/yh_theme.dart")
MARKDOWN_LINK_PATTERN = re.compile(r"\[[^\]]*\]\(([^)]+)\)")


class DesignSystemValidationError(ValueError):
    """清源设计契约不完整或发生漂移。"""


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
            css_name = f"{prefix}-{name.replace('xl2', '2xl')}"
            expected = f"{value:g}px"
            if light.get(css_name) != expected:
                errors.append(f"{group}.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    control_names = {"compact": "control-compact", "regular": "control-regular", "touch": "control-touch", "minimumTarget": "minimum-target"}
    focus_names = {"ringWidth": "focus-ring-width", "ringGap": "focus-ring-gap"}
    for group, names in (("control", control_names), ("focus", focus_names)):
        for name, css_name in names.items():
            expected = f"{tokens[group][name]:g}px"
            if light.get(css_name) != expected:
                errors.append(f"{group}.{name} 与 --{css_name} 漂移：期望 {expected}，实际 {light.get(css_name)}")

    for name, value in tokens["duration"].items():
        expected = f"{value:g}ms"
        if light.get(f"duration-{name}") != expected:
            errors.append(f"duration.{name} 与 --duration-{name} 漂移：期望 {expected}，实际 {light.get(f'duration-{name}')}")

    for name, value in tokens["typography"]["scale"].items():
        expected = f"{value:g}px"
        if light.get(f"type-{name}") != expected:
            errors.append(f"typography.scale.{name} 与 --type-{name} 漂移：期望 {expected}，实际 {light.get(f'type-{name}')}")

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


def validate_design_system(project_root: Path) -> None:
    """通过公开仓库目录校验清源设计契约。"""
    tokens = _load_tokens(project_root)
    if tokens.get("meta", {}).get("version") != "0.3.0":
        raise DesignSystemValidationError("tokens.json meta.version 必须是 0.3.0。")
    _validate_css_tokens(project_root, tokens)
    _validate_flutter_colors(project_root, tokens)
    _validate_component_samples(project_root)
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
