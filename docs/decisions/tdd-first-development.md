---
title: "TDD-First Development"
type: decision
tags: [tdd, testing, orchestrator, failure-handling]
created: 2026-03-26
updated: 2026-03-28
---

## Decision

All orchestrators that modify code (feat, fix, refactor) use test-driven development as their primary implementation methodology.

## Context

Autonomous agents writing code without human oversight need a mechanical way to verify correctness. Tests provide that verification and prevent regressions.

## Rationale

- **Correctness signal** -- A passing test suite is the agent's primary indicator that implementation is correct. Without tests, the agent has no objective way to validate its work.
- **Incremental progress** -- TDD forces small, verifiable units of work. Each red-green-commit cycle produces a checkpoint the agent can fall back to.
- **Regression prevention** -- Running the full test suite after each change catches unintended side effects immediately, before they compound.
- **Scope enforcement** -- Writing the test first constrains the implementation to exactly what is needed, reducing scope creep.

## TDD Cycle

For each unit of work:
1. Write a failing test that describes the next behavior
2. Implement the minimum code to make it pass
3. Run the full test suite to check for regressions
4. Commit the test and implementation together

## Failure Handling

Each orchestrator uses a two-tier retry strategy: an inner loop of 3 attempts per unit, wrapped in an outer loop that reconsiders the approach before giving up.

### Inner loop (3 attempts per unit)

If a test will not pass after 3 attempts for a single unit of work, the orchestrator enters the outer retry loop rather than bailing immediately.

### Outer retry loops (max 2 retries, type-specific)

Each orchestrator type has its own strategy for the outer loop:

- **Feat orchestrator -- Re-plan loop:** Re-reads the spec and reconsiders the unit decomposition. The failing unit may be too large, incorrectly scoped, or based on a wrong assumption.
- **Fix orchestrator -- Re-investigation loop:** Invalidates the previous hypothesis, notes what evidence disproved it, forms a new hypothesis, and retries the TDD cycle.
- **Refactor orchestrator -- Re-approach loop:** Re-reads the handoff scope and design decisions, reconsiders the refactoring approach, reverts the failing change, and tries a different strategy.

### Exhaustion

If the unit still fails after exhausting all outer retries (2 retries x 3 attempts each = up to 9 total attempts):
1. Stop the TDD cycle
2. Commit work-in-progress: `chore(wip): <what was attempted>`
3. Skip remaining steps and open a draft PR with `[WIP]` prefix

## Orchestrator Variations

- **Feat orchestrator** -- Writes new tests for new behavior (standard TDD)
- **Fix orchestrator** -- Writes a reproducing test first, then fixes the bug (TDD reproduce)
- **Refactor orchestrator** -- Does not write new tests. Runs existing tests as a guard before and after each change. If pre-existing tests fail before any changes, the refactor is aborted entirely.
