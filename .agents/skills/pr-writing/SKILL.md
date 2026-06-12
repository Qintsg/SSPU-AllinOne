---
name: pr-writing
description: Use when creating or editing pull requests in SSPU-AllinOne. Covers PR title format, template, linking issues, and merge rules.
---

# Pull Requests

## Title

Format: `type(scope): 中文摘要`

Same as commit message format. Allowed types: feat/fix/docs/style/refactor/test/chore/ci/build/perf/deps/release

## Target Branch

- All regular PRs → `develop`
- Never target `main` directly (except develop→main sync)

## Link Issues

In PR body:

```
Closes #278    # Auto-close on merge to develop
Refs #123      # Reference only
```

## PR Template

Fill `.github/pull_request_template.md`:

- **变更说明**: What changed and why
- **关联 Issue**: `Closes #X` or `Refs #X`
- **变更类型**: Check applicable boxes
- **影响范围**: Check affected areas
- **验证记录**: `flutter analyze`, `flutter test`, platform builds
- **风险与回滚**: Risk level, rollback plan
- **检查清单**: No secrets, docs updated, etc.

## Before Submit

```bash
flutter analyze --no-fatal-infos
flutter test
dart format --set-exit-if-changed <changed-files>
```

## Auto-Labels

PR Metadata workflow auto-applies:

- Type label from title/branch (enhancement, bug, documentation, etc.)
- Priority from linked issue (P0-P3)
- Platform/module labels from linked issue
- `needs-issue` if no linked issue (exempt: docs/chore/deps/release)

## Merge Rules

- develop↔main: **merge commit only** (no squash/rebase)
- Regular PRs: squash or merge (maintainer preference)
- `release` label: manually added to release PRs only

## Checklist

- [ ] Title: `type(scope): 中文摘要`
- [ ] Target: `develop`
- [ ] Linked issue: `Closes #X` or `Refs #X`
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Docs updated if needed
- [ ] No secrets/credentials
