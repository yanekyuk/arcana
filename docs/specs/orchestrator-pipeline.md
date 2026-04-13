---
title: "Orchestrator Pipeline"
type: spec
tags: [orchestrator, pipeline, feat, fix, refactor, docs, agent, config, arch-check, setup, knowledge-alignment]
created: 2026-03-26
updated: 2026-03-30
---

## Behavior

All four orchestrators share a common pipeline structure with type-specific variations. This spec documents the shared skeleton and per-type differences.

## Shared Pipeline Structure

Every orchestrator executes these phases in order:

| Phase | Step | Description |
|---|---|---|
| Setup | Initialize progress tracking | Create all pipeline tasks via TaskCreate. Result reporting mandate: when marking any task `completed`, update its `description` with what happened. |
| Setup | Read handoff | Parse `docs/handoffs/<folder>.md` frontmatter and body |
| Setup | Load project config | Read `docs/ritual-config.json` -- abort if missing |
| Context | Fetch docs | Grep `docs/` for tag matches, read top 5 |
| Context | Knowledge alignment check | Validate planned work against knowledge base -- pause for brainstorming via `AskUserQuestion` on conflict (skipped by docs) |
| Work | Type-specific implementation | See per-type sections below. **When `integrations.context7` is true**, Context7 MCP tools are available for library doc lookups. |
| Quality | Self-review | Diff against main, check scope/spec/domain/tests (skipped by docs) |
| Quality | Arch check | Validate architecture rules against diff -- hard gate (after sync-docs for docs) |
| Knowledge | Sync docs | Detect implicit knowledge, update `docs/`, clash-check. **Gated on `integrations.autoDocs`** -- skipped when false. |
| Cleanup | Remove handoff | `git rm docs/handoffs/<folder>.md` |
| Delivery | Open PR | Push, create PR via `gh pr create` |

## Config Gate

All orchestrators require `docs/ritual-config.json` to exist. This file is created by the `/run-setup` skill and contains:

- **`stack.*`** -- Tech stack configuration (language, runtime, test command, lint/format/typecheck commands). Replaces dynamic tooling discovery.
- **`architecture.rules`** -- Flat list of architecture rules enforced by `run-arch-check` as a hard gate.
- **`directives`** -- Categorized soft guidance object keyed by skill group (`implementation`, `review`, `documentation`, `delivery`, `triage`). Each group is an array of strings. Orchestrators read the relevant groups and pass them to dispatched skills.
- **`integrations`** -- Integration toggles (CodeRabbit, Linear, GitHub Issues, auto-docs, Context7). These flags gate specific pipeline behaviors:
  - `autoDocs`: gates the sync-docs phase (skipped when false)
  - `context7`: enables Context7 MCP tool guidance during implementation phases
  - `linear`: when true and `linear-issue` is present in handoff, orchestrators update Linear issue status at pipeline stages ("In Progress" after config load, "In Review" before PR). All MCP calls use graceful degradation.
  - `githubIssues`, `coderabbit`: passed through to `run-open-pr` and `run-finish` skills

If the config file is missing, the orchestrator stops immediately with: "No project config found. Run `/run-setup` in the target project first."

## Version Bump Phase

Version bumping is **not** performed by orchestrators. It is handled by the `run-finish` skill after PR review passes but before merge. See the [Work Lifecycle](work-lifecycle.md) spec for details.

The bump type is derived from the branch prefix (`feat/`→MINOR, `fix/`→PATCH, `refactor/`→PATCH, `docs/`→none) and can be overridden via a `version-bump:` directive in the PR body or commit messages. The semver bump procedure is inlined directly in the `run-finish` skill (Step 5c) to ensure it is available when the plugin is served from cache. The `versioning` array in `docs/ritual-config.json` remains unchanged.

## Per-Type Variations

### Feat Orchestrator

- **Knowledge alignment** -- Domain: CAN ADD, Decisions: CAN CREATE/ALIGN, Specs: CAN CREATE. Pauses for brainstorming on conflict.
- **Draft spec** -- Creates a spec in `docs/specs/` if one does not exist for the feature
- **TDD cycle** -- Standard red-green-commit loop for each unit of work
- **Max turns:** 100

### Fix Orchestrator

- **Knowledge alignment** -- Domain: READ-ONLY, Decisions: READ-ONLY, Specs: PRIMARY FOCUS. Blocks pipeline on conflict.
- **Root cause investigation** -- Traces backward from symptoms through code paths, forms a written hypothesis
- **TDD reproduce** -- Writes a failing test that reproduces the bug, then fixes it
- **Investigation retry** -- On fix failure, loops back to investigation with a new hypothesis (up to 2 cycles)
- **Max turns:** 100

### Refactor Orchestrator

- **Knowledge alignment** -- Domain: CAN EDIT, Decisions: CAN EDIT/FORCE ALIGN, Specs: NOT PRIMARY. Pauses for brainstorming on conflict.
- **TDD guard** -- Runs full test suite before any changes. Aborts if tests are not green.
- **Incremental refactor** -- One conceptual change at a time, tests must stay green after each
- **No new tests** -- Relies entirely on existing test suite as safety net
- **Max turns:** 80

### Docs Orchestrator

- **No knowledge alignment check** -- Docs orchestrator directly manipulates documentation; clash-check serves as its quality gate instead
- **Write/update documentation** -- Creates or updates docs across all three tiers
- **Clash check** -- Dispatches clash-check subagent on modified tiers
- **No tooling discovery** -- Does not detect test runners or build tools
- **No self-review** -- Replaced by clash-check for quality assurance
- **Max turns:** 60

## Failure Handling

All orchestrators share the same fallback pattern with bounded retry loops at three pipeline stages:

### TDD / Implementation Retry Loops

Each orchestrator type has a type-specific outer retry loop around its implementation step:

| Orchestrator | Loop Name | Max Retries | Strategy |
|---|---|---|---|
| feat | Re-plan loop | 2 | Re-read spec, reconsider unit decomposition |
| fix | Re-investigation loop | 2 | Invalidate hypothesis, form new one, retry TDD |
| refactor | Re-approach loop | 2 | Reconsider refactoring approach, try different strategy |
| docs | N/A | -- | No TDD cycle |

Each inner attempt allows up to 3 tries per unit. With the outer loop, this gives up to 9 total attempts before bailing (3 attempts x initial + 2 retries).

### Self-Review Retry Loop (max 3 iterations)

All orchestrators with a self-review step (feat, fix, refactor) use a bounded retry loop:

1. Run self-review and identify blocking issues
2. Attempt to fix the issues
3. Re-run the full self-review
4. Repeat up to 3 iterations total
5. If blocking issues persist after 3 iterations, bail to draft PR

### Arch Check Retry Loop (max 3 iterations)

All four orchestrators use a bounded retry loop for architecture checks:

1. Run arch check and identify violations
2. Attempt to fix each violation
3. Re-run the arch check
4. Repeat up to 3 iterations total
5. If violations persist after 3 iterations, bail to draft PR

### Escape Hatch

When any retry loop is exhausted:

1. Commit work-in-progress: `chore(wip): <what was attempted>`
2. Skip remaining steps and open a draft PR with `[WIP]` prefix

This ensures the pipeline never hangs and always produces a reviewable artifact.

## Commit Conventions

All commits use Conventional Commits format: `<type>: <description>`. The type matches the work classification from the handoff. Valid types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `style`, `build`.
