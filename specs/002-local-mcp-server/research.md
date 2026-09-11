# Phase 0 Research: 本地个人数据 MCP 服务

**Date**: 2026-09-10  
**Scope**: 协议、Dart 实现、网络安全、平台能力、数据边界与互操作

## Decision 1: 采用 MCP 2026-07-28 Streamable HTTP

**Decision**: 实现单一 `POST /mcp` 端点，按 MCP `2026-07-28` 处理每个独立
JSON-RPC 请求；响应可为 `application/json`，需要流式返回时使用该请求范围内的
`text/event-stream`。不实现旧版 HTTP+SSE 的 GET 长连接端点，也不实现协议级 session。

**Rationale**:

- 当前规范已经移除 HTTP GET 长连接与 `Mcp-Session-Id`，新功能没有兼容历史实现的负担。
- 单 POST 端点减少路由、会话清理和长期连接攻击面。
- 规范明确要求 Streamable HTTP 服务校验 `Origin`，并建议本地服务默认只绑定回环地址和
  使用认证，可直接对应本功能的隐私边界。

**Alternatives considered**:

- **旧 HTTP+SSE**：已弃用，新增实现会制造不必要的兼容面。
- **stdio**：适合由 Agent 启动子进程，但无法满足局域网其它设备访问。
- **自定义 REST API**：不具备 MCP 的能力发现与 Agent 客户端互操作性。

**Source**: [MCP 2026-07-28 Streamable HTTP](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http.md)

## Decision 2: 使用 `mcp_dart ^2.4.2`

**Decision**: 使用 `mcp_dart` 的 `StreamableMcpServer` 作为协议与传输基础，并启用其
DNS rebinding 防护、allowed hosts/origins 和认证 hook；应用自身负责配置校验、授权、审计、
速率限制与 snapshot adapters。

**Rationale**:

- 2.4.2 声明支持 MCP 2026-07-28 与 Streamable HTTP 服务端。
- 已提供 Host/Origin 防重绑定、认证扩展点和协议校验，避免自行实现完整 MCP JSON-RPC 栈。
- 依赖面小，Dart SDK 约束与项目 Dart 3.12 相容。

**Alternatives considered**:

- **`dart_mcp`**：可继续关注，首版所需的安全 Streamable HTTP 服务端资料与落地示例不如
  `mcp_dart` 直接。
- **`mcp 0.0.1`**：占位或能力不足，不作为生产依赖。
- **直接使用 `dart:io HttpServer` 自研协议**：安全和互操作成本过高；仅在 SDK 无法满足已验证
  契约时才局部下沉到 transport adapter，而不是重写 MCP。

**Sources**:

- [mcp_dart package](https://pub.dev/packages/mcp_dart)
- [mcp_dart v2.4.2 transport guide](https://raw.githubusercontent.com/leehack/mcp_dart/v2.4.2/doc/transports.md)
- [mcp_dart v2.4.2 server guide](https://raw.githubusercontent.com/leehack/mcp_dart/v2.4.2/doc/server-guide.md)

## Decision 3: 默认回环，LAN 作为高风险显式模式

**Decision**:

- 默认绑定 `127.0.0.1`，展示 `http://127.0.0.1:<port>/mcp`。
- LAN 模式监听 `0.0.0.0`，但 UI 展示枚举出的真实私网 IPv4 地址，不把 `0.0.0.0` 当作
  客户端地址。
- LAN 模式必须完成风险确认且启用 API Key；禁止公网、路由器端口转发和任意 Host。
- 允许的 Host 由启动时的 localhost、回环地址、设备名和已枚举局域网地址加端口精确构建；
  接口变化时重建或停服，不使用 `*`。
- MVP 不支持浏览器客户端：请求存在 `Origin` 时默认拒绝。后续若支持，必须由用户或产品定义
  精确 origin allowlist，不能用通配符。

**Rationale**: `0.0.0.0` 会扩大到所有接口，Bearer Key 只能认证，不能防止同网段窃听。
显式确认、真实地址与精确 Host 校验使用户知道实际暴露面，并降低 DNS rebinding 风险。

**Alternatives considered**:

- **自动选择某个网卡地址绑定**：网络切换后行为不稳定，也容易误选 VPN/虚拟网卡。
- **允许任意 Host/Origin**：会让恶意网页或 DNS rebinding 绕过用户对“本机/LAN”的理解。
- **首版内置 TLS**：证书签发、信任分发、轮换与跨客户端兼容显著扩大范围；本期用风险提示和
  非公网限制收敛，TLS 留待独立规格。

## Decision 4: API Key 默认开启，LAN 不可关闭

**Decision**: 生成至少 32 字节密码学安全随机值，使用 `Authorization: Bearer <key>`。
Key 存系统安全存储，生成/轮换后只显示一次；验证使用常量时间摘要比较。回环模式允许用户在
明确提示后关闭认证，LAN 模式配置校验必须拒绝无 Key 启动。轮换采用新版本原子替换，旧 Key
立即失效。

**Rationale**: 同设备其它进程也可能访问回环端口，因此认证仍应默认开启；但本机开发集成有
合理的低摩擦需求。LAN 暴露面更大，不能允许匿名访问。

**Alternatives considered**:

- **Query 参数传 Key**：容易进入 URL、历史与代理日志，不采用。
- **共享应用登录密码**：用途混淆且增加主密码暴露风险，不采用。
- **OAuth 2.1**：适合多用户/远程授权服务器，本地单用户首版复杂度过高；若未来支持公网或
  每客户端撤销，再单独规划。

## Decision 5: 仅 tools，且目录发现也遵循授权

**Decision**: MVP 只注册 MCP tools，不注册 resources 或 prompts。`tools/list` 只返回当前
已授权能力；`tools/call` 在执行时再次检查授权、锁定状态和账号 generation。所有 tool 声明
`readOnlyHint: true`、`destructiveHint: false`，输出采用统一 snapshot 元数据和稳定 DTO。

**Rationale**:

- tools 最适合带过滤与分页的查询；resources 的持久 URI 会扩大数据可枚举性。
- 隐藏未授权工具降低元数据泄漏，但不能替代调用时的强制鉴权。
- 稳定 DTO 避免把现有解析器的 `rawFields`、`rawCells`、URI 与内部路径直接暴露。

**Alternatives considered**:

- **全部能力始终可见、调用时拒绝**：实现简单，但会泄露用户启用了哪些数据模块。
- **直接导出快照 JSON**：包含原始字段、来源 URI 或未来新增字段，无法保持最小披露。
- **resources + tools 双轨**：对 MVP 没有独立用户价值，增加授权和缓存语义。

## Decision 6: 外部调用严格离线，只读 adapter 双重校验

**Decision**: 每个能力处理器只能依赖只读 snapshot adapter；adapter 可调用现有
`readLatestCached...` API，不得导入 gateway、credentials `readSecret`、refresh 或写操作。
调用开始记录 `{authorizationVersion, accountGeneration, lockGeneration}`，构造响应后再次比较；
任一变化就丢弃结果并返回 `context_changed`。

**Rationale**: 仅在调用前校验会留下撤权/切换账号竞态；仅依赖类型名“read”也不足以防止某个
现有方法在 cache miss 时联网。显式接口与 import/测试约束共同守住边界。

**Alternatives considered**:

- **MCP 请求触发刷新**：会绕过模块“停止获取”和用户对网络出域的预期。
- **传输层直接读取 StorageService**：协议、权限与业务 schema 紧耦合，难以测试和审查。
- **复制整个数据库再过滤**：扩大内存驻留和泄漏风险。

## Decision 7: 统一限额与脱敏审计

**Decision**:

- 请求体默认上限 256 KiB；超限在解析 JSON 前拒绝。
- 每来源默认 60 请求/分钟，突发 10；全局并发 4；单调用超时 5 秒。
- 列表默认 25 条，单页最多 100 条；响应 JSON 建议硬上限 1 MiB，超过时返回分页/结果过大错误。
- 审计只记 UTC 时间、归一化来源、能力名或传输阶段、allow/deny/result、错误类别和耗时；
  不记 headers、Key、参数、响应、邮箱正文、完整 IP 之外的设备指纹。最多 200 条，环形覆盖。

**Rationale**: 本地服务同样需要防止错误 Agent 循环请求、巨量导出或资源耗尽。审计要支持用户
处置，但不能成为第二份个人数据副本。

**Alternatives considered**:

- **无限制本地服务**：LAN 客户端或失控 Agent 可造成内存/CPU 压力与批量导出。
- **记录请求参数便于排障**：会把搜索词、学号、邮件主题等敏感内容固化。

## Decision 8: 桌面首发，移动端暂不支持

**Decision**: Windows、macOS、Linux 提供服务；Android、iOS 与 Web 显示原因和文档入口，不
展示可操作开关。macOS 当前 Debug/Release entitlement 已包含
`com.apple.security.network.server`，实现阶段保留并补充验收。Windows LAN 模式需向用户说明
系统防火墙可能弹窗/拦截，应用不自动创建宽泛入站规则；Linux 同样不自动修改 ufw/firewalld。

**Rationale**: 桌面进程和托盘生命周期可控；移动后台限制会使“正在运行”与实际监听不一致。
自动改防火墙属于高权限系统变更，不应由普通功能静默执行。

**Alternatives considered**:

- **移动端前台临时服务**：可以后续单独规划，但需明确屏幕锁定、后台、网络切换与系统杀进程
  语义，不能混入桌面 MVP。
- **自动放行防火墙**：权限与卸载清理复杂，且容易产生超出端口/网络配置文件的规则。

## Decision 9: 分阶段数据域

**Decision**:

1. 核心学习：个人资料、课表、考试、成绩、培养计划。
2. 校园生活：校园卡摘要/交易、校园活动。
3. 高敏感文本：消息、邮箱；邮件正文单独授权，附件永不返回。
4. 应用偏好：只维护允许对外的白名单 DTO，不导出内部状态。

**Rationale**: 核心学习数据已有明确快照结构，能先验证端到端边界。邮箱和消息包含自由文本，
需要更严格的字段与搜索规则，后置可降低首版风险。

## Resolved Unknowns

- 协议版本：MCP 2026-07-28。
- 服务端 SDK：`mcp_dart ^2.4.2`。
- 传输：单 `POST /mcp`，不兼容旧 HTTP+SSE。
- 认证：Bearer API Key；回环可显式关闭，LAN 强制。
- TLS：首版不内置；LAN 明文风险显著提示。
- 平台：桌面三端；移动与 Web 不支持。
- 协议能力：MVP 仅 tools。
- 数据读取：仅已有本地快照，绝不由 MCP 触发远端刷新。
