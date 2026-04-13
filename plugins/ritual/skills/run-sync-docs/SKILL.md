---
name: run-sync-docs
description: "Use after implementation to detect if docs/ need updating based on changes made — updates docs, triggers clash-check"
model: sonnet
effort: medium
user-invocable: false
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent
---

# Sync Docs

You are checking whether the implementation work introduced knowledge that should be captured in `docs/`.

## Prerequisites

**Directives:** If `docs/swe-config.json` exists, read `directives.documentation` from the config. These are soft guidelines that influence your documentation style, detail level, and terminology. Apply them when creating or updating docs. If the field is missing or empty, proceed without directives.

## Step 1: Understand what changed

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git diff $BASE...HEAD --stat
git diff $BASE...HEAD
```

## Step 2: Scan for implicit knowledge

Review the diff for:

1. **New domain rules** — business logic, validation rules, constraints that were implemented but not documented in `docs/domain/`
2. **Design decisions** — architectural choices, pattern selections, trade-offs that were made but not captured in `docs/decisions/`
3. **Spec gaps** — behavior that was implemented but differs from or extends existing specs in `docs/specs/`

## Step 3: Update docs

For each piece of implicit knowledge found:

- If a relevant doc exists, update it (add the new rule/decision/behavior)
- If no relevant doc exists, create one with proper frontmatter:

```yaml
---
title: "<descriptive title>"
type: <domain|decision|spec>
tags: [<lowercase, hyphen-separated, matching module/directory names>]
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---
```

## Step 4: Trigger clash-check

If any docs were created or updated, dispatch `run-clash-check` as a subagent (via the Agent tool) on the affected tiers. This is a depth-1 cascade — do NOT trigger further cascades from this invocation.

## Step 5: Check CLAUDE.md

Review changes for new conventions or patterns that might warrant `CLAUDE.md` updates. Do NOT modify `CLAUDE.md` directly. Instead, note any recommended changes — these will be included in the PR description for human review.

Report:
- Which docs were created/updated (if any)
- Any clash-check warnings
- Any recommended CLAUDE.md changes
