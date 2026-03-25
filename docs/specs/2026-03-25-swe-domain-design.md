# SWE Domain Design

Personal Claude Code plugin for automated software engineering workflows. Replaces superpowers with a token-efficient, orchestrator + micro-skills architecture.

---

## Overview

The SWE domain automates the full development lifecycle from triage to PR. It uses a two-session model:

1. **Triage session** — in the project root, explores code, classifies work, creates a worktree with a handoff artifact
2. **Worktree session** — user CDs into the worktree, affirms, and an orchestrator runs the appropriate pipeline autonomously to PR

### Architecture: Orchestrator + Micro-skills

- **Orchestrator agents** sequence micro-skills per work type (feat, fix, refactor, docs)
- **Micro-skills** are small, focused, reusable building blocks loaded on-demand
- **Knowledge system** provides a three-tier document hierarchy with clash detection

This approach minimizes token usage by only loading the skill needed at each step, unlike monolith skill sets that front-load everything.

---

## Component Inventory

### Micro-skills (10)

All skills are prefixed with `run-` and live in `skills/swe/`.

| Skill | Purpose |
|---|---|
| `run-triage` | Explore code, classify work type, create branch + worktree + handoff |
| `run-resume` | Entry point in worktree — reads handoff, dispatches orchestrator |
| `run-tdd` | Write failing test, implement until green, repeat |
| `run-self-review` | Diff changes against spec and domain knowledge, flag issues |
| `run-open-pr` | Commit, push, open PR with conventional title/body |
| `run-sync-docs` | Detect if CLAUDE.md or .claude/docs/ need updating, update them |
| `run-domain-knowledge` | Create/update domain knowledge docs, trigger clash-check |
| `run-design-decision` | Create/update design decision docs, check alignment up and down |
| `run-spec` | Create/update spec docs, check alignment with parents |
| `run-clash-check` | Scan docs tier(s) for contradictions, overlaps, misalignments |

### Orchestrator Agents (4)

Live in `agents/swe/`. Each sequences micro-skills for its work type.

**feat-orchestrator:**
1. Read handoff
2. Fetch relevant docs (domain, decisions, specs)
3. `run-spec` (draft if none exists)
4. `run-tdd`
5. `run-self-review`
6. `run-sync-docs`
7. `run-open-pr`

**fix-orchestrator:**
1. Read handoff
2. Fetch relevant docs
3. `run-tdd` (reproduce bug as failing test first)
4. `run-self-review`
5. `run-sync-docs`
6. `run-open-pr`

**refactor-orchestrator:**
1. Read handoff
2. Fetch relevant docs (primarily decisions)
3. Verify existing tests pass
4. Refactor incrementally, run tests after each change
5. `run-self-review`
6. `run-sync-docs`
7. `run-open-pr`

**docs-orchestrator:**
1. Read handoff
2. Fetch relevant docs from all tiers
3. Write/update documentation
4. `run-clash-check`
5. `run-sync-docs`
6. `run-open-pr`

---

## Triage Flow (Session 1)

Invoked via `/run-triage` in the project root.

1. User provides trigger (ticket, idea, bug report)
2. Explore related code — read files, grep patterns, check recent git history
3. Fetch relevant docs from `.claude/docs/` by scanning frontmatter tags
4. Propose work classification: `feat`, `fix`, `refactor`, or `docs`
5. **Human checkpoint:** user confirms or overrides classification
6. Create branch with conventional naming: `<type>/<short-description>` (e.g., `feat/user-auth`, `fix/null-pointer-cart`)
7. Create worktree at `./.worktrees/<type>-<short-description>` (dashes, not slashes — e.g., `.worktrees/fix-null-pointer-cart` for branch `fix/null-pointer-cart`)
8. Write handoff artifact to `.worktrees/<folder>/.claude/handoff.md`:
   - Trigger (original request, ticket ref)
   - Classification (feat/fix/refactor/docs)
   - Related files discovered
   - Relevant domain/decision/spec doc paths
   - Scope summary
9. Tell user: "Worktree ready. Run `cd ./.worktrees/<folder>` and start a new Claude session."

---

## Worktree Session (Session 2)

User enters worktree, starts new Claude session, invokes `/run-resume`.

1. Read `.claude/handoff.md`
2. Determine work type from classification field
3. Dispatch matching orchestrator agent
4. Orchestrator runs pipeline autonomously to PR — zero human checkpoints

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

### Cascade rules

- **Domain knowledge changed** → `run-clash-check` on decisions + specs
- **Design decision changed** → check alignment with domain (up), `run-clash-check` on specs (down)
- **Spec changed** → check alignment with decisions + domain (up)

### Relevance fetching

At task start, the orchestrator greps `.claude/docs/` frontmatter tags against work context (file paths, module names, keywords from handoff artifact). Matched docs are loaded into context.

### Clash detection

`run-clash-check` scans all docs in the targeted tier(s), reads frontmatter + content, and reports contradictions, overlaps, and misalignments. Uses LLM reasoning (not just keyword matching) to detect logical conflicts.

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

## Design Principles

- **Token-efficient:** Only load the skill needed at each step, not the whole toolkit
- **Composable:** Micro-skills are pipeline-agnostic building blocks
- **Two-session model:** Triage in project root, execution in worktree — clean context per session
- **TDD mandatory:** All code-changing pipelines (feat, fix, refactor) use test-driven development
- **Autopilot to PR:** Zero human checkpoints inside pipelines — the PR is the review gate
- **Knowledge integrity:** Three-tier hierarchy with bidirectional alignment checks and clash detection
