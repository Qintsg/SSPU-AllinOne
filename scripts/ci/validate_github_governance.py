#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
'''
GitHub 仓库治理配置校验脚本
@Project : SSPU-AllinOne
@File : validate_github_governance.py
@Author : Qintsg
@Date : 2026-06-08 10:30
'''

from __future__ import annotations

from pathlib import Path
from typing import Any, Iterable

import yaml


PROJECT_ROOT = Path(__file__).resolve().parents[2]
GITHUB_DIR = PROJECT_ROOT / ".github"
ISSUE_TEMPLATE_DIR = GITHUB_DIR / "ISSUE_TEMPLATE"
PR_TEMPLATE_DIR = GITHUB_DIR / "PULL_REQUEST_TEMPLATE"
LABELER_PATH = GITHUB_DIR / "labeler.yml"

REQUIRED_LABELER_LABELS = {
    "frontend",
    "services",
    "models",
    "storage",
    "installer",
    "update",
    "auth",
    "notification",
    "test",
    "android",
    "ios",
    "macos",
    "linux",
    "windows",
    "web",
    "ci",
    "release-files",
    "governance",
    "documentation",
    "dependencies",
}


class GovernanceValidationError(ValueError):
    """仓库治理配置校验失败。"""


def load_yaml_file(file_path: Path) -> Any:
    """
    读取并解析 YAML 文件。

    :param file_path: YAML 文件路径。
    :return: 解析后的 YAML 对象。
    :raises GovernanceValidationError: YAML 文件为空或解析失败时抛出。
    """
    try:
        loaded = yaml.safe_load(file_path.read_text(encoding="utf-8"))
    except yaml.YAMLError as error:
        raise GovernanceValidationError(f"{file_path} YAML 解析失败：{error}") from error

    if loaded is None:
        raise GovernanceValidationError(f"{file_path} 不能为空。")

    return loaded


def iter_yaml_files() -> Iterable[Path]:
    """
    枚举需要基础 YAML 解析校验的仓库治理文件。

    :return: YAML 文件路径迭代器。
    """
    yield from sorted((GITHUB_DIR / "workflows").glob("*.yml"))
    yield from sorted(ISSUE_TEMPLATE_DIR.glob("*.yml"))
    yield from sorted((GITHUB_DIR / "actions").glob("*/action.yml"))
    yield GITHUB_DIR / "dependabot.yml"
    yield LABELER_PATH


def validate_issue_forms() -> None:
    """
    校验 Issue Forms 的字段结构。

    :return: None。
    :raises GovernanceValidationError: 表单字段 ID、选项或 label 配置异常时抛出。
    """
    for form_path in sorted(ISSUE_TEMPLATE_DIR.glob("*.yml")):
        form = load_yaml_file(form_path)
        if form_path.name == "config.yml":
            continue

        body_items = form.get("body")
        if not isinstance(body_items, list) or not body_items:
            raise GovernanceValidationError(f"{form_path} 必须包含非空 body 列表。")

        labels = form.get("labels")
        if not isinstance(labels, list) or not labels:
            raise GovernanceValidationError(f"{form_path} 必须声明至少一个默认 label。")
        if "release" in labels:
            raise GovernanceValidationError(f"{form_path} 不允许默认添加 release label。")

        seen_ids: set[str] = set()
        for index, item in enumerate(body_items, start=1):
            if not isinstance(item, dict):
                raise GovernanceValidationError(f"{form_path} 第 {index} 个 body 项必须是对象。")

            attributes = item.get("attributes", {})
            if not isinstance(attributes, dict):
                raise GovernanceValidationError(f"{form_path} 第 {index} 个 body 项 attributes 必须是对象。")

            field_id = item.get("id")
            if field_id is not None:
                if field_id in seen_ids:
                    raise GovernanceValidationError(f"{form_path} 存在重复字段 id：{field_id}")
                seen_ids.add(field_id)

            if item.get("type") in {"dropdown", "checkboxes"}:
                options = attributes.get("options")
                if not isinstance(options, list) or not options:
                    raise GovernanceValidationError(f"{form_path} 字段 {field_id or index} 缺少 options。")


def validate_pr_templates() -> None:
    """
    校验 PR 模板只保留默认通用模板与 Release 专项模板。

    :return: None。
    :raises GovernanceValidationError: 模板数量或命名不符合约束时抛出。
    """
    default_template = GITHUB_DIR / "pull_request_template.md"
    release_template = PR_TEMPLATE_DIR / "release.md"

    if not default_template.is_file():
        raise GovernanceValidationError("缺少默认通用 PR 模板 .github/pull_request_template.md。")
    if not release_template.is_file():
        raise GovernanceValidationError("缺少 Release PR 模板 .github/PULL_REQUEST_TEMPLATE/release.md。")

    template_names = sorted(path.name for path in PR_TEMPLATE_DIR.glob("*.md"))
    if template_names != ["release.md"]:
        raise GovernanceValidationError(
            ".github/PULL_REQUEST_TEMPLATE/ 仅允许保留 release.md，"
            f"当前为：{', '.join(template_names)}",
        )


def validate_labeler() -> None:
    """
    校验 labeler 配置与 release label 边界。

    :return: None。
    :raises GovernanceValidationError: labeler 缺少必要标签或误配置 release 时抛出。
    """
    labeler = load_yaml_file(LABELER_PATH)
    if not isinstance(labeler, dict):
        raise GovernanceValidationError(".github/labeler.yml 顶层必须是 label 映射。")

    actual_labels = set(labeler.keys())
    if "release" in actual_labels:
        raise GovernanceValidationError("labeler 不允许自动添加 release label。")

    missing_labels = sorted(REQUIRED_LABELER_LABELS - actual_labels)
    if missing_labels:
        raise GovernanceValidationError(
            ".github/labeler.yml 缺少必要路径标签："
            + ", ".join(missing_labels),
        )


def main() -> int:
    """
    程序主入口。

    :return: 进程退出码，成功返回 0。
    """
    for yaml_path in iter_yaml_files():
        load_yaml_file(yaml_path)

    validate_issue_forms()
    validate_pr_templates()
    validate_labeler()
    print("GitHub governance files are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
