---
name: issue-writing
description: Use when creating or editing GitHub issues in SSPU-AllinOne. Covers issue templates, required fields, and labeling rules.
---

# Issue Writing

Create issues using GitHub Issue Forms at `.github/ISSUE_TEMPLATE/`.

## Templates

| Template | Title Prefix | Use When |
|----------|-------------|----------|
| `bug_report.yml` | `[Bug]` | Crashes, errors, unexpected behavior |
| `feature_request.yml` | `[Feature]` | New features, enhancements |
| `docs.yml` | `[Docs]` | Documentation issues |
| `tasks.yml` | `[Task]` | Clear development tasks |
| `question.yml` | `[Question]` | Usage questions |
| `release_request.yml` | `[Release]` | Release preparation |
| `info_site_request.yml` | `[Feature]` | New website data sources |

## Key Fields

**Priority (required):**
- P0: Blocking / critical
- P1: High priority
- P2: Medium (default)
- P3: Low

**Platforms (multi-select):** Windows, macOS, Linux, Android, iOS, Web

**Affected modules (multi-select):** Frontend, Services, Storage, Installer, CI, Docs, etc.

## Auto-Labeling

- Issue templates auto-apply labels (`bug`, `enhancement`, `documentation`, `task`, `question`)
- `needs-triage` applied once on open; not re-applied if manually removed
- Priority labels (P0-P3) inherited from issue to linked PR

## Checklist

- [ ] Correct template selected
- [ ] Priority set
- [ ] Platforms specified
- [ ] Affected modules specified
- [ ] No sensitive data (passwords, tokens, cookies)
- [ ] Related issues linked if applicable
