---
name: branch-checkout
description: Use when checking out a new branch to work on an issue in SSPU-AllinOne. Covers the full flow from issue to ready-to-commit branch.
---

# Branch Checkout

Create a branch for an issue, ready for development.

## Flow

```
Issue → git checkout develop → git pull → gitflow <type> start <name> → ready to code
```

## Steps

### 1. Sync develop

```bash
git checkout develop
git pull origin develop
```

### 2. Determine Branch Type

From issue labels/title:

| Issue Type | Branch Type | Command |
|------------|-------------|---------|
| `[Feature]` | feature | `gitflow feature start <name>` |
| `[Bug]` | fix | `gitflow bugfix start <name>` |
| `[Docs]` | docs | `gitflow docs start <name>` |
| `[Task]` (CI) | ci | `gitflow ci start <name>` |
| `[Task]` (other) | chore | `gitflow chore start <name>` |

### 3. Name the Branch

From issue title/number. Use kebab-case:

```bash
# Issue #278: "全面配置并启用git flow工作流"
gitflow feature start git-flow-setup

# Issue #123: "修复 macOS 登录崩溃"
gitflow bugfix start macos-login-crash
```

### 4. Verify

```bash
git branch  # Should show new branch with * prefix
git status  # Should be clean, on new branch
```

## Rules

- Always branch from `develop` (never `main`)
- Use kebab-case for branch names
- Optional personal prefix: `qintsg/feature/xxx`
- Do NOT push to `develop` or `main` directly

## After Branch

1. Make changes
2. Commit with `type(scope): 中文摘要`
3. Push: `git push -u origin <branch>`
4. Create PR targeting `develop`
