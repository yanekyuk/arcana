---
title: "Skill Contracts"
type: spec
tags: [skill, contract, triage, resume, finish, tdd, self-review, open-pr, sync-docs, clash-check, domain-knowledge, design-decision, spec, setup, arch-check]
created: 2026-03-26
updated: 2026-03-26
---

## Behavior

Each skill is a composable building block with defined inputs, outputs, and tool requirements. Skills are invoked via slash commands or dispatched by orchestrator agents.

## Configuration Skills

### run-setup

- **Input:** Project files for auto-detection; user responses for overrides and selections
- **Output:** `docs/swe-config.json` written to the target project
- **Tools:** Read, Write, Edit, Bash, Grep, Glob
- **Invocation:** User-invoked in the target project (interactive -- asks questions and waits for responses)
- **Side effects:** Creates `docs/swe-config.json` with tech stack, architecture rules, integration toggles, and custom directives
- **Note:** This is the only interactive skill -- all others are non-interactive when dispatched by orchestrators

### run-arch-check

- **Input:** `docs/swe-config.json` architecture rules, diff against base branch
- **Output:** Pass/fail report with violation details
- **Tools:** Read, Bash, Grep, Glob
- **Invocation:** User-invoked or dispatched by orchestrators after self-review (or after sync-docs for docs orchestrator)
- **Constraint:** Hard gate -- violations must be fixed before PR creation. When dispatched by an orchestrator, a fail result triggers fix attempts; unresolved violations result in a draft PR.

## Lifecycle Skills

### run-triage

- **Input:** User-provided ticket, idea, or bug report
- **Output:** Branch, worktree, committed handoff artifact (`.claude/handoff.md`)
- **Tools:** Read, Grep, Glob, Bash, Write, Agent
- **Invocation:** User-invoked or model-invoked in main session
- **Side effects:** Creates git branch, creates worktree directory, commits handoff

### run-resume

- **Input:** Presence of `.claude/handoff.md` in current worktree
- **Output:** Dispatches orchestrator agent (no direct output of its own)
- **Tools:** Read, Bash, Agent
- **Invocation:** User-invoked in worktree session
- **Side effects:** Spawns orchestrator agent via Agent tool

### run-finish

- **Input:** One or more open PRs on the repository
- **Output:** Merged PR, cleaned-up worktree and branches
- **Tools:** Read, Bash, Grep
- **Invocation:** User-invoked in main session
- **Side effects:** Merges PR, deletes remote/local branches, removes worktree, pulls main

## Development Skills

### run-tdd

- **Input:** Knowledge of test runner (auto-detected or from orchestrator context)
- **Output:** Committed test + implementation pairs
- **Tools:** Read, Write, Edit, Bash, Grep, Glob
- **Invocation:** User-invoked standalone or dispatched by orchestrators
- **Cycle:** Write failing test, implement minimally, refactor, commit
- **Failure:** 3 attempts per unit, then WIP commit and stop

### run-self-review

- **Input:** Diff against base branch, handoff artifact, referenced specs/domain docs
- **Output:** Review report (pass or list of issues with classifications)
- **Tools:** Read, Bash, Grep, Glob
- **Invocation:** User-invoked or dispatched by orchestrators
- **Checks:** Scope compliance, spec alignment, domain rule compliance, test coverage, code quality

### run-open-pr

- **Input:** Committed changes on a feature branch; optionally handoff artifact (falls back to git log/diff if missing)
- **Output:** PR URL
- **Tools:** Read, Bash, Grep
- **Invocation:** User-invoked or dispatched by orchestrators
- **Side effects:** Stages remaining changes, pushes branch, creates PR via `gh pr create`

## Knowledge Management Skills

### run-sync-docs

- **Input:** Diff against base branch
- **Output:** Created/updated docs, clash-check warnings, CLAUDE.md suggestions
- **Tools:** Read, Write, Edit, Bash, Grep, Glob, Agent
- **Invocation:** User-invoked or dispatched by orchestrators
- **Side effects:** Creates/updates docs in `docs/`, dispatches clash-check subagent
- **Cascade:** Depth-1 only (dispatches clash-check but clash-check does not cascade further)

### run-clash-check

- **Input:** Target tiers to scan (one or more of: `docs/domain/`, `docs/decisions/`, `docs/specs/`)
- **Output:** Report of clashes (contradictions, overlaps, ambiguity, alignment violations) or clean pass
- **Tools:** Read, Bash, Grep, Glob
- **Context:** Runs in `fork` context (isolated subagent with own token budget)
- **Invocation:** Dispatched by other skills/orchestrators, not typically user-invoked
- **Constraint:** Must not trigger further cascades (depth-1 limit)

### run-domain-knowledge

- **Input:** Topic from context or user request
- **Output:** Created/updated domain doc, clash-check report
- **Tools:** Read, Write, Edit, Bash, Grep, Glob, Agent
- **Invocation:** User-invoked or dispatched by orchestrators
- **Side effects:** Writes to `docs/domain/`, dispatches clash-check on decisions and specs
- **Cascade:** Downward to both decisions and specs tiers

### run-design-decision

- **Input:** Topic from context or user request
- **Output:** Created/updated decision doc, alignment report, clash-check report
- **Tools:** Read, Write, Edit, Bash, Grep, Glob, Agent
- **Invocation:** User-invoked or dispatched by orchestrators
- **Side effects:** Writes to `docs/decisions/`, dispatches clash-check on specs
- **Upward check:** Verifies alignment with `docs/domain/` before writing
- **Cascade:** Downward to specs tier only

### run-spec

- **Input:** Topic from context, handoff artifact, or user request
- **Output:** Created/updated spec doc
- **Tools:** Read, Write, Edit, Bash, Grep, Glob, Agent
- **Invocation:** User-invoked or dispatched by orchestrators
- **Side effects:** Writes to `docs/specs/`
- **Upward check:** Verifies alignment with both `docs/domain/` and `docs/decisions/`
- **Cascade:** None (specs are leaf-level)
