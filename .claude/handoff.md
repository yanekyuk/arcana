---
trigger: "run-triage Step 7 uses `cd .worktrees/<folder>` to commit handoff artifact, which is blocked by worktree-boundary.sh hook"
type: fix
branch: fix/triage-worktree-commit
created: 2026-03-26
version-bump: patch
---

## Related Files
- plugins/swe/skills/run-triage/SKILL.md — Step 7 commit instructions use `cd` into worktree
- plugins/swe/hooks/scripts/worktree-boundary.sh — blocks `cd`/`pushd` into `.worktrees/`

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope
The triage skill's Step 7 tells the agent to `cd .worktrees/<folder>` then `git add` + `git commit`. The `worktree-boundary.sh` hook blocks any `cd` into `.worktrees/`, causing the commit to fail.

Fix: Replace the `cd` + `git` commands with `git -C .worktrees/<folder>` equivalents, which operate on the worktree without changing the working directory. This is a one-line change in the SKILL.md template.
