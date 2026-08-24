# 课外活动（子系统）

> 子模块：`academic/activity`　·　所属：[教务](../README.md)

## 1. 子系统职责

EAMS 之外、与学业相关的课外活动只读查询：体育打卡考勤、第二课堂学生报告（综合素质）。各自独立服务，经 OA 会话与 [network 门禁](../../network/network-status.md)。

## 2. 功能清单

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 体育打卡考勤 | 部分实现 | — | [`sports-attendance.md`](sports-attendance.md) |
| 第二课堂学生报告 | 部分实现 | — | [`student-report.md`](student-report.md) |

## 3. 共性约束

- 只读查询；凭据复用 [登录与凭据](../auth-credentials.md)；门禁与缓存同教务约定。
