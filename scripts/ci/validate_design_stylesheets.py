#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
校验清源拆分样式表的加载图与 CSS token 引用。
@Project : SSPU-AllinOne
@File : validate_design_stylesheets.py
@Author : Qintsg
@Date : 2026-08-17
"""

from __future__ import annotations

import re
from collections.abc import Iterable
from pathlib import Path


DESIGN_ROOT = Path("docs/design")
PATTERN_SAMPLES_ROOT = DESIGN_ROOT / "patterns" / "samples"
ENTRY_DOCUMENTS = (
    PATTERN_SAMPLES_ROOT / "app-shell.html",
    PATTERN_SAMPLES_ROOT / "state-reference.html",
)
DYNAMIC_VARIABLES = {
    "--academic-accent",
    "--component-progress",
    "--domain",
    "--rule-progress",
}
CSS_DEFINITION_PATTERN = re.compile(r"(?P<name>--[a-z0-9-]+)\s*:")
CSS_REFERENCE_PATTERN = re.compile(r"var\(\s*(?P<name>--[a-z0-9-]+)")
CSS_IMPORT_PATTERN = re.compile(
    r"@import\s+(?:url\()?\s*['\"](?P<target>[^'\"]+\.css)['\"]\s*\)?"
)
HTML_STYLESHEET_PATTERN = re.compile(
    r"<link\s+[^>]*rel=['\"]stylesheet['\"][^>]*href=['\"](?P<target>[^'\"]+\.css)['\"]",
    re.IGNORECASE,
)


class DesignStylesheetValidationError(ValueError):
    """拆分样式表未加载或引用了未定义 token。"""


def _resolve_relative(source: Path, target: str) -> Path:
    """
    解析 HTML/CSS 中相对样式路径。

    :param source: 声明引用的源文件。
    :param target: link 或 import 的相对目标。
    :returns: 规范化后的绝对目标路径。
    """
    return (source.parent / target).resolve()


def _linked_stylesheets(document: Path) -> list[Path]:
    """
    读取一个 HTML 入口直接链接的样式表。

    :param document: HTML 入口文件。
    :returns: 按文档顺序解析的样式表路径。
    """
    source = document.read_text(encoding="utf-8")
    return [
        _resolve_relative(document, match.group("target"))
        for match in HTML_STYLESHEET_PATTERN.finditer(source)
    ]


def _imported_stylesheets(stylesheet: Path) -> list[Path]:
    """
    读取一个 CSS 文件直接导入的样式表。

    :param stylesheet: CSS 源文件。
    :returns: 按声明顺序解析的导入路径。
    """
    source = stylesheet.read_text(encoding="utf-8")
    return [
        _resolve_relative(stylesheet, match.group("target"))
        for match in CSS_IMPORT_PATTERN.finditer(source)
    ]


def _walk_stylesheet_graph(entries: Iterable[Path]) -> tuple[set[Path], list[str]]:
    """
    遍历 link 与 import 形成的样式加载图。

    :param entries: HTML 入口直接链接的样式表。
    :returns: 可达样式表集合与缺失目标错误。
    """
    reachable: set[Path] = set()
    errors: list[str] = []
    pending = list(entries)
    while pending:
        stylesheet = pending.pop()
        if stylesheet in reachable:
            continue
        if not stylesheet.exists():
            errors.append(f"样式加载链引用了不存在的文件：{stylesheet}")
            continue
        reachable.add(stylesheet)
        pending.extend(_imported_stylesheets(stylesheet))
    return reachable, errors


def _relative(project_root: Path, path: Path) -> str:
    """
    生成用于错误消息的仓库相对路径。

    :param project_root: 仓库根目录。
    :param path: 需要显示的绝对路径。
    :returns: POSIX 风格仓库相对路径。
    """
    return path.relative_to(project_root.resolve()).as_posix()


def validate_design_stylesheets(project_root: Path) -> None:
    """
    校验全部参考原型样式都被加载且只引用已定义 token。

    :param project_root: 仓库根目录。
    :raises DesignStylesheetValidationError: 加载图或 token 引用不完整。
    """
    resolved_root = project_root.resolve()
    entry_documents = [resolved_root / path for path in ENTRY_DOCUMENTS]
    errors = [
        f"设计样式入口不存在：{_relative(resolved_root, document)}"
        for document in entry_documents
        if not document.exists()
    ]
    if errors:
        raise DesignStylesheetValidationError("\n".join(errors))

    direct_entries = [
        stylesheet
        for document in entry_documents
        for stylesheet in _linked_stylesheets(document)
    ]
    reachable, graph_errors = _walk_stylesheet_graph(direct_entries)
    errors.extend(graph_errors)

    pattern_root = resolved_root / PATTERN_SAMPLES_ROOT
    expected_pattern_stylesheets = {path.resolve() for path in pattern_root.glob("*.css")}
    orphaned = sorted(expected_pattern_stylesheets - reachable)
    if orphaned:
        errors.append(
            "设计样式未进入原型加载链："
            + ", ".join(_relative(resolved_root, path) for path in orphaned)
        )

    definitions: set[str] = set()
    sources: dict[Path, str] = {}
    for stylesheet in sorted(reachable):
        source = stylesheet.read_text(encoding="utf-8")
        sources[stylesheet] = source
        definitions.update(
            match.group("name") for match in CSS_DEFINITION_PATTERN.finditer(source)
        )

    allowed = definitions | DYNAMIC_VARIABLES
    for stylesheet, source in sources.items():
        unresolved = sorted(
            {
                match.group("name")
                for match in CSS_REFERENCE_PATTERN.finditer(source)
            }
            - allowed
        )
        if unresolved:
            errors.append(
                f"{_relative(resolved_root, stylesheet)} 引用了未定义 CSS 自定义属性："
                + ", ".join(unresolved)
            )

    if errors:
        raise DesignStylesheetValidationError("\n".join(errors))


def main() -> int:
    """
    运行仓库样式契约校验。

    :returns: 成功时返回 0。
    """
    project_root = Path(__file__).resolve().parents[2]
    validate_design_stylesheets(project_root)
    print("Qingyuan split stylesheet contract is valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
