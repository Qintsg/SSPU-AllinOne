# Tasks: 校园服务能力收敛

**Input**: Design documents from `specs/001-campus-service-completion/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: 本功能明确要求关键行为具有 Dart/Flutter 自动化测试，并保留目标平台真实验收任务。

**Organization**: 任务按用户故事分组；遵循用户要求，文档故事先于业务实现检查执行。

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 固化范围、依赖和验证入口。

- [x] T001 核对并锁定复用依赖 `enough_mail`、`file_picker`、`flutter_local_notifications`、`timezone`、`open_filex` 于 `pubspec.yaml` 与 `pubspec.lock`
- [x] T002 [P] 建立需求、行为契约与验证指南于 `specs/001-campus-service-completion/spec.md`、`plan.md`、`contracts/behavior-contracts.md`、`quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 确认所有故事共享的本地存储、凭据、只读和清源 UI 边界。

- [x] T003 核对普通状态、账号隔离缓存与系统安全存储边界于 `lib/services/storage_service.dart`、`lib/services/authenticated_data_cache_service.dart`、`lib/services/academic_credentials_service.dart`
- [x] T004 [P] 核对产品 UI 仅通过清源 facade 和语义图标于 `lib/design/qingyuan/qingyuan_ui.dart`、`lib/design/qingyuan/icons/yh_icons.dart`、`scripts/ci/validate_design_system.py`

**Checkpoint**: 共享依赖、数据边界和设计约束可供所有故事复用。

---

## Phase 3: User Story 10 - 从文档准确判断功能状态 (Priority: P1)

**Goal**: 全部相关文档准确区分已实现、待真实平台验证和未实现。

**Independent Test**: 对照本规格、源码和测试逐项检查 README、USAGE、CHANGELOG、功能矩阵、路线图及模块文档，无矛盾状态。

- [x] T005 [P] [US10] 更新全局说明与变更记录于 `README.md`、`docs/USAGE.md`、`docs/CHANGELOG.md`
- [x] T006 [P] [US10] 更新功能矩阵、路线图和领域关系于 `docs/features/overview/feature-matrix.md`、`roadmap.md`、`domains.md`
- [x] T007 [US10] 更新目标模块状态、入口、限制与验证证据于 `docs/features/academic/`、`docs/features/email/`、`docs/features/campus-life/`、`docs/features/info/`、`docs/features/platform/`、`docs/features/quick-operations/`

---

## Phase 4: User Story 1 - 在支持的平台可靠安装与启动 (Priority: P1)

**Goal**: 正式 macOS 产物具备签名、公证、装订、Gatekeeper 和 universal 架构门禁。

**Independent Test**: 静态校验发布工作流，并在具备签名材料的 macOS Runner 上完成安装和首次启动。

- [x] T008 [P] [US1] 覆盖签名授权与发布元数据门禁于 `test/macos_release_entitlements_test.dart`、`test/release_metadata_script_test.dart`
- [x] T009 [US1] 实现 fail-closed 签名、公证、装订、Gatekeeper 与架构检查于 `.github/workflows/release.yml`、`scripts/release/generate_release_metadata.py`
- [x] T010 [P] [US1] 对齐正式与本地未签名授权配置于 `macos/Runner/Release.entitlements`、`macos/Runner/Release-unsigned.entitlements`

---

## Phase 5: User Story 2 - 自主控制首页展示与数据获取 (Priority: P1)

**Goal**: 显示、获取和排序互相独立且重启持久化，所有网络入口遵守模块开关。

**Independent Test**: 修改偏好后验证首页、详情、手动/自动刷新、提醒及重启状态。

- [x] T011 [P] [US2] 覆盖显隐、排序、获取与持久化于 `test/home_dashboard_preferences_test.dart`、`test/data_module_preferences_test.dart`、`test/home_page_test.dart`
- [x] T012 [US2] 实现偏好模型和持久化于 `lib/services/home_dashboard_preferences.dart`、`lib/services/data_module_preferences.dart`、`lib/services/storage_keys.dart`
- [x] T013 [US2] 接入设置、首页、详情与自动刷新门禁于 `lib/widgets/settings_general_section.dart`、`lib/pages/home_page.dart`、`lib/services/auto_refresh_service_init.dart`

---

## Phase 6: User Story 3 - 查询培养计划与空闲教室 (Priority: P1)

**Goal**: 提供只读培养计划和空闲教室的完整状态与响应式页面。

**Independent Test**: 成功、空、登录失效、网络失败数据在桌面和移动尺寸均可浏览和恢复。

- [x] T014 [P] [US3] 覆盖培养计划和空闲教室解析与页面状态于 `test/academic_eams_service_test.dart`、`test/academic_program_plan_page_test.dart`、`test/academic_free_classroom_page_test.dart`
- [x] T015 [US3] 实现培养计划与空闲教室只读查询、解析和缓存于 `lib/services/academic_eams_service.dart`、`lib/models/academic_eams/program_plan.dart`、`lib/models/academic_eams/free_classrooms.dart`
- [x] T016 [US3] 实现清源详情页和教务入口于 `lib/pages/academic_program_plan_page.dart`、`lib/pages/academic_free_classroom_page.dart`、`lib/pages/academic_page_navigation.dart`

---

## Phase 7: User Story 5 - 获得可控且私密的本地提醒 (Priority: P1)

**Goal**: 课程、考试和消息提醒在支持平台按开关、提前时间、勿扰和权限可靠规划。

**Independent Test**: 验证权限允许/拒绝、模块关闭、勿扰、数据变化、重启恢复与到点投递。

- [x] T017 [P] [US5] 覆盖提醒规划、协调、平台配置与通知服务于 `test/academic_reminder_planner_test.dart`、`test/academic_reminder_coordinator_test.dart`、`test/notification_service_test.dart`、`test/notification_platform_config_test.dart`
- [x] T018 [US5] 实现提醒规划、取消和重排于 `lib/services/academic_reminder_planner.dart`、`lib/services/academic_reminder_coordinator.dart`、`lib/services/notification_service.dart`
- [x] T019 [US5] 接入应用启动、设置和五端平台能力声明于 `lib/main.dart`、`lib/widgets/settings_general_section.dart`、`android/`、`ios/`、`macos/`、`windows/`、`linux/`

---

## Phase 8: User Story 6 - 完整处理学校邮件 (Priority: P1)

**Goal**: 支持最多 100 封邮件加载、IMAP 已读回写、本地搜索和附件收发。

**Independent Test**: 替代邮箱网关验证分页去重、标志回写、主题/正文搜索、附件按需下载和附件发送。

- [x] T020 [P] [US6] 覆盖邮件服务分页、已读、搜索与附件契约于 `test/email_service_test.dart`
- [x] T021 [P] [US6] 覆盖邮箱页面加载、详情、搜索、下载和撰写附件于 `test/email_page_test.dart`
- [x] T022 [US6] 实现邮件与附件模型、IMAP/SMTP/MIME 网关和服务行为于 `lib/models/email_mailbox.dart`、`lib/services/email_gateway.dart`、`lib/services/email_service.dart`
- [x] T023 [US6] 实现邮箱分页、搜索、详情下载和撰写附件交互于 `lib/pages/email_page.dart`、`lib/pages/email_mailbox_widgets.dart`、`lib/pages/email_message_detail_page.dart`、`lib/pages/email_compose_panel.dart`

---

## Phase 9: User Story 7 - 在一个日历中管理课程与考试 (Priority: P1)

**Goal**: 本周/整学期统一议程可导出并交系统日历导入。

**Independent Test**: 使用跨周、考试和特殊字符数据验证议程排序、导出内容和系统打开动作。

- [x] T024 [P] [US7] 覆盖统一议程、RFC 5545 转义和导出于 `test/course_schedule_page_test.dart`、`test/academic_ics_export_service_test.dart`
- [x] T025 [US7] 实现稳定 UID、时间、转义、折行和文件写入于 `lib/services/academic_ics_export_service.dart`
- [x] T026 [US7] 接入本周/整学期议程、导出与系统关联应用于 `lib/pages/course_schedule_page.dart`、`lib/pages/course_schedule_views.dart`

---

## Phase 10: User Story 4 - 使用移动端学习通深链 (Priority: P2)

**Goal**: 仅在 Android/iOS 已安装学习通时显示可用深链。

**Independent Test**: 在支持/不支持平台与安装/未安装状态验证入口可见性和点击结果。

- [x] T027 [P] [US4] 覆盖平台白名单、安装检测和深链打开于 `test/quick_links_config_service_test.dart`、`test/quick_links_availability_service_test.dart`、`test/quick_links_page_test.dart`
- [x] T028 [US4] 声明学习通深链和平台查询能力于 `assets/config/quick_links.yaml`、`android/app/src/main/AndroidManifest.xml`、`ios/Runner/Info.plist`
- [x] T029 [US4] 实现运行平台与安装状态过滤和应用打开反馈于 `lib/services/quick_links_availability_service.dart`、`lib/pages/quick_links_page.dart`

---

## Phase 11: User Story 8 - 查看校园卡消费趋势 (Priority: P2)

**Goal**: 支持四种时间范围及日/周/月消费聚合。

**Independent Test**: 使用跨日、周、月、退款、收入、重复与空数据核对金额和趋势。

- [x] T030 [P] [US8] 覆盖筛选、金额精度、去重和聚合于 `test/campus_consumption_analytics_service_test.dart`、`test/campus_consumption_analytics_page_test.dart`
- [x] T031 [US8] 实现趋势模型与纯本地聚合服务于 `lib/models/campus_consumption_trend.dart`、`lib/services/campus_consumption_analytics_service.dart`
- [x] T032 [US8] 实现清源筛选、汇总、趋势和空/错误状态页面于 `lib/pages/campus_consumption_analytics_page.dart`、`lib/pages/home_campus_card_detail_page.dart`

---

## Phase 12: User Story 9 - 统一刷新微信公众号来源 (Priority: P2)

**Goal**: 公众号和服务号共享认证、刷新、去重和通知意愿链路。

**Independent Test**: 多账号、重复文章、认证失效、部分失败和并发刷新均得到稳定结果。

- [x] T033 [P] [US9] 覆盖统一刷新、文章去重和通知意愿于 `test/message_state_service_test.dart`、`test/settings_wechat_matrix_card_test.dart`
- [x] T034 [US9] 合并公众号与服务号抓取、刷新锁和消息生成于 `lib/services/info_refresh_service.dart`、`lib/services/wxmp_article_service.dart`、`lib/services/message_state_service.dart`
- [x] T035 [US9] 统一设置页认证、账号开关和刷新反馈于 `lib/widgets/settings_wechat_section.dart`、`lib/widgets/settings_wechat_matrix_card.dart`、`lib/pages/info_page.dart`

---

## Phase 13: Polish & Cross-Cutting Concerns

**Purpose**: 运行全部门禁并记录不能由当前 Windows 环境替代的平台证据。

- [x] T036 按 `specs/001-campus-service-completion/quickstart.md` 对变更 Dart 文件执行格式门禁
- [x] T037 运行 `flutter analyze --no-fatal-infos` 并修复目标范围内全部错误于 `lib/`、`test/`
- [x] T038 运行完整 `flutter test` 并确认目标用户故事测试全部通过于 `test/`
- [x] T039 [P] 运行规格、治理、设计、Action workflow 校验于 `scripts/ci/`、`.github/workflows/release.yml`
- [x] T040 构建并验证 Windows release 产物于 `build/windows/x64/runner/Release/`
- [ ] T041 记录 macOS Runner、通知真实设备、Android/iOS 学习通已安装与未安装深链、微信真实认证和系统日历关联应用验收于 `specs/001-campus-service-completion/quickstart.md` 与相关功能文档

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 → 用户故事阶段 → Phase 13。
- 用户要求文档先行，因此 US10 首先执行；之后 P1 故事 US1、US2、US3、US5、US6、US7 可按领域独立验证。
- P2 故事 US4、US8、US9 共享基础设施但彼此无实现依赖。
- T041 依赖可用的 macOS Runner、真实通知设备、微信平台账号和系统日历应用；其他自动化门禁不依赖它。

## Parallel Opportunities

- T002、T004 可与相邻只读核对并行。
- 同一故事中的测试文件与不重叠实现文件可并行准备；最终集成任务顺序执行。
- US1、US2、US3、US5、US6、US7 在 Phase 2 完成后可独立推进。
- US4、US8、US9 可分别推进，不共享可变业务文件。
- T039 可与 T040 在 T036-T038 通过后并行。

## Independent Test Summary

- **US1**: macOS workflow 静态门禁 + Runner 安装/首次启动。
- **US2**: 设置显隐/获取/排序后验证所有入口与重启。
- **US3**: 两个教务页面的成功、空、失败和移动布局。
- **US4**: 移动平台及安装状态矩阵。
- **US5**: 权限、开关、勿扰、重排、重启和到点投递。
- **US6**: 100 封分页去重、IMAP Seen、本地搜索、附件收发。
- **US7**: 课程/考试统一议程、特殊字符导出与系统打开。
- **US8**: 四种窗口与三种粒度的金额人工核对。
- **US9**: 多账号、重复、部分失败和并发刷新。
- **US10**: 文档状态逐项与源码、测试和平台证据交叉核对。

## Implementation Strategy

1. 先完成并校验 US10，确保文档状态不超前承诺。
2. 按 P1 阻塞程度依次收敛 US1、US2、US3、US5、US6、US7。
3. 独立收敛 P2 的 US4、US8、US9。
4. 最后运行完整门禁；T041 未具备外部环境时保持未完成并在文档中明确标注。

## Format Validation

- 所有任务均使用 `- [ ] T### [P?] [US?] 描述 + 精确路径` 格式。
- 用户故事阶段全部含 `[US#]`；Setup、Foundational 和 Polish 阶段不使用故事标签。
- 初始实现共 41 项任务；收敛阶段追加 T042-T057，当前共 57 项任务。

---

## Phase 14: Convergence

**Purpose**: 修复首次实现审计中发现的协议、设置、统计与错误反馈缺口；真实平台验收继续由 T041 跟踪。

- [x] T042 [US6] 改用 IMAP `BODYSTRUCTURE` 与正文 part 按需读取，确保附件内容仅在用户点击下载时传输，并补充协议级测试于 `lib/services/email_gateway.dart`、`test/email_service_test.dart` per FR-012 / SC-005 (partial)
- [x] T043 [US2] 让邮箱已读回写和附件下载共同遵守模块联网获取开关并返回可理解的能力或网络失败状态于 `lib/services/email_service.dart`、`lib/pages/email_page.dart`、`test/email_service_test.dart`、`test/email_page_test.dart` per FR-003 / US2/AC2 (partial)
- [x] T044 [US6] 对选择阶段的无效、超量和超大待发送附件提供明确反馈且不产生重复发信于 `lib/pages/email_page.dart`、`lib/services/email_service.dart`、`test/email_page_test.dart` per FR-013 / US6/AC5 (partial)
- [x] T045 [US8] 按稳定交易身份去重消费记录，并使非法自定义日期保留上一次有效趋势于 `lib/services/campus_consumption_analytics_service.dart`、`lib/pages/campus_consumption_analytics_page.dart`、`test/campus_consumption_analytics_service_test.dart`、`test/campus_consumption_analytics_page_test.dart` per FR-018 / US8/AC2 (partial)
- [x] T046 [US9] 为微信统一刷新返回认证失效、部分来源失败和成功计数，保留成功结果并展示重新认证或重试提示于 `lib/services/wxmp_article_service.dart`、`lib/services/wxmp_article_fetch.dart`、`lib/services/wechat_article_service.dart`、`lib/services/info_refresh_service.dart` 及相关测试 per FR-020 / US9/AC3 (partial)
- [x] T047 [US5] 在设置页暴露并持久化课程与考试提醒提前量，变更后立即重排提醒于 `lib/pages/settings_page.dart`、`lib/pages/settings_page_actions.dart`、`lib/pages/settings_page_layout.dart`、`lib/widgets/settings_general_section.dart` 及相关测试 per FR-007 (partial)
- [x] T048 [US5] 以 `Asia/Shanghai` 墙上时间调度校园提醒，并为 ICS 补充可移植的时区定义与非本地设备时区测试于 `lib/services/notification_service.dart`、`lib/services/academic_ics_export_service.dart` 及相关测试 per FR-007 / FR-015 (partial)
- [x] T049 [US10] 在修复后重新核对邮箱、消费趋势、微信刷新、通知与日历文档和验证证据，避免把本地完成写成真实平台验收于 `docs/features/email/`、`docs/features/campus-life/`、`docs/features/info/`、`docs/features/platform/system/notifications.md`、`docs/features/academic/eams/calendar.md`、`specs/001-campus-service-completion/quickstart.md` per FR-021 / FR-022 (partial)

---

## Phase 15: Convergence

**Purpose**: 补齐第二轮审计发现的通知独立控制、权限可见性与教务详情状态恢复缺口；真实平台验收继续由 T041 跟踪。

- [x] T050 [US5] 增加独立于全局通知、课程提醒和考试提醒的普通消息通知偏好，在设置页持久化该开关，并让自动刷新消息投递遵守它于 `lib/services/message_state_service.dart`、`lib/services/message_state_service_notifications.dart`、`lib/services/auto_refresh_service_timers.dart`、`lib/pages/settings_page.dart`、`lib/pages/settings_page_actions.dart`、`lib/pages/settings_page_layout.dart`、`lib/widgets/settings_general_section.dart` 及相关测试 per FR-007 (verified by targeted and full tests)
- [x] T051 [US5] 查询并持续展示系统通知的已授权、已拒绝和平台不支持状态，在权限缺失或变化时提供恢复说明并取消或重排无效提醒于 `lib/services/notification_service.dart`、`lib/pages/settings_page.dart`、`lib/pages/settings_page_actions.dart`、`lib/widgets/settings_general_section.dart` 及相关测试 per FR-007 / US5/AC3 / plan: 通知协调契约 (verified by targeted and full tests)
- [x] T052 [US3] 修正培养计划空数据状态及窄屏模块进度布局，并覆盖成功、空结果、登录失效、网络失败和重试恢复在桌面与 360px 移动宽度的页面测试于 `lib/pages/academic_program_plan_page.dart`、`test/academic_program_plan_page_test.dart` per SC-003 / US3/AC3 (verified by targeted and full tests)
- [x] T053 [US3] 让空闲教室刷新失败时保留上一次有效列表并在原位显示登录失效或网络失败及重试反馈，补齐桌面与 360px 状态恢复测试于 `lib/pages/academic_free_classroom_page.dart`、`test/academic_free_classroom_page_test.dart` per US3/AC3 (verified by targeted and full tests)

---

## Phase 16: Convergence

**Purpose**: 修正单公众号通知意愿被错当成抓取开关的链路耦合。

- [x] T054 [US9] 让手动与定时刷新始终处理已配置的公众号/服务号，单来源通知开关仅在系统通知投递层生效，并补充回归测试于 `lib/services/wechat_article_service.dart`、`lib/services/wxmp_article_fetch.dart`、`lib/widgets/settings_wechat_matrix_card.dart`、`test/wxmp_article_service_test.dart` per FR-020 / US9/AC4 (verified by targeted and full tests)

---

## Phase 17: Convergence

**Purpose**: 收敛微信通知语义调整后的聚合 Widget 测试与全量验证证据。

- [x] T055 [US9] 更新聚合设置测试中的批量通知文案契约，重新运行全量测试并同步验证记录于 `test/widget_test_settings.dart`、`specs/001-campus-service-completion/quickstart.md` per FR-020 / US9/AC4 (verified by targeted test and full 802-test suite)

---

## Phase 18: Convergence

**Purpose**: 为偏好持久化与邮箱本地搜索补齐成功标准中的量化自动化证据。

- [x] T056 [US2] 模拟连续十次应用存储重载，验证首页卡片显隐、服务摘要顺序和模块联网获取偏好均保持不变于 `test/home_dashboard_preferences_test.dart` per SC-002 (verified by targeted and full tests)
- [x] T057 [US6] 抽取页面复用的纯本地邮件过滤函数，并验证 100 封主题与正文搜索在一秒内完成且不访问远端网关于 `lib/services/email_service.dart`、`lib/pages/email_page.dart`、`test/email_service_test.dart` per FR-011 / SC-004 (verified by targeted service/page tests and full tests)
