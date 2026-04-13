#!/usr/bin/env bash
#
# setup-worktree.sh — Create branch, worktree, copy gitignored files, and commit
#                      a handoff artifact in a single invocation.
#
# Usage:
#   echo "<handoff content>" | bash setup-worktree.sh <branch> <folder> <commit-msg>
#
# Arguments:
#   branch      — Git branch name (e.g., feat/triage-script)
#   folder      — Worktree folder name under .worktrees/ (e.g., feat-triage-script)
#   commit-msg  — Commit message for the handoff artifact
#
# Stdin:
#   The full content of the handoff markdown file (.claude/handoff.md)
#
# The script must be run from the project root (main repo, not a worktree).

set -euo pipefail

branch="${1:?Usage: setup-worktree.sh <branch> <folder> <commit-msg>}"
folder="${2:?Usage: setup-worktree.sh <branch> <folder> <commit-msg>}"
commit_msg="${3:?Usage: setup-worktree.sh <branch> <folder> <commit-msg>}"

worktree_dir=".worktrees/${folder}"

# 1. Create the branch
git branch "$branch"

# 2. Create the worktree
mkdir -p .worktrees
git worktree add "$worktree_dir" "$branch"

# 3. Copy gitignored files into the worktree (preserving directory structure)
#    This ensures environment files (.env, .claude/, etc.) are available in the
#    worktree. Excludes .worktrees/ itself to avoid recursive copies.
ignored_files=$(git ls-files --others --ignored --exclude-standard \
  | grep -v '^\.worktrees/' || true)

if [ -n "$ignored_files" ]; then
  echo "$ignored_files" | rsync -a --files-from=- . "$worktree_dir/"
fi

# 4. Write handoff from stdin (mkdir -p as safety fallback; .claude/ may already
#    exist from the gitignore copy above)
mkdir -p "${worktree_dir}/.claude"
cat > "${worktree_dir}/.claude/handoff.md"

# 5. Stage and commit inside the worktree
git -C "$worktree_dir" add -f .claude/handoff.md
git -C "$worktree_dir" commit -m "$commit_msg"
