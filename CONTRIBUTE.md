# 贡献指南

感谢你对 SSPU-AllinOne（工大聚合）的关注！本文档将帮助你快速搭建开发环境并了解项目的协作流程。

## 目录

- [环境准备](#环境准备)
  - [Flutter SDK](#flutter-sdk)
  - [Git Flow](#git-flow)
  - [Lore Protocol](#lore-protocol)
- [Git Flow 工作流](#git-flow-工作流)
  - [分支策略](#分支策略)
  - [常用命令](#常用命令)
  - [工作流示例](#工作流示例)
- [分支命名规范](#分支命名规范)
- [提交规范](#提交规范)
  - [Commit Message 格式](#commit-message-格式)
  - [Lore 决策记录](#lore-决策记录)
- [Pull Request 流程](#pull-request-流程)
- [开发命令速查](#开发命令速查)

---

## 环境准备

### Flutter SDK

- Flutter SDK >= 3.44.0
- Dart SDK 3.12.0（随 Flutter 3.44.0 提供）
- 各平台对应的开发工具详见 [使用文档](docs/USAGE.md)

```bash
git clone https://github.com/Qintsg/SSPU-AllinOne.git
cd SSPU-AllinOne
flutter pub get
flutter run
```

### Git Flow

Git Flow 是一种广泛使用的分支管理策略，能够规范化开发流程。本项目使用 Git Flow 管理分支生命周期。

#### Windows

```powershell
winget install Kubis1982.GitFlow
```

安装完成后重启终端，使用 `gitflow --version` 验证安装。

#### macOS

```bash
brew install git-flow
```

#### Linux

```bash
# Ubuntu / Debian
sudo apt-get install git-flow

# CentOS / RHEL
sudo yum install gitflow

# Arch Linux
sudo pacman -S gitflow
```

#### 初始化

在仓库根目录执行：

```bash
gitflow init -d
```

项目已配置好默认分支名称，`-d` 参数将使用以下默认值：

| 配置项 | 值 |
|--------|-----|
| Production branch | `main` |
| Development branch | `develop` |
| Feature prefix | `feature/` |
| Bugfix prefix | `bugfix/` |
| Release prefix | `release/` |
| Hotfix prefix | `hotfix/` |
| Support prefix | `support/` |
| Version tag prefix | `v` |

### Lore Protocol

[Lore Protocol](https://github.com/Ian-stetsenko/lore-protocol) 是一个结构化决策上下文工具，用于在 git 提交中记录架构决策和约束信息。

```bash
npm install -g lore-protocol
```

安装后在仓库中初始化：

```bash
lore init
```

这将在 `.lore/` 目录下生成配置文件。详见 [Lore 官方文档](https://github.com/Ian-stetsenko/lore-protocol#readme)。

---

## Git Flow 工作流

### 分支策略

```
main ───────────────────────────────────────── 稳定发布
  │
  └── develop ──────────────────────────────── 日常开发集成
        │
        ├── feature/xxx ───────────────────── 新功能开发
        ├── fix/xxx ───────────────────────── Bug 修复
        ├── docs/xxx ──────────────────────── 文档更新
        ├── chore/xxx ─────────────────────── 杂项维护
        ├── refactor/xxx ──────────────────── 代码重构
        ├── test/xxx ──────────────────────── 测试补充
        └── ci/xxx ────────────────────────── CI 配置
```

- `main`：稳定发布分支，只接收由 `develop` 晋级的 Release PR
- `develop`：日常开发集成分支，所有常规 PR 的默认目标分支

### 常用命令

```bash
# 开始新功能
gitflow feature start <name>

# 完成功能（合并回 develop 并删除功能分支）
gitflow feature finish <name>

# 开始 Bug 修复
gitflow bugfix start <name>

# 完成 Bug 修复
gitflow bugfix finish <name>

# 开始发布
gitflow release start <version>

# 完成发布（合并到 main 和 develop，打标签）
gitflow release finish <version>

# 开始热修复
gitflow hotfix start <version>

# 完成热修复（合并到 main 和 develop，打标签）
gitflow hotfix finish <version>
```

### 工作流示例

以开发一个新功能为例：

```bash
# 1. 确保 develop 是最新的
git checkout develop
git pull origin develop

# 2. 从 develop 创建功能分支
gitflow feature start wechat-subscription

# 3. 在功能分支上开发、提交
git add .
git commit -m "feat(wechat): 添加公众号订阅基础框架"

# 4. 推送到远程
git push -u origin feature/wechat-subscription

# 5. 在 GitHub 上创建 PR（目标分支为 develop）

# 6. PR 合并后，清理本地分支
gitflow feature finish wechat-subscription
```

---

## 分支命名规范

推荐使用小写英文和连字符，避免空格、中文和无语义缩写。允许在分支类型前添加个人前缀（如用户名）。

| 前缀 | 用途 | 示例 |
|------|------|------|
| `feature/` | 新功能 | `feature/wechat-subscription` |
| `fix/` | Bug 修复 | `fix/macos-runner-config` |
| `hotfix/` | 紧急热修复 | `hotfix/v1.0.0.1` |
| `release/` | 发布准备 | `release/v1.0.0` |
| `docs/` | 文档更新 | `docs/release-governance` |
| `chore/` | 杂项维护 | `chore/update-deps` |
| `refactor/` | 代码重构 | `refactor/service-layer` |
| `test/` | 测试补充 | `test/academic-page` |
| `ci/` | CI 配置 | `ci/github-actions-upgrade` |

支持带个人前缀的格式，例如 `qintsg/feature/wechat-subscription`、`alice/fix/login-bug`。

版本号格式：`X.X.X[-channel]`，其中 `channel` 仅允许 `alpha`、`beta`、`hotfix`、`rc`、`lts`。

完整的分支命名与流向规则见 [`.github/分支命名规范.md`](.github/分支命名规范.md)。

---

## 提交规范

### Commit Message 格式

```
type(scope): 中文摘要
```

**允许的 type：**

| type | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档 |
| `style` | 代码格式（不影响逻辑） |
| `refactor` | 重构 |
| `test` | 测试 |
| `chore` | 杂项 |
| `ci` | CI 配置 |
| `build` | 构建相关 |
| `perf` | 性能优化 |
| `deps` | 依赖更新 |

**示例：**

```
feat(wechat): 添加公众号订阅基础框架
fix(macos): 修复 Runner 构建路径错误
docs(readme): 更新构建说明
```

### Lore 决策记录

对于重要的架构决策或技术选型，使用 Lore Protocol 记录决策上下文：

```bash
# 查看某段代码的决策上下文
lore context <file>

# 查看某行代码的决策原因
lore why <file>:<line>

# 创建带 Lore 记录的提交
lore commit
```

---

## Pull Request 流程

1. **创建分支**：从 `develop` 创建功能/修复分支
2. **开发与提交**：遵循提交规范
3. **推送分支**：`git push -u origin <branch>`
4. **创建 PR**：在 GitHub 上创建 PR，目标分支为 `develop`
5. **填写 PR 模板**：包含变更说明、关联 Issue、变更类型、影响范围、验证记录
6. **关联 Issue**：使用 `Closes #123` 或 `Refs #123`
7. **代码审查**：等待 CODEOWNERS 审查
8. **合并**：审查通过后合并

**PR 标题格式：** `type(scope): 中文摘要`

**重要规则：**

- 禁止直接向 `main` / `develop` 推送未审查提交
- `develop` ↔ `main` 同步 PR 必须使用 **merge commit**，不得 squash / rebase
- 影响 `docs/`、依赖、构建发布、平台配置或 API 契约时，必须同步更新相关文档

---

## 开发命令速查

```bash
# 安装依赖
flutter pub get

# 静态分析
flutter analyze --no-fatal-infos

# 运行测试
flutter test

# 运行单个测试文件
flutter test test/academic_page_test.dart

# 格式检查（仅检查变更文件）
dart format --set-exit-if-changed <files>

# 构建
flutter build apk --release        # Android
flutter build windows --release    # Windows
flutter build macos --release      # macOS
flutter build linux --release      # Linux
```

**CI 顺序：** `dart format` → `flutter analyze` → `flutter test`

提交前至少运行 `flutter analyze` + `flutter test`。
