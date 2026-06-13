---
name: issue-writing
description: Use when creating or editing GitHub issues in SSPU-AllinOne. Covers issue templates, required fields, labels, sensitive-data hygiene, acceptance criteria, and issue-to-Git-Flow branch mapping.
---

# Issue Writing

Use GitHub Issue Forms under `.github/ISSUE_TEMPLATE/`.

## Templates

| Template | Title prefix | Use when |
| --- | --- | --- |
| `bug_report.yml` | `[Bug]` | Crash, error, regression, wrong behavior |
| `feature_request.yml` | `[Feature]` | New feature or enhancement |
| `docs.yml` | `[Docs]` | Documentation issue |
| `tasks.yml` | `[Task]` | Clear engineering or governance task |
| `question.yml` | `[Question]` | Usage or clarification question |
| `release_request.yml` | `[Release]` | Release preparation |
| `info_site_request.yml` | `[Feature]` | New website data source |

## Required Content

- Priority: `P0`, `P1`, `P2`, or `P3`.
- Platform: Windows, macOS, Linux, Android, iOS, Web, or cross-platform.
- Affected module: frontend, services, storage, installer, CI, docs, release, governance, etc.
- Current behavior and expected behavior for bugs.
- Acceptance criteria for features/tasks.
- Verification hints when reproducible.

## Sensitive Data

Do not include passwords, tokens, cookies, keystores, private keys, real user identifiers, or screenshots that expose credentials. Redact logs before posting.

## Label Behavior

- Issue templates auto-apply type labels such as `bug`, `enhancement`, `documentation`, `task`, or `question`.
- `needs-triage` is applied once when the issue opens.
- Priority labels (`P0`-`P3`), platform labels, and module labels can be inherited by linked PRs.
- The `release` label is not auto-applied by issue templates.

## Issue-To-Branch Mapping

Use this mapping when moving from issue writing to implementation:

| Issue | Branch prefix | PR title type |
| --- | --- | --- |
| `[Bug]` | `bugfix/` | `fix` |
| `[Feature]` | `feature/` | `feat` |
| `[Docs]` | `docs/` | `docs` |
| `[Task]` CI/workflow | `ci/` | `ci` |
| `[Task]` dependencies | `deps/` | `deps` |
| `[Task]` refactor | `refactor/` | `refactor` |
| `[Task]` tests | `test/` | `test` |
| `[Task]` maintenance | `chore/` | `chore` |
| `[Release]` | `release/` | `release` |

Bug fixes use branch prefix `bugfix/`; do not create new `fix/` branches.

## Checklist

- Correct template selected.
- Priority, platform, and module fields are filled.
- Acceptance criteria are testable.
- Reproduction steps include environment and version where relevant.
- Sensitive data is redacted.
- Related issues or PRs are linked.
