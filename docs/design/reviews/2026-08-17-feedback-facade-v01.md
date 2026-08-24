# 清源全局反馈公共门面 v01

日期：2026-08-17  
分支：`feature/design-language-spec`  
状态：接口与动效契约冻结

## 设计与接口计划

- 保留现有右上角紧凑浮层、3 秒时长、连续反馈替换、手动关闭和语义 live region。
- 保留信息、成功、警告、错误四级语义及现有 token 色彩和 `YhIcons` 图标。
- 将反馈实现从业务 `widgets` 目录归位到清源组件层，以 `showYhFeedback` 从 `qingyuan_ui.dart` 统一导出。
- 语义等级模型继续独立于具体视觉实现，控制器无需感知 Overlay 或卡片结构。
- 保持右上角布局与 3 秒可读时长，使用 `motion.base` 增加短距离淡入/滑入和淡出；减少动态时将过渡归零。

## 自评审

旧实现已经是清源自绘样式，但页面需要直接导入 `widgets/app_feedback.dart`，公共门面没有覆盖计划要求的 Overlay/消息反馈；安全设置中还残留 `_showCredentialInfoBar` 的旧 Fluent 术语。该结构会让后续页面绕过清源公开入口，也使静态门禁难以区分公共 API 与内部实现。

接口归位本身不改变反馈的布局、边距、最大宽度、颜色、图标、文案、时长、替换代次、关闭命中区和语义。复审发现旧实现缺少 Toast 契约要求的进入/退出反馈，会让操作结果在 Overlay 中突兀出现；因此补入唯一一处短距离过渡，并明确不增加弹跳、缩放或常驻装饰。`AppFeedbackSeverity` 仍为与视觉解耦的语义模型，由清源反馈组件转出；业务页面只经 `qingyuan_ui.dart` 使用。

## 实现与验收

- 新入口：`lib/design/qingyuan/components/yh_feedback.dart`。
- 公共导出：`lib/design/qingyuan/qingyuan_ui.dart`。
- 删除旧入口：`lib/widgets/app_feedback.dart`。
- 设计系统门禁会扫描清源目录之外的 Dart import；业务代码直接导入 `design/qingyuan/` 内部文件时立即失败，唯一允许入口为 `qingyuan_ui.dart`。
- `showAppFeedback`、`InfoBar` 和旧文件 import 在源码与测试中均为 0。
- 设计系统校验器测试：37/37 通过；完整设计契约通过。
- Flutter 3.44.0 `flutter analyze`：无问题。
- 反馈、设置与认证定向测试：35/35 通过。
- Flutter 3.44.0 全量测试：681 项通过；包含反馈替换、退出动效和减少动态路径。
- 按后续验收决定，本批跳过 SSIM；动效通过 widget 时序、替换行为与减少动态测试验收。
