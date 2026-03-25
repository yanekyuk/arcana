---
title: "TDD-First Development"
type: decision
tags: [tdd, testing, orchestrator, failure-handling]
created: 2026-03-26
updated: 2026-03-26
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

If a test will not pass after 3 attempts for a single unit of work:
1. Stop the TDD cycle
2. Commit work-in-progress: `chore(wip): <what was attempted>`
3. Skip remaining steps and open a draft PR with `[WIP]` prefix

For the fix orchestrator specifically, failure triggers a second investigation loop -- the initial hypothesis is revisited and a new one is formed before retrying. Only after two full investigation-fix cycles fail does it fall back to a WIP draft PR.

## Orchestrator Variations

- **Feat orchestrator** -- Writes new tests for new behavior (standard TDD)
- **Fix orchestrator** -- Writes a reproducing test first, then fixes the bug (TDD reproduce)
- **Refactor orchestrator** -- Does not write new tests. Runs existing tests as a guard before and after each change. If pre-existing tests fail before any changes, the refactor is aborted entirely.
