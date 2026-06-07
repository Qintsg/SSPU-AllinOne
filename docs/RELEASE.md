# SSPU-AllinOne 发布规则

> 适用范围：本规则约束仓库版本号、发版分支、Release PR、构建产物命名、GitHub Release 标记与发布说明。
> 目标：让版本事实来源、公开版本、内部构建号和用户可下载资产保持一致。

---

## 1. 总体原则

1. `pubspec.yaml` 与 `docs/CHANGELOG.md` 是唯一需要人工维护版本号的文件。
2. `pubspec.yaml` 保存 Flutter 可识别的完整版本：`X.X.X[-channel]+build` 或 `X.X.X.X[-channel]+build`。
3. `docs/CHANGELOG.md` 章节标题保存公开版本，不写 `+build`，例如 `[1.0.0-alpha]`。
4. `+build` 只作为内部构建号，每次发新版本或重发同一公开版本时，都必须在上一次 `pubspec.yaml` build 号基础上自动递增；安装包文件名、系统内部展示、Release 标题和 Release 描述均不得显式写出 `+build`。
5. Git Tag、release 分支名、Release 标题、安装包文件名、`manifest.json` 的公开版本必须一致。
6. 公开 Release 只放终端用户可直接消费的产物，不放中间构建目录、缓存或调试产物。

---

## 2. 版本号规则

### 2.1 公开版本格式

公开版本统一使用：

```text
X.X.X[-channel]
X.X.X.X[-channel]
```

字段说明：

- `X`：数字，至少三段，例如 `1.0.0`。
- 第四段数字仅用于 hotfix 或其它特殊情况，例如 `1.0.0.1-hotfix`。
- `channel` 可选；不写时表示稳定版通道。
- `channel` 仅允许：`alpha`、`beta`、`hotfix`、`rc`、`lts`。

示例：

```text
1.0.0
1.0.0-alpha
1.0.0-beta
1.0.0-rc
1.0.0-lts
1.0.0.1-hotfix
```

### 2.2 `pubspec.yaml` 版本格式

`pubspec.yaml` 中的 `version` 字段必须使用 Flutter 合法格式：

```yaml
version: X.X.X[-channel]+build
version: X.X.X.X[-channel]+build
```

示例：

```yaml
version: 1.0.0-alpha+1
version: 1.0.0+7
version: 1.0.0.1-hotfix+12
```

> 注意：`pubspec.yaml` 不写 `v` 前缀；`v` 前缀只用于 Git Tag 与 `release/v...` 分支名。

### 2.3 Release 类型

| 公开版本 | 通道 | GitHub Release 类型 |
|---|---|---|
| `1.0.0` | stable | 普通 Release |
| `1.0.0-lts` | lts | 普通 Release |
| `1.0.0.1-hotfix` | hotfix | 普通 Release |
| `1.0.0-alpha` | alpha | Pre-release |
| `1.0.0-beta` | beta | Pre-release |
| `1.0.0-rc` | rc | Pre-release |

除稳定版、`lts`、`hotfix` 外，其它 Release 均必须标记为 Pre-release。

---

## 3. 分支与 PR 工作流

### 3.1 日常代码工作流

1. 默认从 `develop` 签出新分支。
2. 按 `.github/分支命名规范.md` 选择分支名，例如 `feature/<topic>`、`fix/<topic>`、`refactor/<topic>`、`docs/<topic>`、`ci/<topic>`。
3. 完成开发、测试与文档同步后，创建 PR 合并回 `develop`。
4. PR 必须使用仓库模板填写变更说明、验证记录、影响范围和风险；关联 Issue 保留 `Closes #123` / `Fixes #123` / `Resolves #123` 等关闭关键字。
5. PR 合并入 `develop` 后，`Close Linked Issues` workflow 会自动关闭同仓库内通过关闭关键字或 GitHub 关联关系识别到的 Issue。
6. 禁止直接向 `develop` 或 `main` 推送未审查提交。

### 3.2 alpha / beta / rc 发布工作流

alpha、beta、rc 属于预发布，直接由 `release/vX.X.X-channel` 分支合入 `develop` 后触发构建：

1. 从 `develop` 签出 `release/vX.X.X-channel` 分支，例如 `release/v1.0.0-alpha`。
2. 只修改 `pubspec.yaml` 与 `docs/CHANGELOG.md` 中的版本号。
3. `pubspec.yaml` 使用 `X.X.X-channel+build`，且 `build` 必须在上一次 `pubspec.yaml` 的基础上自动加一；`docs/CHANGELOG.md` 使用 `[X.X.X-channel]`。
4. 创建 `release/v... -> develop` 的 Release PR。
5. PR 必须使用 Release 模板，完整填写发布说明，并携带 `release` label。
6. PR merge 后由 `Build & Release` workflow 自动构建并创建 GitHub Pre-release。

### 3.3 stable / lts / hotfix 发布工作流

稳定版、lts、hotfix 需要两段 PR，确保版本先进入 `develop`，再由 `develop` 晋级到 `main`：

1. 从 `develop` 签出 `release/vX.X.X[-lts|-hotfix]` 分支。
2. 只修改 `pubspec.yaml` 与 `docs/CHANGELOG.md` 中的版本号。
3. 创建 `release/v... -> develop` 的 Release PR，但不得携带 `release` label。
4. 合并到 `develop` 后，再创建 `develop -> main` 的 Release PR。
5. `develop -> main` 的 Release PR 必须携带 `release` label。
6. PR merge 后由 `Build & Release` workflow 自动构建并创建普通 GitHub Release。

---

## 4. Tag 与命名

### 4.1 Tag 规则

Tag 使用公开版本并加 `v` 前缀，不包含 `+build`：

```text
v1.0.0
v1.0.0-alpha
v1.0.0-lts
v1.0.0.1-hotfix
```

### 4.2 安装包文件名规则

所有安装包和归档文件名均使用公开版本，不包含 `+build`：

```text
SSPU-AllinOne-v{public_version}-{platform}-{arch}-{kind}.{ext}
```

应用显示名可以按语言环境显示为“工大聚合”或 `SSPU-AllinOne`，但 Release 资产文件名始终使用 `SSPU-AllinOne-v...` 规则，不使用中文显示名。

Android universal APK 使用固定短名：

```text
SSPU-AllinOne-v{public_version}-android-universal.apk
```

示例：

```text
SSPU-AllinOne-v1.0.0-alpha-android-universal.apk
SSPU-AllinOne-v1.0.0-windows-x64-installer.exe
SSPU-AllinOne-v1.0.0.1-hotfix-linux-x64-appimage.AppImage
SSPU-AllinOne-v1.0.0-lts-web-universal-static.zip
```

---

## 5. 平台支持矩阵

| 平台 | 架构 | 发布形式 | 默认进入公开 Release |
|---|---|---|---|
| Android | universal | APK | 是 |
| Windows | x64 | installer / portable | 是 |
| Windows | arm64 | installer / portable | 是 |
| macOS | universal | unsigned DMG | 是 |
| Linux | x64 | AppImage / deb / rpm / tar.gz | 是 |
| Linux | arm64 | AppImage / deb / rpm / tar.gz | 是 |
| Web | universal | static.zip | 是 |

Linux 正式发布必须同时覆盖 `x64` 与 `arm64`，并提供 AppImage、deb、rpm、tar.gz 四类产物。

Windows installer 使用 Inno Setup 双模式安装器，x64 与 arm64 行为保持一致：全新安装默认当前用户范围，可在安装向导或命令行显式切换到所有用户范围；安装包文件名和 Release 资产类型仍保持 `windows-{arch}-installer.exe`。安装器许可页使用 `assets/legal/legal_zh.txt`，需要与应用首次启动展示的完整法律与隐私说明保持同步。

Android、iOS、macOS、Linux、Web、portable 与压缩包等当前没有仓库统一控制的安装前 GUI 或 CLI 协议确认页；这些渠道依赖应用首次启动的完整法律与隐私说明弹窗完成一次性确认。

品牌图标与应用徽章的源文件和生成规则见 `docs/BRAND_ASSETS.md`。更换图标时应先更新 `assets/brand/` 源图，再运行 `python scripts/assets/generate_brand_icons.py` 生成平台资源，避免手工只替换单个平台图标导致 Release 展示不一致。

---

## 6. Release 附属文件

每次 Release 必须附带：

- `SHA256SUMS.txt`：列出所有发布资产的 SHA-256。
- `manifest.json`：记录公开版本、`pubspec_version`、构建号、通道、Tag、工具链版本和资产清单。
- `release-notes.md`：由 Release PR 正文生成，与 GitHub Release 正文一致或基本一致。

`manifest.json` 中允许记录 `build_number` 便于追踪，但用户可见标题、文件名和说明不得显式展示 `+build`。

---

## 7. Release PR 发布说明模板

带 `release` label 的 PR 正文必须包含以下章节，并替换为真实内容：

```markdown
## 亮点
- 本次发布最重要的变化

## 新增
- 新增能力

## 修复
- 修复问题

## 优化
- 优化内容

## 破坏性变更
- 无破坏性变更

## 安装 / 升级说明
- 新装用户：
- 升级用户：
- 是否需要清理旧配置：

## 已知问题
- 无已知问题
```

不允许保留“待补充”“请填写”等模板占位文本。

---

## 8. 质量门槛

进入 Release PR 前至少满足：

1. `flutter analyze` 通过。
2. `flutter test` 通过。
3. 版本号只在 `pubspec.yaml` 与 `docs/CHANGELOG.md` 中维护。
4. Release PR 的目标分支、`release` label 使用方式与本规则一致。
5. 构建产物文件名不包含 `+build`。
6. 发布说明列明支持平台、已知问题、安装方式和校验方式。

---

## 9. 失败与重发

1. 构建失败时不得手工上传不完整产物冒充 Release。
2. 需要重发同一公开版本时，只递增 `pubspec.yaml` 中的 `+build`，并重新走对应 Release PR 流程；需要发布新的公开版本时，也必须在上一次 `pubspec.yaml` build 号基础上继续递增，不得重置。
3. 若发现产物命名、校验或版本错误，应撤回或标记失效后重新发版。
4. 不允许静默替换同名产物而不更新校验与说明。

---

## 10. 一句话执行标准

> 版本只维护两处，公开版本不带 `+build`，预发布进 `develop` 触发，稳定 / lts / hotfix 经 `develop` 晋级 `main` 触发。
