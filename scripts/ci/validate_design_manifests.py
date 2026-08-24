#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
校验清源视觉、组件清单与 Flutter 运行时边界。
@Project : SSPU-AllinOne
@File : validate_design_manifests.py
@Author : Qintsg
@Date : 2026-08-17
"""

from __future__ import annotations

import json
import re
from pathlib import Path


VISUAL_MANIFEST_PATH = Path("docs/design/resources/visual-manifest.json")
REFERENCE_CATALOG_PATH = Path("docs/design/resources/reference-catalog.json")


class DesignSystemValidationError(ValueError):
    """清源设计契约不完整或发生漂移。"""


def validate_visual_manifest(project_root: Path) -> None:
    """
    校验五平台视觉清单、确定性采集参数与状态声明。

    :param project_root: 仓库根目录。
    :raises DesignSystemValidationError: 视觉清单缺失或发生契约漂移。
    """
    path = project_root / VISUAL_MANIFEST_PATH
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise DesignSystemValidationError(f"{VISUAL_MANIFEST_PATH} 无法解析：{error}") from error

    meta = manifest.get("meta", {})
    errors: list[str] = []
    required_platforms = {"android", "ios", "windows", "macos", "linux"}
    platforms = set(meta.get("platforms", []))
    missing_platforms = sorted(required_platforms - platforms)
    if missing_platforms:
        errors.append(f"视觉清单缺少平台：{', '.join(missing_platforms)}")
    if "web" in platforms:
        errors.append("视觉清单不得把本轮排除的 web 纳入平台矩阵")

    required_viewports = {(360, 800), (768, 900), (1200, 900), (1600, 1000)}
    viewports = {
        (item.get("width"), item.get("height"))
        for item in meta.get("viewports", [])
        if isinstance(item, dict)
    }
    if viewports != required_viewports:
        errors.append("视觉清单必须覆盖 360x800、768x900、1200x900、1600x1000")
    if set(meta.get("themes", [])) != {"light", "dark"}:
        errors.append("视觉清单必须覆盖 light 与 dark")
    if meta.get("reviewMode") != "manual-per-screen":
        errors.append("视觉清单必须使用逐屏人工评审模式")
    legacy_thresholds = {"applicationThreshold", "externalThreshold"} & set(meta)
    if legacy_thresholds:
        errors.append("视觉清单不得保留 SSIM 阈值")
    required_interaction_checks = {
        "single-flight",
        "stale-result-isolation",
        "system-back",
        "cancel",
        "context-preservation",
        "inline-retry",
        "external-failure",
    }
    if set(meta.get("interactionChecks", [])) != required_interaction_checks:
        errors.append(
            "视觉清单交互验收必须覆盖单飞、旧结果隔离、系统返回、取消、上下文保留、原地重试与外部失败"
        )
    capture = meta.get("capture", {})
    required_capture = {
        "locale": "zh_CN",
        "timezone": "Asia/Shanghai",
        "clock": "2026-07-18T09:30:00+08:00",
        "font": "MiSans",
        "animations": "disabled",
        "fixture": "qingyuan-sanitized-v1",
        "filePattern": "<surface>--<state>--<theme>--<width>x<height>.png",
    }
    if not isinstance(capture, dict) or any(
        capture.get(key) != value for key, value in required_capture.items()
    ):
        errors.append("视觉清单必须锁定 Locale、时区、时钟、MiSans、动画、脱敏 fixture 与文件命名")

    surfaces = manifest.get("surfaces", [])
    surface_ids = [item.get("id") for item in surfaces if isinstance(item, dict)]
    duplicates = sorted({surface_id for surface_id in surface_ids if surface_ids.count(surface_id) > 1})
    if duplicates:
        errors.append(f"视觉清单存在重复界面：{', '.join(duplicates)}")
    required_groups = {
        "global",
        "home",
        "academic",
        "schedule",
        "info",
        "mail",
        "links",
        "settings",
        "legal",
        "external",
    }
    groups = {item.get("group") for item in surfaces if isinstance(item, dict)}
    missing_groups = sorted(required_groups - groups)
    if missing_groups:
        errors.append(f"视觉清单缺少界面分组：{', '.join(missing_groups)}")
    required_states = {"initial", "loading", "content", "empty", "stale", "error"}
    declared_states = set(meta.get("states", []))
    if declared_states != required_states:
        errors.append("视觉清单必须声明统一六态")
    scenario_states = meta.get("scenarioStates", [])
    if (
        not isinstance(scenario_states, list)
        or any(not isinstance(state, str) or not state for state in scenario_states)
        or len(set(scenario_states)) != len(scenario_states)
        or set(scenario_states) & required_states
    ):
        errors.append("视觉清单场景态必须是不重复且不与统一六态冲突的名称")
        declared_scenario_states: set[str] = set()
    else:
        declared_scenario_states = set(scenario_states)
    allowed_states = required_states | declared_scenario_states
    for surface in surfaces:
        if not isinstance(surface, dict):
            errors.append("视觉清单界面条目必须是对象")
            continue
        states = set(surface.get("states", []))
        if not states or not states <= allowed_states:
            errors.append(f"视觉清单界面 {surface.get('id', '<unknown>')} 状态无效")
        external_regions = set(surface.get("externalRegions", []))
        external_region_states = surface.get("externalRegionStates", {})
        if external_regions:
            if not isinstance(external_region_states, dict) or set(external_region_states) != external_regions:
                errors.append(
                    f"视觉清单界面 {surface.get('id', '<unknown>')} 必须逐区域声明外部状态"
                )
            else:
                for region_id, region_states in external_region_states.items():
                    declared_region_states = set(region_states) if isinstance(region_states, list) else set()
                    if not declared_region_states or not declared_region_states <= states:
                        errors.append(
                            f"视觉清单界面 {surface.get('id', '<unknown>')} "
                            f"外部区域 {region_id} 状态无效"
                        )
        elif external_region_states:
            errors.append(
                f"视觉清单界面 {surface.get('id', '<unknown>')} 未声明外部区域却配置了状态"
            )

    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def validate_reference_catalog(project_root: Path) -> None:
    """
    校验全状态参考目录与视觉清单的一致性。

    :param project_root: 仓库根目录。
    :raises DesignSystemValidationError: 参考目录缺失或与清单不一致。
    """
    manifest_path = project_root / VISUAL_MANIFEST_PATH
    catalog_path = project_root / REFERENCE_CATALOG_PATH
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise DesignSystemValidationError(f"{REFERENCE_CATALOG_PATH} 无法解析：{error}") from error

    manifest_surfaces = {
        item["id"]: set(item["states"])
        for item in manifest.get("surfaces", [])
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    }
    entries = catalog.get("surfaces", [])
    catalog_ids = [item.get("id") for item in entries if isinstance(item, dict)]
    errors: list[str] = []
    if catalog.get("meta", {}).get("visualManifest") != manifest.get("meta", {}).get("version"):
        errors.append("全状态参考目录必须绑定当前 visual-manifest 版本")
    duplicates = sorted({surface_id for surface_id in catalog_ids if catalog_ids.count(surface_id) > 1})
    if duplicates:
        errors.append(f"全状态参考目录存在重复界面：{', '.join(duplicates)}")
    missing = sorted(set(manifest_surfaces) - set(catalog_ids))
    unexpected = sorted(set(catalog_ids) - set(manifest_surfaces))
    if missing:
        errors.append(f"全状态参考目录缺少界面：{', '.join(missing)}")
    if unexpected:
        errors.append(f"全状态参考目录包含清单外界面：{', '.join(unexpected)}")

    required_text = ("title", "kicker", "summary", "source", "primaryAction")
    for entry in entries:
        if not isinstance(entry, dict):
            errors.append("全状态参考目录条目必须是对象")
            continue
        surface_id = entry.get("id")
        if surface_id not in manifest_surfaces:
            continue
        for field in required_text:
            if not isinstance(entry.get(field), str) or not entry[field].strip():
                errors.append(f"全状态参考 {surface_id} 缺少 {field}")
        states = set(entry.get("states", []))
        if states != manifest_surfaces[surface_id]:
            errors.append(f"全状态参考 {surface_id} 与视觉清单状态不一致")
        items = entry.get("items")
        if not isinstance(items, list) or len(items) < 3 or any(
            not isinstance(item, str) or not item for item in items
        ):
            errors.append(f"全状态参考 {surface_id} 必须提供至少三项确定性内容")

    reference_files = (
        Path("docs/design/patterns/samples/state-reference.html"),
        Path("docs/design/patterns/samples/_state-reference.css"),
        Path("docs/design/patterns/samples/_settings-dialog-reference.js"),
        Path("docs/design/patterns/samples/_wechat-login-reference.js"),
        Path("docs/design/patterns/samples/_modal-reference.js"),
        Path("docs/design/patterns/samples/_state-reference.js"),
    )
    for relative in reference_files:
        if not (project_root / relative).exists():
            errors.append(f"全状态参考缺少渲染资源：{relative}")
    reference_html_path = project_root / reference_files[0]
    if reference_html_path.exists():
        reference_html = reference_html_path.read_text(encoding="utf-8")
        loaded_scripts = re.findall(
            r"<script\s+[^>]*src=['\"]([^'\"]+)['\"]",
            reference_html,
            re.IGNORECASE,
        )
        required_script_order = (
            "_component-reference.js",
            "_student-report-rules-reference.js",
            "_settings-dialog-reference.js",
            "_wechat-login-reference.js",
            "_modal-reference.js",
            "_state-reference.js",
        )
        missing_scripts = [
            script for script in required_script_order if script not in loaded_scripts
        ]
        if missing_scripts:
            errors.append(
                "全状态参考脚本未进入加载链：" + ", ".join(missing_scripts)
            )
        elif [loaded_scripts.index(script) for script in required_script_order] != sorted(
            loaded_scripts.index(script) for script in required_script_order
        ):
            errors.append("全状态参考脚本加载顺序必须先声明领域渲染器，再启动主渲染器")
    reference_css_path = project_root / reference_files[1]
    if reference_css_path.exists():
        reference_css = reference_css_path.read_text(encoding="utf-8")
        if re.search(r"#[0-9A-Fa-f]{3,8}\b", reference_css):
            errors.append(f"{reference_files[1]} 包含裸颜色值，应复用清源 token")
        if "prefers-reduced-motion: reduce" not in reference_css:
            errors.append(f"{reference_files[1]} 缺少减少动态适配")
    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def validate_qingyuan_runtime(project_root: Path) -> None:
    """
    校验纯清源运行时依赖、公共门面与 token 边界。

    :param project_root: 仓库根目录。
    :raises DesignSystemValidationError: 运行时代码绕过清源边界。
    """
    runtime = project_root / "lib"
    if not runtime.exists():
        return
    errors: list[str] = []
    for source_path in runtime.rglob("*.dart"):
        relative = source_path.relative_to(project_root).as_posix()
        source = source_path.read_text(encoding="utf-8")
        if not relative.startswith("lib/design/qingyuan/"):
            for imported in re.findall(
                r"^\s*import\s+['\"]([^'\"]+)['\"]",
                source,
                re.MULTILINE,
            ):
                if (
                    "design/qingyuan/" in imported
                    and not imported.endswith("design/qingyuan/qingyuan_ui.dart")
                ):
                    errors.append(
                        f"{relative} 绕过 qingyuan_ui.dart 直接导入清源内部实现 {imported}"
                    )
        forbidden_imports = {
            "package:flutter/material.dart": "Material",
            "package:flutter/cupertino.dart": "Cupertino",
            "package:fluent_ui/fluent_ui.dart": "Fluent",
        }
        for import_path, family in forbidden_imports.items():
            if import_path in source:
                errors.append(f"{relative} 直接导入 {family} 成品视觉库")
        if re.search(r"\bIcons\.", source):
            errors.append(f"{relative} 直接使用 Material Icons.*")
        if (
            "package:fluentui_system_icons/fluentui_system_icons.dart" in source
            and relative != "lib/design/qingyuan/icons/yh_icons.dart"
        ):
            errors.append(f"{relative} 绕过 YhIcons 直接导入底层图标包")
        if re.search(r"(?:design/fluent|theme/fluent_tokens|theme/app_theme)", source):
            errors.append(f"{relative} 仍导入旧 Fluent 设计门面")
        if relative != "lib/design/qingyuan/theme/yh_theme.dart" and re.search(
            r"\b(?:width|height|minWidth|maxWidth|minHeight|maxHeight)\s*:\s*\d+(?:\.\d+)?\b",
            source,
        ):
            errors.append(f"{relative} 存在未通过清源 token 表达的固定视觉尺寸")

    pubspec = project_root / "pubspec.yaml"
    if pubspec.exists():
        pubspec_text = pubspec.read_text(encoding="utf-8")
        if re.search(r"^\s*fluent_ui\s*:", pubspec_text, re.MULTILINE):
            errors.append("pubspec.yaml 仍依赖 fluent_ui")
        if re.search(r"^\s*uses-material-design\s*:\s*true", pubspec_text, re.MULTILINE):
            errors.append("pubspec.yaml 仍启用 Material Icons 字体")
    if errors:
        raise DesignSystemValidationError("\n".join(errors))


def validate_component_manifest(project_root: Path) -> None:
    """
    校验 44 个组件的文档、样例、实现与公共导出。

    :param project_root: 仓库根目录。
    :raises DesignSystemValidationError: 组件清单不完整或实现未公开。
    """
    manifest_path = project_root / "docs" / "design" / "resources" / "component-manifest.json"
    if not manifest_path.exists():
        raise DesignSystemValidationError("缺少清源组件机器清单 component-manifest.json")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    components = manifest.get("components", [])
    errors: list[str] = []
    if manifest.get("version") != "0.4.0":
        errors.append("组件清单 version 必须是 0.4.0")
    if len(components) != 44:
        errors.append(f"组件清单必须恰好包含 44 个组件，当前为 {len(components)}")
    ids = [component.get("id") for component in components if isinstance(component, dict)]
    classes = [component.get("class") for component in components if isinstance(component, dict)]
    if len(ids) != len(set(ids)):
        errors.append("组件清单存在重复 id")
    if len(classes) != len(set(classes)):
        errors.append("组件清单存在重复 Flutter class")

    docs_root = project_root / "docs" / "design" / "components"
    runtime_root = project_root / "lib" / "design" / "qingyuan"
    facade_path = runtime_root / "qingyuan_ui.dart"
    facade = facade_path.read_text(encoding="utf-8") if facade_path.exists() else ""
    for component in components:
        if not isinstance(component, dict):
            errors.append("组件清单条目必须是对象")
            continue
        component_id = component.get("id")
        class_name = component.get("class")
        source_name = component.get("source")
        if not all(
            isinstance(value, str) and value for value in (component_id, class_name, source_name)
        ):
            errors.append("组件清单条目必须包含非空 id、class、source")
            continue
        if not (docs_root / f"{component_id}.md").exists():
            errors.append(f"组件清单 {component_id} 缺少规格文档")
        if not (docs_root / "samples" / f"{component_id}.html").exists():
            errors.append(f"组件清单 {component_id} 缺少 HTML 样例")
        if not runtime_root.exists():
            continue
        source_path = runtime_root / source_name
        if not source_path.exists():
            errors.append(f"组件清单 {component_id} 缺少 Flutter 实现 {source_name}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if re.search(rf"\bclass\s+{re.escape(class_name)}(?:<|\s)", source) is None:
            errors.append(f"组件清单 {component_id} 未声明 {class_name}")
        export = f"export '{source_name}';"
        if export not in facade:
            errors.append(f"组件清单 {component_id} 未从 qingyuan_ui.dart 导出")
    if errors:
        raise DesignSystemValidationError("\n".join(errors))
