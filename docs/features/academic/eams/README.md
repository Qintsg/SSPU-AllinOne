# EAMS 教务（子系统）

> 子模块：`academic/eams`　·　所属：[教务](../README.md)

## 1. 子系统职责

通过统一身份认证读取 `jw.sspu.edu.cn` 的学生教务数据。学籍、课表、成绩、考试和培养方案共用[教务基座](foundation.md)提供的会话与账号校验。

## 2. 功能清单

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| EAMS 基座 | 已实现 | — | [`foundation.md`](foundation.md) |
| 个人信息 | 已实现 | — | [`profile.md`](profile.md) |
| 日历（课程+考试） | 本地实现与自动化测试完成；系统日历实机验收待补 | #175 | [`calendar.md`](calendar.md) |
| 成绩查询 | 已实现 | #177（已关闭） | [`grade.md`](grade.md) |
| 过程化成绩 | 已实现 | #177（已关闭） | [`grade-process.md`](grade-process.md) |
| 考试安排 | 已实现 | #178（已关闭） | [`exam-schedule.md`](exam-schedule.md) |
| 开课查询 | 部分实现 | #179（不再计划独立页面） | [`course-offerings.md`](course-offerings.md) |
| 培养计划 | 已实现 | #174 | [`program-plan.md`](program-plan.md) |

## 3. 共性约束

- 新版教务数据通过只读请求获取，结果使用现有快照模型并按账号缓存。
- 学生端入口以[教务处新版手册](https://jwc.sspu.edu.cn/2026/1112/c897a173667/page.htm)及实际可见的功能为准。
- 详见 [EAMS 基座](foundation.md)。
