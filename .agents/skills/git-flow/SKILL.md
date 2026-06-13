---
name: git-flow
description: Use when initializing or checking Git Flow, creating feature/bugfix/release/hotfix branches, or managing branch lifecycle in SSPU-AllinOne. Covers gitflow vs git flow command detection, branch targets, manual branch classes, and cross-platform setup.
---

# Git Flow

Use this skill for SSPU-AllinOne branch lifecycle work.

## Source Of Truth

- Command surface: use whichever exists locally, `gitflow` or `git flow`.
- Production branch: `main`
- Development branch: `develop`
- Feature prefix: `feature/`
- Bugfix prefix: `bugfix/`
- Release prefix: `release/`
- Hotfix prefix: `hotfix/`
- Support prefix: `support/`
- Version tag prefix: `v`

Do not replace the Bugfix branch prefix with `fix/`. The branch prefix is `bugfix/`; the commit and PR type remains `fix(scope): 中文摘要`.

## Check Setup

Try both command surfaces and use the one that works in the current shell:

```bash
gitflow --version
git flow version
git config --get-regexp '^gitflow\.'
```

Use the repo helper when available:

```powershell
pwsh ./scripts/gitflow/check_config.ps1
```

```bash
bash ./scripts/gitflow/check_config.sh
```

Initialize only on a fresh clone or a clone without Git Flow config:

```bash
<git-flow> init -d
```

## Install Git Flow

- Windows: `winget install Kubis1982.GitFlow` commonly provides `gitflow`; some Git extension installs provide `git flow`.
- macOS: `brew install git-flow` commonly provides `git flow`.
- Debian / Ubuntu: `sudo apt-get install git-flow`; command surface depends on package/version.
- RHEL / CentOS / Fedora: use the distro package (`gitflow` / `git-flow`) or the approved package source.
- Arch Linux: `sudo pacman -S gitflow-avh` or the approved package; command surface depends on package/version.

After installation, restart the terminal if neither command surface is found.

## Branch Targets

| Work | Branch | Target |
| --- | --- | --- |
| Feature | `feature/<topic>` | `develop` |
| Bug fix | `bugfix/<topic>` | `develop` |
| Docs | `docs/<topic>` | `develop` |
| Chore | `chore/<topic>` | `develop` |
| Refactor | `refactor/<topic>` | `develop` |
| Test | `test/<topic>` | `develop` |
| CI / governance | `ci/<topic>` | `develop` |
| Dependencies | `deps/<topic>` | `develop` |
| Pre-release | `release/vX.X.X-alpha|beta|rc` | `develop` |
| Stable / lts / hotfix release prep | `release/vX.X.X[-lts|-hotfix]` | `develop`, then `develop -> main` |
| Emergency integration | `hotfix/<topic-or-version>` | `develop`; publish through the release flow |

Except for `develop -> main` release promotion or default-branch sync, PRs target `develop`.

## Supported Git Flow Commands

Use these when the local Git Flow tool supports the branch class. Replace `<git-flow>` with `gitflow` or `git flow`:

```bash
git checkout develop
git pull --ff-only origin develop
<git-flow> feature start <topic-kebab-case>
<git-flow> bugfix start <topic-kebab-case>
<git-flow> release start vX.X.X[-channel]
<git-flow> hotfix start <topic-or-version>
```

Finish commands merge locally and delete branches. Prefer PR-based finishing unless the user explicitly asks for local Git Flow finish:

```bash
<git-flow> feature finish <name>
<git-flow> bugfix finish <name>
<git-flow> release finish <version>
<git-flow> hotfix finish <name>
```

## Manual Branch Classes

The installed Git Flow command does not provide `docs start`, `chore start`, `ci start`, or similar subcommands. Create those branches manually:

```bash
git checkout develop
git pull --ff-only origin develop
git checkout -b docs/<topic-kebab-case>
git checkout -b chore/<topic-kebab-case>
git checkout -b refactor/<topic-kebab-case>
git checkout -b test/<topic-kebab-case>
git checkout -b ci/<topic-kebab-case>
git checkout -b deps/<topic-kebab-case>
```

## Naming Rules

- Format: `[personal-prefix/]<type>/<topic-kebab-case>`
- Use lowercase ASCII and hyphens for the topic.
- Avoid spaces, Chinese characters, issue-title fragments without meaning, and stale prefixes.
- Optional personal prefix is allowed, for example `qintsg/feature/wechat-subscription`.
- Examples: `feature/wechat-subscription`, `bugfix/scorecard-243-sha`, `docs/release-governance`, `ci/github-actions-upgrade`, `deps/flutter-upgrade`.

## Verification Before Handoff

```bash
git status --short --branch
git branch --show-current
```

Confirm the branch is not `develop` or `main`, has the expected prefix, and targets `develop` unless it is the explicit `develop -> main` promotion.
