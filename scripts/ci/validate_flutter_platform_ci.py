#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
校验清源 Flutter 五平台构建与视觉候选 CI 矩阵。
@Project : SSPU-AllinOne
@File : validate_flutter_platform_ci.py
@Author : Qintsg
@Date : 2026-08-18
"""

from __future__ import annotations

import re
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
CI_PATH = PROJECT_ROOT / ".github" / "workflows" / "ci.yml"
REQUIRED_PLATFORMS = ("android", "ios", "windows", "macos", "linux")


class FlutterPlatformCiValidationError(ValueError):
    """Flutter 多平台 CI 契约不完整。"""


def _job_block(workflow: str, job_name: str) -> str:
    """
    提取指定 workflow job 的文本块。

    :param workflow: CI workflow 原文。
    :param job_name: 顶层 job 名称。
    :returns: 该 job 到下一个顶层 job 之前的文本。
    :raises FlutterPlatformCiValidationError: job 不存在时抛出。
    """
    match = re.search(
        rf"(?ms)^  {re.escape(job_name)}:\n(?P<body>.*?)(?=^  [A-Za-z0-9_-]+:\n|\Z)",
        workflow,
    )
    if match is None:
        raise FlutterPlatformCiValidationError(f"CI 缺少 job：{job_name}")
    return match.group("body")


def _assert_platform_entries(job_name: str, block: str) -> None:
    """
    校验 job 的矩阵包含且仅包含五个发布平台。

    :param job_name: 当前 job 名称。
    :param block: 当前 job 文本块。
    :raises FlutterPlatformCiValidationError: 平台条目缺失或包含 Web 时抛出。
    """
    entries = tuple(re.findall(r"^\s+- platform: ([a-z0-9_-]+)\s*$", block, re.MULTILINE))
    if set(entries) != set(REQUIRED_PLATFORMS) or len(entries) != len(REQUIRED_PLATFORMS):
        raise FlutterPlatformCiValidationError(
            f"{job_name} 必须包含且仅包含 Android/iOS/Windows/macOS/Linux 五个平台，当前为 {entries}"
        )
    if "platform: web" in block:
        raise FlutterPlatformCiValidationError(f"{job_name} 不得把 Web 纳入本轮发布矩阵")


def validate_flutter_platform_ci(project_root: Path = PROJECT_ROOT) -> None:
    """
    校验 Flutter 构建、原生 smoke 与视觉候选的五平台 CI 契约。

    :param project_root: 仓库根目录。
    :raises FlutterPlatformCiValidationError: workflow 缺失或平台步骤不完整时抛出。
    """
    ci_path = project_root / ".github" / "workflows" / "ci.yml"
    if not ci_path.is_file():
        raise FlutterPlatformCiValidationError(f"缺少 CI workflow：{ci_path}")
    workflow = ci_path.read_text(encoding="utf-8")
    build = _job_block(workflow, "platform-build-gate")
    visual = _job_block(workflow, "visual-candidate-matrix")
    _assert_platform_entries("platform-build-gate", build)
    _assert_platform_entries("visual-candidate-matrix", visual)

    build_commands = {
        "android": "flutter build apk --debug",
        "ios": "flutter build ios --debug --no-codesign",
        "windows": "flutter build windows --debug",
        "macos": "flutter build macos --debug",
        "linux": "flutter build linux --debug",
    }
    for platform, command in build_commands.items():
        if command not in build:
            raise FlutterPlatformCiValidationError(
                f"platform-build-gate 缺少 {platform} 构建命令：{command}"
            )

    if "integration_test/qingyuan_platform_smoke_test.dart" not in visual:
        raise FlutterPlatformCiValidationError("visual-candidate-matrix 缺少原生能力 smoke")
    if "QINGYUAN_VISUAL_CAPTURE=true" not in visual:
        raise FlutterPlatformCiValidationError("visual-candidate-matrix 缺少视觉候选采集")
    if "scripts/ci/validate_visual_artifacts.py" not in visual:
        raise FlutterPlatformCiValidationError("visual-candidate-matrix 缺少视觉产物完整性校验")
    if "QINGYUAN_VISUAL_PLATFORM=${{ matrix.platform }}" not in visual:
        raise FlutterPlatformCiValidationError("视觉候选未绑定 matrix.platform")


def main() -> int:
    """
    执行 Flutter 多平台 CI 校验。

    :returns: 成功时返回 0。
    """
    validate_flutter_platform_ci()
    print("Flutter five-platform CI matrix is valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
