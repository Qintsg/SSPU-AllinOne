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

## 2. 交互与界面

- 余额卡片：展示余额 + 卡状态 + 最近更新时间。无缓存时刷新显示加载骨架；已有缓存刷新时必须保留余额与详情入口，并以“正在更新”表达操作锁。
- 明细页：按时间倒序展示交易记录，支持按日期范围远端查询与全量只读同步。日期范围、收支方向、分页和输入内容在失败后不得丢失。
- 日期格式错误属于表单级错误：保留上一次有效结果并提供清除路径，不得伪装成整页服务错误。
- 远端查询与全量同步共享单飞锁；重复点击不得产生并发请求。服务、账户、父快照或页面生命周期换代后，旧请求不得回写。
- 有效缓存刷新失败时展示 `partial-error`，保留余额、记录和返回路径；无有效缓存时才展示整页 `error`。
- `stale` 明确数据来自本地缓存；`operation-locked` 继续允许查看现有记录，但锁定会改变远端结果的操作。
- 校园网/VPN 不可用、OA 会话失效、校园卡系统不可用、解析失败、网络异常和未知插件/服务异常都必须映射为可恢复文案，并在异常后解除操作锁。
- 紧凑端的主要操作保持 48dp 触控目标；筛选、同步、清除和返回路径不依赖悬停，键盘可遍历且收支页签支持方向键。
- 所有同步动作均明确标注“只读”，不得提供或暗示充值、挂失、解挂等写操作。
- 与校园卡无关的邮箱或体育查询密码变化不得清空本页；仅 OA 账号或 OA 密码换代使旧校园卡快照失效。

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

## 6. 状态契约

| 表面 | 状态 | 保留内容 | 可用动作 |
| --- | --- | --- | --- |
| 首页余额卡 | `loading` | 无 | 等待；不可进入详情 |
| 首页余额卡 | `content` / `stale` | 余额与摘要 | 进入详情 |
| 首页余额卡 | `operation-locked` | 余额与摘要 | 可进入详情；重复刷新被锁定 |
| 首页余额卡 | `empty` / `error` | 无 | 由首页刷新入口恢复 |
| 明细页 | `content` / `stale` | 余额、记录、筛选 | 查询、同步、切换本地筛选 |
| 明细页 | `empty` | 余额、筛选 | 清除筛选或重新查询 |
| 明细页 | `partial-error` | 最近有效快照、输入、筛选、分页 | 重试、继续本地浏览 |
| 明细页 | `operation-locked` | 最近有效快照、输入、筛选、分页 | 继续浏览；远端操作锁定 |
| 明细页 | `validation-error` | 最近有效快照、输入、筛选、分页 | 修正日期或清除筛选；不发起远端请求 |
| 明细页 | `error` | 无有效快照 | 返回首页或重试 |

## 7. 待办与演进

- [ ] 与 #187 卡片显隐配置协同。
