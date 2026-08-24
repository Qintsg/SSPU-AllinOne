# EAMS 教务（子系统）

> 子模块：`academic/eams`　·　所属：[教务](../README.md)

## 1. 子系统职责

复用 OA/CAS 会话，只读查询 `jx.sspu.edu.cn/eams` 教务系统的各项数据。所有功能共用 [EAMS 基座](foundation.md)（会话/网关/门禁/入口发现/缓存/locale/状态），各功能文档只描述自身数据与解析。

## 2. 功能清单

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| EAMS 基座 | 部分实现 | — | [`foundation.md`](foundation.md) |
| 个人信息 | 部分实现 | — | [`profile.md`](profile.md) |
| 日历（课程+考试） | 部分实现 | #175 | [`calendar.md`](calendar.md) |
| 成绩查询 | 部分实现 | #177 | [`grade.md`](grade.md) |
| 过程化成绩 | 部分实现 | #177 | [`grade-process.md`](grade-process.md) |
| 考试安排 | 部分实现 | #178 | [`exam-schedule.md`](exam-schedule.md) |
| 开课查询 | 部分实现 | #179 | [`course-offerings.md`](course-offerings.md) |
| 空闲教室查询 | 部分实现 | #176 | [`free-classrooms.md`](free-classrooms.md) |
| 培养计划 | 部分实现 | #174 | [`program-plan.md`](program-plan.md) |

## 3. 共性约束

- **严格只读**：`submitForm` 仅查询型 GET/POST；不提供选课、退课、调课、评教、确认、预约教室等写入入口。
- 统一 `AcademicEamsSnapshot` + `AcademicEamsQueryStatus`；per-account 缓存；zh_CN 强制中文界面以保证解析。
- 详见 [EAMS 基座](foundation.md)。
