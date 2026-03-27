---
title: "Skill Contracts"
type: spec
tags: [skill, contract, triage, start, finish, tdd, self-review, open-pr, sync-docs, clash-check, domain-knowledge, design-decision, spec, setup, arch-check, create-triage]
created: 2026-03-26
updated: 2026-03-27
---

## Behavior

Each skill is a composable building block with defined inputs, outputs, and tool requirements. Skills are invoked via slash commands or dispatched by orchestrator agents.

### Directive Groups

Skills that consume directives declare a `directive group` mapping. The group determines which key from `directives` in `docs/swe-config.json` they read:

| Group | Skills |
|---|---|
| `implementation` | run-tdd |
| `review` | run-self-review |
| `documentation` | run-sync-docs, run-spec, run-domain-knowledge, run-design-decision |
| `delivery` | run-open-pr, run-finish |
| `triage` | run-triage |

Skills not listed (run-setup, run-start, run-arch-check, run-clash-check) do not consume directives.

## Configuration Skills

### run-setup

- **Input:** Project files for auto-detection; user responses for overrides and selections
- **Output:** `docs/swe-config.json` written to the target project
- **Tools:** Read, Write, Edit, Bash, Grep, Glob
- **Invocation:** User-invoked or model-invoked in the target project (interactive -- asks questions and waits for responses)
- **Side effects:** Creates `docs/swe-config.json` with tech stack, architecture rules, integration toggles, and categorized directives (per skill group: implementation, review, documentation, delivery, triage)
- **Note:** This is the only interactive skill -- all others are non-interactive when dispatched by orchestrators

### run-arch-check

- **Input:** `docs/swe-config.json` architecture rules, diff against base branch
- **Output:** Pass/fail report with violation details
- **Tools:** Read, Bash, Grep, Glob
- **Invocation:** Model-invoked or dispatched by orchestrators after self-review (or after sync-docs for docs orchestrator)
- **Constraint:** Hard gate -- violations must be fixed before PR creation. When dispatched by an orchestrator, a fail result triggers fix attempts; unresolved violations result in a draft PR.

## Lifecycle Skills

### run-triage

- **Input:** User-provided ticket, idea, or bug report
- **Output:** Branch, worktree, committed handoff artifact (`.claude/handoff.md`)
- **Tools:** Read, Grep, Glob, Bash, Write, Agent
- **Invocation:** User-invoked or model-invoked in main session
- **Directive group:** `triage`
- **Side effects:** Creates git branch, creates worktree directory, commits handoff
- **Integration behavior:**
  - `githubIssues`: searches GitHub Issues via `gh issue list --search` and includes matches in handoff "Related Issues" section
  - `linear`: searches Linear via MCP tools and includes matches in handoff "Related Issues" section. Graceful degradation: if Linear MCP is unavailable, logs warning and continues. If no issue number provided, searches by trigger keywords. Stores matched issue ID in `linear-issue` frontmatter field.

### run-create-triage

- **Input:** User-provided issue type (bug/feature), title, and description
- **Output:** Created issue reference, handoff to run-triage
- **Tools:** Read, Bash, Write
- **Invocation:** User-invoked in main session
- **Side effects:** Creates an issue in the selected backend (GitHub Issues or Linear)
- **Integration behavior:**
  - `githubIssues`: creates via `gh issue create` with bug/enhancement labels
  - `linear`: creates via `mcp__linear__createIssue`. Falls back to GitHub Issues if Linear MCP unavailable and `githubIssues` is enabled.
  - If both enabled, asks user which backend to use
  - If neither enabled, warns and exits
- **Handoff:** After issue creation, instructs user to run `/run-triage` with the created issue

### run-start

- **Input:** Presence of `.claude/handoff.md` in current worktree
- **Output:** Dispatches orchestrator agent (no direct output of its own)
- **Tools:** Read, Bash, Agent
- **Invocation:** User-invoked or model-invoked in worktree session
- **Side effects:** Spawns orchestrator agent via Agent tool

### run-finish

- **Input:** One or more open PRs on the repository
- **Output:** Merged PR, cleaned-up worktree and branches
- **Tools:** Read, Bash, Grep
- **Invocation:** User-invoked or model-invoked in main session
- **Directive group:** `delivery`
- **Side effects:** Merges PR, deletes remote/local branches, removes worktree, pulls main
- **Integration behavior:**
  - `coderabbit`: checks CodeRabbit review status via `gh pr reviews` before delivering verdict. Warns if review is pending, includes CodeRabbit comments if changes requested.
  - `linear`: after successful merge, marks linked Linear issue as "Done" and posts a comment with the PR URL. Graceful degradation on MCP failure.

## Development Skills

### run-tdd

- **Input:** Test command from `docs/swe-config.json` (`stack.test`) or user input when standalone
- **Output:** Committed test + implementation pairs
- **Tools:** Read, Write, Edit, Bash, Grep, Glob
- **Invocation:** Model-invoked or dispatched by orchestrators
- **Directive group:** `implementation`
- **Cycle:** Write failing test, implement minimally, refactor, commit
- **Failure:** 3 attempts per unit, then WIP commit and stop

### run-self-review

- **Input:** Diff against base branch, handoff artifact, referenced specs/domain docs
- **Output:** Review report (pass or list of issues with classifications)
- **Tools:** Read, Bash, Grep, Glob
- **Invocation:** Model-invoked or dispatched by orchestrators
- **Directive group:** `review`
- **Checks:** Scope compliance, spec alignment, domain rule compliance, test coverage, code quality

### run-open-pr

- **Input:** Committed changes on a feature branch; optionally handoff artifact (falls back to git log/diff if missing)
- **Output:** PR URL
- **Tools:** Read, Bash, Grep
- **Invocation:** Model-invoked or dispatched by orchestrators
- **Directive group:** `delivery`
- **Side effects:** Stages remaining changes, pushes branch, creates PR via `gh pr create`
- **Integration behavior:**
  - `githubIssues`: adds `Closes #N` lines to PR body for related GitHub issues from handoff
  - `linear`: adds Linear issue references to PR body from handoff
  - `coderabbit`: adds a "CodeRabbit review requested" note to PR body

## Knowledge Management Skills

### run-sync-docs

- **Input:** Diff against base branch
- **Output:** Created/updated docs, clash-check warnings, CLAUDE.md suggestions
- **Tools:** Read, Write, Edit, Bash, Grep, Glob, Agent
- **Invocation:** Model-invoked or dispatched by orchestrators
- **Directive group:** `documentation`
- **Side effects:** Creates/updates docs in `docs/`, dispatches clash-check subagent
- **Cascade:** Depth-1 only (dispatches clash-check but clash-check does not cascade further)

### run-clash-check

- **Input:** Target tiers to scan (one or more of: `docs/domain/`, `docs/decisions/`, `docs/specs/`)
- **Output:** Report of clashes (contradictions, overlaps, ambiguity, alignment violations) or clean pass
- **Tools:** Read, Bash, Grep, Glob
- **Context:** Runs in `fork` context (isolated subagent with own token budget)
- **Invocation:** Model-invoked or dispatched by other skills/orchestrators
- **Constraint:** Must not trigger further cascades (depth-1 limit)

### run-domain-knowledge

- **Input:** Topic from context or user request
- **Output:** Created/updated domain doc, clash-check report
- **Tools:** Read, Write, Edit, Bash, Grep, Glob, Agent
- **Invocation:** Model-invoked or dispatched by orchestrators
- **Directive group:** `documentation`
- **Side effects:** Writes to `docs/domain/`, dispatches clash-check on decisions and specs
- **Cascade:** Downward to both decisions and specs tiers

### run-design-decision

- **Input:** Topic from context or user request
- **Output:** Created/updated decision doc, alignment report, clash-check report
- **Tools:** Read, Write, Edit, Bash, Grep, Glob, Agent
- **Invocation:** Model-invoked or dispatched by orchestrators
- **Directive group:** `documentation`
- **Side effects:** Writes to `docs/decisions/`, dispatches clash-check on specs
- **Upward check:** Verifies alignment with `docs/domain/` before writing
- **Cascade:** Downward to specs tier only

### run-spec

- **Input:** Topic from context, handoff artifact, or user request
- **Output:** Created/updated spec doc
- **Tools:** Read, Write, Edit, Bash, Grep, Glob, Agent
- **Invocation:** Model-invoked or dispatched by orchestrators
- **Directive group:** `documentation`
- **Side effects:** Writes to `docs/specs/`
- **Upward check:** Verifies alignment with both `docs/domain/` and `docs/decisions/`
- **Cascade:** None (specs are leaf-level)
