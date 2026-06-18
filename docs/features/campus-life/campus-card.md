# 校园卡余额与明细

> 模块：[校园生活](README.md)　·　状态：**部分实现**（服务层已实现，前端重构中）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `campus-life.campus-card` |
| 状态 | 部分实现（服务层可用，前端重新规划） |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #187（卡片显隐） |
| 主要代码 | `lib/services/campus_card_*.dart`；`lib/models/campus_card.dart` |

## 1. 需求

通过 OA/CAS 登录态**只读**查询校园卡的三项基础数据：**余额、卡状态、交易明细**。

**验收要点**
- 余额、卡状态、交易明细可查询并本地缓存按账号隔离。
- 校外/无会话时按门禁与会话刷新策略降级提示，不静默失败。
- 严格只读：**不提供充值、挂失、解挂等任何写操作**。

## 2. 交互与界面（期望行为，前端重构后落地）

- 余额卡片：展示余额 + 卡状态 + 最近更新时间，可手动刷新。
- 明细页：按时间倒序展示交易记录，支持按日期范围查询与全量同步。
- 加载/空/错误态需明确（含校园网/VPN 不可用、OA 会话失效、解析失败等）。
- 组件形态由设计系统与前端重构决定，本文档只约束**数据语义与可用动作**。

## 3. 实现（沿用现有服务层）

### 3.1 数据流

```
OA/CAS 会话 ─→ 校园卡入口(oa.sspu.edu.cn/...xykxt) ─跟随跳转→ epay 业务页(card.sspu.edu.cn/epay)
                                                              ├─ 余额/卡状态页解析
                                                              └─ 交易查询接口（仅明确的只读查询）
                                                                      │
                                                  解析 → CampusCardSnapshot → 按账号本地缓存
```

- `CampusCardService`（单例，实现 `CampusCardBalanceClient`）：编排凭据→门禁→OA 会话→入口跳转→解析→缓存。
- `CampusCardGateway`（可替换）：会话注入、入口跳转、只读页抓取、**仅允许调用明确的交易查询接口**。
- `CampusCardPageParser`：从页面快照解析余额、卡状态与交易记录（GBK 解码）。
- 模型 `campus_card.dart`：`CampusCardSnapshot` / `CampusCardQueryResult` / `CampusCardQueryStatus` / `CampusCardTransactionRecord`。

### 3.2 登录与门禁（照搬现有）

- 需学工号 + OA 密码；缺失时返回 `missingOaAccount` / `missingOaPassword`。
- 经 [网络门禁](../network/network-status.md) 检查校园网/VPN 可达性；不可达时刷新 OA 会话并降级提示（`campusNetworkUnavailable` / `oaLoginRequired`）。
- 会话失效自动强制刷新并重试入口；查询过程中凭据变更则丢弃本次结果。

### 3.3 交易明细同步与缓存（照搬现有）

- 支持按日期范围查询、全量同步（`syncAllTransactions`）。
- 与本地缓存**去重合并**：优先按 `transactionId`，否则按 `时间+标题+对手/商户+金额` 组合键。
- 按账号 (`AuthenticatedDataCacheService`) 缓存最近成功快照；账号为空不缓存。

### 3.4 自动刷新

- 余额自动刷新开关 + 间隔（默认 30min），存于 `StorageService`；归 [后台自动刷新](../platform/system/auto-refresh.md) 协同。

## 4. 关联

- 依赖：[登录与凭据](../academic/auth-credentials.md)（OA/CAS 会话）、[网络状态检测](../network/network-status.md)（门禁）、[本地存储](../platform/system/storage-sync.md)（缓存）、[后台自动刷新](../platform/system/auto-refresh.md)。
- 被依赖：[消费统计与可视化](consumption-analytics.md)（消费数据源 = 交易明细缓存）；[主页仪表盘](../platform/shell/home-dashboard.md)（余额卡片）。

## 5. 约束

- **严格只读**：不做充值、挂失等写操作；网关仅允许明确的只读查询接口。
- 凭据进系统安全存储，不写 `app_state.json`；缓存按账号隔离。
- 数据全本地（系统默认应用数据目录）；敏感信息不进日志。
- 校园卡系统多为 epay 同类结构，真实页面以运行时解析为准，解析失败需降级。

## 6. 待办与演进

- [ ] 前端重构后的余额卡片与明细页（不沿用旧 widget）。
- [ ] 与 #187 卡片显隐配置协同。
