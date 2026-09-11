# 体育打卡考勤

> 子模块：[课外活动](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.activity.sports-attendance` |
| 状态 | 已实现 |
| 平台 | 全平台 |
| 关联 Issue | — |
| 主要代码 | `lib/services/sports_attendance_service.dart`、`sports_attendance_gateway.dart`、`sports_attendance_page_parser.dart`、`sports_attendance_support.dart`；`lib/models/sports_attendance.dart` |

## 1. 需求

只读查询体育打卡考勤记录与统计（次数/达标情况）。

## 2. 实现

- 独立服务 `SportsAttendanceService` + 可替换网关/解析；复用 OA 会话，经 [network 门禁](../../network/network-status.md)。
- 数据源为体育部站点（`tygl.sspu.edu.cn` 同域，亦为 network 门禁的校园站点探针目标）。
- per-account 缓存。

## 3. 关联

- 依赖：[登录与凭据](../auth-credentials.md)、[network 门禁](../../network/network-status.md)、[本地存储](../../platform/system/storage-sync.md)。
- 被依赖：[主页仪表盘](../../platform/shell/home-dashboard.md)（打卡卡片）。

## 4. 约束

- 只读；不提供打卡补卡等写操作。敏感数据缓存按账号隔离。

## 5. 待办与演进

- [x] 清源体育考勤卡片、详情页、状态反馈与响应式布局。
