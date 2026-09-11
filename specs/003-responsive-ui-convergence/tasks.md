# Tasks: 校园工作台响应式收敛

**Input**: Design documents from `/specs/003-responsive-ui-convergence/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Phase 1: Setup

- [x] T001 在 `specs/003-responsive-ui-convergence/` 建立规格、计划、研究、数据模型与 UI 契约
- [x] T002 运行现有相关测试并记录教务学分与课表底部溢出的失败基线到 `specs/003-responsive-ui-convergence/quickstart.md`

## Phase 2: Foundational

- [x] T003 [P] 为 360×800、768×900、1200×900 创建共享 Widget 测试尺寸辅助逻辑于 `test/support/`
- [x] T004 审核受影响页面的滚动所有权和 Qingyuan 组件约束并在 `specs/003-responsive-ui-convergence/contracts/ui-contract.md` 保持实现映射

## Phase 3: User Story 1 - 任意窗口无障碍浏览 (Priority: P1) 🎯 MVP

**Goal**: 消除课表与主要长内容区域的溢出，并建立可验证的响应式基础。

**Independent Test**: 在三个目标窗口尺寸打开受影响入口，`tester.takeException()` 均为 null，课表全部时段可滚动访问。

- [x] T005 [US1] 先在 `test/course_schedule_page_test.dart` 增加 1084×706 底部溢出与跨节次定位回归测试
- [x] T006 [US1] 在 `lib/pages/course_schedule_page.dart` 移除受紧约束且不可滚动的桌面内容路径
- [x] T007 [US1] 在 `lib/pages/course_schedule_views.dart` 实现左侧时间轴、顶部星期与跨节次彩色课程块的可滚动周网格
- [x] T008 [P] [US1] 在 `test/academic_page_test_layout.dart` 增加体育考勤窄屏与宽屏无溢出测试
- [x] T009 [US1] 在 `lib/pages/academic_sports_attendance_card.dart` 仿第二课堂指标布局实现宽度自适应

## Phase 4: User Story 2 - 准确精简的教务概览 (Priority: P1)

**Goal**: 修复已获学分并将个人信息与概览整合为紧凑头部。

**Independent Test**: 已通过课程学分合计准确，页面只显示五项身份字段，删除项不可见且下一场考试对齐。

- [x] T010 [US2] 先在 `test/academic_eams_models_test.dart` 增加全学期已通过课程学分合计测试
- [x] T011 [US2] 在 `lib/models/academic_eams/grades.dart` 实现 `earnedCreditsForTerm` 并在 `lib/pages/academic_overview_view.dart` 使用独立成绩快照
- [x] T012 [US2] 更新 `test/academic_page_test_overview.dart` 与 `test/academic_page_test_layout.dart`，断言删除项消失、五字段与对齐布局成立
- [x] T013 [US2] 在 `lib/pages/academic_overview_page_layout.dart`、`lib/pages/academic_overview_content_grid.dart` 和 `lib/pages/academic_overview_cards.dart` 合并概览与个人摘要到 Heading，删除完成度、档案、详细来源按钮及冗余 Wrap
- [x] T014 [US2] 在 `lib/pages/academic_eams_summary_card.dart` 与 `lib/pages/academic_page.dart` 清理重复个人摘要和已删除按钮的 key/focus/callback

## Phase 5: User Story 3 - 集中刷新可信来源 (Priority: P2)

**Goal**: 来源只分官网和微信，刷新一次覆盖全部启用渠道，来源面板与分页自适应。

**Independent Test**: 两渠道启用时一次刷新均被调用；筛选仅三项；窄屏分页无溢出且跳页回顶。

- [x] T015 [US3] 先在 `test/info_refresh_service_test.dart` 增加全部启用渠道原子刷新与部分失败测试
- [x] T016 [US3] 在 `lib/services/info_refresh_service.dart` 实现统一的全部启用渠道刷新任务和进度状态
- [x] T017 [US3] 更新 `test/info_page_layout_test.dart`，覆盖来源合并、删除常规控制行、分页跳转和窄屏布局
- [x] T018 [US3] 在 `lib/pages/info_page.dart`、`lib/pages/info_page_view.dart` 和 `lib/pages/info_page_header.dart` 改为刷新全部启用渠道并删除 `info-regular-controls`
- [x] T019 [US3] 在 `lib/pages/info_page_source_controls.dart`、`lib/pages/info_page_filters.dart` 和 `lib/pages/info_page_filter_view.dart` 合并官网来源，按内容宽度重排来源面板与分页并在跳页后回顶

## Phase 6: User Story 4 - 屏幕内高效阅读邮件 (Priority: P2)

**Goal**: 桌面邮件列表/详情限制在视口并独立滚动，移动端详情保持可达，删除搜索和旧说明。

**Independent Test**: 50 封邮件与长正文均在一屏工作区内可完整滚动，列表只显示三字段且搜索/说明不存在。

- [x] T020 [US4] 先更新 `test/email_page_test.dart` 与 `test/email_visual_layout_test.dart`，覆盖三字段、独立滚动、删除项和目标尺寸无溢出
- [x] T021 [US4] 在 `lib/pages/email_page.dart` 清理搜索状态、控制器和旧说明文本
- [x] T022 [US4] 在 `lib/pages/email_page_layout.dart` 将桌面邮件客户端约束为剩余视口高度并保留窄屏独立详情流
- [x] T023 [US4] 在 `lib/pages/email_mailbox_widgets.dart` 为列表和详情增加独立滚动条，精简摘要字段并改善本地正文段落样式
- [x] T024 [US4] 在 `lib/services/email_gateway.dart` 保留正文段落换行并验证不加载远端 HTML、图片、脚本或样式

## Phase 7: User Story 5 - 高密度工作台快捷操作 (Priority: P3)

**Goal**: 快速链接横向换行，AI 配置双栏等高，服务按钮邻近端口，设置固定左下角。

**Independent Test**: 宽屏与窄屏分别满足约定布局，所有 destination 索引与导航行为保持不变。

- [x] T025 [P] [US5] 更新 `test/quick_links_page_test.dart` 并在 `lib/pages/quick_links_directory.dart`、`lib/pages/quick_links_row.dart` 实现分组内横向换行 tile
- [x] T026 [P] [US5] 更新 `test/ai_services_page_test.dart` 并在 `lib/pages/ai_services_page.dart` 实现窄宽等高双栏与端口右侧启停按钮
- [x] T027 [US5] 更新 `test/widget_test_shell.dart` 并在 `lib/design/qingyuan/navigation/yh_navigation.dart`、`lib/app.dart` 将设置作为桌面导航 footer 固定在底部且保持索引

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T028 更新受用户删除项影响的 `test/visual/` 视觉契约和金丝雀断言
- [x] T029 运行 `dart format --output=none --set-exit-if-changed lib test integration_test`、`flutter analyze --no-fatal-infos`、`flutter test` 与 `python scripts/ci/validate_spec_kit.py`
- [x] T030 运行 `flutter build windows --debug` 和 `flutter run -d windows --debug`，按 `quickstart.md` 检查七个入口与控制台日志
- [x] T031 使用 `$speckit-converge` 对照 spec/plan/tasks 收敛遗漏并将所有已完成任务标记为 `[x]`
- [x] T032 使用 Lore 提交、推送分支、创建目标为 `develop` 的 PR，等待 CI 后通过 PR 合并

## Dependencies & Execution Order

- T001-T004 建立共同验收基础。
- US1 与 US2 同为 P1；先修复课表溢出基线，再收敛教务数据与布局。
- US3 和 US4 在基础阶段完成后互不依赖。
- US5 可在信息与邮件完成后独立实现。
- Polish 依赖全部用户故事完成。

## Parallel Opportunities

- T003 与 T004 可并行；T008 可与课表实现并行。
- US3 与 US4 修改不同服务和页面，可并行开发但须分别先写测试。
- T025 与 T026 文件互不重叠，可并行。

## Implementation Strategy

1. 先用失败测试固定已确认的学分错误与课表溢出。
2. 按 US1 → US2 → US3 → US4 → US5 小步实现，每阶段运行目标测试。
3. 完成后执行全量质量门禁与真实 Windows Debug。
4. 规格收敛通过后使用 Lore 和 PR 流程合并到 `develop`。
