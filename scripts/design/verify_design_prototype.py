#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
在真实浏览器中核验清源页面级原型。
@Project : SSPU-AllinOne
@File : verify_design_prototype.py
@Author : Qintsg
@Date : 2026-08-14
"""

from __future__ import annotations

import argparse
from pathlib import Path

from playwright.sync_api import sync_playwright

from verify_design_prototype_core import (
    PROTOTYPE,
    SCREEN_SURFACES,
    SCREENS,
    VIEWPORTS,
    _assert,
    _assert_screen_interactions,
    _assert_targets,
    _capture_missing_state_references,
    _capture_reference,
    _load_reference_contract,
    _open_screen,
    _write_reference_index,
)
from verify_design_prototype_surfaces import (
    _capture_academic_state_references,
    _capture_academic_surface_prefix,
    _capture_campus_card_detail_state_references,
    _capture_campus_card_home_state_references,
    _capture_campus_card_surface_prefix,
    _capture_home_state_references,
    _capture_home_surface_prefix,
    _capture_info_state_references,
    _capture_info_surface_prefix,
    _capture_link_confirmation_state_references,
    _capture_links_state_references,
    _capture_mail_state_references,
    _capture_settings_account_state_references,
    _capture_settings_account_surface_prefix,
    _capture_settings_home_surface_prefix,
)


def verify(output_dir: Path, surface_prefix: str | None = None) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for stale_reference in output_dir.glob("*.png"):
        stale_reference.unlink()
    for stale_sidecar in output_dir.glob("*.png.regions.json"):
        stale_sidecar.unlink()
    (output_dir / "reference-index.json").unlink(missing_ok=True)
    manifest, _, expected = _load_reference_contract()
    if surface_prefix:
        expected = [item for item in expected if item["surface"].startswith(surface_prefix)]
        _assert(bool(expected), f"视觉清单中没有界面前缀 {surface_prefix!r}")
    prototype_url = PROTOTYPE.resolve().as_uri()
    errors: list[str] = []

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()
        page.on("console", lambda message: errors.append(f"console {message.type}: {message.text}") if message.type == "error" else None)
        page.on("pageerror", lambda error: errors.append(f"pageerror: {error}"))

        if surface_prefix:
            if surface_prefix == "home.dashboard":
                _capture_home_surface_prefix(
                    page,
                    output_dir,
                    prototype_url,
                )
            elif surface_prefix == "settings.home-notifications":
                _capture_settings_home_surface_prefix(
                    page,
                    output_dir,
                    prototype_url,
                )
            elif surface_prefix == "settings.account":
                _capture_settings_account_surface_prefix(
                    page,
                    output_dir,
                    prototype_url,
                )
            elif surface_prefix == "info.feed":
                _capture_info_surface_prefix(
                    page,
                    output_dir,
                    prototype_url,
                )
            elif surface_prefix == "academic.overview":
                _capture_academic_surface_prefix(
                    page,
                    output_dir,
                    prototype_url,
                )
            elif surface_prefix in ("home.campus-card", "home.campus-card-detail"):
                _capture_campus_card_surface_prefix(
                    page,
                    output_dir,
                    prototype_url,
                    include_home=surface_prefix == "home.campus-card",
                    include_detail=True,
                )
            else:
                _capture_missing_state_references(page, output_dir, expected)
            _write_reference_index(output_dir, manifest, expected)
            _assert(not errors, "浏览器控制台错误：" + " | ".join(errors))
            context.close()
            browser.close()
            print(
                "Qingyuan page prototype passed browser verification. "
                f"Screenshots: {len(expected)} at {output_dir}"
            )
            return

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
            page.evaluate(
                """localStorage.setItem('qingyuan:samples:theme', 'light');
                document.documentElement.setAttribute('data-theme', '');"""
            )

            for screen in SCREENS:
                _open_screen(page, prototype_url, screen)
                _assert_targets(page, width, screen)
                _assert_screen_interactions(page, screen, width)
                # 交互验证会改变 Tab、筛选和详情选中态；参考稿必须回到默认内容态。
                _open_screen(page, prototype_url, screen)
                surface = SCREEN_SURFACES.get(screen)
                # 课表已经迁移到全状态冻结参考；旧交互原型只继续承担行为核验，
                # 不得抢先写入同名 content 基线并遮蔽状态参考。
                if surface is not None and surface != "schedule.calendar":
                    _capture_reference(
                        page,
                        output_dir / f"{surface}--content--light--{width}x{height}.png",
                        width,
                        height,
                    )
                if screen == "home":
                    _capture_home_state_references(page, output_dir, "light", width, height)
                    _capture_campus_card_home_state_references(page, output_dir, "light", width, height)
                if screen == "settings":
                    _capture_settings_account_state_references(
                        page,
                        output_dir,
                        "light",
                        width,
                        height,
                    )
                    _open_screen(page, prototype_url, "settings")
                    page.locator('[data-settings-section="general"]').evaluate("element => element.click()")
                    _capture_reference(
                        page,
                        output_dir / f"settings.home-notifications--content--light--{width}x{height}.png",
                        width,
                        height,
                    )
                if screen == "campus-card-detail":
                    _capture_campus_card_detail_state_references(page, output_dir, "light", width, height)
                if screen == "academic":
                    _capture_academic_state_references(page, output_dir, "light", width, height)
                if screen == "info":
                    _capture_info_state_references(page, output_dir, "light", width, height)
                if screen == "mail":
                    _capture_mail_state_references(page, output_dir, "light", width, height)
                if screen == "links":
                    _capture_links_state_references(page, output_dir, "light", width, height)
                if screen == "link-confirmation":
                    _capture_link_confirmation_state_references(page, output_dir, "light", width, height)

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

            page.evaluate(
                """localStorage.setItem('qingyuan:samples:theme', 'dark');
                document.documentElement.setAttribute('data-theme', 'dark');
                document.querySelectorAll('.theme-toggle').forEach((button) => {
                  button.setAttribute('aria-pressed', 'true');
                });"""
            )
            for screen in SCREENS:
                _open_screen(page, prototype_url, screen)
                _assert(page.locator("html").get_attribute("data-theme") == "dark", f"{width}px {screen} 暗色参考稿未生效")
                surface = SCREEN_SURFACES.get(screen)
                if surface is not None and surface != "schedule.calendar":
                    _capture_reference(
                        page,
                        output_dir / f"{surface}--content--dark--{width}x{height}.png",
                        width,
                        height,
                    )
                if screen == "home":
                    _capture_home_state_references(page, output_dir, "dark", width, height)
                    _capture_campus_card_home_state_references(page, output_dir, "dark", width, height)
                if screen == "settings":
                    _capture_settings_account_state_references(
                        page,
                        output_dir,
                        "dark",
                        width,
                        height,
                    )
                    _open_screen(page, prototype_url, "settings")
                    page.locator('[data-settings-section="general"]').evaluate("element => element.click()")
                    _capture_reference(
                        page,
                        output_dir / f"settings.home-notifications--content--dark--{width}x{height}.png",
                        width,
                        height,
                    )
                if screen == "campus-card-detail":
                    _capture_campus_card_detail_state_references(page, output_dir, "dark", width, height)
                if screen == "academic":
                    _capture_academic_state_references(page, output_dir, "dark", width, height)
                if screen == "info":
                    _capture_info_state_references(page, output_dir, "dark", width, height)
                if screen == "mail":
                    _capture_mail_state_references(page, output_dir, "dark", width, height)
                if screen == "links":
                    _capture_links_state_references(page, output_dir, "dark", width, height)
                if screen == "link-confirmation":
                    _capture_link_confirmation_state_references(page, output_dir, "dark", width, height)

        _capture_missing_state_references(page, output_dir, expected)
        _write_reference_index(output_dir, manifest, expected)
        _assert(not errors, "浏览器控制台错误：" + " | ".join(errors))
        context.close()
        browser.close()

    print(
        "Qingyuan page prototype passed browser verification. "
        f"Screenshots: {len(expected)} at {output_dir}"
    )

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--surface-prefix")
    args = parser.parse_args()
    verify(args.output.resolve(), args.surface_prefix)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
