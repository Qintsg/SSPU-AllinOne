#!/usr/bin/env python3
"""在真实浏览器中核验清源页面级原型。"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import struct

from playwright.sync_api import Page, sync_playwright


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PROTOTYPE = PROJECT_ROOT / "docs" / "design" / "patterns" / "samples" / "app-shell.html"
STATE_REFERENCE = PROJECT_ROOT / "docs" / "design" / "patterns" / "samples" / "state-reference.html"
VISUAL_MANIFEST = PROJECT_ROOT / "docs" / "design" / "resources" / "visual-manifest.json"
REFERENCE_CATALOG = PROJECT_ROOT / "docs" / "design" / "resources" / "reference-catalog.json"
SCREENS = ("home", "campus-card-detail", "academic", "schedule", "info", "mail", "mail-detail", "links", "link-confirmation", "settings")
SCREEN_SURFACES = {
    "home": "home.dashboard",
    "campus-card-detail": "home.campus-card-detail",
    "academic": "academic.overview",
    "schedule": "schedule.calendar",
    "info": "info.feed",
    "mail": "mail.inbox",
    "mail-detail": "mail.message-detail",
    "links": "links.directory",
    "link-confirmation": "links.external-confirmation",
    "settings": "settings.account",
}
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
    # file:// 同文档仅改变 hash 不会重建 DOM，必须显式重载才能清除上一页交互状态。
    page.reload(wait_until="networkidle")
    _assert(page.locator(f'[data-screen="{screen}"]:visible').count() == 1, f"{screen} 页面未唯一显示")
    _assert(page.locator("[data-screen]:visible").count() == 1, f"{screen} 页面切换后存在多个活动页面")


def _capture_reference(page: Page, target: Path, width: int, height: int) -> None:
    # Playwright 的鼠标位置跨 reload 保留；截图前移出交互目标，避免默认态被 hover 污染。
    page.mouse.move(0, 0)
    png = page.screenshot(path=target, full_page=False)
    actual_width, actual_height = struct.unpack(">II", png[16:24])
    _assert(
        (actual_width, actual_height) == (width, height),
        f"{target.name} 截图尺寸错误：{actual_width}x{actual_height} != {width}x{height}",
    )


def _load_reference_contract() -> tuple[dict, dict[str, dict], list[dict]]:
    manifest = json.loads(VISUAL_MANIFEST.read_text(encoding="utf-8"))
    catalog = json.loads(REFERENCE_CATALOG.read_text(encoding="utf-8"))
    entries = {entry["id"]: entry for entry in catalog["surfaces"]}
    expected: list[dict] = []
    for surface in manifest["surfaces"]:
        entry = entries[surface["id"]]
        external_region_states = surface.get("externalRegionStates", {})
        for state in surface["states"]:
            active_external_regions = [
                region_id
                for region_id, states in external_region_states.items()
                if state in states
            ]
            for theme in manifest["meta"]["themes"]:
                for viewport in manifest["meta"]["viewports"]:
                    expected.append(
                        {
                            "entry": entry,
                            "group": surface["group"],
                            "surface": surface["id"],
                            "state": state,
                            "theme": theme,
                            "width": viewport["width"],
                            "height": viewport["height"],
                            "externalRegions": active_external_regions,
                            "filename": (
                                f'{surface["id"]}--{state}--{theme}--'
                                f'{viewport["width"]}x{viewport["height"]}.png'
                            ),
                        }
                    )
    return manifest, entries, expected


def _capture_missing_state_references(page: Page, output_dir: Path, expected: list[dict]) -> None:
    reference_url = STATE_REFERENCE.resolve().as_uri()
    for width, height in VIEWPORTS:
        page.set_viewport_size({"width": width, "height": height})
        page.emulate_media(reduced_motion="reduce")
        page.goto(reference_url, wait_until="networkidle")
        page.evaluate("document.fonts.ready")
        for item in expected:
            if item["width"] != width or item["height"] != height:
                continue
            target = output_dir / item["filename"]
            if target.exists():
                continue
            page.evaluate(
                "payload => window.qingyuanStateReference.render(payload)",
                {
                    "entry": item["entry"],
                    "group": item["group"],
                    "state": item["state"],
                    "theme": item["theme"],
                    "externalRegions": item["externalRegions"],
                },
            )
            _assert(
                page.locator(f'body[data-surface="{item["surface"]}"][data-state="{item["state"]}"]').count() == 1,
                f'{item["filename"]} 状态参考未正确渲染',
            )
            document_width = page.evaluate("document.documentElement.scrollWidth")
            _assert(
                document_width <= width,
                f'{item["filename"]} 出现页面级横向溢出：{document_width}>{width}',
            )
            _assert_targets(page, width, item["surface"])
            if item["state"] == "external-confirmation":
                dialog = page.get_by_role("dialog")
                _assert(dialog.count() == 1, f'{item["filename"]} 外部确认层缺少 dialog 语义')
                _assert(dialog.get_attribute("aria-modal") == "true", f'{item["filename"]} 外部确认层缺少 aria-modal')
                title_id = dialog.get_attribute("aria-labelledby")
                _assert(bool(title_id), f'{item["filename"]} 外部确认层缺少标题关联')
                _assert(
                    page.locator(f"#{title_id}").count() == 1,
                    f'{item["filename"]} 外部确认层标题关联无效',
                )
                cancel = dialog.get_by_role("button", name="取消")
                confirm = dialog.get_by_role("button", name="继续打开")
                _assert(cancel.evaluate("element => element === document.activeElement"), f'{item["filename"]} 默认焦点未落在安全行动')
                page.keyboard.press("Shift+Tab")
                _assert(confirm.evaluate("element => element === document.activeElement"), f'{item["filename"]} Shift+Tab 逃出对话框')
                page.keyboard.press("Tab")
                _assert(cancel.evaluate("element => element === document.activeElement"), f'{item["filename"]} Tab 逃出对话框')
                page.keyboard.press("Escape")
                _assert(page.locator('.reference-modal-scrim[hidden]').count() == 1, f'{item["filename"]} Escape 未关闭对话框')
                return_focus = (
                    page.locator('.reference-license-link').first
                    if item["surface"] == "settings.licenses"
                    else page.locator('[data-reference-more]')
                )
                _assert(
                    return_focus.evaluate("element => element === document.activeElement"),
                    f'{item["filename"]} 关闭后未归还触发器焦点',
                )
                page.evaluate(
                    "payload => window.qingyuanStateReference.render(payload)",
                    {
                        "entry": item["entry"],
                        "group": item["group"],
                        "state": item["state"],
                        "theme": item["theme"],
                        "externalRegions": item["externalRegions"],
                    },
                )
            elif item["state"] == "external-cancelled" and item["surface"] == "settings.about":
                return_focus = page.locator('[data-reference-more]')
                _assert(
                    return_focus.evaluate("element => element === document.activeElement"),
                    f'{item["filename"]} 取消态未保留触发器焦点',
                )
            _capture_reference(page, target, width, height)
            if item["externalRegions"]:
                regions = []
                for region_id in item["externalRegions"]:
                    region = page.locator(f'[data-external-region="{region_id}"]')
                    _assert(
                        region.count() == 1,
                        f'{item["filename"]} 缺少外部区域 {region_id}',
                    )
                    box = region.bounding_box()
                    _assert(box is not None, f'{item["filename"]} 外部区域 {region_id} 不可见')
                    regions.append(
                        {
                            "id": region_id,
                            "x": round(box["x"]),
                            "y": round(box["y"]),
                            "width": round(box["width"]),
                            "height": round(box["height"]),
                        }
                    )
                Path(f"{target}.regions.json").write_text(
                    json.dumps({"externalRegions": regions}, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8",
                )


def _write_reference_index(output_dir: Path, manifest: dict, expected: list[dict]) -> None:
    expected_names = {item["filename"] for item in expected}
    actual_files = sorted(output_dir.glob("*.png"), key=lambda item: item.name)
    actual_names = {item.name for item in actual_files}
    missing = sorted(expected_names - actual_names)
    unexpected = sorted(actual_names - expected_names)
    _assert(not missing, f"设计参考缺少 {len(missing)} 张：{', '.join(missing[:5])}")
    _assert(not unexpected, f"设计参考存在清单外截图：{', '.join(unexpected[:5])}")
    expected_sidecars = {
        f'{item["filename"]}.regions.json'
        for item in expected
        if item["externalRegions"]
    }
    actual_sidecars = {
        item.name for item in output_dir.glob("*.png.regions.json")
    }
    _assert(
        actual_sidecars == expected_sidecars,
        "设计参考外部区域 sidecar 与逐状态声明不一致",
    )
    index = {
        "meta": {
            "version": manifest["meta"]["version"],
            "designSystem": manifest["meta"]["designSystem"],
            "fixture": manifest["meta"]["capture"]["fixture"],
            "clock": manifest["meta"]["capture"]["clock"],
            "count": len(actual_files),
            "externalRegionSidecars": len(actual_sidecars),
            "status": "design-review-candidate",
        },
        "files": [
            {
                "name": item.name,
                "sha256": hashlib.sha256(item.read_bytes()).hexdigest(),
            }
            for item in actual_files
        ],
        "regions": [
            {
                "name": name,
                "sha256": hashlib.sha256((output_dir / name).read_bytes()).hexdigest(),
            }
            for name in sorted(actual_sidecars)
        ],
    }
    (output_dir / "reference-index.json").write_text(
        json.dumps(index, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _assert_screen_interactions(page: Page, screen: str, viewport_width: int) -> None:
    if screen == "home":
        page.get_by_role("button", name="刷新首页").click()
        _assert("刷新首页已完成" in page.locator('.prototype-toast:visible').inner_text(), "页面行动缺少可感知反馈")
        page.locator('.campus-card-overview').click()
        _assert(page.locator('[data-screen="campus-card-detail"]:visible').count() == 1, "首页校园卡无法进入交易详情")
        page.get_by_role("button", name="返回主页").click()
        _assert(page.locator('[data-screen="home"]:visible').count() == 1, "校园卡详情无法返回主页")
    elif screen == "campus-card-detail":
        _assert(page.locator('.campus-card-transaction:visible').count() == 3, "校园卡详情未展示确定性交易记录")
        expense = page.get_by_role("tab", name="支出")
        expense.click()
        _assert(page.locator('.campus-card-transaction:visible').count() == 2, "校园卡支出筛选结果错误")
        expense.focus()
        page.keyboard.press("ArrowRight")
        _assert(page.get_by_role("tab", name="收入").get_attribute("aria-selected") == "true", "校园卡方向键未切换收支方向")
        _assert(page.locator('.campus-card-transaction:visible').count() == 1, "校园卡收入筛选结果错误")
        page.evaluate("window.qingyuanPrototype.setCampusCardDetailState('error')")
        _assert(page.locator('.campus-card-filter-error:visible').count() == 1, "校园卡日期错误没有明确提示")
        _assert(page.locator('[data-campus-card-detail-content]:visible').count() == 1, "校园卡日期错误清空了上次有效结果")
    elif screen == "schedule":
        schedule_page = page.locator('[data-screen="schedule"]')
        if viewport_width < 768:
            selected_box = schedule_page.locator('.domain-tab[aria-selected="true"]').bounding_box()
            strip_box = schedule_page.locator('.domain-tabs').bounding_box()
            _assert(
                selected_box is not None
                and strip_box is not None
                and selected_box["x"] >= strip_box["x"]
                and selected_box["x"] + selected_box["width"] <= strip_box["x"] + strip_box["width"],
                "compact 课表未露出当天 Tab",
            )
        first_tab = schedule_page.locator('.domain-tab').first
        first_tab.click()
        _assert(first_tab.get_attribute("aria-selected") == "true", "课表日期 Tab 未更新选择状态")
        _assert(schedule_page.locator('.domain-tab[aria-selected="true"]').count() == 1, "课表存在多个已选 Tab")
        if viewport_width < 768:
            _assert(schedule_page.locator('.schedule-board:visible').count() == 0, "compact 课表仍显示桌面周网格")
            _assert(schedule_page.locator('.schedule-day-list:visible').count() == 1, "compact 课表未显示按天列表")
            _assert("数据结构" in schedule_page.locator('.schedule-day-list:visible').inner_text(), "课表 Tab 未切换当天课程")
        else:
            _assert(schedule_page.locator('.schedule-board:visible').count() == 1, "非 compact 课表未显示周网格")
        first_tab.focus()
        page.keyboard.press("ArrowRight")
        second_tab = schedule_page.locator('.domain-tab').nth(1)
        _assert(second_tab.get_attribute("aria-selected") == "true", "课表方向键未切换 Tab")
        _assert(second_tab.evaluate("element => element === document.activeElement"), "课表方向键未移动焦点")
    elif screen == "info":
        page.get_by_role("button", name="学校官网 · 5").click()
        _assert(page.locator('.feed-entry:visible').count() == 1, "信息来源筛选未过滤文章")
        _assert("学校官网" in page.locator('.feed-entry:visible').inner_text(), "信息来源筛选结果不正确")
        school_filter = page.get_by_role("button", name="学校官网 · 5")
        _assert(school_filter.get_attribute("aria-pressed") == "true", "信息筛选未同步按压语义")
        school_filter.focus()
        page.keyboard.press("ArrowRight")
        _assert(page.get_by_role("button", name="教务处 · 4").get_attribute("aria-pressed") == "true", "信息筛选方向键未切换来源")
        page.locator('[data-info-search]').fill("不存在的资讯")
        _assert(page.locator('[data-info-filter-panel="empty"]:visible').count() == 1, "资讯搜索没有明确筛选空状态")
        page.locator('[data-info-clear-filter]:visible').click()
        _assert(page.locator('[data-info-entry]:visible').count() == 3, "清除资讯筛选未恢复全部内容")
    elif screen == "mail":
        page.locator('.mail-item').first.focus()
        page.keyboard.press("ArrowDown")
        _assert(page.locator('.mail-item.is-active').count() == 1, "邮件列表存在多个选中项")
        _assert(page.locator('.mail-item').nth(1).get_attribute("aria-selected") == "true", "邮件方向键未同步选中语义")
        _assert(page.locator('.mail-content:visible h2').inner_text() == "图书馆借阅到期提醒", "可见邮件详情未随选择更新")
        if viewport_width <= 900:
            _assert(page.locator('.mail-list:visible').count() == 0, "compact/medium 邮件详情未替换列表")
            page.locator('.mail-back:visible').click()
            _assert(page.locator('.mail-list:visible').count() == 1, "邮件详情无法返回收件箱")
    elif screen == "links":
        favorites = page.locator('.link-favorite')
        _assert(favorites.count() == 6, "快速跳转未完整表达六个收藏入口")
        favorites.first.click()
        _assert(favorites.first.get_attribute("aria-pressed") == "true", "快速跳转收藏状态未同步语义")
        page.locator('[data-screen="links"] .search-box input').fill("图书馆")
        _assert(page.locator('.link-groups .action-row:visible').count() == 1, "快速跳转搜索结果不唯一")
        _assert("图书馆" in page.locator('.link-groups .action-row:visible').inner_text(), "快速跳转搜索结果不正确")
        page.locator('[data-screen="links"] .search-box input').fill("不存在的入口")
        _assert(page.locator('[data-search-empty]:visible').count() == 1, "快速跳转没有明确空状态")
        page.locator('[data-clear-search]:visible').click()
        _assert(page.locator('.link-groups .action-row:visible').count() == 6, "清除搜索未恢复全部入口")
    elif screen == "link-confirmation":
        _assert("auth.example.invalid" in page.locator('.external-target').inner_text(), "外部确认页未显示目标域名")
        page.evaluate("window.qingyuanPrototype.setLinkConfirmationState('error')")
        _assert(page.locator('[data-link-confirmation-state="error"]:visible').count() == 2, "外部确认页未阻止缺少 OA 凭据的跳转")
        page.locator('[data-link-confirmation-back]').click()
        _assert(page.locator('[data-screen="links"]:visible').count() == 1, "外部确认页无法返回快捷入口")
    elif screen == "settings":
        switch = page.get_by_role("switch", name="自动锁定")
        switch.click()
        _assert(switch.get_attribute("aria-checked") == "false", "设置开关 ARIA 状态未同步")
        account_tab = page.get_by_role("tab", name="账户与连接")
        account_tab.focus()
        page.keyboard.press("ArrowRight")
        page.keyboard.press("ArrowRight")
        appearance = page.locator('[data-settings-panel="appearance"]:visible')
        _assert(appearance.count() == 1 and "颜色主题" in appearance.inner_text(), "设置外观分区内容未切换")
        _assert(page.locator('[data-settings-panel="account"]:visible').count() == 0, "设置切换后仍显示账户内容")
        _assert(page.locator('#settings-title').inner_text() == "外观", "设置分区切换未同步页面标题")
        if viewport_width <= 900:
            nav_box = page.locator('.settings-nav').bounding_box()
            _assert(nav_box is not None and nav_box["height"] <= 64, "compact/medium 设置导航仍占用过多纵向空间")


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
) -> None:
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
    for state in ("loading", "content", "empty", "stale", "error"):
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
    for state in ("initial", "loading", "stale", "error"):
        page.evaluate("state => window.qingyuanPrototype.setHomeState(state)", state)
        if state == "stale":
            _assert(page.locator('.home-stale-banner:visible').count() == 1, "首页 stale 状态未显示缓存提示")
            _assert(page.locator('.home-layout:visible').count() == 1, "首页 stale 状态丢失已有内容")
        else:
            panel = page.locator(f'[data-home-state-panel="{state}"]:visible')
            _assert(panel.count() == 1, f"首页 {state} 状态面板未显示")
        _capture_reference(
            page,
            output_dir / f"home.dashboard--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )
    page.evaluate("window.qingyuanPrototype.setHomeState('content')")
    page.locator('.prototype-main').evaluate("element => element.scrollTop = 0")


def _capture_campus_card_detail_state_references(
    page: Page,
    output_dir: Path,
    theme: str,
    width: int,
    height: int,
) -> None:
    for state in ("empty", "error"):
        page.evaluate("state => window.qingyuanPrototype.setCampusCardDetailState(state)", state)
        if state == "empty":
            panel = page.locator('.campus-card-detail-state[data-campus-card-detail-state="empty"]:visible')
            _assert(panel.count() == 1, "校园卡详情 empty 状态未显示")
            panel.scroll_into_view_if_needed()
        else:
            error = page.locator('.campus-card-filter-error:visible')
            _assert(error.count() == 1, "校园卡详情 error 状态未显示")
            _assert(page.locator('[data-campus-card-detail-content]:visible').count() == 1, "校园卡详情 error 状态丢失有效记录")
            error.scroll_into_view_if_needed()
        _capture_reference(
            page,
            output_dir / f"home.campus-card-detail--{state}--{theme}--{width}x{height}.png",
            width,
            height,
        )
    page.evaluate("window.qingyuanPrototype.setCampusCardDetailState('content')")
    page.locator('.prototype-main').evaluate("element => element.scrollTop = 0")


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
            if surface_prefix == "academic.overview":
                _capture_academic_surface_prefix(
                    page,
                    output_dir,
                    prototype_url,
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
                surface = SCREEN_SURFACES[screen]
                _capture_reference(
                    page,
                    output_dir / f"{surface}--content--light--{width}x{height}.png",
                    width,
                    height,
                )
                if screen == "home":
                    _capture_home_state_references(page, output_dir, "light", width, height)
                    _capture_campus_card_home_state_references(page, output_dir, "light", width, height)
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
                surface = SCREEN_SURFACES[screen]
                _capture_reference(
                    page,
                    output_dir / f"{surface}--content--dark--{width}x{height}.png",
                    width,
                    height,
                )
                if screen == "home":
                    _capture_home_state_references(page, output_dir, "dark", width, height)
                    _capture_campus_card_home_state_references(page, output_dir, "dark", width, height)
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
