#!/usr/bin/env python
# -*- coding: UTF-8 -*-
"""
清源首页可配置概览密度的浏览器交互核验。
@Project : SSPU-AllinOne
@File : check_home_density_interactions.py
@Author : Qintsg
@Date : 2026-08-18
"""

from __future__ import annotations

from pathlib import Path
from typing import Final

from playwright.sync_api import Page, sync_playwright


PROJECT_ROOT: Final = Path(__file__).resolve().parents[2]
PROTOTYPE: Final = (
    PROJECT_ROOT / "docs" / "design" / "patterns" / "samples" / "app-shell.html"
)
OUTPUT_ROOT: Final = PROJECT_ROOT / "build" / "design-review-home-density-v05-interactions"
VISIBLE_ITEMS: Final = ("program", "campus", "mail", "sports")
VIEWPORTS: Final = (("compact", 360, 800), ("expanded", 1200, 900))
SCENARIOS: Final = {
    "all": VISIBLE_ITEMS,
    "single": ("campus",),
    "none": (),
}


def _rect(page: Page, selector: str) -> dict[str, float]:
    """
    读取页面元素的几何边界。

    :param page: 当前 Playwright 页面。
    :param selector: CSS 选择器。
    :returns: 包含 x、y、width、height 的矩形字典。
    :raises AssertionError: 目标元素不存在。
    """
    result = page.locator(selector).evaluate(
        "element => { const r = element.getBoundingClientRect(); "
        "return {x: r.x, y: r.y, width: r.width, height: r.height}; }"
    )
    assert result is not None, f"未找到布局元素：{selector}"
    return result


def _assert_greeting_phrase_layout(page: Page, viewport_name: str) -> None:
    """
    核验首页问候语按阅读短语而非中文孤字换行。

    :param page: 当前原型页面。
    :param viewport_name: 当前视口名称。
    :returns: 无。
    """
    fragments = page.locator(
        '[data-screen="home"] #home-title .home-greeting-fragment'
    )
    assert fragments.count() == 2, "首页问候语必须保留两个阅读短语"
    greeting = _rect(page, '[data-screen="home"] #home-title')
    prefix = _rect(
        page,
        '[data-screen="home"] #home-title .home-greeting-fragment:first-child',
    )
    focus = _rect(
        page,
        '[data-screen="home"] #home-title .home-greeting-fragment:last-child',
    )
    assert prefix["width"] > 0 and focus["width"] > 0
    assert focus["x"] + focus["width"] <= greeting["x"] + greeting["width"] + 1
    if viewport_name == "compact":
        assert focus["y"] >= prefix["y"] + prefix["height"] - 1, (
            "compact: 首页问候语未在完整短语之间换行"
        )
    else:
        assert abs(focus["y"] - prefix["y"]) <= 1, (
            "expanded: 首页问候语在空间充足时未恢复同一行"
        )


def _assert_scenario(
    page: Page,
    scenario: str,
    visible: tuple[str, ...],
    viewport_name: str,
    width: int,
    height: int,
) -> None:
    """
    核验一个首页配置场景及其响应式约束。

    :param page: 当前 Playwright 页面。
    :param scenario: 场景名称。
    :param visible: 要保留的概览项。
    :param viewport_name: 视口档位名称。
    :param width: 视口宽度。
    :param height: 视口高度。
    :returns: 无。
    """
    page.set_viewport_size({"width": width, "height": height})
    page.goto(PROTOTYPE.as_uri(), wait_until="networkidle")
    page.evaluate(
        "visible => window.qingyuanPrototype.setHomeOverviewVisibility(visible)",
        list(visible),
    )
    page.wait_for_timeout(250)

    home = page.locator('[data-screen="home"]')
    _assert_greeting_phrase_layout(page, viewport_name)
    layout = _rect(page, '[data-screen="home"] .home-layout')
    timeline = _rect(page, '[data-screen="home"] .timeline-panel')
    stack_locator = page.locator('[data-screen="home"] .overview-stack')
    stack_count = stack_locator.locator('[data-home-overview-item]:not([hidden])').count()

    assert stack_count == len(visible), (
        f"{viewport_name}/{scenario}: 概览数量为 {stack_count}，"
        f"预期 {len(visible)}"
    )
    if not visible:
        assert stack_locator.evaluate("element => element.classList.contains('is-empty')")
        assert timeline["width"] > width * 0.7, (
            f"{viewport_name}/{scenario}: 空概览时主时间轨未释放宽度"
        )
    elif len(visible) == 1 and viewport_name == "expanded":
        stack = _rect(page, '[data-screen="home"] .overview-stack')
        assert stack["height"] < timeline["height"], (
            f"{viewport_name}/{scenario}: 单项概览仍被拉伸为整列高度"
        )
    else:
        stack = _rect(page, '[data-screen="home"] .overview-stack')
        assert stack["width"] > 0 and stack["height"] > 0

    assert layout["width"] <= width + 1, f"{viewport_name}/{scenario}: 横向溢出"
    if viewport_name == "compact":
        assert home.evaluate("element => element.scrollHeight <= element.clientHeight + 1"), (
            f"{viewport_name}/{scenario}: 首页出现页面级滚动"
        )

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    page.screenshot(
        path=str(OUTPUT_ROOT / f"home-density--{scenario}--{viewport_name}.png"),
        animations="disabled",
    )


def main() -> int:
    """
    运行首页配置密度的浏览器矩阵。

    :returns: 成功时返回 0。
    """
    total = 0
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        page = browser.new_page()
        try:
            for viewport_name, width, height in VIEWPORTS:
                for scenario, visible in SCENARIOS.items():
                    _assert_scenario(page, scenario, visible, viewport_name, width, height)
                    total += 1
        finally:
            browser.close()
    print(f"首页密度交互核验通过：{total} 个场景，截图位于 {OUTPUT_ROOT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
