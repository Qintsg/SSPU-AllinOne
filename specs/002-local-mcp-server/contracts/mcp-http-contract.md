# MCP Streamable HTTP Contract

**Protocol version**: `2026-07-28`  
**Endpoint**: `POST /mcp`  
**OpenAPI**: [mcp-http.openapi.yaml](mcp-http.openapi.yaml)

## 1. Endpoint and transport

- 服务只接受 `POST /mcp`。其它路径返回 `404`；`GET /mcp` 等其它方法返回 `405`。
- 每个 POST 只承载一个 JSON-RPC 请求或通知，不支持 JSON-RPC batch。
- 请求使用 `Content-Type: application/json`。
- 客户端 `Accept` 至少允许 `application/json`，需要流式响应时同时允许
  `text/event-stream`。
- 普通请求返回一个 JSON-RPC response，流式请求只在当前 HTTP 响应内使用 SSE。
- 通知成功可返回 `202 Accepted` 且无正文。
- 不实现 GET SSE 长连接、`Mcp-Session-Id` 或服务端协议 session。

## 2. Required protocol metadata

请求必须符合 MCP 2026-07-28 的 HTTP 元数据要求：

| Header | Required | Rule |
| --- | --- | --- |
| `MCP-Protocol-Version` | yes | 必须精确为 `2026-07-28`；协商前的 initialize 按 SDK 规范处理 |
| `Mcp-Method` | yes | 必须与 JSON-RPC body 的 `method` 一致 |
| `Mcp-Name` | conditional | 对 tools/list、tools/call 等命名能力按协议要求携带并与 body 一致 |
| `Authorization` | config-dependent | Key 开启时必须为 `Bearer <api-key>`；LAN 永远要求 |
| `Origin` | optional | 缺失可接受；存在时必须精确命中 allowlist，MVP 默认无浏览器 allowlist |
| `Host` | yes (HTTP/1.1) | 必须命中启动时构造的精确 host:port allowlist |

Header/body 不一致、未知协议版本或重复冲突 header 必须在调用能力前拒绝。

## 3. Processing order

```text
socket accepted
  -> path/method/content-length
  -> Host allowlist
  -> Origin allowlist
  -> Bearer authentication
  -> rate/concurrency limits
  -> JSON and MCP protocol validation
  -> capability authorization
  -> read-only snapshot adapter
  -> post-execution generation check
  -> bounded response + redacted audit
```

认证失败前不得读取个人数据；Host/Origin/auth 失败时也不得把请求 body 或 header 写入审计。

## 4. Authentication

```http
Authorization: Bearer <generated-api-key>
```

- API Key 默认开启；回环模式由用户确认后可关闭；LAN 模式无法关闭。
- 缺失/错误 Key 返回 `401`，并带固定 `WWW-Authenticate: Bearer`；不得区分 Key 不存在、
  已轮换或格式错误。
- 轮换后旧 Key 对新请求立即失效。在途请求还须通过完成前的 Key/account/authorization
  generation 校验。
- 禁止 query string、cookie 或 JSON body 传 Key。

## 5. Supported MCP surface

MVP 支持：

- `initialize`
- `notifications/initialized`
- `ping`
- `tools/list`
- `tools/call`

不声明 resources、prompts、sampling、roots 或其它能力。`tools/list` 只返回当前已授权工具；
`tools/call` 始终再次强制授权。

## 6. Tool result envelope

成功调用返回 MCP `CallToolResult`，其中人类可读 `content` 只给简短摘要，机器数据放在
`structuredContent`：

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "result": {
    "content": [
      {"type": "text", "text": "返回 2 条课程记录；本地快照更新时间 2026-09-10T01:00:00Z。"}
    ],
    "structuredContent": {
      "status": "ok",
      "snapshotAt": "2026-09-10T01:00:00Z",
      "isStale": false,
      "data": {"items": []},
      "page": {"limit": 25, "nextCursor": null, "hasMore": false}
    },
    "isError": false
  }
}
```

状态语义：

- `ok`: 有当前可用快照。
- `empty`: 当前无本地快照，`data` 为 null；不触发远端刷新。
- `stale`: 返回已有快照并给出 `snapshotAt`；Agent 应向用户说明可能过期。

时间一律输出 ISO-8601 UTC。金额为 JSON number 和明确币种，不返回已本地化的拼接字符串。

## 7. Pagination

- 列表参数：`limit` 默认 25，最小 1，最大 100；`cursor` 可选。
- cursor 是不可逆、不透明且有完整性保护的令牌，绑定 tool、过滤条件、账号 generation。
- 过期、损坏或上下文不匹配 cursor 返回 `invalid_cursor`，不得回退为第一页。
- 排序必须稳定；同一快照分页时使用确定性 tie-breaker。

## 8. Error mapping

### HTTP transport errors

| HTTP | Condition | Body rule |
| --- | --- | --- |
| 400 | JSON、协议 header 或 header/body 不一致 | 通用 JSON 错误，不含内部异常 |
| 401 | Bearer 缺失或错误 | 固定文案 + `WWW-Authenticate` |
| 403 | Host/Origin 被拒绝 | 固定文案，不回显 allowlist |
| 404 | 路径错误 | 无个人信息 |
| 405 | `/mcp` 使用非 POST | `Allow: POST` |
| 413 | 请求体超过 256 KiB | 在解析前拒绝 |
| 415 | 非 JSON 请求体 | 固定文案 |
| 429 | 来源速率或全局并发超限 | 可带整数 `Retry-After` |
| 503 | 服务停止中/锁定/上下文不可用 | 固定文案 |

### JSON-RPC / tool errors

| Code | `data.code` | Meaning |
| --- | --- | --- |
| `-32600` | `invalid_request` | 非合法 JSON-RPC 请求 |
| `-32601` | `method_not_found` | 未声明 MCP 方法 |
| `-32602` | `invalid_params` | schema、limit、filter 或 cursor 无效 |
| `-32603` | `internal_error` | 已脱敏内部错误 |
| `-32001` | `permission_denied` | 工具未授权或授权已撤销 |
| `-32002` | `context_changed` | 锁定、账号、Key 或授权 generation 在执行中改变 |
| `-32003` | `timeout` | 调用超过 5 秒 |
| `-32004` | `result_too_large` | 无法在分页/上限内安全返回 |

工具错误响应不包含 stack trace、文件路径、账号、缓存键、Key、原始响应或查询参数。

## 9. Network allowlists

### Loopback

- bind: `127.0.0.1`
- endpoint: `http://127.0.0.1:<port>/mcp`
- allowed Host 包含规范化的 `127.0.0.1:<port>`、`localhost:<port>` 和 `[::1]:<port>`
  （只有实现同时安全绑定 IPv6 回环时）。

### LAN

- bind: `0.0.0.0`
- UI endpoint: 每个合格私网 IPv4 的 `http://<ip>:<port>/mcp`
- allowed Host 只包含启动时实际展示的 IP/设备名与端口。
- 排除 link-local、loopback、未启用接口；VPN/虚拟网卡默认不展示，后续如支持须显式选择。
- 网络地址变化时旧 allowlist 不继续放行；无法安全重建则停服并进入 failed。

`0.0.0.0` 绝不是客户端连接 URL。首版 LAN 是明文 HTTP：API Key 只做认证，不提供机密性。

## 10. Limits

| Limit | Default |
| --- | --- |
| request body | 256 KiB |
| requests per source | 60/minute, burst 10 |
| global concurrent tool calls | 4 |
| tool timeout | 5 seconds |
| list page | default 25, max 100 |
| response body | target hard ceiling 1 MiB |
| audit retention | latest 200 |

这些值通过内部常量管理；如未来暴露设置，必须给出安全范围，不能允许无限值。

## 11. Audit contract

每次请求最多产生一条审计：`occurredAt`、`sourceAddress`、`capabilityId`、`decision`、
`outcome`、`errorCategory`、`durationMs`。认证前拒绝使用 `transport.auth` 等固定 capabilityId。
禁止记录请求/响应 body、headers、Key、参数、搜索词、异常堆栈或个人数据。
