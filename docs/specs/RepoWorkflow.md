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
4. 按仓库 PR 模板创建合并到 `develop` 的 PR。
5. PR 中写明变更说明、验证记录、影响范围和回滚方式。

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

- Dart/Flutter 静态分析：优先运行 `flutter analyze`，期望 `No issues found!`。
- 测试：优先运行 `flutter test`；若耗时或平台限制导致无法全量运行，应至少运行受影响测试并说明限制。
- UI/响应式改动应至少覆盖桌面宽屏、平板/中屏、移动窄屏的布局自查；不可出现非预期横向滚动、遮挡、溢出。
- 安全/密码保护改动必须验证：启用、禁用、修改密码、失败/取消回退、清除本地状态等路径。

## 安全与隐私

- 不读取、不输出、不提交 `.env`、密钥、token、私钥、keystore、云凭据等敏感内容。
- 不保存系统 PIN、指纹、Face ID、Touch ID 等原始生物识别数据。
- 不以明文形式保存用户密码。
- 所有用户数据原则上仅保留在本地，不上传云端。

## 本地工具与插件配置

- 本地插件、agent 运行态、worktree、临时状态、自动化缓存、浏览器测试状态等文件默认不入库。
- 只有明确需要团队共享的配置才允许入库；共享配置必须不含机器路径、密钥、token 或个人账号信息。
- 新增忽略规则时应避免误忽略项目源码、文档、测试、CI 配置和平台工程文件。

## 代码风格

- 遵循 `flutter_lints` 推荐规则。
- Bugfix 保持最小变更，不夹带无关重构。
- 前端 UI 使用 Fluent 2 主题、设计 token 和响应式断点；Flutter Material 仅作为底座，避免重新引入外部 Fluent UI 依赖。
