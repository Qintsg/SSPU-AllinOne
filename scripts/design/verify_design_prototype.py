#!/usr/bin/env python3
"""在真实浏览器中核验清源页面级原型。"""

from __future__ import annotations

import argparse
from pathlib import Path

from playwright.sync_api import Page, sync_playwright


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PROTOTYPE = PROJECT_ROOT / "docs" / "design" / "patterns" / "samples" / "app-shell.html"
SCREENS = ("home", "academic", "schedule", "info", "mail", "links", "settings")
VIEWPORTS = ((360, 800), (768, 900), (1200, 900), (1600, 1000))


def _assert(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def _assert_targets(page: Page, viewport_width: int, screen: str) -> None:
    targets = page.locator("button:visible")
    for index in range(targets.count()):
        target = targets.nth(index)
        box = target.bounding_box()
        label = target.get_attribute("aria-label") or target.inner_text().strip()
        _assert(bool(label), f"{viewport_width}px {screen} 存在无可访问名称的按钮[{index}]")
        _assert(
            box is not None and box["width"] >= 47.5 and box["height"] >= 47.5,
            f"{viewport_width}px {screen} 的交互目标 {label!r} 小于 48px",
        )


def _open_screen(page: Page, prototype_url: str, screen: str) -> None:
    page.goto(f"{prototype_url}#{screen}", wait_until="networkidle")
    _assert(page.locator(f'[data-screen="{screen}"]:visible').count() == 1, f"{screen} 页面未唯一显示")
    _assert(page.locator("[data-screen]:visible").count() == 1, f"{screen} 页面切换后存在多个活动页面")


def _assert_screen_interactions(page: Page, screen: str, viewport_width: int) -> None:
    if screen == "schedule":
        first_tab = page.locator('.domain-tab').first
        first_tab.click()
        _assert(first_tab.get_attribute("aria-selected") == "true", "课表日期 Tab 未更新选择状态")
        _assert(page.locator('.domain-tab[aria-selected="true"]').count() == 1, "课表存在多个已选 Tab")
        if viewport_width < 768:
            _assert(page.locator('.schedule-board:visible').count() == 0, "compact 课表仍显示桌面周网格")
            _assert(page.locator('.schedule-day-list:visible').count() == 1, "compact 课表未显示按天列表")
            _assert("高等数学" in page.locator('.schedule-day-list:visible').inner_text(), "课表 Tab 未切换当天课程")
        else:
            _assert(page.locator('.schedule-board:visible').count() == 1, "非 compact 课表未显示周网格")
    elif screen == "info":
        page.get_by_role("button", name="学校官网 · 5").click()
        _assert(page.locator('.feed-entry:visible').count() == 1, "信息来源筛选未过滤文章")
        _assert("学校官网" in page.locator('.feed-entry:visible').inner_text(), "信息来源筛选结果不正确")
    elif screen == "mail":
        page.locator('.mail-item').nth(1).click()
        _assert(page.locator('.mail-item.is-active').count() == 1, "邮件列表存在多个选中项")
        _assert(page.locator('.mail-content:visible h2').inner_text() == "夏季学期选课确认", "可见邮件详情未随选择更新")
        if viewport_width <= 900:
            _assert(page.locator('.mail-list:visible').count() == 0, "compact/medium 邮件详情未替换列表")
            page.locator('.mail-back:visible').click()
            _assert(page.locator('.mail-list:visible').count() == 1, "邮件详情无法返回收件箱")
    elif screen == "links":
        page.locator('.search-box input').fill("图书馆")
        _assert(page.locator('.link-groups .action-row:visible').count() == 1, "快速跳转搜索结果不唯一")
        _assert("图书馆" in page.locator('.link-groups .action-row:visible').inner_text(), "快速跳转搜索结果不正确")
    elif screen == "settings":
        switch = page.get_by_role("switch", name="自动锁定")
        switch.click()
        _assert(switch.get_attribute("aria-checked") == "false", "设置开关 ARIA 状态未同步")
        page.get_by_role("button", name="外观", exact=True).click()
        appearance = page.locator('[data-settings-panel="appearance"]:visible')
        _assert(appearance.count() == 1 and "颜色主题" in appearance.inner_text(), "设置外观分区内容未切换")
        _assert(page.locator('[data-settings-panel="account"]:visible').count() == 0, "设置切换后仍显示账户内容")


def verify(output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    prototype_url = PROTOTYPE.resolve().as_uri()
    errors: list[str] = []

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()
        page.on("console", lambda message: errors.append(f"console {message.type}: {message.text}") if message.type == "error" else None)
        page.on("pageerror", lambda error: errors.append(f"pageerror: {error}"))

        for width, height in VIEWPORTS:
            page.set_viewport_size({"width": width, "height": height})
            page.emulate_media(reduced_motion="reduce")
            page.goto(prototype_url, wait_until="networkidle")
            page.evaluate("localStorage.setItem('qingyuan:samples:theme', 'light')")
            page.reload(wait_until="networkidle")

            active_page = page.locator("[data-screen]:visible")
            _assert(active_page.get_attribute("data-screen") == "home", f"{width}px 默认页面不是 home")
            animation = active_page.evaluate("element => getComputedStyle(element).animationName")
            _assert(animation == "none", f"{width}px 减少动态时仍有页面动画：{animation}")

            viewport_width = page.evaluate("document.documentElement.clientWidth")
            document_width = page.evaluate("document.documentElement.scrollWidth")
            _assert(document_width <= viewport_width, f"{width}px 出现页面级横向溢出：{document_width}>{viewport_width}")

            navigation = page.locator(".prototype-nav-button:visible")
            for index in range(navigation.count()):
                box = navigation.nth(index).bounding_box()
                _assert(box is not None and box["width"] >= 47.5 and box["height"] >= 47.5, f"{width}px 主导航目标小于 48px")

            navigation.first.focus()
            outline = navigation.first.evaluate("element => getComputedStyle(element).outlineWidth")
            _assert(float(outline.removesuffix("px")) >= 2, f"{width}px 键盘焦点不可见")

            if width < 768:
                page.locator("[data-more]:visible").click()
            theme_toggle = page.locator(".theme-toggle:visible").first
            theme_toggle.click()
            _assert(page.locator("html").get_attribute("data-theme") == "dark", f"{width}px 主题切换失败")
            _assert(theme_toggle.get_attribute("aria-pressed") == "true", f"{width}px 主题按钮状态未同步")
            if width < 768:
                page.keyboard.press("Escape")
            page.screenshot(path=output_dir / f"home-{width}-dark.png", full_page=True)

            page.evaluate(
                """localStorage.setItem('qingyuan:samples:theme', 'light');
                document.documentElement.setAttribute('data-theme', '');"""
            )

            for screen in SCREENS:
                _open_screen(page, prototype_url, screen)
                _assert_targets(page, width, screen)
                _assert_screen_interactions(page, screen, width)
                if width in (360, 1200):
                    page.screenshot(path=output_dir / f"{screen}-{width}-light.png", full_page=True)

            if width < 768:
                _open_screen(page, prototype_url, "home")
                more_trigger = page.locator("[data-more]:visible")
                more_trigger.click()
                _assert(page.locator(".more-sheet.is-open:visible").count() == 1, "移动端更多抽屉未打开")
                _assert(page.locator(".more-item").first.evaluate("element => element === document.activeElement"), "更多抽屉打开后未聚焦首项")
                page.keyboard.press("Shift+Tab")
                _assert(page.locator(".more-item").last.evaluate("element => element === document.activeElement"), "更多抽屉 Shift+Tab 未循环到末项")
                page.keyboard.press("Tab")
                _assert(page.locator(".more-item").first.evaluate("element => element === document.activeElement"), "更多抽屉 Tab 未循环到首项")
                page.keyboard.press("Escape")
                _assert(page.locator(".more-sheet.is-open:visible").count() == 0, "Escape 未关闭更多抽屉")
                _assert(more_trigger.evaluate("element => element === document.activeElement"), "更多抽屉关闭后未恢复触发器焦点")
                more_trigger.click()
                page.locator('.more-item[data-page="mail"]').click()
                _assert(page.locator('[data-screen="mail"]:visible').count() == 1, "移动端无法从更多进入邮箱")
                _assert(more_trigger.evaluate("element => element === document.activeElement"), "选择更多目的地后未恢复触发器焦点")

        _assert(not errors, "浏览器控制台错误：" + " | ".join(errors))
        context.close()
        browser.close()

    print(f"Qingyuan page prototype passed browser verification. Screenshots: {output_dir}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    verify(args.output.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
