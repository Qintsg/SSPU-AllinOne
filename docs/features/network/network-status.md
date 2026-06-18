# 校园网状态检测

> 模块：[校园网](README.md)　·　状态：**设计中**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `network.network-status` |
| 状态 | 设计中（重新规划，不沿用旧前端） |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | 重构目标：`lib/services/campus_network_status_service.dart`、`lib/models/campus_network_status.dart` |

## 1. 需求

作为整个应用的**网络环境单一真源**与**受限服务访问门禁**：

- 判定当前处于 6 态中的哪一种（见模块总览「网络状态模型」）。
- 供顶栏/主页等多个入口共享展示，避免重复探测。
- 供教务、校园卡、邮箱等受限功能在请求前做前置检查与门禁决策。
- 向 VPN 插件暴露当前网络状态，供插件判断「可否开启」。

**验收要点**
- 首次检测前为 `unknown`，不误报「未连接」。
- 能区分「离线」「校外·未连接」「VPN·非插件」「VPN·插件」，不混为一谈。
- 检测异步、可合并并发、可配置间隔（含 0=仅手动）。

## 2. 交互与界面（期望行为，前端重构后落地）

- **共享徽标**：展示短文案（校园网 / VPN / 校外 / 离线 / 检测中）与详情 tooltip；点击可手动刷新。
- **门禁提示**：受限入口在不可达时给出明确原因与「连接 VPN / 重新检测」动作，不静默失败。
- 具体组件形态由设计系统与前端重构决定，本文档只约束**状态语义与可用动作**。

## 3. 实现

### 3.1 探测信号（多探针融合）

状态由四类信号融合判定，任一探针失败收敛为「不可达」而非中断整体：

| 信号 | 探测对象 | 用途 |
| --- | --- | --- |
| 通用连通性 | 中性公网端点 / `connectivity_plus` | 区分 `offline` 与「有外网」 |
| 校园站点可达 | `https://tygl.sspu.edu.cn/`（可配置） | 是否可达校园受限服务 |
| VPN 入口可达 | `https://vpn.sspu.edu.cn/`（可配置） | 校园 LAN 与 VPN 的启发式区分；VPN 是否可开启 |
| VPN 插件隧道态 | 本地插件宿主上报（仅桌面） | 区分 `vpnPlugin` 与 `vpnExternal` |

探针默认只发只读 `GET`，任何非 5xx 响应视为目标域名可达；超时/连接失败视为不可达。

### 3.2 状态判定（决策顺序）

```
1. 无通用连通性                                   → offline
2. 校园站点可达 且 插件隧道处于已连接             → vpnPlugin
3. 校园站点可达 且 VPN 入口可达 且 插件未连接     → vpnExternal   // 经非插件 VPN
4. 校园站点可达 且 VPN 入口不可达                 → campus        // 校园 LAN 启发式
5. 校园站点不可达 且 有外网                       → outsideUnconnected
6. 其它 / 检测中                                  → unknown
```

> 注：第 3/4 步为启发式（校园 LAN 内 VPN 入口行为与校外不同），可随实测调整；插件隧道态是区分插件/非插件 VPN 的权威信号。

### 3.3 服务结构

- `CampusNetworkStatusService`（`ChangeNotifier` 单例）：缓存当前状态、合并并发刷新、可配置自动检测间隔（默认 15min，0=仅手动）、引用计数式监听启停。
- 探针签名可注入（`CampusNetworkProbe`），测试用 fake。
- 订阅 [本地插件机制](plugin-host.md) 的 VPN 隧道状态事件（仅桌面），状态变化时重算并 `notifyListeners`。

### 3.4 门禁 API

- `bool get canAccessRestrictedServices` — `campus / vpnExternal / vpnPlugin` 为 `true`。
- `Future<NetworkGateResult> ensureReachable({bool allowAutoConnect})` — 前置检查；不可达且允许自动连接且处于 `outsideUnconnected` 且 VPN 入口可达时触发插件 VPN 连接，否则返回需手动处理的结果。详见 [`vpn-connect.md`](vpn-connect.md) 门禁集成一节。

## 4. 关联

- 依赖：[本地插件机制](plugin-host.md)（读取桌面 VPN 插件隧道态）。
- 被依赖：[VPN 一键连接](vpn-connect.md)、[网络诊断与测速](network-diagnostics.md)；教务/校园卡/邮箱等受限服务（门禁）。

## 5. 约束

- 检测全程异步、不阻塞 UI；探测频率受自动检测间隔与并发合并约束，避免高频骚扰校园站点。
- 探测仅只读 GET，不携带任何凭据。
- 探测目标地址可配置，便于域名调整与测试。

## 6. 待办与演进

- [ ] 落地 6 态模型与决策顺序，迁移旧 4 态调用点。
- [ ] 接入通用连通性信号以区分 `offline`。
- [ ] 与 [本地插件机制](plugin-host.md) 隧道态事件打通，实现 `vpnPlugin` / `vpnExternal` 区分。
- [ ] 暴露 `ensureReachable()` 门禁能力并接入受限服务。
