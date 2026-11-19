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

读取新版学生教务页公布且未结束的考试安排。列表可按考试时间切换正序和倒序。

**验收要点**
- 解析学校提供的课程、时间、地点和考试类型。
- 新版学生考试页提供未结束考试。应用据此展示列表和空状态。
- **排序**：默认按考试时间**正序**（最早在前），可切换正/倒序；无时间的占位项排末尾。

## 2. 实现

- 经 [EAMS 基座](foundation.md) `fetchExamSchedule({term, semester, examTypeId})`（scope=examScheduleOnly）。
- **排序**：详情页按考试开始时间排序，默认正序，可在同一时间轴原地切换倒序；无时间项始终置末，排序在本地对结果集进行，不额外请求。
- per-account 缓存（examSchedule collection）。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)、[校历](../../platform/academic-calendar.md)（学期）。
- 被依赖：[通知与提醒](../../platform/system/notifications.md)（考试提醒 #188）、[主页仪表盘](../../platform/shell/home-dashboard.md)。

## 4. 约束

- 只读，缓存按账号隔离。

## 5. 待办与演进

- [x] 清源考试卡片与未结束考试详情。
- [x] 列表按考试时间排序（默认正序）与正/倒序切换。
- [x] 考试时间已叠加到[课程与考试日历](calendar.md)，并可随议程导出 `.ics`。
- [x] 已接入 #188 考试提醒规划与调度链路；真实设备到点投递仍待验证。
- [ ] 与 #189 系统小组件进行平台能力对接。
