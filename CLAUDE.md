# CLAUDE.md

## 项目基础信息

- 项目名称：SSPU-AllinOne
- 默认开发分支：`develop`
- 稳定发布分支：`main`

## 默认工作流

1. 进行代码工作时，默认从 `develop` 分支签出新分支。
2. 分支命名必须遵循 `.github/分支命名规范.md`。
3. 常规功能、修复、重构、文档、CI 和依赖工作完成后，创建 PR 合并回 `develop`。
4. PR 必须符合仓库 issue / PR 模板要求，写明变更说明、验证记录、影响范围和回滚方式。
5. 禁止直接向 `develop` 或 `main` 推送未审查提交。

## Release 工作流

### alpha / beta / rc

1. 从 `develop` 签出 `release/vX.X.X-alpha`、`release/vX.X.X-beta` 或 `release/vX.X.X-rc`。
2. 只修改 `pubspec.yaml` 与 `docs/CHANGELOG.md` 中的版本号。
3. 创建 `release/v... -> develop` 的 Release PR。
4. PR 必须携带 `release` label，merge 后自动触发 Build & Release workflow。
5. 这些发布必须是 GitHub Pre-release。

### stable / lts / hotfix

1. 从 `develop` 签出 `release/vX.X.X`、`release/vX.X.X-lts` 或 `release/vX.X.X.X-hotfix`。
2. 只修改 `pubspec.yaml` 与 `docs/CHANGELOG.md` 中的版本号。
3. 创建 `release/v... -> develop` 的 Release PR，但不得携带 `release` label。
4. 合并后创建 `develop -> main` 的 Release PR，并在该 PR 携带 `release` label。
5. stable、lts、hotfix 发布均为普通 GitHub Release，不标记为 Pre-release。

## 版本号规则

- 公开版本格式：`X.X.X[-channel]` 或 `X.X.X.X[-channel]`。
- `channel` 仅允许：`alpha`、`beta`、`hotfix`、`rc`、`lts`。
- `pubspec.yaml` 版本格式：`X.X.X[-channel]+build` 或 `X.X.X.X[-channel]+build`。
- `+build` 由发版自动化在每次发版时递增，不得出现在安装包文件名、系统内部展示、Release 标题或 Release 描述中。
- 版本号只在 `pubspec.yaml` 与 `docs/CHANGELOG.md` 中维护。

## 文档要求

- 发布规则以 `docs/RELEASE.md` 为准。
- 仓库工作流以 `docs/specs/RepoWorkflow.md` 与 `.github/分支命名规范.md` 为准。
- 修改工作流、CI/CD、Action、版本规则、Release 行为、issue/PR 模板时，必须同步更新相关文档。

## 安全要求

- 不提交 `.env`、密钥、token、Cookie、私钥、keystore、系统凭据或本地 agent worktree 缓存。
- 不在日志、Release 描述、issue、PR 或提交信息中泄露敏感信息。
- 本地自动化缓存目录应保持在 `.gitignore` 中。
