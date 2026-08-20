#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""
清源页面原型验证核心契约与截图完整性。
@Project : SSPU-AllinOne
@File : verify_design_prototype_core.py
@Author : Qintsg
@Date : 2026-08-18
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import struct

from playwright.sync_api import Page


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

def _assert_component_workbench(page: Page, viewport_width: int, surface: str) -> None:
    """
    核验组件工作台的响应式密度、可达性与协同状态。

    :param page: 当前 Playwright 页面。
    :param viewport_width: 当前视口宽度。
    :param surface: 当前组件界面标识。
    :returns: 无返回值。
    """
    stage = page.locator(".reference-component-stage")
    grid = page.locator(".reference-component-workbench-grid")
    cards = page.locator(".reference-component-card")
    _assert(stage.count() == 1, f"{viewport_width}px {surface} 缺少唯一组件工作台")
    _assert(grid.count() == 1, f"{viewport_width}px {surface} 缺少组件契约网格")
    _assert(cards.count() == 3, f"{viewport_width}px {surface} 未完整显示三组组件契约")
    _assert(
        page.locator(".reference-component-card:visible").count() == 3,
        f"{viewport_width}px {surface} 隐藏了组件契约",
    )

    expected_columns = 1 if viewport_width < 700 else 2 if viewport_width < 1200 else 3
    actual_columns = grid.evaluate(
        "element => getComputedStyle(element).gridTemplateColumns.trim().split(/\\s+/).length"
    )
    _assert(
        actual_columns == expected_columns,
        f"{viewport_width}px {surface} 网格列数错误：{actual_columns}!={expected_columns}",
    )

    unused_card_space = cards.evaluate_all(
        """elements => elements.map((element) => {
          const style = getComputedStyle(element);
          const last = element.lastElementChild;
          return element.getBoundingClientRect().bottom
            - Number.parseFloat(style.paddingBottom)
            - last.getBoundingClientRect().bottom;
        })"""
    )
    _assert(
        all(abs(value) <= 1.5 for value in unused_card_space),
        f"{viewport_width}px {surface} 存在被无效拉高的空白卡片：{unused_card_space}",
    )

    animation = stage.evaluate("element => getComputedStyle(element).animationName")
    _assert(animation == "none", f"{viewport_width}px {surface} 减少动态时仍有工作台动画")
    first_button = stage.locator("button:visible").first
    if first_button.count() > 0:
        first_button.focus()
        outline = first_button.evaluate("element => getComputedStyle(element).outlineWidth")
        _assert(
            float(outline.removesuffix("px")) >= 2,
            f"{viewport_width}px {surface} 键盘焦点不可见",
        )

    if surface == "components.actions":
        segments = page.locator("[data-component-segment]")
        segments.nth(0).click()
        _assert(segments.nth(0).get_attribute("aria-checked") == "true", "分段点击未同步选中态")
        segments.nth(0).focus()
        page.keyboard.press("ArrowRight")
        _assert(segments.nth(1).get_attribute("aria-checked") == "true", "分段方向键未切换选中态")
        _assert(
            segments.nth(1).evaluate("element => element === document.activeElement"),
            "分段方向键未同步焦点",
        )
        component_switch = page.locator("[data-component-switch]")
        component_switch.click()
        _assert(component_switch.get_attribute("aria-checked") == "false", "开关状态未同步")
        slider = page.locator("[data-component-slider]")
        slider.focus()
        page.keyboard.press("ArrowRight")
        _assert(slider.get_attribute("aria-valuenow") == "72", "滑块键盘增量错误")
    elif surface == "components.navigation":
        tabs = page.locator("[data-component-tab]")
        tabs.nth(1).click()
        _assert(tabs.nth(1).get_attribute("aria-selected") == "true", "页签点击未同步选中态")
        tabs.nth(1).focus()
        page.keyboard.press("ArrowLeft")
        _assert(tabs.nth(0).get_attribute("aria-selected") == "true", "页签方向键未切换选中态")
        pages = page.locator("[data-component-page]")
        pages.nth(2).click()
        _assert(pages.nth(2).get_attribute("aria-current") == "page", "分页点击未同步当前页")
        destinations = page.locator(".reference-component-bottom-nav [data-component-destination]")
        destinations.nth(1).click()
        _assert(destinations.nth(1).get_attribute("aria-pressed") == "true", "底栏目的地未同步选中态")
    elif surface == "components.feedback":
        undo = page.locator("[data-component-undo]")
        undo.click()
        _assert("更改已撤销" in undo.locator("..").inner_text(), "Toast 撤销未同步反馈")

    scroller = page.locator(".reference-component-scroll")
    scroller.evaluate("element => element.scrollTop = element.scrollHeight")
    scroller_box = scroller.bounding_box()
    last_card_box = cards.last.bounding_box()
    _assert(
        scroller_box is not None
        and last_card_box is not None
        and last_card_box["y"] + last_card_box["height"] <= scroller_box["y"] + scroller_box["height"] + 1,
        f"{viewport_width}px {surface} 最后一组组件无法滚动到达",
    )
    scroller.evaluate("element => element.scrollTop = 0")

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
            if item["surface"].startswith("components."):
                _assert_component_workbench(page, width, item["surface"])
                # 协同行为核验会改变选中、进度和反馈状态；截图前恢复冻结默认态。
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
                if item["surface"] == "settings.licenses":
                    return_focus = page.locator('.reference-license-link').first
                elif page.locator('[data-reference-external-trigger]').count() > 0:
                    return_focus = page.locator('[data-reference-external-trigger]').first
                else:
                    return_focus = page.locator('[data-reference-more]')
                _assert(
                    return_focus.evaluate("element => element === document.activeElement"),
                    f'{item["filename"]} 关闭后未归还触发器焦点',
                )
                page.mouse.click(width - 1, height - 1)
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
            elif item["surface"].startswith("settings.confirm-"):
                dialog = page.get_by_role("dialog")
                cancel = dialog.get_by_role("button", name="取消")
                danger = dialog.get_by_role("button").last
                return_focus = page.locator('.reference-shell-destination.is-active:visible')
                _assert(cancel.evaluate("element => element === document.activeElement"), f'{item["filename"]} 默认焦点未落在取消行动')
                page.keyboard.press("Shift+Tab")
                _assert(danger.evaluate("element => element === document.activeElement"), f'{item["filename"]} Shift+Tab 逃出危险确认')
                page.keyboard.press("Tab")
                _assert(cancel.evaluate("element => element === document.activeElement"), f'{item["filename"]} Tab 逃出危险确认')
                page.mouse.click(1, 1)
                _assert(dialog.is_visible(), f'{item["filename"]} 遮罩错误关闭危险确认')
                page.keyboard.press("Escape")
                _assert(dialog.is_hidden(), f'{item["filename"]} Escape 未关闭危险确认')
                _assert(return_focus.evaluate("element => element === document.activeElement"), f'{item["filename"]} 关闭后未归还设置入口焦点')
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
        page.evaluate("window.qingyuanPrototype.setCampusCardValidation(true)")
        _assert(page.locator('.campus-card-filter-error:visible').count() == 1, "校园卡日期错误没有明确提示")
        _assert(page.locator('[data-campus-card-detail-content]:visible').count() == 1, "校园卡日期错误清空了上次有效结果")
        page.evaluate("window.qingyuanPrototype.setCampusCardDetailState('operation-locked')")
        _assert(page.locator('[data-campus-card-operation]:visible').count() == 1, "校园卡同步锁缺少可感知反馈")
        _assert(page.locator('[data-campus-card-detail-content]:visible').count() == 1, "校园卡同步锁清空了有效记录")
        _assert(page.locator('[data-campus-card-operation-lock]:not([disabled])').count() == 0, "校园卡同步期间仍可修改日期范围或重复触发远端操作")
        page.evaluate("window.qingyuanPrototype.setCampusCardDetailState('partial-error')")
        _assert(page.locator('[data-campus-card-partial-error]:visible').count() == 1, "校园卡部分失败缺少恢复提示")
        _assert(page.locator('[data-campus-card-detail-content]:visible').count() == 1, "校园卡部分失败清空了有效记录")
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
        switch = page.get_by_role("switch", name="显示今日学程时间轨")
        switch.click()
        _assert(switch.get_attribute("aria-checked") == "false", "设置开关 ARIA 状态未同步")
        switch.click()
        _assert(switch.get_attribute("aria-checked") == "true", "设置开关无法恢复原值")
        if viewport_width < 900:
            trigger = page.locator('.settings-compact-trigger:visible')
            trigger.click()
            drawer = page.locator('#settings-section-list[role="dialog"]:visible')
            _assert(drawer.count() == 1, "compact 设置分区未以抽屉呈现")
            general_tab = page.get_by_role("tab", name="常规")
            _assert(general_tab.evaluate("element => element === document.activeElement"), "设置抽屉未聚焦当前分区")
            page.keyboard.press("Shift+Tab")
            _assert(page.get_by_role("tab", name="关于").evaluate("element => element === document.activeElement"), "设置抽屉 Shift+Tab 未循环")
            page.keyboard.press("Escape")
            _assert(page.locator('#settings-section-list[role="dialog"]:visible').count() == 0, "Escape 未关闭设置抽屉")
            _assert(trigger.evaluate("element => element === document.activeElement"), "关闭设置抽屉后未归还焦点")
            trigger.click()
            page.get_by_role("tab", name="学期").click()
            _assert(trigger.evaluate("element => element === document.activeElement"), "选择设置分区后未归还触发器焦点")
        else:
            general_tab = page.get_by_role("tab", name="常规")
            general_tab.focus()
            page.keyboard.press("ArrowRight")
        term = page.locator('[data-settings-panel="term"]:visible')
        _assert(term.count() == 1 and "当前学期" in term.inner_text(), "设置学期分区内容未切换")
        _assert(page.locator('[data-settings-panel="general"]:visible').count() == 0, "设置切换后仍显示常规内容")
        _assert(page.locator('#settings-title').inner_text() == "设置", "设置分区切换意外改变应用页标题")
        _assert("学期" in page.locator('[data-settings-summary]').inner_text(), "设置分区切换未同步上下文说明")
        if viewport_width <= 900:
            nav_box = page.locator('.settings-nav').bounding_box()
            _assert(nav_box is not None and nav_box["height"] <= 64, "compact/medium 设置导航仍占用过多纵向空间")
