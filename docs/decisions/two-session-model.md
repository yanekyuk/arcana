---
title: "Two-Session Model"
type: decision
tags: [session, triage, orchestrator, worktree, finish]
created: 2026-03-26
updated: 2026-03-26
---

## Decision

Work is split across two separate Claude sessions:

1. **Main session** (project root) -- runs triage (`/run-triage`) to classify and set up work, then later runs finish (`/run-finish`) to review, merge, and clean up.
2. **Worktree session** (`.worktrees/<type>-<desc>`) -- runs start (`/run-start`) which dispatches the appropriate orchestrator agent to execute the work autonomously.

## Context

Claude Code sessions have limited context windows and token budgets. A single session attempting to triage, implement, review, and merge would exhaust its budget on complex tasks. Additionally, the main repository working tree must remain clean for concurrent work.

## Rationale

- **Token isolation** -- The orchestrator session consumes the bulk of tokens (TDD cycles, self-review, doc sync). Keeping triage and finish in a separate session preserves budget for those lightweight operations.
- **Working tree safety** -- The main session never leaves the project root. All implementation happens in an isolated worktree, preventing interference with the main branch or other ongoing work.
- **Clean lifecycle boundaries** -- Triage produces a handoff artifact. The orchestrator consumes it. Finish reviews the result. Each phase has clear entry and exit conditions.

## Constraints

- The main session must never `cd` into a worktree (per project convention).
- The worktree session must validate it is in a worktree before proceeding.
- The handoff artifact (`.claude/handoff.md`) is the sole contract between sessions.
