#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
清源 Flutter 多平台 CI 矩阵校验器行为测试。
@Project : SSPU-AllinOne
@File : test_validate_flutter_platform_ci.py
@Author : Qintsg
@Date : 2026-08-18
"""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from validate_flutter_platform_ci import (
    FlutterPlatformCiValidationError,
    validate_flutter_platform_ci,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]


class FlutterPlatformCiValidationTest(unittest.TestCase):
    """验证五平台矩阵和关键步骤不会意外漂移。"""

    def test_repository_ci_matrix_is_valid(self) -> None:
        """当前仓库 workflow 应包含五平台构建与视觉候选。"""
        validate_flutter_platform_ci(PROJECT_ROOT)

    def test_web_platform_is_rejected(self) -> None:
        """Web 不属于本轮视觉与构建验收范围。"""
        source = (PROJECT_ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            workflow = root / ".github" / "workflows" / "ci.yml"
            workflow.parent.mkdir(parents=True)
            workflow.write_text(source.replace("- platform: linux", "- platform: web", 1), encoding="utf-8")
            with self.assertRaises(FlutterPlatformCiValidationError):
                validate_flutter_platform_ci(root)


if __name__ == "__main__":
    unittest.main()
