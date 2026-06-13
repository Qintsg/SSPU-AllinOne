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
import re

import yaml


PROJECT_ROOT = Path(__file__).resolve().parents[2]
GITHUB_DIR = PROJECT_ROOT / ".github"
ISSUE_TEMPLATE_DIR = GITHUB_DIR / "ISSUE_TEMPLATE"
PR_TEMPLATE_DIR = GITHUB_DIR / "PULL_REQUEST_TEMPLATE"
LABELER_PATH = GITHUB_DIR / "labeler.yml"
CONTRIBUTE_PATH = PROJECT_ROOT / "CONTRIBUTE.md"
CODE_OF_CONDUCT_PATH = PROJECT_ROOT / "CODE_OF_CONDUCT.md"
SECURITY_PATH = PROJECT_ROOT / "SECURITY.md"
GITATTRIBUTES_PATH = PROJECT_ROOT / ".gitattributes"
README_AGENTS_PATH = PROJECT_ROOT / "README_agents.md"
BRANCH_NAMING_PATH = GITHUB_DIR / "分支命名规范.md"
CI_WORKFLOW_PATH = GITHUB_DIR / "workflows" / "ci.yml"
PR_METADATA_WORKFLOW_PATH = GITHUB_DIR / "workflows" / "pr-metadata.yml"

REQUIRED_PROJECT_SKILLS = {
    "branch-checkout",
    "commit-messages",
    "git-flow",
    "issue-writing",
    "lore-usage",
    "pr-writing",
}

REQUIRED_HELPER_SCRIPTS = {
    "scripts/gitflow/check_config.ps1",
    "scripts/gitflow/check_config.sh",
    "scripts/lore/status.ps1",
    "scripts/lore/status.sh",
}

REQUIRED_COMPOSITE_ACTIONS = {
    "generate-release-metadata",
    "package-linux-release-assets",
    "package-windows-portable",
    "release-context",
    "setup-flutter",
    "setup-flutter-arm64",
}

REQUIRED_LABELER_LABELS = {
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

FORBIDDEN_FIX_BRANCH_PATTERN = re.compile(
    r"(?<![a-zA-Z0-9_-])(?:[a-zA-Z0-9_-]+/)?fix/[a-zA-Z0-9][a-zA-Z0-9._-]*",
)

BRANCH_POLICY_FILES = {
    README_AGENTS_PATH,
    BRANCH_NAMING_PATH,
    CONTRIBUTE_PATH,
    PROJECT_ROOT / "docs" / "specs" / "RepoWorkflow.md",
    PROJECT_ROOT / "docs" / "RELEASE.md",
    PROJECT_ROOT / ".agents" / "skills" / "branch-checkout" / "SKILL.md",
    PROJECT_ROOT / ".agents" / "skills" / "commit-messages" / "SKILL.md",
    PROJECT_ROOT / ".agents" / "skills" / "git-flow" / "SKILL.md",
    PROJECT_ROOT / ".agents" / "skills" / "issue-writing" / "SKILL.md",
    PROJECT_ROOT / ".agents" / "skills" / "lore-usage" / "SKILL.md",
    PROJECT_ROOT / ".agents" / "skills" / "pr-writing" / "SKILL.md",
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


def validate_composite_actions() -> None:
    """
    校验 Release workflow 依赖的 composite actions 存在并保持 composite 类型。

    :return: None。
    :raises GovernanceValidationError: action 缺失或类型不符合约束时抛出。
    """
    actions_dir = GITHUB_DIR / "actions"
    action_names = {
        action_path.parent.name
        for action_path in actions_dir.glob("*/action.yml")
    }
    missing_actions = sorted(REQUIRED_COMPOSITE_ACTIONS - action_names)
    if missing_actions:
        raise GovernanceValidationError(
            ".github/actions/ 缺少必要 composite action："
            + ", ".join(missing_actions),
        )

    for action_name in sorted(REQUIRED_COMPOSITE_ACTIONS):
        action_path = actions_dir / action_name / "action.yml"
        action = load_yaml_file(action_path)
        runs = action.get("runs")
        if not isinstance(runs, dict) or runs.get("using") != "composite":
            raise GovernanceValidationError(f"{action_path} 必须声明 runs.using: composite。")

    release_workflow = (GITHUB_DIR / "workflows" / "release.yml").read_text(encoding="utf-8")
    missing_uses = sorted(
        action_name
        for action_name in REQUIRED_COMPOSITE_ACTIONS
        if f"./.github/actions/{action_name}" not in release_workflow
    )
    if missing_uses:
        raise GovernanceValidationError(
            ".github/workflows/release.yml 未引用必要 composite action："
            + ", ".join(missing_uses),
        )


def validate_contribute_doc() -> None:
    """
    校验 CONTRIBUTE.md、CODE_OF_CONDUCT.md、SECURITY.md 和 .gitattributes 存在。

    :return: None。
    :raises GovernanceValidationError: 文件不存在时抛出。
    """
    if not CONTRIBUTE_PATH.is_file():
        raise GovernanceValidationError("缺少贡献指南 CONTRIBUTE.md。")
    if not CODE_OF_CONDUCT_PATH.is_file():
        raise GovernanceValidationError("缺少行为准则 CODE_OF_CONDUCT.md。")
    if not SECURITY_PATH.is_file():
        raise GovernanceValidationError("缺少安全政策 SECURITY.md。")
    if not GITATTRIBUTES_PATH.is_file():
        raise GovernanceValidationError("缺少行尾治理文件 .gitattributes。")
    gitattributes = GITATTRIBUTES_PATH.read_text(encoding="utf-8")
    if "* text=auto eol=lf" not in gitattributes:
        raise GovernanceValidationError(".gitattributes 必须声明默认文本 LF 行尾。")


def validate_project_skills() -> None:
    """
    校验项目级 agent skills 与治理辅助脚本存在。

    :return: None。
    :raises GovernanceValidationError: 必要 skill 或脚本缺失时抛出。
    """
    skills_dir = PROJECT_ROOT / ".agents" / "skills"
    missing_skills = sorted(
        skill_name
        for skill_name in REQUIRED_PROJECT_SKILLS
        if not (skills_dir / skill_name / "SKILL.md").is_file()
    )
    if missing_skills:
        raise GovernanceValidationError(
            ".agents/skills/ 缺少必要项目 skill："
            + ", ".join(missing_skills),
        )

    missing_scripts = sorted(
        script_path
        for script_path in REQUIRED_HELPER_SCRIPTS
        if not (PROJECT_ROOT / script_path).is_file()
    )
    if missing_scripts:
        raise GovernanceValidationError(
            "缺少必要治理辅助脚本："
            + ", ".join(missing_scripts),
        )


def validate_branch_governance() -> None:
    """
    校验 Git Flow 分支命名治理规则。

    :return: None。
    :raises GovernanceValidationError: 分支前缀或 workflow 规则漂移时抛出。
    """
    for policy_path in sorted(BRANCH_POLICY_FILES):
        if not policy_path.is_file():
            raise GovernanceValidationError(f"缺少分支治理文件：{policy_path}")

        text = policy_path.read_text(encoding="utf-8")
        forbidden_matches = sorted(set(FORBIDDEN_FIX_BRANCH_PATTERN.findall(text)))
        if forbidden_matches:
            relative_path = policy_path.relative_to(PROJECT_ROOT)
            raise GovernanceValidationError(
                f"{relative_path} 仍包含旧 fix/ 分支前缀："
                + ", ".join(forbidden_matches)
                + "。Bugfix 分支必须使用 bugfix/，commit/PR type 才使用 fix。",
            )

    ci_workflow = CI_WORKFLOW_PATH.read_text(encoding="utf-8")
    if "bugfix" not in ci_workflow:
        raise GovernanceValidationError("CI workflow 分支命名 warning 必须包含 bugfix。")
    if "feature|fix|hotfix" in ci_workflow:
        raise GovernanceValidationError("CI workflow 仍在推荐旧 fix/ 分支前缀。")

    pr_metadata = PR_METADATA_WORKFLOW_PATH.read_text(encoding="utf-8")
    if "['bugfix', 'bug']" not in pr_metadata:
        raise GovernanceValidationError("PR Metadata workflow 必须将 bugfix 分支映射为 bug label。")
    if "feature|feat|fix|hotfix" in pr_metadata:
        raise GovernanceValidationError("PR Metadata workflow 仍在匹配旧 fix/ 分支前缀。")

    for command_policy_path in [
        README_AGENTS_PATH,
        CONTRIBUTE_PATH,
        PROJECT_ROOT / ".agents" / "skills" / "git-flow" / "SKILL.md",
        PROJECT_ROOT / ".agents" / "skills" / "branch-checkout" / "SKILL.md",
    ]:
        text = command_policy_path.read_text(encoding="utf-8")
        if "gitflow" not in text or "git flow" not in text:
            relative_path = command_policy_path.relative_to(PROJECT_ROOT)
            raise GovernanceValidationError(
                f"{relative_path} 必须说明 Git Flow 命令可能是 gitflow 或 git flow。",
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
    validate_composite_actions()
    validate_contribute_doc()
    validate_project_skills()
    validate_branch_governance()
    print("GitHub governance files are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
