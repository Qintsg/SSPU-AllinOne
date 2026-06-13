---
name: commit-messages
description: Use when writing git commit messages in SSPU-AllinOne. Covers required title format, allowed types, branch-to-type mapping, Chinese summaries, issue references, and Lore trailers.
---

# Commit Messages

Use this format:

```text
type(scope): 中文摘要
```

The summary must contain Chinese characters. Scope is optional but recommended.

## Allowed Types

| Type | Use |
| --- | --- |
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Formatting without behavior change |
| `refactor` | Code restructuring |
| `test` | Tests |
| `chore` | Maintenance |
| `ci` | CI / workflow config |
| `build` | Build system |
| `perf` | Performance |
| `deps` | Dependencies |
| `release` | Release preparation metadata |

Bug-fix branches use `bugfix/<topic>`, but the commit type is still `fix`.

## Scope

Use a lowercase, short affected area:

```text
feat(wechat): 添加公众号订阅基础框架
fix(macos): 修复 Runner 构建路径错误
docs(readme): 更新构建说明
ci(actions): 修复 Scorecard 固定 SHA
deps(flutter): 升级 Flutter 工具链
```

## Lore Requirement

Agent-made commits should be created with Lore:

```bash
lore commit -i
```

Validate the new commit:

```bash
lore validate HEAD~1..HEAD
```

Use repository status helpers when local `lore status` is unavailable:

```powershell
pwsh ./scripts/lore/status.ps1
```

```bash
bash ./scripts/lore/status.sh
```

## Body And Trailers

Use the body for concise rationale. Put Lore trailers as the final contiguous block:

```text
Constraint: <external constraint>
Rejected: <alternative> | <reason>
Confidence: high
Scope-risk: narrow
Directive: <future warning>
Tested: <verification>
Not-tested: <gap>
```

## Issue References

Use these in the commit body or PR body:

- `Closes #123` / `Fixes #123` / `Resolves #123`: close on merge.
- `Refs #123`: reference without closing.

Prefer PR body references when the same branch contains multiple commits.
