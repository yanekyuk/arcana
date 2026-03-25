# SWE Domain Design

Personal Claude Code plugin for automated software engineering workflows. Replaces superpowers with a token-efficient, orchestrator + micro-skills architecture.

---

## Overview

The SWE domain automates the full development lifecycle from triage to PR. It uses a two-session model:

1. **Triage session** — in the project root, explores code, classifies work, creates a worktree with a handoff artifact
2. **Worktree session** — user CDs into the worktree, affirms, and an orchestrator runs the appropriate pipeline autonomously to PR

### Architecture: Orchestrator + Micro-skills

- **Orchestrator agents** are prompt-based agent definitions that contain the full sequencing logic and inline instructions for each step. They do not invoke skills via slash commands — they carry the knowledge of each step in their own prompt, calling tools (Read, Write, Edit, Bash, Agent, etc.) directly.
- **Micro-skills** are user-invokable building blocks for standalone use outside of pipelines (e.g., `/run-tdd` during manual development). Within pipelines, the orchestrator agent embeds the equivalent logic.
- **Knowledge system** provides a three-tier document hierarchy with clash detection.

This approach minimizes token usage by only loading the skill needed at each step, unlike monolith skill sets that front-load everything.

---

## Component Inventory

### Micro-skills (10)

All skills are prefixed with `run-` and live in `skills/swe/`. Skills are divided into three categories:

**Dispatch skill** — bridges sessions, does not represent pipeline logic:

| Skill | Purpose |
|---|---|
| `run-triage` | Explore code, classify work type, create branch + worktree + handoff |
| `run-resume` | Entry point in worktree — reads handoff, dispatches matching orchestrator agent |

**Pipeline skills** — core steps used by orchestrator agents (logic is embedded in orchestrator prompts, skills exist for standalone user invocation):

| Skill | Purpose |
|---|---|
| `run-tdd` | Write failing test, implement until green, repeat |
| `run-self-review` | Diff changes against spec and domain knowledge, flag issues |
| `run-open-pr` | Commit, push, open PR (see [PR Convention](#pr-convention)) |
| `run-sync-docs` | Detect if `.claude/docs/` need updating, update them (see [Sync Docs Scope](#sync-docs-scope)) |
| `run-spec` | Create/update spec docs, check alignment with parents |

**Standalone skills** — user-invoked for knowledge management, not called by orchestrator pipelines directly:

| Skill | Purpose |
|---|---|
| `run-domain-knowledge` | Create/update domain knowledge docs, trigger `run-clash-check` |
| `run-design-decision` | Create/update design decision docs, check alignment up and down |
| `run-clash-check` | Scan docs tier(s) for contradictions, overlaps, misalignments |

### Orchestrator Agents (4)

Live in `agents/swe/`. Each is a self-contained agent prompt that carries the full sequencing logic for its pipeline. Orchestrators use tools directly (Read, Write, Edit, Bash, Grep, Agent, etc.) — they do not invoke slash-command skills.

All code-changing orchestrators (feat, fix, refactor) begin with a **discovery step** after reading the handoff: detect the project's test runner and build tools by checking `package.json` scripts, `Makefile`, `Cargo.toml`, `pyproject.toml`, etc. This is stored in working memory for the TDD and self-review steps. The docs-orchestrator skips discovery since it doesn't run tests.

**feat-orchestrator:**
1. Read handoff (`<worktree-root>/.claude/handoff.md`)
2. Discover project tooling (test runner, build command)
3. Fetch relevant docs (domain, decisions, specs) — see [Relevance Fetching](#relevance-fetching)
4. Draft spec if none exists (write to `.claude/docs/specs/`, check alignment with parent docs). Features need specs because they introduce new behavior.
5. TDD cycle: write failing tests → implement → green, repeat per unit of work
6. Self-review: diff changes against spec and domain knowledge, flag issues
7. Sync docs: detect if `.claude/docs/` need updating, update them
8. Open PR

**fix-orchestrator:**
1. Read handoff (`<worktree-root>/.claude/handoff.md`)
2. Discover project tooling
3. Fetch relevant docs
4. TDD cycle: write failing test that reproduces the bug → fix → green. Fixes don't draft new specs — the bug is a deviation from existing expected behavior.
5. Self-review
6. Sync docs
7. Open PR

**refactor-orchestrator:**
1. Read handoff (`<worktree-root>/.claude/handoff.md`)
2. Discover project tooling
3. Fetch relevant docs (primarily decisions)
4. TDD guard: run existing test suite, confirm all green before touching code. Refactors don't write new tests or draft specs — they preserve existing behavior under existing tests.
5. Refactor incrementally: make change → run tests → confirm green → repeat
6. Self-review: verify no behavior change, alignment with design decisions
7. Sync docs
8. Open PR

**docs-orchestrator:**
1. Read handoff (`<worktree-root>/.claude/handoff.md`)
2. Fetch relevant docs from all tiers
3. Write/update documentation
4. Clash check: scan affected tiers for contradictions
5. Sync docs: detect if other `.claude/docs/` entries need updating based on the documentation changes (e.g., a new domain doc may require a corresponding decision or spec update)
6. Open PR

---

## Triage Flow (Session 1)

Invoked via `/run-triage` in the project root.

1. User provides trigger (ticket, idea, bug report)
2. Explore related code — read files, grep patterns, check recent git history
3. Fetch relevant docs from `.claude/docs/` by scanning frontmatter tags
4. Propose work classification: `feat`, `fix`, `refactor`, or `docs`
5. **Human checkpoint:** user confirms or overrides classification
6. Create branch with conventional naming: `<type>/<short-description>` (e.g., `feat/user-auth`, `fix/null-pointer-cart`)
7. Create worktree for the branch created in step 6: `git worktree add .worktrees/<type>-<short-description> <branch>` (dashes not slashes, because slashes create nested directories — e.g., `.worktrees/fix-null-pointer-cart` for branch `fix/null-pointer-cart`)
8. Write handoff artifact to `.worktrees/<folder>/.claude/handoff.md`. This file is **committed to the branch** so it survives across sessions and appears in the PR for traceability:

```yaml
---
trigger: "Original request or ticket reference"
type: feat              # feat | fix | refactor | docs
branch: feat/user-auth
created: 2026-03-25
---

## Related Files
- src/auth/login.ts
- src/auth/session.ts

## Relevant Docs
- .claude/docs/domain/authentication-rules.md
- .claude/docs/specs/login-flow.md
(If none found: "None — knowledge base does not cover this area yet.")

## Scope
Summary of what needs to be done and why.
```

9. Create initial commit with the handoff artifact on the new branch
10. Tell user: "Worktree ready. Run `cd ./.worktrees/<folder>` and start a new Claude session."

---

## Worktree Session (Session 2)

User enters worktree, starts new Claude session, invokes `/run-resume`.

**Precondition:** Current working directory is the worktree root.

1. Validate this is a worktree (check for `.git` file, not `.git` directory)
2. Read `<cwd>/.claude/handoff.md`
3. Determine work type from `type` field
4. Dispatch matching orchestrator agent via the Agent tool. Mapping is direct: the `type` field maps to `agents/swe/<type>-orchestrator.md`.
5. Orchestrator runs pipeline autonomously to PR — zero human checkpoints

---

## Knowledge System

### Directory structure (per project, tracked in git)

```
.claude/docs/
├── domain/       # Business rules, invariants, constraints
├── decisions/    # Architectural choices, patterns, rationale
└── specs/        # Feature/fix behavior definitions
```

### Document format

Each doc is markdown with YAML frontmatter:

```yaml
---
title: "Order cancellation rules"
type: domain          # domain | decision | spec
tags: [orders, cancellation, billing]
created: 2026-03-25
updated: 2026-03-25
---

Content here.
```

**Tag convention:** Tags should use lowercase, hyphen-separated terms that match module/directory names in the codebase (e.g., `user-auth`, `billing`, `cart`). This ensures convergence between code structure and doc discoverability.

### Cascade rules

Cascades are triggered by the skill that writes the doc:

- `run-domain-knowledge` after writing → dispatches `run-clash-check` on decisions + specs
- `run-design-decision` after writing → checks alignment with domain (up), dispatches `run-clash-check` on specs (down)
- `run-spec` after writing → checks alignment with decisions + domain (up)
- `run-sync-docs` after writing any doc → dispatches `run-clash-check` on affected tiers

The writing skill is responsible for triggering the cascade. This is enforced in the skill prompt, not via external automation.

**Cascade depth limit:** Cascade depth is 1. A skill invoked as part of a cascade (e.g., `run-clash-check` dispatched by `run-sync-docs`) must not trigger further cascades. This prevents infinite loops.

### Relevance fetching

At task start, the orchestrator fetches relevant knowledge docs:

1. Extract keywords from the handoff artifact: file paths → module/directory names (e.g., `src/billing/cart.ts` → `billing`, `cart`), trigger text → nouns and domain terms. Exclude common non-domain path segments: `src`, `lib`, `utils`, `helpers`, `index`, `test`, `tests`, `__tests__`, `dist`, `build`.
2. Normalize keywords: lowercase, split on hyphens and camelCase boundaries (e.g., `userAuth` → `user`, `auth`)
3. Grep `.claude/docs/` frontmatter `tags` fields for normalized keyword matches
4. Rank by number of tag matches
5. Load top 5 matching docs (cap prevents token bloat). If more than 5 match, log skipped docs for transparency.
6. If zero docs match, proceed without — the knowledge base may not cover this area yet

### Clash detection

`run-clash-check` is dispatched as a subagent (via the Agent tool) to keep its token cost isolated from the main pipeline context:

1. Reads all docs in the targeted tier(s)
2. Uses LLM reasoning to detect logical contradictions, overlaps, and misalignments
3. Reports findings or passes clean
4. If clashes found: logs them as warnings in the pipeline output. The pipeline continues — clashes are informational, not blocking. The PR description includes any clash warnings so the human reviewer sees them.

---

## PR Convention

PRs follow Conventional Commits for the title and a structured body template:

**Title format:** `<type>: <short description>` (e.g., `feat: add user authentication`, `fix: null pointer in cart checkout`)

**Target branch:** PRs target the repository's default branch (typically `main`).

**Body template:**
```markdown
## Summary
<What changed and why, derived from handoff scope>

## Changes
<Bulleted list of key changes>

## Test Plan
<How this was tested — TDD cycle summary>

## Knowledge Warnings
<Any clash-check warnings, or "None">
```

---

## Sync Docs Scope

`run-sync-docs` is scoped to `.claude/docs/` only — it detects whether implementation work introduced implicit domain rules, design decisions, or spec changes that should be captured.

`CLAUDE.md` is **not** automatically updated by `run-sync-docs`. Changes to `CLAUDE.md` affect Claude's behavior for the entire project and require human review. If `run-sync-docs` detects that `CLAUDE.md` might need updating (e.g., new conventions established by the implementation), it adds a note to the PR description recommending specific `CLAUDE.md` changes for the human to review.

---

## Failure Handling

Pipelines are autopilot but not blind. Each failure mode has a defined behavior:

| Failure | Behavior |
|---|---|
| TDD: tests won't pass after 3 attempts per unit of work | Stop pipeline. Commit WIP. Open draft PR with `[WIP]` prefix and failure summary. |
| Self-review finds blocking issues | Attempt to fix. If fix fails after 1 retry, stop and open draft PR with issues listed. |
| Clash-check detects contradictions | Log warnings. Continue pipeline. Include clash warnings in PR description. |
| Open PR: push rejected or creation fails | Retry once. If still failing, print error and leave changes committed locally. |
| Branch/worktree already exists during triage | Inform user, offer to resume existing worktree or create with a suffix. |
| Refactor: existing tests fail before any changes | Stop pipeline. Inform user that the test suite is not green. Do not open a PR. |

**TDD retry scope:** The 3-attempt limit applies **per unit of work** (i.e., per test case being driven). A feature with 5 units of work gets 3 attempts each. If any single unit exhausts its attempts, the pipeline stops.

**Principle:** Never silently fail. Never lose work. When in doubt, commit what you have and open a draft PR so the human can pick up.

---

## File Layout in Plugin

```
skills/swe/
├── run-triage/SKILL.md
├── run-resume/SKILL.md
├── run-tdd/SKILL.md
├── run-self-review/SKILL.md
├── run-open-pr/SKILL.md
├── run-sync-docs/SKILL.md
├── run-domain-knowledge/SKILL.md
├── run-design-decision/SKILL.md
├── run-spec/SKILL.md
└── run-clash-check/SKILL.md

agents/swe/
├── feat-orchestrator.md
├── fix-orchestrator.md
├── refactor-orchestrator.md
└── docs-orchestrator.md
```

---

## Out of Scope

- **Worktree cleanup:** Stale worktrees in `.worktrees/` are not automatically cleaned up after PR merge. This may be addressed in a future iteration.
- **Schema versioning:** The handoff artifact and knowledge doc frontmatter formats are not versioned. Breaking changes to these formats require manual migration.

---

## Design Principles

- **Token-efficient:** Only load the skill needed at each step, not the whole toolkit
- **Composable:** Micro-skills are pipeline-agnostic building blocks for standalone use; orchestrators embed equivalent logic
- **Two-session model:** Triage in project root, execution in worktree — clean context per session
- **TDD mandatory:** All code-changing pipelines (feat, fix, refactor) use test-driven development. Refactor uses TDD as a guard (existing tests must stay green) rather than write-new-tests-first.
- **Autopilot to PR:** Zero human checkpoints inside pipelines — the PR is the review gate
- **Knowledge integrity:** Three-tier hierarchy with bidirectional alignment checks and clash detection. Cascade depth limited to 1.
- **Never lose work:** On failure, commit WIP and open draft PR rather than discarding progress
- **CLAUDE.md is sacred:** Never auto-modify — only recommend changes for human review
