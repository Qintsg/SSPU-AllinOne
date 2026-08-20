# 校园资讯恢复列宽评审 v03

<!--
  校园资讯恢复列宽的实现前自评审记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-information-feed-state-width-v03.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

日期：2026-08-19  
分支：`feature/design-language-spec`  
状态：实现前冻结；按截图、交互协同和异常恢复人工复核，跳过 SSIM。

## 证据

- Windows 1200×900 error 候选中，“无法刷新校园资讯”状态卡宽度近 900dp，而图标、说明和“重试”总共只占一行内容；中间出现无意义的大面积边框内留白。
- 360px content 与 768/1200/1600px content 的来源、搜索、列表和筛选结构已符合冻结模式；本批不能改动这些内容态骨架。
- error 没有缓存，而 stale 已保留缓存、筛选和原地刷新；两者的恢复行为必须继续分离。

## 结论与协同检查

采用 [`information-feed-state-width-v03.md`](../patterns/information-feed-state-width-v03.md) 的宽屏 560dp 左锚定恢复列。保持窄屏满宽和纵向行动，保持宽屏同排图标、说明和按钮。

- 读取、重试、来源与认证设置使用原有回调；不新增请求，也不把未认证误接到刷新。
- loading 保留活动环与禁止重复刷新；stale、筛选无结果、来源切换、分页、Drawer 焦点归还和减少动态保持原逻辑。
- 只改状态容器的视觉空间，不改消息数据、来源权限、缓存、路由和外部网页行为。

## 实施后核验要求

1. 增加 1200px 错误面板宽度和左锚定回归，并保留 360px 满宽与行动可达性。
2. 运行资讯布局与页面回归、静态分析、原型浏览器门禁。
3. 重采集 `info.feed` 全部状态的四档亮暗 Windows 候选，并人工检查 error、empty、loading、stale 与筛选无结果。

## 实施后核验

| 项目 | 结果 |
| --- | --- |
| 布局与协同回归 | `flutter test test/info_page_layout_test.dart`，9 项通过；新增 1200px 左锚定 560dp 错误恢复列回归。 |
| 浏览器参考 | `info.feed` 前缀四档亮暗 48 张参考图通过 Chromium 核验。 |
| Windows 候选 | 6 态 × 四档 × 亮暗共 48 张重新采集并通过；全量 Windows 目录保持 1544 张 PNG、144 份 sidecar，完整性校验通过。 |
| 人工复核 | 1200px error、768px empty、360px loading 与 1200px stale 均确认恢复按钮、活动环、缓存内容和来源/筛选上下文完整。 |

资讯主视图拆为页面根、头部内容、来源控件和状态面板四个内部模块；数据、筛选、来源权限、分页和路由接口均未改变。本批跳过 SSIM。

最新全量 `flutter test` 720 项通过、1,556 项视觉采集用例按开关跳过；`flutter analyze --no-fatal-infos`、设计系统/样式/CI 门禁以及当前源码 Windows Release 构建均通过。
