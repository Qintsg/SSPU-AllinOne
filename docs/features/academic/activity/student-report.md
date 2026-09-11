# 第二课堂学生报告

> 子模块：[课外活动](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.activity.student-report` |
| 状态 | 已实现 |
| 平台 | 全平台 |
| 关联 Issue | — |
| 主要代码 | `lib/services/student_report_service.dart`、`student_report_gateway.dart`、`student_report_page_parser.dart`、`student_report_page_navigator.dart`、`student_report_detail_json_parser.dart`、`student_affairs_service.dart`；`lib/models/student_report.dart` |

## 1. 需求

只读查询第二课堂（综合素质）学生报告：活动/学分构成、规则矩阵与汇总。

## 2. 实现

- 独立服务 `StudentReportService` + 网关/页面导航/解析（含 JSON 明细解析、URI 抽取）；复用 OA 会话，经 [network 门禁](../../network/network-status.md)。
- 解析报告汇总、规则矩阵与明细 → `StudentReport`。
- per-account 缓存。

## 3. 关联

- 依赖：[登录与凭据](../auth-credentials.md)、[network 门禁](../../network/network-status.md)、[本地存储](../../platform/system/storage-sync.md)。
- 被依赖：[主页仪表盘](../../platform/shell/home-dashboard.md)（综合素质卡片）。

## 4. 约束

- 只读；不提供活动报名等写操作。敏感数据缓存按账号隔离。

## 5. 待办与演进

- [x] 清源报告卡片、详情页、规则台账与规则矩阵展示。
