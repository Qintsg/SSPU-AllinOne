# Implementation Plan: 本地个人数据 MCP 服务

**Branch**: `feature/frontend-visual-refresh` | **Date**: 2026-09-10 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-local-mcp-server/spec.md`

## Summary

在 Windows、macOS 与 Linux 客户端内提供默认关闭的 MCP 2026-07-28
Streamable HTTP 服务。服务只暴露显式授权的本地只读快照：默认绑定
`127.0.0.1`，用户确认风险后可绑定 `0.0.0.0`；API Key 默认开启，且局域网
模式强制开启。实现采用 `mcp_dart ^2.4.2` 的 `StreamableMcpServer`，由独立的
生命周期协调器管理监听，由能力注册表、实时授权门和只读快照适配器隔离协议层与现有业务
存储。首版只注册 tools，不注册 resources 或 prompts，以缩小协议面和持久 URI 泄漏风险。

## Technical Context

**Language/Version**: Dart 3.12.0、Flutter >= 3.44.0  
**Primary Dependencies**: `mcp_dart ^2.4.2`、`flutter_secure_storage ^11.0.0`、现有清源 UI facade  
**Storage**: 普通配置、授权与最近 200 条脱敏审计进入现有应用状态存储；API Key 仅进入系统安全存储；个人数据继续使用现有本地快照  
**Testing**: `flutter_test` 单元/Widget/集成测试；真实回环端口协议测试；两个独立 MCP 客户端互操作验收  
**Target Platform**: Windows、macOS、Linux 桌面；Android、iOS 首版只显示不支持说明；Web 不提供服务端  
**Project Type**: 单体 Flutter 多平台应用，内嵌本地 HTTP 服务  
**Performance Goals**: 不超过 100 条的缓存查询 p95 < 500 ms；撤权、锁定、停服、Key 轮换后的新边界 < 1 s 生效  
**Constraints**: 默认关闭、只读、离线快照、无公网暴露、无首版 TLS、请求体/并发/速率/超时/结果均受限；局域网模式必须认证  
**Scale/Scope**: 单用户设备、少量可信客户端；MVP 9 个只读工具，分三批覆盖 8 个数据域；单页最多 100 条、审计最多 200 条  

## Constitution Check

*GATE: Phase 0 前检查，并在 Phase 1 设计后复查。*

| 原则 | 设计满足方式 | 结果 |
| --- | --- | --- |
| 用户价值优先 | `spec.md` 含 5 个可独立测试的用户故事、边界场景与量化成功标准 | PASS |
| Flutter 设计系统一致性 | 设置页面复用清源 facade、tokens 和现有设置导航，不引入 Material/Cupertino 或硬编码样式 | PASS |
| 测试先行与质量门禁 | 每个故事在 `quickstart.md` 映射至单元、Widget、端口集成与跨设备验收；实现阶段执行完整 Flutter 门禁 | PASS |
| 本地数据与最小权限 | API Key 进系统安全存储；数据默认不授权；只读 adapters 不触发校园系统联网 | PASS |
| 可审查的增量交付 | 规格、计划、契约、后续 tasks 与实现保持能力 ID/需求编号追踪；架构取舍在实现前记录 Lore | PASS |
| API 文档约束 | MCP 是 JSON-RPC 而非 REST，但 HTTP 入口仍以 OpenAPI 3.0 描述并由 Redocly 校验；工具 schema 另由 `tool-catalog.md` 定义 | PASS |

**Phase 1 复查**: 数据模型明确区分普通配置、系统安全存储与运行态；HTTP 契约先做
Host/Origin/认证检查，再进入能力层；所有工具均有最小字段、分页与只读标记。无宪章例外。

## Architecture

```text
Settings UI / app lock / app exit / account changes
                      │
                      ▼
        McpServerController (single lifecycle owner)
                      │
                      ▼
       StreamableMcpServer + POST /mcp transport
          │ Host/Origin │ auth │ limits │ audit
          ▼             ▼      ▼        ▼
              McpCapabilityRegistry
                      │
      execution-time authorization + account generation
                      │
                      ▼
        read-only snapshot adapter interfaces
          │              │              │
          ▼              ▼              ▼
   academic cache   campus-card cache   message/email cache
```

关键边界：

- `McpServerController` 是唯一允许创建或关闭监听 socket 的对象；配置变更采用
  stop → validate → bind → publish-state 的串行状态机，失败时不保留半启动实例。
- 传输层不导入任何业务服务，只接受能力注册表；能力处理器只依赖只读 adapter 接口。
- 每次调用在读取快照前和构造响应后各校验一次授权版本、账号 generation 与锁定状态，防止
  撤权或切换账号期间的旧请求回传数据。
- 发现阶段只返回当前已授权 tools；客户端缓存旧目录也不影响执行阶段的强制再授权。
- 外部请求不得调用现有 `refresh`、gateway 或 credentials API；adapter 仅调用明确命名的
  `readLatestCached...` 方法并转换为稳定 DTO。
- 浏览器携带 `Origin` 的请求默认全部拒绝；未来若支持浏览器客户端，必须加入精确 origin
  allowlist，禁止通配符。原生客户端无 `Origin` 时仍需通过 Host 与认证校验。

## Lifecycle State Machine

```text
stopped ──start──▶ starting ──bind ok──▶ running
   ▲                  │                    │
   │                  └─failure──▶ failed │ config/auth/account/lock change
   │                                       ▼
   └────────────── stop complete ◀──── stopping
```

- 应用启动时读取配置，但只有“已显式启用 + 已解锁 + 协议已接受 + 桌面受支持”同时成立才可
  启动；从旧版本升级时配置缺失视为关闭。
- 手动锁定、清除数据、断开账号与真正退出应用前，先等待服务器停止；最小化到托盘不等于退出，
  用户已启用服务时可继续运行并在设置中明确展示。
- 网络接口变化只更新展示地址；LAN 绑定失效时进入 `failed` 并释放旧监听，不自动切换端口或
  放宽 Host allowlist。

## Delivery Slices

1. **安全服务骨架**：配置、Key 安全存储、状态机、POST `/mcp`、Host/Origin、防重绑定、
   限流、审计，以及设置页的本机模式；用无能力目录验证默认拒绝。
2. **核心学习数据**：个人资料、课表、考试、成绩、培养计划、校园卡摘要与交易；仅缓存读取。
3. **高敏感文本数据**：消息、邮箱按独立授权接入；邮箱正文与附件不在默认输出，附件内容首版
   永不暴露。
4. **LAN 与互操作**：风险确认、强制 Key、实际局域网地址、防火墙指引、另一设备验收与两个
   客户端互操作。
5. **扩展域**：校园活动与安全的应用偏好白名单；不直接导出整个应用状态文件。

每个切片都必须保持默认关闭和零授权，能够独立回滚；不得先交付无认证的 LAN 监听。

## Project Structure

### Documentation (this feature)

```text
specs/002-local-mcp-server/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── mcp-http-contract.md
│   ├── mcp-http.openapi.yaml
│   └── tool-catalog.md
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
lib/
├── main.dart                              # 锁定/解锁与启动生命周期接线
├── models/
│   ├── mcp_server_config.dart
│   ├── mcp_server_state.dart
│   ├── mcp_authorization.dart
│   └── mcp_access_audit.dart
├── services/
│   ├── mcp_server_controller.dart         # 唯一生命周期 owner
│   ├── mcp_server_auth_service.dart       # Key 生成、验证、轮换、删除
│   ├── mcp_authorization_service.dart     # 版本化授权快照
│   ├── mcp_capability_registry.dart       # tool schema 与 handler
│   ├── mcp_snapshot_adapters.dart         # 只读接口与 DTO 映射
│   ├── mcp_access_audit_service.dart
│   ├── mcp_network_service.dart           # 地址枚举、Host allowlist
│   └── storage_keys.dart
├── pages/
│   └── ai_services_page.dart               # 顶级“AI 服务”管理页
└── widgets/
    └── settings_widgets.dart               # 复用清源设置行、按钮、输入控件

test/
├── mcp_server_config_test.dart
├── mcp_server_auth_service_test.dart
├── mcp_authorization_service_test.dart
├── mcp_capability_registry_test.dart
├── mcp_snapshot_adapters_test.dart
├── mcp_server_controller_test.dart
├── mcp_streamable_http_contract_test.dart
├── settings_mcp_server_page_test.dart
└── support/mcp_test_fakes.dart

integration_test/
└── mcp_server_loopback_test.dart
```

**Structure Decision**: 保持现有单体 Flutter 布局，不引入第二个后台进程或独立 server package。
协议实现、授权和业务读取通过接口分层，从而允许测试用 fake adapters，并为未来拆包保留边界。

## Failure and Error Policy

- 端口无效/占用、平台不支持、Key 缺失、LAN 未确认、绑定失败均在监听前失败并提供恢复动作。
- HTTP 入口区分传输/认证错误与 MCP JSON-RPC 错误；详细内部异常永不返回客户端。
- 无快照返回成功的 `empty` 状态；陈旧快照返回成功的 `stale` 状态与时间戳；禁止为了消除
  `stale` 状态而隐式联网。
- 未授权或授权已撤销使用稳定错误码；调用期间账号 generation 变化时丢弃结果并返回
  `context_changed`，不返回旧账号数据。
- Key 使用常量时间摘要比较；服务端仅保存随机 Key 的安全存储原文或可验证材料，UI 不长期
  展示，生成/轮换后只提供一次复制机会。

## Verification Strategy

- **静态质量**：`dart format`、`flutter analyze --no-fatal-infos`、`flutter test`。
- **契约**：OpenAPI 3.0 经 Redocly lint；针对 MCP 2026-07-28 header、JSON-RPC、只允许
  POST、Host/Origin、Bearer、请求体上限与错误映射编写端口级测试。
- **安全**：测试默认不监听、LAN 无 Key 不可启动、旧 Key 即时失效、撤权竞态、账号切换、
  锁定/退出停服、审计脱敏、敏感字段扫描。
- **互操作**：至少使用 `mcp_dart` inspector 和一个独立 MCP 客户端，分别验证
  initialize、tools/list、tools/call、分页、empty/stale/denied。
- **平台**：Windows/macOS/Linux 分别验证本机；LAN 声明支持的平台还需从另一设备验证。

## Complexity Tracking

无需要偏离宪章的复杂度例外。选择单进程、单端点和仅 tools 的 MVP 正是为了压缩攻击面与
实现复杂度。
