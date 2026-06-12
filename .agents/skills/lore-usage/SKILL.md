---
name: lore-usage
description: Use when recording architectural decisions, querying decision context, or creating Lore-enriched commits in SSPU-AllinOne.
---

# Lore Usage

Lore Protocol records structured decision context in git commits.

## Prerequisites

```bash
# Check if installed
lore --version || echo "NOT INSTALLED"

# Install (ask user first)
npm install -g lore-protocol

# Initialize in repo (one-time)
lore init
```

## Query Decisions

```bash
# Full context for a file
lore context <file>

# Why a specific line exists
lore why <file>:<line>

# Active constraints
lore constraints <file>

# Rejected alternatives
lore rejected <file>

# Forward-looking directives
lore directives <file>

# Search all lore
lore search --text "keyword"
```

## Create Lore-Enriched Commit

### Interactive Mode
```bash
lore commit -i
```

### JSON Mode (for AI agents)
```bash
echo '{
  "intent": "fix: handle null user in auth middleware",
  "trailers": {
    "Constraint": ["must not throw -- return 401 instead"],
    "Confidence": "high"
  }
}' | lore commit
```

## Trailers Reference

| Trailer | Cardinality | Values | Purpose |
|---------|-------------|--------|---------|
| `Lore-id` | 1 | 8-char hex | Unique atom ID (auto) |
| `Constraint` | 0..n | free text | Hard requirements |
| `Rejected` | 0..n | alt \| reason | Rejected approaches |
| `Confidence` | 0..1 | low/medium/high | Author confidence |
| `Scope-risk` | 0..1 | narrow/moderate/wide | Blast radius |
| `Reversibility` | 0..1 | clean/migration-needed/irreversible | Undo difficulty |
| `Directive` | 0..n | free text | Future maintainer instructions |
| `Tested` | 0..n | free text | What was verified |
| `Not-tested` | 0..n | free text | Known gaps |

## Health Check

```bash
lore doctor
lore validate
```
