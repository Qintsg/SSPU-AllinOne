---
name: git-flow
description: Use when initializing Git Flow, creating feature/bugfix/release/hotfix branches, or managing branch lifecycle in SSPU-AllinOne.
---

# Git Flow

Branch lifecycle management for SSPU-AllinOne.

## Prerequisites

```bash
# Check if installed
gitflow --version || echo "NOT INSTALLED"
```

**Install (ask user first):**
- Windows: `winget install Kubis1982.GitFlow`
- macOS: `brew install git-flow`
- Linux: `sudo apt-get install git-flow` (Debian) / `sudo yum install gitflow` (RHEL)

**Initialize (one-time per clone):**
```bash
gitflow init -d
```

## Branch Types

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

## Commands

```bash
# Start
gitflow feature start <name>
gitflow bugfix start <name>
gitflow release start <version>
gitflow hotfix start <version>

# Finish (merges back and deletes branch)
gitflow feature finish <name>
gitflow bugfix finish <name>
gitflow release finish <version>
gitflow hotfix finish <version>
```

## Naming Convention

Format: `[prefix/]<type>/<topic-kebab-case>`

- Use lowercase, hyphens (no spaces/Chinese)
- Optional personal prefix: `qintsg/feature/xxx`
- Release version: `X.X.X[-channel]` (channel: alpha/beta/rc/lts/hotfix)

**Examples:**
- `feature/wechat-subscription`
- `fix/macos-runner-config`
- `release/v1.0.0-alpha`
- `qintsg/fix/login-bug`
