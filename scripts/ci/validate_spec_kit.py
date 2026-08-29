#!/usr/bin/env python
# -*- coding: UTF-8 -*-
'''
校验 GitHub Spec Kit 项目基础设施与规格资产。
@Project : SSPU-AllinOne
@File : validate_spec_kit.py
@Author : Qintsg
@Date : 2026-08-30
'''

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


REQUIRED_FILES = (
    ".specify/integration.json",
    ".specify/workflows/workflow-registry.json",
    ".specify/workflows/speckit/workflow.yml",
    ".specify/memory/constitution.md",
    ".specify/templates/constitution-template.md",
    ".specify/templates/spec-template.md",
    ".specify/templates/plan-template.md",
    ".specify/templates/tasks-template.md",
)


def load_json(path: Path) -> dict[str, object]:
    """
    读取并解析 JSON 文件。

    :param path: JSON 文件路径。
    :returns: 解析后的对象。
    :raises ValueError: 文件内容不是 JSON 对象时抛出。
    """
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path} 必须是 JSON 对象")
    return value


def validate_constitution(path: Path) -> list[str]:
    """
    校验项目宪章已完成初始化且包含可追踪版本信息。

    :param path: 宪章路径。
    :returns: 校验错误列表。
    """
    content = path.read_text(encoding="utf-8")
    errors: list[str] = []
    if re.search(r"\[[A-Z][A-Z0-9_]+\]", content):
        errors.append(f"{path} 仍包含未替换的 Spec Kit 占位符")
    if re.search(r"\bTODO\([A-Z][A-Z0-9_]+\)", content):
        errors.append(f"{path} 仍包含未处理的 TODO 占位符")
    if re.search(r"\*\*Version\*\*: \d+\.\d+\.\d+", content) is None:
        errors.append(f"{path} 缺少语义化版本号")
    return errors


def validate_project(root: Path) -> list[str]:
    """
    校验 Spec Kit 所需文件、Codex 集成和工作流注册信息。

    :param root: 仓库根目录。
    :returns: 校验错误列表。
    """
    errors: list[str] = []
    for relative_path in REQUIRED_FILES:
        if not (root / relative_path).is_file():
            errors.append(f"缺少必需文件：{relative_path}")

    if errors:
        return errors

    try:
        integration = load_json(root / ".specify/integration.json")
        if integration.get("integration") != "codex":
            errors.append(".specify/integration.json 必须声明 codex 集成")

        registry = load_json(root / ".specify/workflows/workflow-registry.json")
        workflows = registry.get("workflows")
        if not isinstance(workflows, dict) or "speckit" not in workflows:
            errors.append("工作流注册表缺少 speckit 工作流")
    except (OSError, ValueError, json.JSONDecodeError) as error:
        errors.append(f"Spec Kit JSON 配置无效：{error}")

    errors.extend(validate_constitution(root / ".specify/memory/constitution.md"))
    if not list((root / ".agents/skills").glob("speckit-*/SKILL.md")):
        errors.append("缺少 Codex 的 speckit 技能文件")
    return errors


def main() -> int:
    """
    执行仓库级 Spec Kit 校验并输出结果。

    :returns: 成功时返回 0，否则返回 1。
    """
    root = Path(__file__).resolve().parents[2]
    errors = validate_project(root)
    if errors:
        for error in errors:
            print(f"::error::{error}", file=sys.stderr)
        return 1
    print("Spec Kit structure and constitution validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
