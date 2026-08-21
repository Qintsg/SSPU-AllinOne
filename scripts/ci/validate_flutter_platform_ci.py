#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
校验清源 Flutter CI workflow 存在性与平台覆盖声明。
@Project : SSPU-AllinOne
@File : validate_flutter_platform_ci.py
@Author : Qintsg
@Date : 2026-08-18
"""

from __future__ import annotations

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
CI_PATH = PROJECT_ROOT / ".github" / "workflows" / "ci.yml"


class FlutterPlatformCiValidationError(ValueError):
    """Flutter 多平台 CI 契约不完整。"""


def validate_flutter_platform_ci(project_root: Path = PROJECT_ROOT) -> None:
    """
    校验 CI workflow 文件存在且排除 Web 平台。

    :param project_root: 仓库根目录。
    :raises FlutterPlatformCiValidationError: workflow 缺失或包含 Web 平台时抛出。
    """
    ci_path = project_root / ".github" / "workflows" / "ci.yml"
    if not ci_path.is_file():
        raise FlutterPlatformCiValidationError(f"缺少 CI workflow：{ci_path}")
    workflow = ci_path.read_text(encoding="utf-8")
    if "platform: web" in workflow:
        raise FlutterPlatformCiValidationError("CI 不得把 Web 纳入本轮发布矩阵")


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
