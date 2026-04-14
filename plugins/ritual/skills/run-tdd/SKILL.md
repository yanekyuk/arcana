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

**Context7 eager documentation lookups:** If `docs/ritual-config.json` exists and `integrations.context7` is true, you MUST proactively use Context7 MCP tools to fetch authoritative documentation for any language, library, framework, runtime, or CLI tool involved in the work. Do NOT rely on training-data recall for version-specific behavior.

Before writing the first failing test, and again whenever a new dependency enters the diff:

1. Identify the languages, libraries, frameworks, and runtimes involved in the unit of work. Check `stack.*` in `docs/ritual-config.json` (language, runtime, packageManager, test runner) and the files you are about to modify for imports, require calls, package names, or framework markers.
2. For each identified library or framework, call `mcp__context7__resolve-library-id` to obtain its Context7 ID. Prefer version-matched IDs when a version is pinned in lockfiles, `stack.*`, or package manifests.
3. Call `mcp__context7__get-library-docs` with the resolved ID. Use the `topic` parameter to narrow the fetch to the specific API, configuration, or feature you are about to use. Pass version information via the `topic` parameter when relevant (for example, "v15 app router" or "3.12 type hints").
4. Apply the fetched documentation when writing the test and the implementation. Prefer Context7 output over assumptions.

These lookups MUST happen proactively, not only when a test fails or you get stuck. When `integrations.context7` is false or no config is present, proceed without Context7 lookups.

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
- **Context7 eager lookup (when `integrations.context7` is true):** Before writing the test, if the unit under test touches an external library, framework, or language feature whose API you have not just fetched, MUST resolve and fetch its docs via Context7 (`mcp__context7__resolve-library-id` then `mcp__context7__get-library-docs`) so assertions match real API behavior.

### 2. Implement minimally

- Write the minimum code to make the failing test pass
- Do NOT write code for behavior that isn't tested yet
- Run the test to confirm it passes
- **Context7 eager lookup (when `integrations.context7` is true):** Before calling any library/framework API in the implementation, MUST consult Context7 docs (via `mcp__context7__get-library-docs`) for the specific API, configuration option, or usage pattern. Do this even for well-known libraries -- version-specific behavior changes frequently.

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
