---
title: "Orchestrator Pipeline"
type: spec
tags: [orchestrator, pipeline, feat, fix, refactor, docs, agent, config, arch-check, setup, knowledge-alignment]
created: 2026-03-26
updated: 2026-03-27
---

## Behavior

All four orchestrators share a common pipeline structure with type-specific variations. This spec documents the shared skeleton and per-type differences.

## Shared Pipeline Structure

Every orchestrator executes these phases in order:

| Phase | Step | Description |
|---|---|---|
| Setup | Initialize progress tracking | Create all pipeline tasks via TaskCreate |
| Setup | Read handoff | Parse `.claude/handoff.md` frontmatter and body |
| Setup | Load project config | Read `docs/swe-config.json` -- abort if missing |
| Context | Fetch docs | Grep `docs/` for tag matches, read top 5 |
| Context | Knowledge alignment check | Validate planned work against knowledge base -- pause for brainstorming on conflict (skipped by docs) |
| Work | Type-specific implementation | See per-type sections below |
| Quality | Self-review | Diff against main, check scope/spec/domain/tests (skipped by docs) |
| Quality | Arch check | Validate architecture rules against diff -- hard gate (after sync-docs for docs) |
| Knowledge | Sync docs | Detect implicit knowledge, update `docs/`, clash-check |
| Release | Version bump | Evaluate versioning rules from config, bump matching manifests |
| Cleanup | Remove handoff | `git rm .claude/handoff.md` |
| Delivery | Open PR | Push, create PR via `gh pr create` |

## Config Gate

All orchestrators require `docs/swe-config.json` to exist. This file is created by the `/run-setup` skill and contains:

- **`stack.*`** -- Tech stack configuration (language, runtime, test command, lint/format/typecheck commands). Replaces dynamic tooling discovery.
- **`architecture.rules`** -- Flat list of architecture rules enforced by `run-arch-check` as a hard gate.
- **`directives`** -- Soft guidance strings read by orchestrators during implementation.
- **`integrations`** -- Integration toggles (CodeRabbit, Linear, GitHub Issues, auto-docs).

If the config file is missing, the orchestrator stops immediately with: "No project config found. Run `/run-setup` in the target project first."

## Version Bump Phase

The version bump phase uses rule-based versioning configured in `docs/swe-config.json` under the `versioning` array. Each entry is a natural-language rule string that specifies which manifest to bump and when.

**Evaluation flow:**

1. Read the `versioning` array from config. If empty or absent, skip the version bump entirely.
2. For each rule, evaluate whether it applies to the current change (based on the diff and handoff scope).
3. For each matching rule, invoke the semver bump procedure on the specified manifest with the orchestrator's default bump type.
4. If no rules match, skip the version bump.

This replaces the previous approach of scanning a hardcoded list of manifest filenames at the project root. It supports monorepos with multiple independent version manifests where different parts of the codebase have their own version files.

## Per-Type Variations

### Feat Orchestrator

- **Knowledge alignment** -- Domain: CAN ADD, Decisions: CAN CREATE/ALIGN, Specs: CAN CREATE. Pauses for brainstorming on conflict.
- **Draft spec** -- Creates a spec in `docs/specs/` if one does not exist for the feature
- **TDD cycle** -- Standard red-green-commit loop for each unit of work
- **Default version bump:** MINOR
- **Max turns:** 100

### Fix Orchestrator

- **Knowledge alignment** -- Domain: READ-ONLY, Decisions: READ-ONLY, Specs: PRIMARY FOCUS. Blocks pipeline on conflict.
- **Root cause investigation** -- Traces backward from symptoms through code paths, forms a written hypothesis
- **TDD reproduce** -- Writes a failing test that reproduces the bug, then fixes it
- **Investigation retry** -- On fix failure, loops back to investigation with a new hypothesis (up to 2 cycles)
- **Default version bump:** PATCH
- **Max turns:** 100

### Refactor Orchestrator

- **Knowledge alignment** -- Domain: CAN EDIT, Decisions: CAN EDIT/FORCE ALIGN, Specs: NOT PRIMARY. Pauses for brainstorming on conflict.
- **TDD guard** -- Runs full test suite before any changes. Aborts if tests are not green.
- **Incremental refactor** -- One conceptual change at a time, tests must stay green after each
- **No new tests** -- Relies entirely on existing test suite as safety net
- **Default version bump:** PATCH
- **Max turns:** 80

### Docs Orchestrator

- **No knowledge alignment check** -- Docs orchestrator directly manipulates documentation; clash-check serves as its quality gate instead
- **Write/update documentation** -- Creates or updates docs across all three tiers
- **Clash check** -- Dispatches clash-check subagent on modified tiers
- **No tooling discovery** -- Does not detect test runners or build tools
- **No self-review** -- Replaced by clash-check for quality assurance
- **Default version bump:** none
- **Max turns:** 60

## Failure Handling

All orchestrators share the same fallback pattern:

1. Attempt the failing operation up to 3 times
2. If still failing, commit work-in-progress: `chore(wip): <what was attempted>`
3. Skip remaining steps and open a draft PR with `[WIP]` prefix

This ensures the pipeline never hangs and always produces a reviewable artifact.

## Commit Conventions

All commits use Conventional Commits format: `<type>: <description>`. The type matches the work classification from the handoff. Valid types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `style`, `build`.
