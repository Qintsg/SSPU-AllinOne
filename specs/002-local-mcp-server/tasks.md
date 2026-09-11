# Tasks: 本地个人数据 MCP 服务

**Input**: Design documents from `/specs/002-local-mcp-server/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: 规格明确要求关键行为、协议、安全边界与前端状态均有测试，因此测试任务先于实现任务。

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 建立依赖、目录和可测试边界，不改动既有业务行为。

- [X] T001 Add the pinned `mcp_dart` dependency and regenerate dependency metadata in `pubspec.yaml` and `pubspec.lock`
- [X] T002 [P] Create MCP model barrel and source files in `lib/models/mcp_server_config.dart`, `lib/models/mcp_server_state.dart`, `lib/models/mcp_authorization.dart`, and `lib/models/mcp_access_audit.dart`
- [X] T003 [P] Create shared MCP test fakes and fixtures in `test/support/mcp_test_fakes.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 所有用户故事共用的配置、秘密、授权、分页和只读快照基础。

- [X] T004 Write config and validation tests in `test/mcp_server_config_test.dart`
- [X] T005 Write API-key generation, validation, rotation, and deletion tests in `test/mcp_server_auth_service_test.dart`
- [X] T006 Write default-deny and versioned authorization tests in `test/mcp_server_config_test.dart`
- [X] T007 Implement MCP configuration persistence keys and APIs in `lib/services/storage_keys.dart` and `lib/services/mcp_server_controller.dart`
- [X] T008 Implement API-key secure storage and constant-time verification in `lib/services/mcp_server_auth_service.dart`
- [X] T009 Implement versioned capability grants in `lib/services/mcp_authorization_service.dart`
- [X] T010 Implement bounded cursor pagination and stable snapshot envelopes in `lib/services/mcp_capability_registry.dart` and `lib/services/mcp_snapshot_adapters.dart`

**Checkpoint**: 配置、Key 与授权均可在无 HTTP 服务时独立测试。

---

## Phase 3: User Story 1 - 安全开启本地 MCP 服务 (Priority: P1) 🎯 MVP

**Goal**: 在支持平台安全启动/停止标准 HTTP MCP 服务，并显示真实运行状态。

**Independent Test**: 默认不监听；显式开启后 MCP 客户端可 initialize/ping；关闭、锁定或退出后端口释放。

- [X] T011 [P] [US1] Write Streamable HTTP protocol and default-off coverage in `test/mcp_server_controller_test.dart`
- [X] T012 [P] [US1] Write lifecycle, port-conflict, generation, and shutdown tests in `test/mcp_server_controller_test.dart`
- [X] T013 [US1] Implement MCP request routing, JSON-RPC methods, body limits, and sanitized errors through `mcp_dart` in `lib/services/mcp_server_controller.dart` and `lib/services/mcp_capability_registry.dart`
- [X] T014 [US1] Implement the single-owner service lifecycle state machine in `lib/services/mcp_server_controller.dart`
- [X] T015 [US1] Wire MCP stop/start into unlock, manual lock, and exit flows in `lib/main.dart` and `lib/services/app_exit_service.dart`

**Checkpoint**: User Story 1 可在没有任何数据授权的情况下独立启动、连接和停止。

---

## Phase 4: User Story 2 - 按数据范围授权外部 Agent (Priority: P1)

**Goal**: 用户逐项授权个人信息、成绩、课表、培养计划、二课学分等本地只读数据。

**Independent Test**: 只开启一个授权时，tools/list 与 tools/call 只允许该能力；撤权立即生效且不触发联网刷新。

- [X] T016 [P] [US2] Write capability discovery, execution-time authorization, and stale/empty tests in `test/mcp_capability_registry_test.dart`
- [X] T017 [P] [US2] Add minimum-field snapshot adapter coverage through `test/mcp_server_controller_test.dart` and `test/mcp_server_config_test.dart`
- [X] T018 [US2] Implement read-only local snapshot adapters in `lib/services/mcp_snapshot_adapters.dart`
- [X] T019 [US2] Implement schemas and handlers for the authorized MCP tools in `lib/services/mcp_capability_registry.dart`
- [X] T020 [US2] Add second-classroom credit capability and contract traceability in `specs/002-local-mcp-server/contracts/tool-catalog.md` and `docs/features/ai/mcp-server.md`

**Checkpoint**: 每项授权可独立发现和调用，返回稳定最小字段及快照时间。

---

## Phase 5: User Story 3 - 选择本机或局域网访问 (Priority: P1)

**Goal**: 支持回环或 `0.0.0.0` 监听，并以精确 Host/Origin 规则保护入口。

**Independent Test**: 回环模式外部设备不可达；LAN 需风险确认和 Key，展示真实私网地址，切回回环后外部连接失效。

- [X] T021 [P] [US3] Write bind-scope, Host/Origin, and LAN-precondition tests in `test/mcp_network_service_test.dart`
- [X] T022 [US3] Implement address discovery, exact Host allowlists, and scope binding in `lib/services/mcp_network_service.dart` and `lib/services/mcp_server_controller.dart`
- [X] T023 [US3] Integrate Host/Origin validation and network changes with the `mcp_dart` transport in `lib/services/mcp_server_controller.dart`

**Checkpoint**: 两种访问范围均有明确且可验证的网络边界。

---

## Phase 6: User Story 4 - 配置可选 API Key (Priority: P1)

**Goal**: 在 UI 中生成、一次性复制、轮换或按规则关闭 API Key。

**Independent Test**: 回环可确认后关闭；LAN 永远强制；错误/旧 Key 被拒绝，新 Key 即时生效。

- [X] T024 [P] [US4] Write HTTP authentication and rotation integration tests in `test/mcp_http_authentication_test.dart`
- [X] T025 [US4] Integrate Bearer authentication before capability access in `lib/services/mcp_server_controller.dart`

**Checkpoint**: API Key 策略从持久化、HTTP 入口到轮换均闭环。

---

## Phase 7: User Story 5 - AI 服务栏目、访问记录与快速撤销 (Priority: P2)

**Goal**: 新建顶级“AI 服务”栏目，集中提供服务状态、连接信息、访问范围、Key、授权矩阵和审计处置。

**Independent Test**: 桌面/平板/窄屏均可完成启停、复制连接、授权和撤销；状态、错误和不支持平台均清晰可见。

- [X] T026 [P] [US5] Write audit redaction/retention tests in `test/mcp_access_audit_service_test.dart`
- [X] T027 [P] [US5] Write AI services page navigation, responsive, state, and authorization tests in `test/ai_services_page_test.dart`
- [X] T028 [US5] Implement bounded redacted access audit storage in `lib/services/mcp_access_audit_service.dart`
- [X] T029 [US5] Implement the Qingyuan AI services page in `lib/pages/ai_services_page.dart`
- [X] T030 [US5] Add the new top-level “AI 服务” destination in `lib/app.dart`
- [X] T031 [US5] Connect page actions to service lifecycle, API Key, grants, copy feedback, LAN warning, audit clearing, and recovery states in `lib/pages/ai_services_page.dart`

**Checkpoint**: 用户无需进入“设置”即可在独立 AI 服务栏目完成全部 MCP 管理与授权。

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: 文档、平台说明、视觉验证、互操作与完整质量门禁。

- [X] T032 [P] Update AI feature index and navigation docs in `docs/features/ai/README.md`, `docs/features/ai/mcp-server.md`, and `docs/features/platform/shell/navigation-shell.md`
- [X] T033 Add visual fixtures and capture coverage for the AI services destination in `test/visual/qingyuan_visual_fixtures_settings.dart` and `test/visual/qingyuan_visual_capture_test.dart`
- [X] T034 Run MCP-focused tests and fix all failures in `test/mcp_server_config_test.dart`, `test/mcp_server_controller_test.dart`, and `test/ai_services_page_test.dart`
- [X] T035 Run `dart format`, `flutter analyze --no-fatal-infos`, Spec Kit validation, Redocly lint, and `git diff --check`
- [ ] T036 Perform rendered Windows desktop and narrow-width QA for AI services, capture evidence, verify browser/app logs, and record results in `specs/002-local-mcp-server/quickstart.md`

---

## Dependencies & Execution Order

- Phase 1 blocks Phase 2; Phase 2 blocks all stories.
- US1 establishes the service lifecycle and transport used by US2–US5.
- US2 and US3 can proceed after US1; US4 depends on transport plus auth foundation; US5 integrates all prior stories.
- Polish depends on all stories.

## Parallel Opportunities

- T002 and T003 can proceed independently after dependency selection.
- Tests marked `[P]` touch separate files and can be written together before their implementations.
- Snapshot adapters and network rules are separate modules after lifecycle foundation is stable.
- Documentation updates can proceed independently of focused tests after user-facing behavior stabilizes.

## Implementation Strategy

1. Establish a default-off, zero-capability HTTP service.
2. Add explicit grants and safe snapshot tools, including second-classroom credits.
3. Add LAN and API-key policy enforcement.
4. Deliver the top-level AI services destination as the only management surface.
5. Validate protocol, security, responsive rendering, platform behavior, and full project gates.

---

## Phase 9: Convergence

**Purpose**: Close the remaining context-safety, quantified acceptance, interoperability, and declared-platform evidence gaps found after implementation.

- [X] T037 Add an execution-context generation guard around MCP snapshot reads and invalidate it before account disconnect, cache/data clearing, privacy lock, and related context changes per FR-017 and the account-change edge case (missing)
- [X] T038 Complete the distinguishable error automation matrix for concurrency, timeout, oversized response, empty/stale data, authentication, authorization, request limits, and port conflicts, and record full scenario coverage per SC-008 and FR-021 (partial)
- [X] T039 Validate initialize, tools/list, tools/call, pagination, empty/stale/denied behavior, and key rotation with a non-`mcp_dart` client and record reproducible evidence per SC-009 and plan: interoperability (missing)
- [ ] T040 Validate packaged loopback mode on Windows, macOS, and Linux plus authenticated LAN access, revocation, scope tightening, and firewall allow/deny behavior from a second same-subnet device on every declared LAN platform per SC-010 and US3 (partial)
- [X] T041 Add a repeatable 100-run fresh-install and upgrade-start harness that proves no MCP listener appears without prior explicit enablement per SC-001 (partial)
- [X] T042 Perform and record a timed end-to-end enable, connection-copy, and authorized capability-discovery acceptance flow within two minutes per SC-002 (partial)
- [X] T043 Add a reproducible local-snapshot performance acceptance run proving p95 first-result latency below 500 ms for result sets up to 100 records per SC-006 (partial)
