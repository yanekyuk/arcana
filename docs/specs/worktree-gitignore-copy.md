---
title: "Worktree Gitignore Copy"
type: spec
tags: [worktree, gitignore, setup-worktree, triage, script]
created: 2026-04-14
updated: 2026-04-14
---

## Behavior

The `setup-worktree.sh` script copies all gitignored files from the main repository into the newly created worktree, preserving directory structure. This happens after the worktree is created but before the handoff artifact is written.

The script uses `git ls-files --others --ignored --exclude-standard` to enumerate gitignored files in the main repo, then copies them into the worktree using `rsync` (with `--files-from`), preserving relative paths.

Because `.claude/` is gitignored, the copy step ensures `.claude/` already exists in the worktree before the handoff write, making the explicit `mkdir -p .claude` call a safety fallback rather than a requirement.

## Constraints

- The enumeration must use git's own ignore machinery (`--exclude-standard`) to stay consistent with `.gitignore` rules
- Directory structure must be preserved -- files land at the same relative paths in the worktree
- The copy must not fail if there are no gitignored files (empty list is valid)
- The copy must not include `.worktrees/` itself (it is gitignored but copying it would be recursive/nonsensical)
- The existing `mkdir -p .claude` + handoff write must remain as a safety fallback
- The script must continue to work from the project root (main repo)

## Acceptance Criteria

- After `setup-worktree.sh` runs, all files reported by `git ls-files --others --ignored --exclude-standard` (except those under `.worktrees/`) exist in the worktree at their original relative paths
- The handoff artifact write still works correctly
- The script exits cleanly when no gitignored files exist
- The script does not copy the `.worktrees/` directory itself
