<!--
  清源校历初始加载账本设计自评审与冻结记录
  @Project : SSPU-AllinOne
  @File : 2026-08-21-academic-calendar-loading-v01.md
  @Author : Qintsg
  @Date : 2026-08-21
-->

# 校历初始加载账本评审 v01

日期：2026-08-21  
分支：`feature/design-language-spec`  
验收：跳过 SSIM；以截图完整性、人工逐屏审查、操作协同和异常恢复为准。

## 审查证据

- 旧实现在 360px 内容区只放一条约 160dp 宽、无标题的居中进度条，首屏出现大片无信息空白，与首页、邮件等页面的“活动环 + 标题 + 说明”加载账本不一致。
- 本批采用 [`academic-calendar-loading-v01.md`](../patterns/academic-calendar-loading-v01.md)：初始加载改为左锚定、内容高的活动环 + 标题 + 说明账本；768px 及以上收束为 `layout.formContentWidth`，不把短提示拉成整页。

## 决议

采用活动环 + 标题 + 说明的加载账本，替换居中 `YhProgressBar`。

保留所有校历服务、学年/学期保存、PDF 渲染、外部打开、下载、来源文本、状态文案、刷新单飞与失败恢复契约；`loading` 期间不提供“重试/刷新”假操作，页面标题与返回按钮保持可用。

## 实施后核验要求

1. 添加行为回归，证明初始加载呈现活动环账本且无假操作按钮。
2. 验证 360×800 窄屏不横向溢出，加载完成后进入既有 content / empty / error 分支。
3. 运行校历页、PDF 框架相关测试。
4. 通过 `flutter analyze`、设计系统/样式表门禁与 `git diff --check`。

## 冻结

本批只调整初始加载状态呈现；业务数据、PDF 区域与交互行为均冻结不变。

## 实施后核验

| 项目 | 结果 |
| --- | --- |
| 校历/PDF 行为回归 | `flutter test test/academic_calendar_page_test.dart test/academic_calendar_pdf_frame_test.dart`，23 项通过；新增初始加载账本回归，覆盖活动环语义、无假操作与 360×800 不溢出。 |
| 视觉候选 | 重新采集 `build/visual/windows` 中 `academic.calendar` 前缀 72 张（9 状态 × 四档视口 × 亮暗），loading 8 张尺寸正确且内容收束于顶部；全量 1544 PNG + 144 sidecar 完整性校验通过。 |
| 静态门禁 | `flutter analyze` 无问题；设计系统/样式表/五平台 CI 契约与 `git diff --check` 均通过；全量 `flutter test` 722 项通过（1556 项视觉用例跳过）。另修复前批拆分遗留的 `component-manifest.json` slider/stepper source 指向旧文件问题。 |

本批证据为本机 Windows 目标候选；其余四个平台仍需真实 runner 验证。
