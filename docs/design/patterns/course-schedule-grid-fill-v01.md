# 课表周视图视口填充 v01

<!--
  清源课表页桌面端周网格填充视口的密度参考稿
  @Project : SSPU-AllinOne
  @File : course-schedule-grid-fill-v01.md
  @Author : Qintsg
  @Date : 2026-08-21
-->

## 目标

对象是查看课表的学生。当前周视图网格按内容定高（节次组数 × 最小行高），1600×1000 下网格只占视口约 55%，下方约 45% 完全空白；768/1200 同样存在底部空白。

本稿只调整桌面端周网格的垂直编排，不改变节次表、课程块、按天列表、窄屏切换、刷新单飞或任何业务契约。

## 现状证据

- `course_schedule_page.dart`：body 为 `SingleChildScrollView` + 内容定高 Column，网格不感知视口高度。
- `course_schedule_views.dart`：`_CourseWeekGridView` 每行 `IntrinsicHeight` + `minHeight`，总高 = 行数 × 最小行高。

## 视觉方向

- 沿用现有 token，不新增组件或动画。
- 桌面端（视口宽 ≥ `breakpoint.medium` 且可用高度足够）把周网格包进 `Expanded`，行高在 `cellMinHeight` 基础上均分剩余高度（每行 `Expanded`），网格填满主区，底部不再空白。
- 窄屏/矮视口保持现有内容定高 + 滚动路径不变。
- 课程块在更高单元格内顶部对齐，保持现有内边距。

## 自评审

1. **保持内容定高**：否决。桌面端底部大片空白持续存在。
2. **网格 Expanded 填充 + 行均分**：采用。行高随视口均匀增大，课程块顶部对齐，视觉稳定。
3. **整页改为不可滚动固定布局**：否决。窄屏与矮视口仍需滚动，风险大。

## 实现边界

- `course_schedule_page.dart`：桌面端 body 改为 `Column`（页头 + `Expanded(_buildContent)`），矮视口/窄屏保留 `SingleChildScrollView`。
- `course_schedule_views.dart`：`_CourseWeekGridView` 增加 `fillHeight` 参数；为 true 时每节次组行用 `Expanded`，否则保持 `IntrinsicHeight` 定高。

实施后需验证四档视口亮暗 `schedule.calendar` content 截图、360×800 仍可滚动、全量测试与门禁。