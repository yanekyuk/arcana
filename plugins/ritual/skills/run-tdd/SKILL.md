---
name: run-tdd
description: "Use for test-driven development — write failing test, implement until green, repeat per unit of work"
model: sonnet
effort: high
user-invocable: false
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# TDD Cycle

You are doing test-driven development. Follow this cycle strictly.

## Prerequisites

Determine the test command:
1. Check if `docs/ritual-config.json` exists — if so, use `stack.test` from the config. In pipeline context (dispatched by an orchestrator), the config is guaranteed to exist — the orchestrator aborts if it is missing.
2. If no config (standalone invocation), ask the user for the test command. Do not attempt auto-detection — that logic belongs in `/run-setup`.

**Directives:** If `docs/ritual-config.json` exists, read `directives.implementation` from the config. These are soft guidelines that influence your coding style and implementation choices. Apply them throughout the TDD cycle. If the field is missing or empty, proceed without directives.

## The Cycle

For each unit of work:

### 1. Write a failing test

- Write the smallest test that describes the next piece of behavior
- The test MUST fail before you write implementation code
- Run the test to confirm it fails:
  ```
  <test-command> <specific-test-file-or-filter>
  ```
- If the test passes without implementation, your test isn't testing anything new — revise it

### 2. Implement minimally

- Write the minimum code to make the failing test pass
- Do NOT write code for behavior that isn't tested yet
- Run the test to confirm it passes

### 3. Refactor (if needed)

- Clean up the implementation while keeping tests green
- Run all related tests after refactoring

### 4. Commit

Use [Conventional Commits](https://www.conventionalcommits.org/) format. Valid types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `style`, `build`.

```bash
git add <test-file> <implementation-file>
git commit -m "<type>: <what this unit does>"
```

The `<type>` must match the work classification from the handoff (e.g., `feat` for features, `fix` for bug fixes). Use `test` only for test-only commits with no implementation changes.

## Failure handling

If a test won't pass after 3 attempts for a single unit of work:
1. Stop the TDD cycle
2. Commit what you have with message: `chore(wip): <what was attempted>`
3. Report what failed and why
