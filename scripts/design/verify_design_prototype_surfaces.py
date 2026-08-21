#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
清源页面原型各领域状态采集。
@Project : SSPU-AllinOne
@File : verify_design_prototype_surfaces.py
@Author : Qintsg
@Date : 2026-08-18
"""

from __future__ import annotations

from pathlib import Path

from playwright.sync_api import Page

from verify_design_prototype_core import (
    VIEWPORTS,
    _assert,
    _assert_screen_interactions,
    _assert_targets,
    _capture_reference,
    _open_screen,
)


def _capture_mail_state_references(
    page: Page,
    output_dir: Path,
    theme: str,
    width: int,
    height: int,
) -> None:
    for state in ("initial", "loading", "empty", "stale", "error"):
        page.evaluate("state => window.qingyuanPrototype.setMailState(state)", state)
        if state == "stale":
            _assert(page.locator('.mail-stale-banner:visible').count() == 1, "邮箱 stale 状态未显示缓存提示")
            _assert(page.locator('.mail-layout:visible').count() == 1, "邮箱 stale 状态丢失已有列表")
        else:
            panel = page.locator(f'[data-mail-state-panel="{state}"]:visible')
            _assert(panel.count() == 1, f"邮箱 {state} 状态面板未显示")
        _capture_reference(
            page,
            output_dir / f"mail.inbox--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )

    for state in ("initial", "content", "loading", "error"):
        page.evaluate("state => window.qingyuanPrototype.setMailComposeState(state)", state)
        compose = page.locator('[data-mail-compose-panel]:visible')
        _assert(compose.count() == 1, f"邮箱撰写 {state} 状态未显示")
        if state == "content":
            compose.locator('input[name="to"]').fill("advisor@example.invalid")
            compose.locator('input[name="subject"]').fill("课程安排确认")
            compose.locator('textarea[name="body"]').fill("老师您好，我已核对本学期课程安排，谢谢。")
        if state == "loading":
            _assert(compose.locator('[data-mail-send]').is_disabled(), "邮箱撰写 loading 状态仍可提交")
        if state == "error":
            _assert(compose.locator('.mail-compose-error:visible').count() == 1, "邮箱撰写 error 状态未显示错误")
        _capture_reference(
            page,
            output_dir / f"mail.compose--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )

    page.evaluate("window.qingyuanPrototype.setMailState('content')")

def _capture_info_state_references(
    page: Page,
    output_dir: Path,
    theme: str,
    width: int,
    height: int,
    *,
    include_filters: bool = True,
) -> None:
    """
    采集当前资讯页的非内容状态，并按需附带筛选子流程。

    :param page: Playwright 页面。
    :param output_dir: 截图输出目录。
    :param theme: light 或 dark。
    :param width: 视口宽度。
    :param height: 视口高度。
    :param include_filters: 是否同时采集 info.filters 状态。
    :returns: None。
    """
    for state in ("initial", "loading", "empty", "stale", "error"):
        page.evaluate("state => window.qingyuanPrototype.setInfoState(state)", state)
        if state == "stale":
            _assert(page.locator('.info-stale-banner:visible').count() == 1, "资讯 stale 状态未显示缓存提示")
            _assert(page.locator('[data-info-feed-list]:visible').count() == 1, "资讯 stale 状态丢失已有内容")
        else:
            panel = page.locator(f'[data-info-state-panel="{state}"]:visible')
            _assert(panel.count() == 1, f"资讯 {state} 状态面板未显示")
        _capture_reference(
            page,
            output_dir / f"info.feed--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )

    page.evaluate("window.qingyuanPrototype.setInfoState('content')")
    if not include_filters:
        return
    page.evaluate("window.qingyuanPrototype.setInfoFilterState('content')")
    _capture_reference(
        page,
        output_dir / f"info.filters--content--{theme}--{width}x{height}.png",
        width,
        height,
    )
    page.evaluate("window.qingyuanPrototype.setInfoFilterState('empty')")
    _assert(page.locator('[data-info-filter-panel="empty"]:visible').count() == 1, "资讯筛选 empty 状态未显示")
    _capture_reference(
        page,
        output_dir / f"info.filters--empty--{theme}--{width}x{height}.png",
        width,
        height,
    )
    page.evaluate("window.qingyuanPrototype.setInfoFilterState('content')")

def _capture_info_surface_prefix(
    page: Page,
    output_dir: Path,
    prototype_url: str,
) -> None:
    """
    采集资讯流六态高保真参考图。

    :param page: Playwright 页面。
    :param output_dir: 截图输出目录。
    :param prototype_url: 页面原型地址。
    :returns: None。
    """
    for width, height in VIEWPORTS:
        page.set_viewport_size({"width": width, "height": height})
        page.emulate_media(reduced_motion="reduce")
        page.goto(prototype_url, wait_until="networkidle")
        for theme in ("light", "dark"):
            page.evaluate(
                "theme => localStorage.setItem('qingyuan:samples:theme', theme)",
                theme,
            )
            _open_screen(page, prototype_url, "info")
            _assert_screen_interactions(page, "info", width)
            _open_screen(page, prototype_url, "info")
            _assert_targets(page, width, "info")
            filter_action = page.locator('[data-info-more-filters]:visible')
            _assert(filter_action.count() == 1, "资讯页缺少更多筛选入口")
            _capture_reference(
                page,
                output_dir / f"info.feed--content--{theme}--{width}x{height}.png",
                width,
                height,
            )
            _capture_info_state_references(
                page,
                output_dir,
                theme,
                width,
                height,
                include_filters=False,
            )

def _capture_academic_state_references(
    page: Page,
    output_dir: Path,
    theme: str,
    width: int,
    height: int,
) -> None:
    states = (
        "initial",
        "loading",
        "empty",
        "stale",
        "error",
        "partial-error",
        "credentials-required",
        "credentials-partial",
        "operation-locked",
    )
    for state in states:
        page.evaluate("state => window.qingyuanPrototype.setAcademicState(state)", state)
        if state in ("stale", "partial-error", "credentials-partial", "operation-locked"):
            banner_class = {
                "stale": "academic-stale-banner",
                "partial-error": "academic-partial-banner",
                "credentials-partial": "academic-credentials-banner",
                "operation-locked": "academic-locked-banner",
            }[state]
            banner = page.locator(f'.{banner_class}:visible')
            _assert(banner.count() == 1, f"教务 {state} 状态缺少协同提示")
            _assert(page.locator('[data-academic-content]:visible').count() >= 2, f"教务 {state} 丢失已有内容")
        else:
            panel = page.locator(f'[data-academic-state-panel="{state}"]:visible')
            _assert(panel.count() == 1, f"教务 {state} 状态面板未显示")
        if state == "operation-locked":
            _assert(page.locator('[data-academic-refresh]:not([disabled])').count() == 0, "教务协同刷新期间仍可重复刷新")
            _assert(page.locator('[data-academic-route]:not([disabled])').count() == 0, "教务协同刷新期间仍可进入详情")
        _capture_reference(
            page,
            output_dir / f"academic.overview--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )
    page.evaluate("window.qingyuanPrototype.setAcademicState('content')")

def _capture_academic_surface_prefix(
    page: Page,
    output_dir: Path,
    prototype_url: str,
) -> None:
    for width, height in VIEWPORTS:
        page.set_viewport_size({"width": width, "height": height})
        page.emulate_media(reduced_motion="reduce")
        page.goto(prototype_url, wait_until="networkidle")
        for theme in ("light", "dark"):
            page.evaluate(
                "theme => localStorage.setItem('qingyuan:samples:theme', theme)",
                theme,
            )
            _open_screen(page, prototype_url, "academic")
            _capture_reference(
                page,
                output_dir / f"academic.overview--content--{theme}--{width}x{height}.png",
                width,
                height,
            )
            _capture_academic_state_references(
                page,
                output_dir,
                theme,
                width,
                height,
            )

def _capture_campus_card_home_state_references(
    page: Page,
    output_dir: Path,
    theme: str,
    width: int,
    height: int,
) -> None:
    for state in ("loading", "content", "empty", "stale", "error", "operation-locked"):
        page.evaluate("state => window.qingyuanPrototype.setCampusCardHomeState(state)", state)
        visible = page.locator(f'[data-campus-card-home-state="{state}"]:visible')
        _assert(visible.count() == 1, f"首页校园卡 {state} 状态未唯一显示")
        page.locator('.campus-card-overview').evaluate(
            "element => element.scrollIntoView({block: 'center', inline: 'nearest'})"
        )
        _capture_reference(
            page,
            output_dir / f"home.campus-card--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )
    page.evaluate("window.qingyuanPrototype.setCampusCardHomeState('content')")
    page.locator('.prototype-main').evaluate("element => element.scrollTop = 0")

def _capture_home_state_references(
    page: Page,
    output_dir: Path,
    theme: str,
    width: int,
    height: int,
) -> None:
    retained_states = ("stale", "partial-error", "credentials-partial", "operation-locked")
    for state in ("initial", "loading", "stale", "error", "partial-error", "credentials-partial", "operation-locked"):
        page.evaluate("state => window.qingyuanPrototype.setHomeState(state)", state)
        if state in retained_states:
            banner_class = {
                "stale": "home-stale-banner",
                "partial-error": "home-partial-banner",
                "credentials-partial": "home-credentials-banner",
                "operation-locked": "home-locked-banner",
            }[state]
            _assert(page.locator(f'.{banner_class}:visible').count() == 1, f"首页 {state} 状态未显示协同提示")
            _assert(page.locator('.home-layout:visible').count() == 1, "首页 stale 状态丢失已有内容")
        else:
            panel = page.locator(f'[data-home-state-panel="{state}"]:visible')
            _assert(panel.count() == 1, f"首页 {state} 状态面板未显示")
        if state == "operation-locked":
            _assert(page.locator('[data-home-refresh]:not([disabled])').count() == 0, "首页刷新期间仍可重复触发刷新")
        _assert_home_density(page, width, height)
        _capture_reference(
            page,
            output_dir / f"home.dashboard--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )
    page.evaluate("window.qingyuanPrototype.setHomeState('content')")
    page.locator('.prototype-main').evaluate("element => element.scrollTop = 0")

def _assert_home_density(page: Page, width: int, height: int) -> None:
    """
    校验首页在给定视口下无需默认滚动且不被导航遮挡。

    :param page: Playwright 页面。
    :param width: 视口宽度。
    :param height: 视口高度。
    :returns: None。
    """
    main_metrics = page.locator('.prototype-main').evaluate(
        "element => ({scrollHeight: element.scrollHeight, clientHeight: element.clientHeight, scrollTop: element.scrollTop})"
    )
    _assert(main_metrics["scrollHeight"] <= main_metrics["clientHeight"] + 1, f"{width}x{height} 首页需要滚动")
    _assert(main_metrics["scrollTop"] == 0, f"{width}x{height} 首页默认位置发生滚动")
    if width < 768 and page.locator('.home-utility-dock:visible').count() == 1:
        dock_box = page.locator('.home-utility-dock:visible').bounding_box()
        navigation_box = page.locator('.mobile-bar:visible').bounding_box()
        _assert(
            dock_box is not None
            and navigation_box is not None
            and dock_box["y"] + dock_box["height"] <= navigation_box["y"] + 1,
            f"{width}x{height} 首页行动坞被底部导航遮挡",
        )

def _capture_home_surface_prefix(
    page: Page,
    output_dir: Path,
    prototype_url: str,
) -> None:
    """
    采集首页内容态及协同状态参考图。

    :param page: Playwright 页面。
    :param output_dir: 截图输出目录。
    :param prototype_url: 页面原型地址。
    :returns: None。
    """
    for width, height in VIEWPORTS:
        page.set_viewport_size({"width": width, "height": height})
        page.emulate_media(reduced_motion="reduce")
        page.goto(prototype_url, wait_until="networkidle")
        for theme in ("light", "dark"):
            page.evaluate(
                "theme => localStorage.setItem('qingyuan:samples:theme', theme)",
                theme,
            )
            _open_screen(page, prototype_url, "home")
            _assert_screen_interactions(page, "home", width)
            _open_screen(page, prototype_url, "home")
            _assert_home_density(page, width, height)
            _capture_reference(
                page,
                output_dir / f"home.dashboard--content--{theme}--{width}x{height}.png",
                width,
                height,
            )
            _capture_home_state_references(page, output_dir, theme, width, height)

def _capture_settings_home_surface_prefix(
    page: Page,
    output_dir: Path,
    prototype_url: str,
) -> None:
    """
    采集常规设置与首页显示参考图。

    :param page: Playwright 页面。
    :param output_dir: 截图输出目录。
    :param prototype_url: 页面原型地址。
    :returns: None。
    """
    for width, height in VIEWPORTS:
        page.set_viewport_size({"width": width, "height": height})
        page.emulate_media(reduced_motion="reduce")
        page.goto(prototype_url, wait_until="networkidle")
        for theme in ("light", "dark"):
            page.evaluate(
                "theme => localStorage.setItem('qingyuan:samples:theme', theme)",
                theme,
            )
            _open_screen(page, prototype_url, "settings")
            _assert_screen_interactions(page, "settings", width)
            _open_screen(page, prototype_url, "settings")
            page.locator('[data-settings-section="general"]').evaluate("element => element.click()")
            _assert(page.locator('[data-settings-panel="general"]:visible').count() == 1, "常规设置未显示")
            _assert(page.locator('[data-settings-home-card] [role="switch"]:visible').count() == 8, "首页 8 项独立设置未完整显示")
            _assert_targets(page, width, "settings.home-notifications")
            _capture_reference(
                page,
                output_dir / f"settings.home-notifications--content--{theme}--{width}x{height}.png",
                width,
                height,
            )

def _capture_settings_account_state_references(
    page: Page,
    output_dir: Path,
    theme: str,
    width: int,
    height: int,
) -> None:
    """
    采集当前视口与主题下的安全账户正常态和保留内容错误态。

    :param page: 已打开设置页的 Playwright 页面。
    :param output_dir: 截图输出目录。
    :param theme: light 或 dark。
    :param width: 视口宽度。
    :param height: 视口高度。
    :returns: None。
    """
    page.locator('[data-settings-section="security"]').evaluate(
        "element => element.click()"
    )
    panel = page.locator('[data-settings-panel="security"]:visible')
    _assert(panel.count() == 1, "安全设置未显示")
    _assert(
        panel.locator('.security-toggle-row:visible').count() == 2,
        "安全设置缺少密码保护或系统快速验证",
    )
    _assert(
        panel.locator('.settings-credentials-form:visible').count() == 1,
        "安全设置缺少教务凭据表单",
    )
    _assert(
        panel.get_by_role("button", name="打开数据与隐私").count() == 1,
        "安全设置缺少数据与隐私入口",
    )
    document_width = page.evaluate("document.documentElement.scrollWidth")
    _assert(
        document_width <= width,
        f"{width}x{height} 安全设置出现页面级横向溢出：{document_width}>{width}",
    )
    _assert_targets(page, width, "settings.account")
    for state in ("content", "error"):
        page.evaluate(
            "state => window.qingyuanPrototype.setSettingsAccountState(state)",
            state,
        )
        error = panel.locator('[data-settings-account-error]:visible')
        _assert(
            error.count() == (1 if state == "error" else 0),
            f"安全设置 {state} 状态提示不正确",
        )
        _assert(
            panel.locator('.security-toggle-row:visible').count() == 2
            and panel.locator('.settings-credentials-form:visible').count() == 1
            and panel.get_by_role("button", name="打开数据与隐私").count() == 1,
            f"安全设置 {state} 状态未保留协同任务",
        )
        page.locator('.prototype-main').evaluate("element => element.scrollTop = 0")
        _capture_reference(
            page,
            output_dir / f"settings.account--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )
        if state == "error":
            retry = panel.get_by_role("button", name="重试")
            retry.click()
            _assert(
                panel.locator('[data-settings-account-error]:visible').count() == 0,
                "安全设置重试后未原位清除错误提示",
            )
            _assert(
                panel.locator('.settings-credentials-form:visible').count() == 1,
                "安全设置重试清空了凭据表单",
            )

def _capture_settings_account_surface_prefix(
    page: Page,
    output_dir: Path,
    prototype_url: str,
) -> None:
    """
    采集安全与账户的正常和保留内容错误状态。

    :param page: Playwright 页面。
    :param output_dir: 截图输出目录。
    :param prototype_url: 页面原型地址。
    :returns: None。
    """
    for width, height in VIEWPORTS:
        page.set_viewport_size({"width": width, "height": height})
        page.emulate_media(reduced_motion="reduce")
        page.goto(prototype_url, wait_until="networkidle")
        for theme in ("light", "dark"):
            page.evaluate(
                "theme => localStorage.setItem('qingyuan:samples:theme', theme)",
                theme,
            )
            _open_screen(page, prototype_url, "settings")
            _capture_settings_account_state_references(
                page,
                output_dir,
                theme,
                width,
                height,
            )

def _capture_campus_card_detail_state_references(
    page: Page,
    output_dir: Path,
    theme: str,
    width: int,
    height: int,
) -> None:
    for state in ("empty", "stale", "error", "partial-error", "operation-locked", "validation-error"):
        page.evaluate("window.scrollTo(0, 0)")
        page.locator('.prototype-main').evaluate("element => element.scrollTop = 0")
        page.evaluate("state => window.qingyuanPrototype.setCampusCardDetailState(state)", state)
        if state == "empty":
            panel = page.locator('.campus-card-detail-state[data-campus-card-detail-state="empty"]:visible')
            _assert(panel.count() == 1, "校园卡详情 empty 状态未显示")
            panel.scroll_into_view_if_needed()
        elif state == "error":
            panel = page.locator('.campus-card-detail-state[data-campus-card-detail-state="error"]:visible')
            _assert(panel.count() == 1, "校园卡详情 error 状态未显示")
            _assert(page.locator('[data-campus-card-detail-content]:visible').count() == 0, "校园卡详情首次失败错误保留了无效记录")
            _assert(page.locator('[data-campus-card-balance]:visible').count() == 0, "校园卡详情首次失败错误展示了无效余额")
            panel.scroll_into_view_if_needed()
        elif state == "validation-error":
            banner = page.locator('[data-campus-card-detail-validation]:visible')
            _assert(banner.count() == 1, "校园卡详情日期校验错误未显示")
            _assert(page.locator('[data-campus-card-detail-content]:visible').count() == 1, "校园卡详情日期校验错误清空了有效记录")
            banner.scroll_into_view_if_needed()
        else:
            banner_selector = {
                "stale": "[data-campus-card-stale]",
                "partial-error": "[data-campus-card-partial-error]",
                "operation-locked": "[data-campus-card-operation]",
            }[state]
            banner = page.locator(f'{banner_selector}:visible')
            _assert(banner.count() == 1, f"校园卡详情 {state} 缺少协同提示")
            _assert(page.locator('[data-campus-card-detail-content]:visible').count() == 1, f"校园卡详情 {state} 丢失有效记录")
            if state == "operation-locked":
                _assert(page.locator('[data-campus-card-operation-lock]:not([disabled])').count() == 0, "校园卡详情操作锁未冻结日期范围与远端操作")
            banner.scroll_into_view_if_needed()
        _capture_reference(
            page,
            output_dir / f"home.campus-card-detail--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )
    page.evaluate("window.qingyuanPrototype.setCampusCardDetailState('content')")
    page.locator('.prototype-main').evaluate("element => element.scrollTop = 0")

def _capture_campus_card_surface_prefix(
    page: Page,
    output_dir: Path,
    prototype_url: str,
    include_home: bool,
    include_detail: bool,
) -> None:
    for width, height in VIEWPORTS:
        page.set_viewport_size({"width": width, "height": height})
        page.emulate_media(reduced_motion="reduce")
        page.goto(prototype_url, wait_until="networkidle")
        for theme in ("light", "dark"):
            page.evaluate(
                "theme => localStorage.setItem('qingyuan:samples:theme', theme)",
                theme,
            )
            if include_home:
                _open_screen(page, prototype_url, "home")
                _capture_campus_card_home_state_references(
                    page, output_dir, theme, width, height
                )
            if include_detail:
                _open_screen(page, prototype_url, "campus-card-detail")
                _capture_reference(
                    page,
                    output_dir / f"home.campus-card-detail--content--{theme}--{width}x{height}.png",
                    width,
                    height,
                )
                _capture_campus_card_detail_state_references(
                    page, output_dir, theme, width, height
                )

def _capture_links_state_references(
    page: Page, output_dir: Path, theme: str, width: int, height: int
) -> None:
    for state in ("loading", "empty", "error"):
        page.evaluate("state => window.qingyuanPrototype.setLinksState(state)", state)
        panel = page.locator(f'[data-links-state-panel="{state}"]:visible')
        _assert(panel.count() == 1, f"快捷入口 {state} 状态面板未显示")
        _capture_reference(
            page,
            output_dir / f"links.directory--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )
    page.evaluate("window.qingyuanPrototype.setLinksState('content')")

def _capture_link_confirmation_state_references(
    page: Page, output_dir: Path, theme: str, width: int, height: int
) -> None:
    page.evaluate("window.qingyuanPrototype.setLinkConfirmationState('error')")
    _assert(
        page.locator('[data-link-confirmation-state="error"]:visible').count() == 2,
        "外部确认页 error 状态未显示",
    )
    _capture_reference(
        page,
        output_dir / f"links.external-confirmation--error--{theme}--{width}x{height}.png",
        width,
        height,
    )
    page.evaluate("window.qingyuanPrototype.setLinkConfirmationState('content')")
