# 考试安排

> 子模块：[EAMS 教务](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.exam-schedule` |
| 状态 | 已实现 |
| 平台 | 全平台 |
| 关联 Issue | #178 |
| 主要代码 | `lib/services/academic_eams_service.dart`（`fetchExamSchedule`）、`academic_eams_page_parser_tables.dart`；`lib/models/academic_eams/exams.dart` |

## 1. 需求

读取指定学期、指定考试类型的考试安排，默认期末考试、可切换类型；纯占位过滤；列表支持**按考试时间排序，默认正序（由近及远）**。

**验收要点**
- 默认 `examType.id=1`（期末），可切换其它类型。
- 解析课程、时间、地点、座位等；过滤纯占位项。
- **排序**：默认按考试时间**正序**（最早在前），可切换正/倒序；无时间的占位项排末尾。
- 需 zh_CN 强制中文界面才能正确解析（见基座）。

## 2. 实现

- 经 [EAMS 基座](foundation.md) `fetchExamSchedule({term, semester, examTypeId})`（scope=examScheduleOnly）。
- **排序**：详情页按考试开始时间排序，默认正序，可在同一时间轴原地切换倒序；无时间项始终置末，排序在本地对结果集进行，不额外请求。
- per-account 缓存（examSchedule collection）。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)、[校历](../../platform/academic-calendar.md)（学期）。
- 被依赖：[通知与提醒](../../platform/system/notifications.md)（考试提醒 #188）、[主页仪表盘](../../platform/shell/home-dashboard.md)。

## 4. 约束

- 只读；英文界面账号需注入 zh_CN 才能解析考试表。

## 5. 待办与演进

- [x] 清源考试卡片、详情与类型切换。
- [x] 列表按考试时间排序（默认正序）与正/倒序切换。
- [x] 考试时间已叠加到[课程与考试日历](calendar.md)，并可随议程导出 `.ics`。
- [x] 已接入 #188 考试提醒规划与调度链路；真实设备到点投递仍待验证。
- [ ] 与 #189 系统小组件进行平台能力对接。
