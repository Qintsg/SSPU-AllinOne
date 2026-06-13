# Agent Instructions — SSPU-AllinOne

This file is the tracked source of truth for AI agents working in this repository. Read it before investigating, editing, committing, or opening a pull request.

## Project

**SSPU-AllinOne（工大聚合）** is a Flutter + Fluent UI campus services app for Shanghai Second Polytechnic University. It targets Android, iOS, macOS, Linux, and Windows.

- Flutter SDK: `>= 3.44.0`
- Dart SDK: `3.12.0`
- License: Artistic License 2.0
- Shared agent skills: `.agents/skills/`
- Local-only agent files: `AGENTS.md`, `CLAUDE.md`, `.codex/`, `.claude/`, `.opencode/`

Default to Simplified Chinese in conversation, comments, issue/PR text, and commit summaries unless a target file or external API requires another language.

## First Steps For Repo Work

1. Start from the current repository root and check `git status --short --branch`.
2. Read this file and the relevant project skill under `.agents/skills/`.
3. Do not investigate or edit directly on `develop` or `main`; create a task branch first.
4. Ignore unrelated untracked or dirty local files unless they block the requested task.
5. Use Lore for commits and include fresh verification evidence before reporting completion.

## Key Commands

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter test test/some_test.dart
dart format --set-exit-if-changed <changed-dart-files>
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64,android-x64,android-x86
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

CI order is `dart format` -> `flutter analyze --no-fatal-infos` -> `flutter test`. Before committing, run at least the checks that cover the changed surface; for routine Dart changes this means analyze plus targeted or full tests.

## Git Flow

The repository is already initialized for Git Flow. The command surface differs by platform and install method:

- Windows often provides `gitflow`, but some Git installations provide `git flow`.
- macOS and Linux commonly provide the Git plugin form `git flow`.
- Always detect the available command first and use that form consistently in the current shell. In examples below, `<git-flow>` means either `gitflow` or `git flow`.

On a fresh clone only, run `<git-flow> init -d` and verify the result with:

```bash
pwsh ./scripts/gitflow/check_config.ps1
# or
bash ./scripts/gitflow/check_config.sh
```

Expected Git Flow configuration:

| Config | Value |
| --- | --- |
| Production branch | `main` |
| Development branch | `develop` |
| Feature prefix | `feature/` |
| Bugfix prefix | `bugfix/` |
| Release prefix | `release/` |
| Hotfix prefix | `hotfix/` |
| Support prefix | `support/` |
| Version tag prefix | `v` |

Branch targets:

| Work | Branch prefix | Target |
| --- | --- | --- |
| New feature | `feature/` | `develop` |
| Bug fix | `bugfix/` | `develop` |
| Documentation | `docs/` | `develop` |
| Maintenance | `chore/` | `develop` |
| Refactor | `refactor/` | `develop` |
| Tests | `test/` | `develop` |
| CI / governance | `ci/` | `develop` |
| Dependencies | `deps/` | `develop` |
| Pre-release | `release/vX.X.X-alpha\|beta\|rc` | `develop` |
| Stable / lts / hotfix release prep | `release/vX.X.X[-lts\|-hotfix]` | `develop`, then `develop -> main` |
| Emergency integration | `hotfix/` | `develop`; public release still uses the release flow |

Use Git Flow only for branch classes the installed tool supports:

```bash
<git-flow> feature start <name>
<git-flow> bugfix start <name>
<git-flow> release start <version>
<git-flow> hotfix start <version>
```

For `docs/`, `chore/`, `refactor/`, `test/`, `ci/`, and `deps/`, create the branch manually from an up-to-date `develop`:

```bash
git checkout develop
git pull --ff-only origin develop
git checkout -b docs/<topic-kebab-case>
```

Branch naming format: `[personal-prefix/]<type>/<topic-kebab-case>`. Use lowercase ASCII and hyphens for the topic. A personal prefix such as `qintsg/` is allowed before the branch type.

Important distinction: bug-fix branches use the Git Flow prefix `bugfix/`, but commit and PR titles still use the conventional type `fix(scope): 中文摘要`.

## Issue Handling Workflow

Always create the branch before investigation or fixes:

1. Sync `develop`.
2. Select a branch class from the issue title, labels, and scope.
3. Create the branch with `<git-flow> feature start`, `<git-flow> bugfix start`, or manual `git checkout -b <type>/<topic>`.
4. Investigate, implement, and verify on that branch.
5. Commit with Lore.
6. Push and create a PR targeting `develop`, except the final `develop -> main` release promotion.

Example:

```bash
git checkout develop
git pull --ff-only origin develop
<git-flow> bugfix start scorecard-243-sha
# work, verify
lore commit -i
git push -u origin bugfix/scorecard-243-sha
gh pr create --base develop --title "fix(ci): 升级 Scorecard 到 v2.4.3 并修复 SHA"
```

## Commit Messages And Lore

Commit title format:

```text
type(scope): 中文摘要
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`, `deps`, `release`.

Every agent-made commit should use Lore. Preferred command:

```bash
lore commit -i
```

Useful checks:

```bash
lore doctor
lore validate HEAD~1..HEAD
pwsh ./scripts/lore/status.ps1
# or
bash ./scripts/lore/status.sh
```

`lore-protocol@0.5.0` does not provide a built-in `lore status` subcommand in all installations. Use the repository helper scripts above when the local shim is unavailable.

Lore trailers must be a contiguous trailer block at the end of the commit message:

```text
Constraint: <external constraint that shaped the decision>
Rejected: <alternative> | <reason>
Confidence: high
Scope-risk: narrow
Directive: <future warning>
Tested: <verification run>
Not-tested: <known gap>
```

## Pull Requests

- All regular PRs target `develop`.
- The only normal PR into `main` is `develop -> main` release promotion or default-branch synchronization.
- PR title format is `type(scope): 中文摘要`.
- Link issues with `Closes #123`, `Fixes #123`, `Resolves #123`, or `Refs #123`.
- `develop -> main` synchronization must use a merge commit. Do not squash or rebase it.
- The `release` label is manually added only to legal release PRs.

Release paths:

```text
release/vX.X.X-alpha|beta|rc -> develop   # with release label
release/vX.X.X[-lts|-hotfix] -> develop   # without release label
develop -> main                           # with release label for stable/lts/hotfix publication
```

Release PR bodies must include:

```markdown
## 亮点
## 新增
## 修复
## 优化
## 破坏性变更
## 已知问题
```

## Cross-Platform Notes

- Windows: prefer PowerShell (`pwsh` or Windows PowerShell) for local helper scripts; install Git Flow with `winget install Kubis1982.GitFlow` or the Git extension package your environment uses; verify whether the command is `gitflow` or `git flow`; ensure `npm` global shims are on `PATH` for Lore.
- macOS: install Git Flow with `brew install git-flow`; the command is commonly `git flow`; use Bash or Zsh for `.sh` helpers.
- Linux: install Git Flow with the distro package manager (`apt`, `dnf`/`yum`, or `pacman`); the command is commonly `git flow`; use Bash helpers.
- Flutter desktop builds require platform-specific SDKs and signing material. Do not claim platform release verification unless that platform build actually ran.
- Do not commit machine-local paths, credentials, keystores, tokens, IDE settings, build output, or agent runtime state.

## Design System

- Single UI import: `import 'design/fluent_ui.dart'`
- Do not import `package:fluent_ui` directly outside the design facade.
- Use the project `FluentIcons` facade, not Material `Icons.*`.
- Avoid raw design tokens: no direct `Color(0xFF...)`, `Colors.*`, bare `EdgeInsets`, or bare `fontSize` in product UI.
- Prefer components from `design/components/`.
- Full rules live in `DESIGN.md`.

## Data And Privacy

- User data stays local: desktop `~/.sspu-aio/`, mobile app data directory.
- Academic credentials are stored in system secure storage (`flutter_secure_storage`), not in `app_state.json`.
- The app provides read-only queries only; do not add enrollment, payment, recharge, or other write actions.

## Project-Level Skills

Use these tracked skills when the task matches their scope:

| Skill | Purpose |
| --- | --- |
| `issue-writing` | Issue forms, labels, sensitive-data checks, and issue-to-branch mapping |
| `branch-checkout` | Git Flow branch creation before issue investigation or implementation |
| `git-flow` | Branch lifecycle, supported Git Flow command surfaces, manual branch classes, and config checks |
| `commit-messages` | Commit title rules and Lore trailer expectations |
| `lore-usage` | Lore query, commit, validation, and local status compatibility |
| `pr-writing` | PR target, template, label, release, and merge rules |

## Governance Scripts

- `scripts/ci/validate_github_governance.py` validates GitHub governance files, required project skills, branch naming rules, and helper script presence.
- `scripts/gitflow/check_config.ps1` / `scripts/gitflow/check_config.sh` validate local Git Flow configuration.
- `scripts/lore/status.ps1` / `scripts/lore/status.sh` provide a portable Lore status check.
- `scripts/release/render_release_notes.py` validates Release Notes sections.
- `scripts/release/generate_release_metadata.py` generates Release metadata.

## Common Pitfalls

- Do not use the branch prefix for commit type decisions: branch `bugfix/...` maps to PR/commit type `fix`.
- Windows directory rename issues often require deleting `build/windows` before rebuilding because CMake caches paths.
- Android signing uses `android/key.properties` plus a `.jks` locally and GitHub Secrets in CI.
- macOS signing and notarization require all signing/notary secrets; release CI must fail rather than silently producing unsigned assets.
- `pubspec.lock` is generated only by `flutter pub get`; do not hand-edit it.
- Issue templates apply labels automatically, but issues from non-contributors may still need maintainer triage.
- `needs-triage` is added only when an issue is opened; removing it manually is intentional.
