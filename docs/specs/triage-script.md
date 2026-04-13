---
title: "Triage Script"
type: spec
tags: [triage, script, worktree, handoff, permission]
created: 2026-03-26
updated: 2026-04-14
---

## Behavior

A shell script at `plugins/swe/scripts/setup-worktree.sh` consolidates triage steps 7-9 (branch creation, worktree setup, handoff write, commit) into a single invocation. The script:

1. Accepts three positional arguments: branch name, worktree folder name, and commit message
2. Reads handoff content from stdin
3. Creates the git branch
4. Creates the `.worktrees/` directory and adds the worktree
5. Copies all gitignored files from the main repo into the worktree (preserving directory structure), excluding `.worktrees/` itself
6. Writes the handoff content to `.worktrees/<folder>/.claude/handoff.md`
7. Stages and commits the handoff artifact inside the worktree

Step 5 uses `git ls-files --others --ignored --exclude-standard` to enumerate gitignored files, filters out `.worktrees/` entries, then uses `rsync --files-from` to copy them into the worktree. This ensures environment files (`.env`, `.claude/`, etc.) are available in the worktree session. If no gitignored files exist, the step is a no-op.

The `run-triage` skill calls this script instead of issuing separate tool calls for each operation.

## Constraints

- The script must be idempotent-safe: it should fail cleanly if the branch or worktree already exists (collision detection happens in the skill before invoking the script)
- The script must work from the project root (the main repo, not a worktree)
- The skill must resolve the script path for both development (arcana repo) and installed-plugin contexts (cache path)
- The skill's `allowed-tools` must include Bash to invoke the script
- No cross-plugin imports: the script lives within `plugins/swe/`

## Acceptance Criteria

- Running the script with valid args and stdin produces a worktree with a committed handoff artifact
- All gitignored files from the main repo exist in the worktree at their original relative paths (except `.worktrees/`)
- The script exits cleanly when no gitignored files exist
- The `run-triage` skill step 8 calls the script via a single Bash invocation
- Steps 7 (branch naming/collision check) and the final user instruction remain in the skill as separate steps
- The script exits with a non-zero code on failure (e.g., git errors)
- Permission prompts are reduced from 3 to 1 for the branch+worktree+handoff+commit operation
