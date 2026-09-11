# Quickstart Validation: 校园服务能力收敛

## 前置条件

- 位于仓库根目录和 `feature/frontend-visual-refresh` 分支。
- Flutter/Dart SDK 满足 `pubspec.yaml`。
- 不使用真实账号、密码、Cookie 或生产邮箱作为测试 fixture。
- macOS 最终验收需要具备签名、公证材料的 macOS Runner 与干净测试环境。

## 1. 规格与文档一致性

```powershell
python scripts/ci/validate_spec_kit.py
python scripts/ci/validate_github_governance.py
python scripts/ci/validate_design_system.py
```

预期：全部退出码为 0；功能矩阵与模块文档正确区分本地实现和平台验收。

## 2. 依赖、格式与静态分析

```powershell
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
```

预期：锁文件无需手工修改，格式和分析均通过。

## 3. 目标功能测试

```powershell
flutter test test/home_dashboard_preferences_test.dart test/data_module_preferences_test.dart
flutter test test/academic_program_plan_page_test.dart test/academic_free_classroom_page_test.dart
flutter test test/quick_links_availability_service_test.dart test/quick_links_page_test.dart
flutter test test/notification_service_test.dart test/academic_reminder_planner_test.dart test/academic_reminder_coordinator_test.dart
flutter test test/widget_test.dart test/message_state_service_test.dart
flutter test test/email_service_test.dart test/email_page_test.dart
flutter test test/academic_ics_export_service_test.dart test/course_schedule_page_test.dart
flutter test test/campus_consumption_analytics_service_test.dart test/campus_consumption_analytics_page_test.dart
flutter test test/message_state_service_test.dart
flutter test test/macos_release_entitlements_test.dart test/release_metadata_script_test.dart
```

预期：所有目标测试通过；测试覆盖成功、空、失败、禁用、去重和边界条件。

## 4. 全量回归与 Windows 产物

```powershell
flutter test
flutter build windows --release
```

预期：全量测试通过，Windows release 产物可启动；视觉采集按仓库策略跳过时不计为失败。

## 5. 发布工作流静态校验

```powershell
actionlint .github/workflows/release.yml
```

预期：工作流语法通过，macOS 正式路径包含签名、公证、装订、Gatekeeper 与 universal 架构检查。

## 6.1 本地验证记录（2026-09-10）

| 检查 | 结果 | 证据边界 |
| --- | --- | --- |
| `dart format --set-exit-if-changed lib test` | 通过（458 个文件） | 仅代码格式 |
| `flutter analyze --no-fatal-infos` | 通过 | 当前 Windows 工作树 |
| `flutter test` | 通过（802 项） | 含 1564 项视觉采集按仓库策略跳过 |
| 规格 / 治理 / 设计校验 | 通过 | `scripts/ci/` 静态契约 |
| `actionlint .github/workflows/release.yml` | 通过 | 工作流语法与静态结构 |
| `flutter build windows --release` | 通过 | 生成 `build/windows/x64/runner/Release/sspu_allinone.exe` |
| `flutter build apk --release --split-per-abi` | 阻塞（外部依赖下载） | Gradle 从 Maven Central 下载 Kotlin/Netty 依赖时 TLS 握手失败；未据此判断 Android 源码构建失败 |
| Flutter Web 宽屏设置页 | 通过 | 提醒提前量选择器可见、可展开、状态与文案同步；360px 布局由响应式 Widget 测试确认无溢出 |

本轮专项测试还覆盖：普通消息独立通知开关与权限状态查询、培养计划四态/窄屏恢复、空闲教室失败保留旧结果、邮箱分页/已读/搜索/附件、课程考试 ICS、消费趋势四窗口三粒度、公众号统一刷新、通知与抓取语义分离、批量通知文案契约和学习通深链；对应测试文件见上方第 3 节。

量化成功标准由以下自动化证据覆盖：`home_dashboard_preferences_test.dart` 连续执行十次存储服务重载并核对卡片显隐、摘要顺序与模块获取偏好；`email_service_test.dart` 在 100 封本地邮件中同时匹配主题和正文，并断言纯本地过滤在一秒内完成。页面搜索继续由 `email_page_test.dart` 验证交互和结果展示。

以上记录证明本地实现与自动化门禁，不替代 macOS Runner、真实通知设备、微信平台认证或系统日历关联应用验收。

## 7. 真实平台验收

1. macOS：下载正式 DMG，在干净环境安装并首次启动；记录签名、公证、装订、Gatekeeper 和架构结果。
2. Android/iOS/macOS/Windows：分别验证通知权限允许/拒绝、重启恢复、勿扰时段和到点投递。
3. Android/iOS：分别验证学习通已安装和未安装时的入口可见性与深链。
4. 微信公众平台：使用测试账号完成扫码认证，验证公众号与服务号统一刷新、部分失败和去重。
5. 系统日历：在每个目标平台将导出文件交给关联应用，确认事件数量、时间、标题和地点。

任何未执行的平台场景必须记录为 pending，不得写成已完成。

## 8. 本轮收敛边界

- 邮箱列表已验证不下载附件内容，已读与附件下载遵守模块停止获取；真实 IMAP/SMTP 服务兼容性仍需测试账号验收。
- 消费趋势去重、非法日期保留、微信部分成功与认证分类由自动化测试覆盖；真实校园卡与微信公众平台仍需联调。
- 提醒提前量、上海墙上时间和 ICS `VTIMEZONE` 已由单元/Widget 测试覆盖；这不替代各系统通知到点投递和关联日历应用导入验收。
