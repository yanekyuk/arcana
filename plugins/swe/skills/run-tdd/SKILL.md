---
name: run-tdd
description: "Use for test-driven development — write failing test, implement until green, repeat per unit of work"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# TDD Cycle

You are doing test-driven development. Follow this cycle strictly.

## Prerequisites

Before starting, discover the test runner:
- Check `package.json` scripts for `test` command
- Check for `Makefile`, `Cargo.toml`, `pyproject.toml`, `go.mod`
- If unclear and used standalone, ask the user. Within a pipeline (orchestrator context), infer the best available option — check for common test runner binaries on PATH.

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
