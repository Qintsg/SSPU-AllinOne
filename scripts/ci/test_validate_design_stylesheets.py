#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
清源拆分样式表契约校验器测试。
@Project : SSPU-AllinOne
@File : test_validate_design_stylesheets.py
@Author : Qintsg
@Date : 2026-08-17
"""

from __future__ import annotations

import shutil
import tempfile
import unittest
from pathlib import Path

from validate_design_stylesheets import (
    DesignStylesheetValidationError,
    validate_design_stylesheets,
)


PROJECT_ROOT = Path(__file__).resolve().parents[2]


class DesignStylesheetValidatorTest(unittest.TestCase):
    """验证拆分后的全部设计样式都进入 token 与加载链门禁。"""

    def test_repository_stylesheet_contract_is_valid(self) -> None:
        """仓库当前样式表必须形成完整且无漂移的加载图。"""
        validate_design_stylesheets(PROJECT_ROOT)

    def test_split_stylesheet_rejects_undefined_variable(self) -> None:
        """新拆出的资讯样式也必须拒绝未定义 token。"""
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(
                PROJECT_ROOT / "docs" / "design",
                root / "docs" / "design",
            )
            stylesheet = (
                root
                / "docs"
                / "design"
                / "patterns"
                / "samples"
                / "_info-state-density.css"
            )
            stylesheet.write_text(
                stylesheet.read_text(encoding="utf-8")
                + "\n.invalid { gap: var(--space-does-not-exist); }\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                DesignStylesheetValidationError,
                r"_info-state-density\.css.*--space-does-not-exist",
            ):
                validate_design_stylesheets(root)

    def test_unlinked_split_stylesheet_is_rejected(self) -> None:
        """新增样式文件必须进入原型的 link 或 import 加载链。"""
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            shutil.copytree(
                PROJECT_ROOT / "docs" / "design",
                root / "docs" / "design",
            )
            orphan = (
                root
                / "docs"
                / "design"
                / "patterns"
                / "samples"
                / "_orphan.css"
            )
            orphan.write_text("/* 未进入参考原型的样式。 */\n", encoding="utf-8")

            with self.assertRaisesRegex(
                DesignStylesheetValidationError,
                r"未进入原型加载链.*_orphan\.css",
            ):
                validate_design_stylesheets(root)


if __name__ == "__main__":
    unittest.main()
