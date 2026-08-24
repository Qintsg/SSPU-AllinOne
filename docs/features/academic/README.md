# 教务（Academic）

> 业务域：`academic`　·　所属：[功能总览](../README.md)
>
> 本模块为重新规划版本，**不沿用旧前端**（前端重构中）。服务层多已实现，状态按实标注。

## 1. 模块职责

覆盖学业相关的只读查询，分为两个子系统 + 一份共享基座：

- **EAMS 教务**（[`eams/`](eams/README.md)）：复用 OA/CAS 会话查询个人信息、日历（课程+考试）、成绩、过程化成绩、考试、开课、空闲教室、培养计划。共用 [EAMS 基座](eams/foundation.md)。
- **课外活动**（[`activity/`](activity/README.md)）：体育打卡考勤、第二课堂学生报告。
- **[登录与凭据](auth-credentials.md)**：OA/CAS 登录与凭据底座，被 EAMS、活动以及 [校园卡](../campus-life/campus-card.md)、[邮箱](../email/README.md) 共用。

> 校历已上移为通用能力：见 [platform/校历](../platform/academic-calendar.md)（无需登录，供全局学期/周次计算）。

## 2. 子模块

| 子模块 | 范围 | 文档 |
| --- | --- | --- |
| 登录与凭据 | OA/CAS 登录、凭据安全存储、会话 | [`auth-credentials.md`](auth-credentials.md) |
| EAMS 教务 | 8 个教务查询 + 基座 | [`eams/`](eams/README.md) |
| 课外活动 | 体育打卡、第二课堂 | [`activity/`](activity/README.md) |

## 3. 模块级约束

- **严格只读**：所有查询仅展示，不做选课、退课、调课、评教、预约、报名等写操作。
- **凭据安全**：学工号/OA 密码/邮箱密码进系统安全存储；学籍信息加密缓存；不写 `app_state.json`。
- **门禁**：EAMS 与活动经 [network 门禁](../network/network-status.md) 检查校园网/VPN，会话失效自动刷新、失败降级。
- 数据全本地（系统默认应用数据目录），缓存按账号隔离；敏感信息不进日志。

## 4. 相关 Issue

#177（成绩/过程化）、#178（考试）、#175（课表）、#179（开课）、#176（空闲教室）、#174（培养计划）。
