# Agent Instructions — SSPU-AllinOne

This file provides AI agents with essential context for working in this repository. It is tracked in git and synced across all contributors.

## Project Overview

**SSPU-AllinOne (工大聚合)** is a campus services app for Shanghai Second Polytechnic University, built with Flutter + Fluent UI. It targets Android, iOS, macOS, Linux, and Windows.

- **Flutter SDK**: >= 3.44.0
- **Dart SDK**: 3.12.0
- **License**: Artistic License 2.0

## Key Commands

```bash
flutter pub get                        # Install dependencies
flutter analyze --no-fatal-infos       # Static analysis
flutter test                           # Run all tests
flutter test test/some_test.dart       # Run single test
dart format --set-exit-if-changed <f>  # Format check (CI only checks changed files)
flutter build apk --release            # Android
flutter build windows --release        # Windows
flutter build macos --release          # macOS
flutter build linux --release          # Linux
```

**CI order**: `dart format` → `flutter analyze` → `flutter test`. Run at least `analyze` + `test` before committing.

## Git Flow

The repo uses Git Flow for branch management. Initialize with `gitflow init -d`.

### Branch Types

| Type | Prefix | Target | Use For |
|------|--------|--------|---------|
| Feature | `feature/` | develop | New features |
| Bugfix | `fix/` | develop | Bug fixes |
| Docs | `docs/` | develop | Documentation |
| Chore | `chore/` | develop | Maintenance |
| Refactor | `refactor/` | develop | Code restructuring |
| Test | `test/` | develop | Test additions |
| CI | `ci/` | develop | CI changes |
| Release | `release/` | develop→main | Version releases |
| Hotfix | `hotfix/` | develop→main | Emergency fixes |

### Naming Convention

Format: `[prefix/]<type>/<topic-kebab-case>`

- Use lowercase and hyphens (no spaces or Chinese)
- Optional personal prefix: `qintsg/feature/xxx`
- Release version: `X.X.X[-channel]` (channel: alpha/beta/rc/lts/hotfix)

### Common Commands

```bash
gitflow feature start <name>    # Create feature branch
gitflow feature finish <name>   # Merge back and delete
gitflow bugfix start <name>     # Create bugfix branch
gitflow release start <version> # Create release branch
gitflow hotfix start <version>  # Create hotfix branch
```

## Commit Messages

Format: `type(scope): 中文摘要`

| type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Formatting (no logic change) |
| `refactor` | Code restructuring |
| `test` | Tests |
| `chore` | Maintenance |
| `ci` | CI config |
| `build` | Build system |
| `perf` | Performance |
| `deps` | Dependencies |

**Summary MUST contain Chinese characters.**

## Pull Requests

### Rules

- All regular PRs → `develop` (never `main` directly)
- PR title: `type(scope): 中文摘要`
- Link issues: `Closes #123` (auto-close) or `Refs #123` (reference only)
- develop↔main: **merge commit only** (no squash/rebase)

### Before Submit

```bash
flutter analyze --no-fatal-infos
flutter test
```

### Auto-Labels

PR Metadata workflow auto-applies labels from title/branch and inherits from linked issues.

## Issue Templates

| Template | Title Prefix | Use When |
|----------|-------------|----------|
| `bug_report.yml` | `[Bug]` | Crashes, errors, unexpected behavior |
| `feature_request.yml` | `[Feature]` | New features, enhancements |
| `docs.yml` | `[Docs]` | Documentation issues |
| `tasks.yml` | `[Task]` | Clear development tasks |
| `question.yml` | `[Question]` | Usage questions |
| `release_request.yml` | `[Release]` | Release preparation |

**Priority**: P0 (blocking) > P1 (high) > P2 (medium, default) > P3 (low)

## Release Workflow

### Trigger

Release is triggered when a PR with `release` label is merged.

### Two Paths

**Pre-release (alpha/beta/rc)**:
```
release/vX.X.X-channel → develop (with release label)
```

**Stable (stable/lts/hotfix)**:
```
release/vX.X.X → develop (no label)
develop → main (with release label)
```

### Artifacts

| Platform | Naming |
|----------|--------|
| Android | `SSPU-AllinOne-v{ver}-android-arm64-v8a.apk`, `-armeabi-v7a.apk`, `-x86_64.apk`, `-x86.apk` |
| Windows | `SSPU-AllinOne-v{ver}-windows-{arch}-setup.exe`, `-portable.zip` |
| macOS | `SSPU-AllinOne-v{ver}-macos-{arch}.dmg` |
| Linux | `SSPU-AllinOne-v{ver}-linux-{arch}.{ext}` |
| iOS | `SSPU-AllinOne-v{ver}-ios-arm64.app` |

### Release Notes

PR body must include these sections (validated by CI):

```markdown
## 亮点
## 新增
## 修复
## 优化
## 破坏性变更
## 已知问题
```

## Lore Protocol

Lore records structured decision context in git commits.

```bash
lore context <file>        # Full decision context
lore constraints <file>    # Active constraints
lore rejected <file>       # Rejected alternatives
lore why <file>:<line>     # Why a specific line exists
lore commit -i             # Create Lore-enriched commit (interactive)
lore doctor                # Health check
```

## Design System

- **Single UI import**: `import 'design/fluent_ui.dart'` (do NOT import `package:fluent_ui` directly)
- **Icons**: Use project `FluentIcons` facade, not Material `Icons.*`
- **No raw tokens**: Never use `Color(0xFF...)`, `Colors.*`, bare `EdgeInsets`, bare `fontSize`
- **Components**: Use `design/components/` business components

## Data & Privacy

- User data stays local (desktop: `~/.sspu-aio/`, mobile: app directory)
- Credentials in system secure storage (`flutter_secure_storage`)
- Read-only queries only (no write operations for enrollment/payment)

## Files NOT Committed

`.env`, `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.codex/`, `.agents/` (except skills), `.opencode/`, `dist/`, `build/`, `.idea/`, `.vscode/`

## Project-Level Skills

Located in `.agents/skills/`:

| Skill | Purpose |
|-------|---------|
| `issue-writing` | Issue creation guide |
| `lore-usage` | Lore Protocol usage |
| `git-flow` | Git Flow commands |
| `branch-checkout` | Branch creation for issues |
| `commit-messages` | Commit message format |
| `pr-writing` | PR creation guide |
