#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
'''
User-Agent 策略校验脚本
@Project : SSPU-AllinOne
@File : validate_user_agent_policy.py
@Author : Qintsg
@Date : 2026-06-12 09:20
'''

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SCAN_ROOTS = ("lib",)
ALLOW_MARKER = "UA-POLICY-ALLOW:"
COMMENT_PREFIXES = ("//", "///", "/*", "*", "#")
STANDARD_USER_AGENT_REFERENCES = (
    "HttpService.userAgent",
    "AppUserAgentService.userAgent",
)
BROWSER_USER_AGENT_PATTERN = re.compile(
    r"Mozilla/5\.0|AppleWebKit/|Chrome/[0-9]|Firefox/[0-9]|Safari/[0-9]|"
    r"Gecko/20100101|Edg/[0-9]",
)
USER_AGENT_HEADER_PATTERN = re.compile(r"""['"]User-Agent['"]\s*:""")
USER_AGENT_PROPERTY_PATTERN = re.compile(r"\buserAgent\s*:")
USER_AGENT_LITERAL_ASSIGNMENT_PATTERN = re.compile(
    r"\b\w*userAgent\w*\s*=\s*['\"]",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class UserAgentPolicyViolation:
    """User-Agent 策略违规位置。"""

    path: Path
    line_number: int
    line: str
    reason: str


def iter_runtime_source_files() -> list[Path]:
    """
    枚举需要检查的运行时代码文件。

    :returns: 按路径排序的源码文件列表。
    """
    source_files: list[Path] = []
    for root_name in SCAN_ROOTS:
        root = PROJECT_ROOT / root_name
        if not root.exists():
            continue
        source_files.extend(
            path
            for path in root.rglob("*")
            if path.is_file() and path.suffix in {".dart", ".js", ".ts"}
        )
    return sorted(source_files)


def has_policy_allow_comment(lines: list[str], line_index: int) -> bool:
    """
    判断指定行附近是否有 UA 例外说明注释。

    :param lines: 文件内容按行拆分结果。
    :param line_index: 当前命中行的 0 基索引。
    :returns: 找到合规例外说明时返回 True。
    """
    start = max(0, line_index - 4)
    for candidate in lines[start : line_index + 1]:
        stripped = candidate.strip()
        if not stripped.startswith(COMMENT_PREFIXES):
            continue
        marker_index = stripped.find(ALLOW_MARKER)
        if marker_index < 0:
            continue
        reason = stripped[marker_index + len(ALLOW_MARKER) :].strip()
        if len(reason) >= 12:
            return True
    return False


def is_comment_line(line: str) -> bool:
    """
    判断当前行是否为注释行。

    :param line: 待判断文本行。
    :returns: 注释行返回 True。
    """
    return line.strip().startswith(COMMENT_PREFIXES)


def uses_standard_user_agent(line: str) -> bool:
    """
    判断当前行是否引用标准应用 User-Agent。

    :param line: 待判断文本行。
    :returns: 引用标准应用 User-Agent 时返回 True。
    """
    return any(reference in line for reference in STANDARD_USER_AGENT_REFERENCES)


def user_agent_policy_reason(lines: list[str], line_index: int) -> str | None:
    """
    判断指定行是否命中 User-Agent 策略。

    :param lines: 文件内容按行拆分结果。
    :param line_index: 当前检查行的 0 基索引。
    :returns: 命中策略时返回违规原因，否则返回 None。
    """
    line = lines[line_index]
    if is_comment_line(line):
        return None

    if BROWSER_USER_AGENT_PATTERN.search(line) is not None:
        return (
            "浏览器样式 User-Agent 必须改用 HttpService.userAgent，"
            f"或在近邻注释中写明 {ALLOW_MARKER} 例外原因。"
        )

    if USER_AGENT_HEADER_PATTERN.search(line) is not None:
        if uses_standard_user_agent(line):
            return None
        return (
            "非标准 User-Agent 请求头必须改用 HttpService.userAgent，"
            f"或在近邻注释中写明 {ALLOW_MARKER} 例外原因。"
        )

    if USER_AGENT_LITERAL_ASSIGNMENT_PATTERN.search(line) is not None:
        return (
            "代码中定义的非标准 User-Agent 必须有近邻 "
            f"{ALLOW_MARKER} 例外原因。"
        )

    property_match = USER_AGENT_PROPERTY_PATTERN.search(line)
    if property_match is None:
        return None

    value_part = line[property_match.end() :].strip()
    if value_part and not value_part.startswith(("'", '"')):
        return None

    context = "\n".join(lines[line_index : line_index + 4])
    if any(reference in context for reference in STANDARD_USER_AGENT_REFERENCES):
        return None

    return (
        "非标准 userAgent 属性必须改用标准应用 User-Agent，"
        f"或在近邻注释中写明 {ALLOW_MARKER} 例外原因。"
    )


def validate_file(path: Path) -> list[UserAgentPolicyViolation]:
    """
    校验单个文件是否存在未说明的非标准 User-Agent。

    :param path: 待检查源码文件路径。
    :returns: 违规列表。
    """
    lines = path.read_text(encoding="utf-8").splitlines()
    violations: list[UserAgentPolicyViolation] = []
    for index, line in enumerate(lines):
        reason = user_agent_policy_reason(lines, index)
        if reason is None:
            continue
        if has_policy_allow_comment(lines, index):
            continue
        violations.append(
            UserAgentPolicyViolation(
                path=path.relative_to(PROJECT_ROOT),
                line_number=index + 1,
                line=line.strip(),
                reason=reason,
            ),
        )
    return violations


def main() -> int:
    """
    程序主入口。

    :returns: 成功返回 0，发现策略违规返回 1。
    """
    violations: list[UserAgentPolicyViolation] = []
    for source_file in iter_runtime_source_files():
        violations.extend(validate_file(source_file))

    if not violations:
        print("User-Agent policy is valid.")
        return 0

    print("User-Agent policy violations found:")
    for violation in violations:
        print(f"- {violation.path}:{violation.line_number}: {violation.reason}")
        print(f"  {violation.line}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
