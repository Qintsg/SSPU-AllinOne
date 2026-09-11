# 校园网状态检测

> 模块：[校园网](README.md)　·　状态：**部分实现**（4 态双探针门禁已实现）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `network.network-status` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/campus_network_status_service.dart`、`lib/models/campus_network_status.dart`、`lib/widgets/campus_network_status_indicator.dart` |

## 1. 需求

作为整个应用的**网络环境单一真源**与**受限服务访问门禁**。当前实现提供 4 态；原 6 态与插件 VPN 方案不再属于现行范围。

- 判定 `unknown / campus / vpn / outsideCampus` 四态。
- 供顶栏/主页等多个入口共享展示，避免重复探测。
- 供教务、校园卡、邮箱等受限功能在请求前做前置检查与门禁决策。

**验收要点**
- 首次检测前为 `unknown`，不误报「未连接」。
- 能区分校园网、学校 VPN、校外和未知状态。
- 检测异步、可合并并发、可配置间隔（含 0=仅手动）。

## 2. 交互与界面

- **共享徽标**：清源状态指示器展示校园网 / VPN / 校外 / 未知与详情；支持按刷新策略重测。
- **门禁提示**：受限入口在不可达时给出明确原因与重新检测建议，不静默失败。

## 3. 当前实现

### 3.1 双探针信号

状态由四类信号融合判定，任一探针失败收敛为「不可达」而非中断整体：

| 信号 | 探测对象 | 用途 |
| --- | --- | --- |
| 校园站点可达 | `https://tygl.sspu.edu.cn/`（可配置） | 是否可达校园受限服务 |
| VPN 入口可达 | `https://vpn.sspu.edu.cn/`（可配置） | 校园 LAN 与 VPN 的启发式区分；VPN 是否可开启 |

探针默认只发只读 `GET`，任何非 5xx 响应视为目标域名可达；超时/连接失败视为不可达。

### 3.2 状态判定

```
1. 校园站点可达且 VPN 入口可达   → vpn
2. 校园站点可达且 VPN 入口不可达 → campus
3. VPN 入口可达且校园站点不可达 → outsideCampus
4. 两者均不可达或检测中           → unknown
```

> 该模型为启发式双探针判断；当前不能区分离线与探针同时不可达。

### 3.3 服务结构

- `CampusNetworkStatusService`（`ChangeNotifier` 单例）：缓存当前状态、合并并发刷新、可配置自动检测间隔（默认 15min，0=仅手动）、引用计数式监听启停。
- 探针签名可注入（`CampusNetworkProbe`），测试用 fake。

### 3.4 门禁能力

- `bool get canAccessRestrictedServices` — `campus / vpn` 为 `true`。
- 受限服务在请求前调用共享状态服务；不可达时返回结构化业务错误，不尝试自动连接 VPN。

## 4. 关联

- 被依赖：[网络诊断与测速](network-diagnostics.md)；教务、校园卡与课外活动等受限服务（门禁）。

## 5. 约束

- 检测全程异步、不阻塞 UI；探测频率受自动检测间隔与并发合并约束，避免高频骚扰校园站点。
- 探测仅只读 GET，不携带任何凭据。
- 探测目标地址可配置，便于域名调整与测试。

## 6. 待办与演进

- [x] 4 态双探针模型、并发合并、检测间隔与受限服务门禁。
- [ ] 如确有产品需求，另建 Issue 评估通用连通性信号与 `offline` 状态；不依赖已取消的本地插件方案。
