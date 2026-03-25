---
title: "Worktree Isolation"
type: decision
tags: [worktree, git, branch, isolation, concurrency]
created: 2026-03-26
updated: 2026-03-26
---

## Decision

All implementation work happens in git worktrees rather than the main working tree. Each piece of work gets its own worktree.

## Context

When multiple tasks are in flight (or a single task needs isolation from the main branch), working directly in the main checkout risks uncommitted changes, merge conflicts, and accidental modifications to the main branch.

## Rationale

- **Concurrent work** -- Multiple worktrees can exist simultaneously, each on a different branch, without interfering with each other or the main checkout.
- **Clean main** -- The main working tree stays on the `main` branch with no unstaged changes, available for triage and finish operations at any time.
- **Disposable** -- Worktrees are cheap to create and remove. After merge, `git worktree remove` and `git branch -d` clean up completely.

## Naming Conventions

**Branch names** follow the pattern `<type>/<short-description>` where:
- `type` is one of: `feat`, `fix`, `refactor`, `docs`
- `short-description` is 2-4 words in kebab-case

**Worktree folders** are placed under `.worktrees/<type>-<short-description>` (note: hyphens replace the slash from the branch name).

**Collision handling** -- If a branch or worktree already exists with the chosen name, triage offers two options: resume the existing worktree, or create with a numeric suffix (e.g., `feat/user-auth-2`).

## Constraints

- The `.worktrees/` directory lives at the project root.
- Worktrees are created by triage and removed by finish -- orchestrators do not manage worktree lifecycle.
