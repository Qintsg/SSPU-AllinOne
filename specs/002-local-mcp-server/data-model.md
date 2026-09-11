# Data Model: 本地个人数据 MCP 服务

**Date**: 2026-09-10  
**Principle**: 配置可持久化、秘密进安全存储、运行态不持久化、个人数据只经稳定只读 DTO 返回。

## 1. `McpServerConfig`

持久化在现有普通应用状态中，不包含 Key。

| Field | Type | Default | Validation / Meaning |
| --- | --- | --- | --- |
| `enabled` | `bool` | `false` | 仅表示用户是否显式要求服务运行；升级缺失时必须为 false |
| `accessScope` | `McpAccessScope` | `loopback` | `loopback` 或 `lan` |
| `port` | `int` | `8765` | 1024–65535；不得是项目保留端口；启动前探测占用 |
| `apiKeyEnabled` | `bool` | `true` | `lan` 时必须为 true |
| `startWithApp` | `bool` | `false` | 仅在 enabled、已解锁、协议接受且平台支持时生效 |
| `lanRiskAcceptedAt` | `DateTime?` | `null` | 切到 LAN 或风险文案版本变化时重新确认 |
| `riskNoticeVersion` | `int` | `1` | 与当前文案版本不符时 LAN 配置无效 |

```dart
enum McpAccessScope { loopback, lan }
```

### Validation invariants

1. `accessScope == lan` implies `apiKeyEnabled == true`。
2. `accessScope == lan` implies 当前版本的 `lanRiskAcceptedAt != null`。
3. `enabled == true` 不代表 `running`；真实状态只来自 `McpServerRuntimeState`。
4. `0.0.0.0` 只由 `accessScope` 派生，不作为可自由输入的字符串保存。
5. 保存无效配置失败时，仍保留上一个已验证配置，不部分写入。

## 2. `McpApiKeyCredential`

只存在于系统安全存储和短生命周期内存中，不进入普通状态、审计或异常文本。

| Field | Type | Storage | Meaning |
| --- | --- | --- | --- |
| `secret` | random bytes / encoded string | secure storage | 至少 32 随机字节；仅生成/轮换后向用户显示一次 |
| `keyId` | short opaque string | ordinary state or secure metadata | 用于 UI 和轮换版本识别，不可用于恢复 secret |
| `createdAt` | `DateTime` | secure metadata | 生成时间 |
| `generation` | `int` | secure metadata + memory | 轮换即递增，旧请求验证失败 |

服务只暴露 `McpApiKeyStatus(hasKey, keyId, createdAt, generation)` 给 UI；不得提供读取现有
secret 的通用 API。Key 比较使用固定长度摘要和常量时间比较。

## 3. `McpAuthorizationGrant`

持久化在普通应用状态；默认不存在/关闭。

| Field | Type | Meaning |
| --- | --- | --- |
| `capabilityId` | `String` | 与 tool 名称一致的稳定 ID |
| `domain` | `McpDataDomain` | 所属数据域 |
| `enabled` | `bool` | 用户是否授权；缺失等价于 false |
| `updatedAt` | `DateTime` | 最近修改时间 |
| `version` | `int` | 每次变更递增，供请求竞态校验 |

```dart
enum McpDataDomain {
  profile,
  coursesAndExams,
  gradesAndProgram,
  campusActivities,
  campusCard,
  messages,
  email,
  appPreferences,
}
```

### Authorization semantics

- “域开关”是批量编辑 UI，不替代每个 `capabilityId` 的最终 grant。
- `tools/list` 只投影 enabled grants。
- `tools/call` 取执行时最新授权快照；处理完成后版本变化则丢弃结果。
- 未知 capability 永远拒绝，不因域授权自动放行未来新增工具。

## 4. `McpCapabilityDefinition`

编译期注册，不从持久化配置动态构造。

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | `String` | MCP tool name，snake_case 且永久稳定 |
| `domain` | `McpDataDomain` | 授权与 UI 分组 |
| `title` / `description` | `String` | 不泄露当前用户是否有数据 |
| `inputSchema` | JSON Schema | 参数、范围、分页约束 |
| `outputSchema` | JSON Schema | 稳定最小 DTO |
| `sensitivity` | enum | `standard` / `sensitiveText` |
| `adapter` | handler reference | 只读 snapshot adapter |
| `annotations` | MCP annotations | read-only、non-destructive、幂等 |

注册时断言：ID 唯一、schema 无额外属性、无写入语义、结果包含统一 `snapshot` 元数据、列表
能力包含分页上限。

## 5. `McpServerRuntimeState`

只存在于内存，通过 `ValueListenable`/stream 投影到设置 UI。

| Field | Type | Meaning |
| --- | --- | --- |
| `phase` | `McpServerPhase` | `stopped/starting/running/stopping/failed` |
| `bindAddress` | `String?` | 真实监听地址：`127.0.0.1` 或 `0.0.0.0` |
| `port` | `int?` | 成功绑定的端口 |
| `endpointUris` | `List<Uri>` | 给客户端使用的回环或实际 LAN 地址 |
| `authentication` | enum | `required/disabled` |
| `startedAt` | `DateTime?` | 本次运行开始时间 |
| `lastAccessAt` | `DateTime?` | 最近请求时间，不含内容 |
| `failureCode` | `String?` | 可映射为本地化恢复建议的稳定代码 |
| `generation` | `int` | 每次 start/stop/reconfigure 递增 |

```dart
enum McpServerPhase { stopped, starting, running, stopping, failed }
```

### State transitions

- `stopped -> starting`: 配置和平台预检通过后。
- `starting -> running`: socket 成功绑定且安全中间件就绪后。
- `starting -> failed`: 端口占用、权限、Key 或网络校验失败；必须释放部分资源。
- `running -> stopping`: 用户停服、重配、锁定、账号清理或退出。
- `stopping -> stopped`: 所有新请求拒绝、在途请求取消/失效、socket 释放。
- 任意异步完成只能提交到发起时相同 generation，防止旧 start 覆盖新 stop。

## 6. `McpRequestContext`

每个 HTTP 请求创建一次，只存在于内存。

| Field | Type | Meaning |
| --- | --- | --- |
| `requestId` | opaque string | 内部关联，不回写日志正文 |
| `sourceAddress` | normalized IP | 审计来源 |
| `serverGeneration` | `int` | 服务生命周期代次 |
| `authorizationVersion` | `int` | 授权快照版本 |
| `accountGeneration` | `int` | 当前账号代次 |
| `lockGeneration` | `int` | 隐私锁代次 |
| `deadline` | `DateTime` | 默认 5 秒超时 |

handler 返回前必须调用 `context.isStillValid()`；任一 generation/version 不匹配则清空临时结果并
返回 `context_changed`。

## 7. `McpSnapshotEnvelope<T>`

所有 tool 的 `structuredContent` 使用统一封装，具体字段见工具契约。

| Field | Type | Meaning |
| --- | --- | --- |
| `status` | `ok/empty/stale` | 无快照是 empty；超出模块新鲜度阈值是 stale |
| `snapshotAt` | ISO-8601 UTC string? | 本地快照获取时间；empty 时为 null |
| `isStale` | `bool` | 明确供 Agent 判断是否提醒用户 |
| `data` | `T?` | 经过 allowlist DTO 转换的数据 |
| `page` | `McpPageInfo?` | 列表工具的分页元数据 |

`sourceUri`、`rawFields`、`rawCells`、账号缓存 owner hash、Cookie、token、密码、安全存储键名和
完整本地路径永不进入 envelope。

## 8. `McpPageInfo`

| Field | Type | Validation |
| --- | --- | --- |
| `limit` | `int` | 默认 25，范围 1–100 |
| `nextCursor` | `String?` | 不透明、有完整性保护、绑定 capability/filter/account generation |
| `hasMore` | `bool` | 是否仍有下一页 |

Cursor 不包含可逆个人数据；过滤条件变化或账号 generation 变化时视为无效。

## 9. `McpAccessAuditEntry`

持久化为最近 200 条环形记录，可由用户清除。

| Field | Type | Meaning |
| --- | --- | --- |
| `occurredAt` | UTC `DateTime` | 请求完成或拒绝时间 |
| `sourceAddress` | `String` | 规范化 IP；不附加设备指纹 |
| `capabilityId` | `String` | 未进入能力层时使用 `transport.auth` 等固定阶段名 |
| `decision` | `allowed/denied` | 是否通过边界校验 |
| `outcome` | `success/empty/stale/error` | 不记录响应正文 |
| `errorCategory` | `String?` | `auth/host/origin/rate/permission/context/timeout/internal` |
| `durationMs` | `int` | 处理耗时 |

禁止字段：HTTP headers、API Key、请求参数、搜索词、JSON-RPC body、响应、个人数据、异常堆栈。

## 10. Relationships

```text
McpServerConfig 1 ───── 1 McpServerRuntimeState (derived, memory only)
       │
       └── requires ─── 0..1 McpApiKeyCredential (secure storage)

McpAuthorizationGrant * ──▶ 1 McpCapabilityDefinition
                                      │
                                      └──▶ 1 ReadOnlySnapshotAdapter
                                                   │
                                                   └──▶ McpSnapshotEnvelope<T>

each request ──▶ McpRequestContext ──▶ 1 McpAccessAuditEntry
```

## 11. Persistence and deletion matrix

| Data | Store | On stop | On lock | On clear app data |
| --- | --- | --- | --- | --- |
| Config | ordinary app state | keep | keep | delete |
| Grants | ordinary app state | keep | keep but unusable | delete |
| API Key | system secure storage | keep | inaccessible to active server | delete |
| Runtime state | memory only | reset | reset | reset |
| Audit | ordinary app state, max 200 | keep | keep | delete |
| Personal snapshots | existing stores | unchanged | inaccessible via MCP | existing privacy flow deletes |

停止服务不会偷偷删除用户配置；清除全部数据、断开账号或账号变化必须先使 generation 失效，
再删除对应快照，最后才允许 UI 报告完成。
