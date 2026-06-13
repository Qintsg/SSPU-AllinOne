---
name: pr-writing
description: Use when creating or editing pull requests in SSPU-AllinOne. Covers PR title format, target branch rules, issue links, templates, release labels, merge rules, and Git Flow branch naming.
---

# Pull Requests

Use this skill before creating or editing a PR.

## Title

Format:

```text
type(scope): 中文摘要
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`, `deps`, `release`.

Bug-fix branches are named `bugfix/<topic>`, but PR title type remains `fix`.

## Target Branch

- Regular PRs target `develop`.
- Documentation, CI, dependencies, refactors, chores, and bug fixes also target `develop`.
- The normal PR into `main` is `develop -> main` release promotion or default-branch synchronization.
- Do not open feature or bugfix branches directly into `main`.

## Branch Naming Check

Expected source branches:

```text
feature/<topic>
bugfix/<topic>
docs/<topic>
chore/<topic>
refactor/<topic>
test/<topic>
ci/<topic>
deps/<topic>
release/vX.X.X[-channel]
hotfix/<topic-or-version>
```

Optional personal prefixes such as `qintsg/feature/<topic>` are allowed.

## Link Issues

Use the PR body:

```text
Closes #278
Refs #123
```

Use closing keywords only when merging the PR should close the issue.

## Template

Use `.github/pull_request_template.md` for regular PRs. Fill:

- 变更说明
- 关联 Issue
- 变更类型
- 影响范围
- 验证记录
- 风险与回滚
- 检查清单

Use `.github/PULL_REQUEST_TEMPLATE/release.md` for Release PRs.

## Release Labels

Only manually add `release` to legal Release PRs:

```text
release/vX.X.X-alpha|beta|rc -> develop   # with release label
develop -> main                           # with release label for stable/lts/hotfix
```

Do not add `release` to the first `release/vX.X.X -> develop` stable/lts/hotfix prep PR.

## Verification Before PR

Run checks that match the changed surface:

```bash
dart format --set-exit-if-changed <changed-dart-files>
flutter analyze --no-fatal-infos
flutter test
python scripts/ci/validate_github_governance.py
lore validate origin/develop..HEAD
```

If a check cannot run on the current platform, state the reason and the next-best validation.

## Merge Rules

- `develop -> main`: merge commit only; no squash or rebase.
- Regular PRs: maintainer preference unless a release/sync rule says otherwise.
- Do not directly push to `develop` or `main`.
