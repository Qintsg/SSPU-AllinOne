# AGENTS.md

## 仓库速记

- Flutter 应用包名 `sspu_allinone`，最低工具链以 `pubspec.yaml` / CI 为准：Flutter `3.41.7`，Dart `3.11.5`。
- 入口是 `lib/main.dart`：初始化存储、协议/隐私确认、密码锁、桌面窗口关闭拦截、系统托盘、通知与自动刷新；主导航在 `lib/app.dart`。
- 当前 UI 使用外部 `fluent_ui` 与 `fluentui_system_icons`：页面统一从 `lib/design/fluent_ui.dart` 导入外部 Fluent 控件、项目语义图标 facade 与兼容 token/组件；`lib/theme/` 仅保留历史主题入口，页面不要再引入 Material 命名可见控件。
- 没有 `build_runner` / `freezed` / `json_serializable` 代码生成；仓库使用手写模型和 Dart `part` 拆分大型页面/服务。
- 新增 Dart 文件沿用现有块注释文件头和中文 DartDoc；大文件优先按现有 `part` 风格拆分，不新增生成器。

## 常用命令

- 依赖安装：`flutter pub get`。
- 依赖变更通过 `flutter pub get` / `flutter pub upgrade` 生成 `pubspec.lock`；不要手改 lockfile。
- 本地静态检查：`flutter analyze`；CI 对普通 PR 实际运行 `flutter analyze --no-fatal-infos`。
- 全量测试：`flutter test`；单文件：`flutter test test/<file>_test.dart`；单用例：`flutter test test/<file>_test.dart --name "用例名片段"`。
- 覆盖率：`flutter test --coverage`，生成 `coverage/lcov.info`。
- 常用构建：`flutter build apk --release`、`flutter build web --release`、`flutter build windows --release`、`flutter build linux --release`、`flutter build macos --release`。
- Release PR 正文可用脚本校验：`python scripts/release/render_release_notes.py --body-file pr-body.md --output release-notes.md --validate-only`。

## 工作流与发版

- 默认开发分支是 `develop`，稳定发布分支是 `main`；禁止直接向两者推送未审查提交。
- 分支名按 `.github/分支命名规范.md`：`feature/`、`fix/`、`docs/`、`chore/`、`refactor/`、`test/`、`ci/`、`hotfix/`、`release/v<public-version>`。
- PR 标题和 commit message 使用 `type(scope): 中文摘要`；PR 必须写明变更说明、验证记录、影响范围和回滚方式。
- 版本号只改 `pubspec.yaml` 与 `docs/CHANGELOG.md`；`pubspec.yaml` 用 `X.X.X[-channel]+build` 或 `X.X.X.X[-channel]+build`，`+build` 每次发版/重发都递增，且不得出现在资产文件名、Release 标题或说明中。
- `alpha` / `beta` / `rc`：`release/v... -> develop`，必须加 `release` label，merge 后生成 GitHub Pre-release。
- `stable` / `lts` / `hotfix`：先 `release/v... -> develop` 且不加 `release` label；合并后再 `develop -> main` 并加 `release` label，merge 后生成普通 Release。
- 修改 `.github/`、CI/CD、Action、Release、版本规则、issue/PR 模板时，同步更新 `docs/RELEASE.md`、`docs/specs/RepoWorkflow.md`、`.github/分支命名规范.md` 中受影响内容。

## 代码边界

- `lib/services/` 放外部站点、存储、通知、自动刷新等业务服务；网络请求优先经 `HttpService` / 可注入 gateway，测试中用 fake，避免命中真实校园系统。
- `StorageService` 保存统一应用状态：桌面端 `~/.sspu-all-in/app_state.json`，移动端系统应用支持目录，Web 端 `SharedPreferences:sspu_app_state_json`。
- OA 账号、OA 密码、体育部查询密码、邮箱密码和 OA Cookie 会话由 `AcademicCredentialsService` 写入 `flutter_secure_storage`；不要把这些值写进 `app_state.json`、日志、PR、Release notes 或测试 fixture。
- 微信公众号平台配置在本地 `wxmp_config.toml`，包含 cookie/token 覆盖能力；不要提交真实配置或认证材料。
- 受限校园服务先走 `CampusNetworkStatusService` 校园网/VPN 检测；OA/CAS、体育部、校园卡、学工报表、本专科教务、学校邮箱均按只读能力实现，不新增选课、退课、充值、发送邮件、删除邮件等写入操作。
- CAS 出现验证码、MFA 或安全验证时只提示状态，不尝试绕过交互验证；相关流程变更先看 `docs/OA_LOGIN_RULES.md`、`docs/SPORTS_ATTENDANCE_RULES.md`、`docs/CAMPUS_CARD_RULES.md`、`docs/STUDENT_REPORT_RULES.md`、`docs/EMAIL_RULES.md`。

## UI 与平台注意

- UI 改动优先使用 `lib/design/fluent_ui.dart` 导出的外部 Fluent 控件、语义 `FluentIcons` 和项目兼容组件/token，或现有 `AppSpacing`、`AppBreakpoints`、`AppTheme`；不要新增裸 `Color(0x...)`、`Colors.*`、硬编码间距/字号作为组件样式来源。
- 新增/迁移页面时保留自适应导航约束：窄屏底部 Fluent 导航，中屏/大屏使用 `fluent_ui` `NavigationView` / `NavigationPane`；至少自查桌面宽屏、平板/中屏、移动窄屏。
- 桌面插件调用必须先判断平台；`window_manager`、`tray_manager` 只在 Windows/Linux/macOS 注册，Web/移动端不能直接调用桌面通道。
- Web 不支持本地文件目录和 `local_auth`；Linux 当前没有官方 `local_auth` 实现，仍走手动密码解锁。
- Android `applicationId` / namespace 是 `cn.qintsg.sspu_allinone`，release 签名读取 `android/key.properties`，CI 可用 `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD` 注入；不要提交 `.jks` 或真实 `key.properties`。

## 测试习惯

- 存储测试使用 `StorageService.debugUseSharedPreferencesStorageForTesting` 或 `debugSetStateFilePathForTesting`，并配合 `SharedPreferences.setMockInitialValues({})` 清理状态。
- 安全存储测试先调用 `FlutterSecureStorage.setMockInitialValues({})`，不要读取真实系统钥匙串。
- 校园网/OA/CAS 等服务测试通过构造函数注入 fake probe/gateway；不要依赖真实校园网、VPN 或线上账号。
- Widget 测试改视口后要重置 `tester.view` / `setSurfaceSize(null)`；含 `flutter_animate` 页面结束前通常需要额外 `pump(const Duration(milliseconds: 300))` 清理短计时器。
- Windows 下临时目录删除可能遇到句柄延迟，沿用测试里的短重试模式，不要直接假设一次删除成功。

## 文档与安全

- 影响 `docs/`、依赖、构建发布、平台配置、API/外部网页契约时，同步更新相关文档；发布规则以 `docs/RELEASE.md` 为准。
- 不提交 `.env`、token、Cookie、私钥、keystore、系统凭据、本地 agent 缓存或真实用户状态；`.agents/`、`.opencode/`、`.claude/`、`.worktree/` 等本地自动化目录保持忽略。
