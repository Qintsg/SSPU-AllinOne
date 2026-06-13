---
name: branch-checkout
description: Use when checking out a new branch to work on an issue in SSPU-AllinOne. Covers the issue-to-branch flow, Git Flow bugfix naming, manual branch classes, and ready-to-edit verification.
---

# Branch Checkout

Create a task branch before investigating or editing an issue.

## Flow

```text
Issue -> sync develop -> choose branch type -> create branch -> verify branch -> investigate/edit
```

## Sync develop

```bash
git status --short --branch
git checkout develop
git pull --ff-only origin develop
```

If unrelated local changes exist, do not discard them unless the user explicitly asks. Stash only when needed and safe.

## Choose Branch Type

| Issue or task | Branch prefix | Command |
| --- | --- | --- |
| `[Feature]` / enhancement | `feature/` | `<git-flow> feature start <name>` |
| `[Bug]` / failing behavior | `bugfix/` | `<git-flow> bugfix start <name>` |
| `[Docs]` | `docs/` | `git checkout -b docs/<name>` |
| CI / workflow / governance | `ci/` | `git checkout -b ci/<name>` |
| Dependency update | `deps/` | `git checkout -b deps/<name>` |
| Refactor | `refactor/` | `git checkout -b refactor/<name>` |
| Tests | `test/` | `git checkout -b test/<name>` |
| Maintenance task | `chore/` | `git checkout -b chore/<name>` |
| Release prep | `release/` | `<git-flow> release start vX.X.X[-channel]` |
| Emergency hotfix coordination | `hotfix/` | `<git-flow> hotfix start <name>` |

The branch prefix for bug fixes is `bugfix/`, not `fix/`. Commit and PR titles still use `fix(scope): 中文摘要`.

## Create The Branch

Examples:

```bash
# Issue #278: 全面配置并启用 Git Flow 工作流
<git-flow> feature start git-flow-setup

# Issue #287: Scorecard SHA 错误
<git-flow> bugfix start scorecard-243-sha

# Documentation task
git checkout -b docs/release-governance

# Workflow task
git checkout -b ci/github-actions-upgrade
```

Use a short kebab-case topic. Include the issue number only when it improves traceability.

`<git-flow>` means the command surface available on the machine: `gitflow` on this Windows checkout, or `git flow` on installations that expose Git Flow as a Git subcommand.

## Verify

```bash
git branch --show-current
git status --short --branch
```

The active branch must not be `develop` or `main`.

## After Checkout

1. Investigate and edit on the task branch.
2. Verify with targeted tests or governance scripts.
3. Commit with Lore.
4. Push with `git push -u origin <branch>`.
5. Create a PR targeting `develop`, except explicit `develop -> main` promotion.
