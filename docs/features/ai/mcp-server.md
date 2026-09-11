# 本地数据 MCP 暴露

> 模块：[AI 助手](README.md)　·　状态：**已实现（桌面）**
>
> 与 [模型与数据边界](model-data-boundary.md) 同源同策的「反向」能力：AI 助手是**对内**调用本地数据；本功能是把本地**只读**数据通过 MCP **对外**暴露给外部 MCP 客户端。

| 项 | 内容 |
| --- | --- |
| 功能 ID | `ai.mcp-server` |
| 状态 | 已实现（桌面） |
| 平台 | **仅桌面（Windows · macOS · Linux）**；Android/iOS 不支持 |
| 关联 Issue | — |
| 主要代码 | `lib/pages/ai_services_page.dart`、`lib/services/mcp_server_controller.dart`、`mcp_capability_registry.dart`、`mcp_snapshot_adapters.dart` |

## 1. 需求

将用户本地各域**只读**数据做成**可选**对外暴露的 MCP server，供外部 MCP 客户端（Claude Desktop、IDE、其它 Agent）按授权访问。权限、端口、绑定地址等可配；**默认关闭**。

**验收要点**
- 默认关闭，用户显式开启。
- 仅暴露**经授权的只读**数据；无写能力。
- 端口、绑定范围可配；API Key 默认开启，局域网模式强制认证。
- 移动端不支持（不提供 server）。

## 2. 传输与访问控制

- **传输**：MCP `2026-07-28` **Streamable HTTP**，单一 `POST /mcp` 端点，可配端口。
- **绑定范围可配**：默认 `127.0.0.1`（仅本机）；确认风险后可监听 `0.0.0.0` 并展示真实局域网 IPv4。
- **API Key**：默认开启并进入系统安全存储，可生成和轮换；仅回环模式允许关闭，局域网模式强制开启。
- **入口防护**：校验 Host 与 Origin，拒绝 JSON-RPC batch 和旧 MCP 协议。
- **默认关闭**：仅在用户开启且配置完成后监听。

## 3. 暴露内容与权限（复用按域授权矩阵）

- 暴露为 MCP **只读 tools**，当前覆盖个人信息、成绩、课表、考试、培养计划、二课学分、校园卡、校园消息和学校邮箱列表。
- **复用** [模型与数据边界](model-data-boundary.md) 的按域授权矩阵：逐域开关决定哪些域可经 MCP 暴露；最小必要字段。
- **无写工具**：不暴露任何写操作。

```
MCP 客户端 ──Streamable HTTP + 可选/强制 API Key──▶ 本地 MCP server
                                          │ 按域授权校验（复用矩阵）
                                          ▼
                              各域只读工具/资源（最小必要）
```

## 4. 实现

- 桌面启动可配端口的 Streamable HTTP MCP server；监听前校验配置（端口/范围/API Key 就绪）。
- 请求经 API Key 认证（如已开启）→ 按域授权校验 → 调用对应只读工具 → 返回最小必要数据；无效分页游标和日期参数会明确返回参数错误。
- 生命周期：随开关启停；调用可脱敏审计。
- 移动端：不实现 server，设置项显示「不支持」。

## 5. 关联

- 关联：[模型与数据边界](model-data-boundary.md)（共用按域授权矩阵与只读工具）；[设置中心](../platform/shell/settings.md)（开关/端口/地址/Token 配置）；[安全锁屏与隐私](../platform/system/security-privacy.md)（Token 安全存储）。
- 数据来源：各被授权只读功能（教务/资讯/校园生活等）。

## 6. 约束

- **默认关闭、默认 API Key、只读**；局域网必须 API Key，无任何写能力。
- 绑定非回环地址属用户显式选择，需提示风险。
- Token 与暴露内容不进日志；数据对外暴露完全由用户开关与授权控制。
- 仅桌面；移动端不支持。

## 7. 待办与演进

- [x] 桌面 Streamable HTTP MCP server（可配端口/范围）。
- [x] API Key 安全存储、生成与轮换。
- [x] 按域授权矩阵及只读本地快照工具。
- [x] 独立“AI 服务”栏目（开关/端口/范围/API Key/授权）。
- [x] 调用脱敏审计与最多 200 条保留策略。
- [x] 网卡地址变化监测：局域网地址变化时重启监听并刷新 Host allowlist；无法确认地址时释放监听并提示恢复。
- [ ] Android/iOS 前台限定服务模式（后续独立评估）。
