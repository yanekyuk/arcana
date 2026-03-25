---
title: "Handoff Artifact Pattern"
type: decision
tags: [handoff, triage, orchestrator, contract, artifact]
created: 2026-03-26
updated: 2026-03-26
---

## Decision

A structured markdown file at `.claude/handoff.md` serves as the contract between the triage skill and the orchestrator agent.

## Context

The triage skill runs in one session and the orchestrator runs in another. There is no shared memory or state between sessions. A persistent, file-based contract is needed to transfer context.

## Rationale

- **Structured format** -- YAML frontmatter carries machine-readable fields (`trigger`, `type`, `branch`, `created`, `version-bump`). Markdown body carries human-readable sections (Related Files, Relevant Docs, Scope).
- **Single source of truth** -- The orchestrator reads only this file to understand what to build. It does not re-explore the codebase from scratch.
- **Auditable** -- The handoff is committed to git, so the exact instructions given to the orchestrator are part of the branch history.
- **Disposable** -- The handoff is removed (`git rm`) before the PR is opened, so it never appears in the final diff against main.

## Lifecycle

1. **Created by triage** -- `/run-triage` writes the handoff into the worktree at `.worktrees/<folder>/.claude/handoff.md` and commits it.
2. **Consumed by resume** -- `/run-resume` reads the handoff and dispatches the matching orchestrator based on the `type` field.
3. **Removed before PR** -- The orchestrator runs `git rm .claude/handoff.md` as its second-to-last step, ensuring the artifact does not appear in the PR.

## Frontmatter Schema

```yaml
---
trigger: "<original user request>"
type: <feat|fix|refactor|docs>
branch: <type>/<short-description>
created: <YYYY-MM-DD>
version-bump: <major|minor|patch|none>  # optional override
---
```

## Body Sections

- **Related Files** -- Files discovered during triage exploration
- **Relevant Docs** -- Matched knowledge docs from `docs/`, or "None" if the knowledge base does not cover the area
- **Scope** -- Summary of what needs to be done and why
