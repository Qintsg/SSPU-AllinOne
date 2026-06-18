# 校园生活（Campus Life）

> 业务域：`campus-life`　·　所属：[功能总览](../README.md)

## 1. 模块职责

面向校园日常生活类服务的**只读**查询与分析，当前以校园卡为核心，并基于其交易明细提供消费统计；预留其它生活服务（如水电、班车等）的扩展位。

## 2. 功能清单

| 功能 | 状态 | Issue | 文档 |
| --- | --- | --- | --- |
| 校园卡余额与明细 | 部分实现 | #187 | [`campus-card.md`](campus-card.md) |
| 消费统计与可视化 | 设计中 | — | [`consumption-analytics.md`](consumption-analytics.md) |

## 3. 内部依赖

- 校园卡查询依赖：[登录与凭据](../academic/auth-credentials.md)（OA/CAS 会话）、[网络门禁](../network/network-status.md)、[本地存储](../platform/system/storage-sync.md)、[后台自动刷新](../platform/system/auto-refresh.md)。
- 消费统计**依赖校园卡**的交易明细缓存（纯本地计算，不额外联网）。

## 4. 模块级约束

- **严格只读**：仅查询余额、明细并做本地统计，**不提供充值、挂失等写操作**。
- 数据全本地（系统默认应用数据目录），缓存按账号隔离；凭据进系统安全存储。

## 5. 相关 Issue

#187（卡片/模块显隐，影响余额卡片与统计卡片的展示配置）。
