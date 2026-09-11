# Quickstart and Acceptance Guide

本文件描述当前实现的开发、验证与用户验收路径。桌面版 MCP 服务、授权矩阵、API Key、
局域网边界和“AI 服务”管理页已经落地；跨设备、系统防火墙和第二客户端互操作仍需按本文
的手工步骤完成发布前验收。

## 当前验证证据（2026-09-11）

- Windows release 构建已通过：`build/windows/x64/runner/Release/sspu_allinone.exe`。
- `flutter test` 已通过 819 个测试；MCP 配置、认证、授权、快照、HTTP 边界、审计和 AI
  服务页面均包含在内。
- `flutter analyze --no-fatal-infos`、Spec Kit 校验、Redocly OpenAPI lint 与
  `git diff --check` 已通过。
- 收敛验收自动化已通过：`test/mcp_quantitative_acceptance_test.dart` 验证 100 次默认关闭启动、
  2 分钟内启用/发现流程，以及 20 次最多 100 条快照查询的 p95 < 500 ms；
  `test/mcp_independent_client_interop_test.dart` 使用不依赖 `mcp_dart` 的原始 HTTP 客户端验证
  `server/discover`、`tools/list`、`tools/call`、分页、越权和 Key 轮换。
- `test/mcp_capability_registry_test.dart` 现覆盖数据上下文撤销、empty、并发上限、超时和响应体上限；
  `test/mcp_server_controller_test.dart` 覆盖端口冲突失败关闭。
- AI 服务视觉 fixture 已采集 360×800、768×900、1200×900、1600×1000 的明暗主题；
  视觉采集测试在默认测试运行中按约定跳过，仅用于本地截图审查。
- 尚未替代的外部证据：Windows 打包版人工点击、第二台设备 LAN 访问、系统防火墙允许/拒绝、
  第二种非 `mcp_dart` 客户端互操作，以及 macOS/Linux 真机验收。

## 1. Developer setup

1. 确认 `pubspec.yaml` 已锁定 `mcp_dart ^2.4.2`。
2. 只通过 fake snapshot adapters 运行协议测试；测试不得登录或访问真实校园系统。
3. 端口测试绑定 `127.0.0.1` 的 OS 分配临时端口，禁止硬编码共享测试端口。
4. 测试 API Key 使用进程内固定夹具，禁止写入仓库、日志或测试截图。

建议实现顺序：

```text
models/config -> auth/authorization -> controller/transport
-> fake adapters + contract tests -> real snapshot adapters
-> settings UI -> lifecycle wiring -> LAN/platform acceptance
```

## 2. Local loopback smoke test

### Preconditions

- 应用已解锁且已接受协议。
- 至少一个业务模块已有本地快照。
- MCP 默认仍为关闭状态，所有数据项均未监听端口。

### Procedure

1. 打开顶级导航“AI 服务”。
2. 确认默认值为：服务关闭、仅本机、API Key 开启、全部数据未授权。
3. 生成 API Key，立即复制到安全的客户端配置；关闭一次性展示后确认 UI 不再回显原文。
4. 只授权 `list_schedule`，端口使用默认值或一个未占用合法端口。
5. 开启服务，确认状态从“启动中”变为“运行中”，端点为
   `http://127.0.0.1:<port>/mcp`。
6. 在 MCP 客户端中配置 Streamable HTTP URL 和 Bearer Key（若本机模式关闭 API Key，则无需认证）。
7. 验证 `tools/list` 只包含 `list_schedule`；调用后仅返回本地快照和 freshness 元数据。
8. 撤销授权，立即再次 list/call；目录中工具消失，旧名称调用被拒绝。
9. 关闭服务，确认客户端不可再连接且端口已释放。

不得把真实 Key 粘贴到 issue、终端录屏、测试日志或 PR 描述中。

## 3. Negative security matrix

| Scenario | Expected |
| --- | --- |
| Fresh install / upgrade without config | no listening port |
| Wrong path or GET `/mcp` | 404 / 405（传输层错误） |
| Oversized body | 413 before JSON parsing |
| Missing/wrong Key in authenticated mode | 401; no personal cache read |
| Host not in exact allowlist | 403; allowlist not echoed |
| Any Origin in MVP | 403 |
| Header/body method mismatch | 400 before tool handler |
| Unauthorised tool call | JSON-RPC `permission_denied`; zero data |
| Authorization revoked during call | result discarded; `context_changed` |
| Account changed/cleared during call | result discarded; `context_changed` |
| App manually locked | listener stops within 1 second |
| API Key rotated | old Key immediately 401; new Key works |
| No snapshot | successful `empty`; no network refresh |
| Stale snapshot | successful `stale` with `snapshotAt` |
| Limit > 100 / invalid cursor / invalid date | `invalid_params` / `invalid_cursor` |
| Audit inspected | no Key, params, body, response, password, Cookie, Token, paths |

## 4. LAN acceptance

### Preconditions

- 两台设备位于用户确认可信的同一局域网。
- 用户理解 HTTP 与 API Key 不加密传输。
- 路由器未配置公网端口转发；测试不使用公共网络。

### Procedure

1. 在服务设置中选择“局域网”，阅读并确认风险。
2. 确认 API Key 被强制开启且无法关闭。
3. 开启后确认内部 bind 是 `0.0.0.0`，但 UI 只显示实际私网地址，例如
   `http://192.168.1.23:<port>/mcp`。
4. 本机用显示地址完成一次认证调用。
5. 第二台设备用同一显示地址和 Key 完成 `initialize`、`tools/list`、`tools/call`。
6. 去掉或篡改 Key，确认 100% 被拒绝。
7. 切回“仅本机”，确认第二台设备立即失联，而本机回环地址按新配置可用。
8. 轮换 Key，确认第二台设备旧 Key 失效。

### Platform notes

- **Windows**: 系统防火墙可能阻止 LAN 入站；应用展示指引，不自动创建任意网络配置文件的
  宽泛规则。验收同时覆盖“允许”和“拒绝防火墙提示”的可理解状态。
- **macOS**: 当前 DebugProfile/Release entitlements 已包含
  `com.apple.security.network.server`；仍需分别验证签名构建和系统防火墙行为。
- **Linux**: 不自动修改 ufw/firewalld；发行包、普通用户与启用防火墙环境分别验证。
- **Android/iOS/Web**: 设置页显示“不支持在此平台运行服务”，不存在可误触的开启开关。

## 5. Client interoperability

至少使用两个独立实现的 MCP 客户端：

1. `mcp_dart` 自带 inspector/示例客户端，用于同 SDK 诊断。
2. 一个非 `mcp_dart` 的独立 MCP 客户端，用于发现协议偏差。

两者均需覆盖：

- `initialize` 协商到 `2026-07-28`
- `tools/list` 的授权过滤
- `tools/call` 的 JSON 与 request-scoped SSE 响应（若客户端请求流式）
- `empty`、`stale`、分页、拒绝与 Key 轮换
- 无 `Mcp-Session-Id`、无 GET SSE 依赖

## 6. Automated quality gates

实现阶段按顺序执行：

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --no-fatal-infos
flutter test
python scripts/ci/validate_spec_kit.py
npx --yes @redocly/cli lint specs/002-local-mcp-server/contracts/mcp-http.openapi.yaml
git diff --check
```

若仓库后续固定 Redocly 版本，应改用锁定版本而非浮动 `npx`。

## 7. Story-to-test traceability

| User story | Automated evidence | Manual/platform evidence |
| --- | --- | --- |
| US1 安全开启/关闭 | controller state machine、port conflict、shutdown tests | 设置状态与真实端口一致 |
| US2 按范围授权 | registry/authorization/adapter tests、撤权竞态 | 客户端 list/call 仅见授权能力 |
| US3 本机/LAN | bind/Host allowlist tests | 两设备可达性与切回回环 |
| US4 API Key | auth、rotation、constant-time verifier interface tests | 一次性复制与旧 Key 失效 |
| US5 审计与撤销 | audit redaction/retention tests | 从记录页停服、撤权、轮换 |

## 8. Release exit criteria

- 三个桌面平台本机模式均通过。
- 声明支持 LAN 的每个平台均通过另一设备验收。
- 两个 MCP 客户端互操作通过。
- 敏感词与结构扫描确认审计、日志、普通状态和响应中无秘密材料。
- 100 次冷启动/升级场景无未经用户操作的监听。
- 当前功能文档中的旧“HTTP/SSE”“必须 Token”表述已同步为本规格策略。
