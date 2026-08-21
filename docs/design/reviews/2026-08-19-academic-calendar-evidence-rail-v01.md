<!--
  清源校历证据栏密度设计自评审与冻结记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-academic-calendar-evidence-rail-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

# 校历证据栏密度评审 v01

日期：2026-08-19  
分支：`feature/design-language-spec`  
验收：跳过 SSIM；以截图完整性、人工逐屏审查、操作协同和异常恢复为准。

## 审查证据

- 本次重新采集 `build/visual/calendar-pdf-audit-v01`：校历 72 张、PDF 64 张，覆盖所有注册状态、四档视口和亮暗主题。
- `academic.calendar--content--light--1200x900.png` 显示左侧“学期边界”卡因 `Expanded` 跟随右侧文档高度，底部出现无信息边框空白。
- `academic.calendar--content--light--360x800.png` 的连续选择、统一查询、边界和 PDF 入口完整，不应因宽屏问题而改变。
- PDF content/empty/error/external-confirmation 候选表明 PDF 大正文区属于明确的外部区域；恢复动作、工具栏和确认对话框均正常，本批不修改。

## 决议

采用 [`academic-calendar-evidence-rail-v01.md`](../patterns/academic-calendar-evidence-rail-v01.md)：解除宽屏证据卡随文档填高的约束，左栏保持内容高，右侧 PDF 继续独立填充。

保留所有学期、服务、PDF、下载、外部打开、单飞锁、加载、错误和 sidecar 契约。

## 实施后核验要求

1. 添加宽屏回归，证明证据卡高度低于右侧文档面板且仍显示所有边界事实。
2. 运行校历页、PDF 框架相关测试。
3. 重新采集校历全状态与 PDF 关键状态，检查四档亮暗、操作锁和外部确认。
4. 通过 `flutter analyze`、设计系统/样式表门禁与 `git diff --check`。

## 冻结

本批只调整页面布局约束；业务数据、状态文案、PDF 区域和交互行为均冻结不变。

## 实施后核验

| 项目 | 结果 |
| --- | --- |
| 校历/PDF 行为回归 | `flutter test test/academic_calendar_page_test.dart test/academic_calendar_pdf_frame_test.dart`，22 项通过；新增桌面证据卡高度小于文档面板的回归。 |
| Flutter 视觉候选 | `build/visual/calendar-evidence-rail-v01`，校历 72 张，覆盖 9 态、四档视口与亮暗主题；文件名和物理尺寸均通过检查。 |
| PDF 复核 | 同次审查的 `build/visual/calendar-pdf-audit-v01` 已生成 PDF 64 张，覆盖 loading/content/empty/error/partial-error/operation-locked/external-error/external-confirmation；未发现本批需修改的内部清源区域。 |
| 人工抽检 | 360 content、768 operation-locked、1200 content、1600 external-error 均已检查。左栏在宽屏自然结束，移动流、错误横幅、刷新锁和外部区域边界完整。 |
| 静态门禁 | `flutter analyze`、清源设计系统/样式表契约与 `git diff --check` 均通过。 |

本批证据为本机 Windows 目标候选；其余四个平台仍需真实 runner 验证。
