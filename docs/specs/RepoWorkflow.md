# Spec: RepoWorkflow

Scope: repo

# 仓库工作流约束

适用于 SSPU-AllinOne 仓库内所有修复、功能、视觉、文档、发布与工程配置改动。

## 基础原则

- `main` 是稳定发布分支，`develop` 是日常开发集成分支。
- 常规代码工作默认从 `develop` 签出新分支，完成后通过 PR 合并回 `develop`。
- 禁止直接向 `main` / `develop` 推送未审查提交。
- Pull Request 标题与 commit message 统一使用 `type(scope): 中文摘要`。
- 影响 `docs/`、依赖、构建发布、平台配置或 API 契约时，必须同步更新相关文档。

## 日常开发流程

1. 从 `develop` 同步最新代码。
2. 根据 `.github/分支命名规范.md` 签出任务分支，例如 `feature/<topic>`、`fix/<topic>`、`refactor/<topic>`、`docs/<topic>`。
3. 完成开发、测试、文档和模板更新。
4. 默认使用 `.github/pull_request_template.md` 通用 PR 模板创建合并到 `develop` 的 PR；Release PR 使用 `.github/PULL_REQUEST_TEMPLATE/release.md`，也可在创建 PR URL 中指定 `?template=release.md`。
5. 关联 Issue 默认使用 `Refs #123`；需要合并后自动关闭时，必须在 PR 正文保留 `Closes #123` / `Fixes #123` / `Resolves #123` 等关闭关键字。
6. PR 中写明变更说明、验证记录、影响范围和回滚方式。
7. PR 合并入 `develop` 后，`Close Linked Issues` workflow 会关闭同仓库内通过关闭关键字或 GitHub closing reference 识别到的 Issue。
8. `develop -> main` 可用于默认分支治理配置同步；只有明确发版时才添加 `release` label。

## Issue 与 PR 模板

- 普通 PR 只保留一个默认通用模板，覆盖 bugfix、feature、docs、refactor、chore、CI / 依赖 / 仓库治理等常规改动。
- Release PR 只使用 Release 专项模板，并保持发布说明章节与 `docs/RELEASE.md` 的校验规则一致。
- Issue 表单优先使用结构化字段描述优先级、目标平台、影响模块和验证/验收标准；可多选字段用于平台、模块、任务类型、影响范围等天然多值信息。
- Issue 表单中的优先级建议与 `P0` / `P1` / `P2` / `P3` 标签语义对齐，最终优先级仍由维护者确认。
- Issue Triage workflow 会从 Issue Form 结构化字段同步类型、优先级、平台、模块和状态标签；新 Issue 默认进入 `needs-triage`，任务型 Issue 在待办与验收标准完整时可进入 `ready`。
- PR Metadata workflow 会根据 PR 标题 / 分支添加类型标签，从关联 Issue 继承最高优先级、平台和模块标签，并在缺少关联 Issue 且不属于 docs/chore/dependencies/release 豁免时添加 `needs-issue`。
- PR Metadata workflow 会收集 PR commit author / committer 对应的 GitHub 用户，自动把可识别且有仓库权限的非 bot 用户加入 Assignees，不移除人工分配人员。
- 日志、截图、录屏和补充信息不得包含账号、密码、Cookie、Token、验证码、私钥、keystore 或真实用户隐私数据。

## Labels

- 类型标签：`bug`、`enhancement`、`documentation`、`dependencies`、`task`、`refactor`、`chore`、`question`。
- 优先级标签：`P0` 阻塞 / 紧急，`P1` 高优先级，`P2` 中优先级，`P3` 低优先级。
- 模块标签：`frontend`、`services`、`models`、`storage`、`installer`、`update`、`auth`、`notification`、`ci`、`governance`、`release-files`。
- 平台标签：`windows`、`macos`、`linux`、`android`、`ios`、`web`。
- 状态标签：`needs-triage`、`needs-info`、`blocked`、`ready`、`needs-issue`。
- `release` 仅作为人工触发公开 Release workflow 的标签，任何 labeler / triage 自动化都不得自动添加。

## Release 流程

### alpha / beta / rc

- 从 `develop` 签出 `release/vX.X.X-alpha`、`release/vX.X.X-beta` 或 `release/vX.X.X-rc`。
- 只修改 `pubspec.yaml` 与 `docs/CHANGELOG.md` 中的版本号。
- 创建 `release/v... -> develop` PR，并添加 `release` label。
- merge 后自动触发 Build & Release workflow，生成 GitHub Pre-release。

### stable / lts / hotfix

- 从 `develop` 签出 `release/vX.X.X`、`release/vX.X.X-lts` 或 `release/vX.X.X.X-hotfix`。
- 只修改 `pubspec.yaml` 与 `docs/CHANGELOG.md` 中的版本号。
- 先创建 `release/v... -> develop` PR，不添加 `release` label。
- 合并后创建 `develop -> main` PR，并添加 `release` label。
- merge 后自动触发 Build & Release workflow，生成普通 GitHub Release。

## 版本规则

- 公开版本格式为 `X.X.X[-channel]` 或 `X.X.X.X[-channel]`。
- `channel` 仅允许 `alpha`、`beta`、`hotfix`、`rc`、`lts`。
- `pubspec.yaml` 使用 `X.X.X[-channel]+build` 或 `X.X.X.X[-channel]+build`。
- `+build` 必须在上一次 `pubspec.yaml` build 号基础上递增；无论发布新的公开版本还是重发同一公开版本，都不得重置，并且不在安装包文件名、系统内部展示或 Release 描述中显式写出。
- 除 stable、lts、hotfix 外，其它 Release 均为 Pre-release。

## 验证规则

- CI 对非草稿 PR 默认校验 PR 标题格式、目标分支、release label 使用、GitHub 治理文件、变更 Dart 文件格式、`flutter analyze --no-fatal-infos` 与 `flutter test`；分支命名按规范推荐但不作为普通 PR 阻断项；`develop -> main` 同步 PR 会跳过变更 Dart 文件格式检查，避免历史差异阻断默认分支治理同步。
- 安全与质量扫描包含高级 CodeQL、Gitleaks 密钥扫描与 Flutter 覆盖率报告：CodeQL 扫描 GitHub Actions、C/C++ 平台 runner 和 Python 维护脚本；Dart/Flutter 代码由 Dart Format、Flutter Analyze、Flutter Test 与 Coverage workflow 承担，避免使用不支持 Dart 的 CodeQL 语言配置。
- Coverage workflow 在 PR、`develop` 与 `main` 相关 Dart/测试变更上运行 `flutter test --coverage`，并上传 `coverage/lcov.info` 作为短期 artifact。
- User-Agent Policy workflow 在 PR 阶段检查运行时代码中的非标准 UA。OA/CAS 与校园受限 HTTP 请求必须默认使用 `SSPU-AllinOne/{version} ({platform}; {os_version})`；确需使用其它 UA 时，必须在相邻代码注释中写明 `UA-POLICY-ALLOW: <原因>`，说明外部平台兼容要求和保留边界。
- Release workflow 复用逻辑放在 `.github/actions/` composite actions 中，覆盖 Flutter 初始化、arm64 SDK 安装、Windows portable 打包、Linux 多格式产物整理和 Release 元数据生成；治理校验会检查这些 action 存在且被 Release workflow 引用。
- 本地 Dart/Flutter 静态分析：优先运行 `flutter analyze`，期望 `No issues found!`。
- 本地测试：优先运行 `flutter test`；若耗时或平台限制导致无法全量运行，应至少运行受影响测试并说明限制。
- 修改依赖、lockfile、Gradle、Podfile、GitHub Actions 或 composite action 时，Dependency Review workflow 会检查已知漏洞风险。
- GitHub Actions 固定策略：发布、供应链和会写入仓库元数据的高风险 action 优先固定到 SHA 并保留版本注释；普通工具类 action 可固定到明确版本 tag，并交由 Dependabot 分组升级。
- UI/响应式改动应至少覆盖桌面宽屏、平板/中屏、移动窄屏的布局自查；不可出现非预期横向滚动、遮挡、溢出。
- 安全/密码保护改动必须验证：启用、禁用、修改密码、失败/取消回退、清除本地状态等路径。

## 安全与隐私

- 不读取、不输出、不提交 `.env`、密钥、token、私钥、keystore、云凭据等敏感内容。
- 不保存系统 PIN、指纹、Face ID、Touch ID 等原始生物识别数据。
- 不以明文形式保存用户密码。
- 所有用户数据原则上仅保留在本地，不上传云端。
- 修改免责声明、用户协议、隐私协议、开源许可证、第三方协议或安装器许可页时，必须同步更新 `assets/legal/` 中文与英文正文、当前协议确认键、关于页入口、Windows Inno Setup `LicenseFile` 和相关文档/测试。

## 本地工具与插件配置

- 本地插件、agent 运行态、worktree、临时状态、自动化缓存、浏览器测试状态等文件默认不入库。
- 只有明确需要团队共享的配置才允许入库；共享配置必须不含机器路径、密钥、token 或个人账号信息。
- 新增忽略规则时应避免误忽略项目源码、文档、测试、CI 配置和平台工程文件。

## 代码风格

- 遵循 `flutter_lints` 推荐规则。
- Bugfix 保持最小变更，不夹带无关重构。
- 前端 UI 使用外部 `fluent_ui` / `fluentui_system_icons` 承载可见 Fluent 控件与图标，并保留项目兼容 token 和响应式断点；不要新增 Material 命名的可见控件或直接引用 Material 图标。
