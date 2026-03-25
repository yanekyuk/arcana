---
trigger: "gh pr merge --delete-branch fails when worktree holds the branch, and stale version conflicts are not caught during review"
type: fix
branch: fix/run-finish-cleanup
created: 2026-03-26
version-bump: patch
---

## Related Files
- plugins/swe/skills/run-finish/SKILL.md — the skill with both bugs

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope

Two fixes in `/run-finish`:

### 1. Merge step fails due to worktree holding branch
Step 5 uses `gh pr merge --delete-branch` which tries to delete the local branch. But the worktree still holds it at that point, so `gh` exits with code 1 even though the merge succeeds.

**Fix:** Remove `--delete-branch` from the `gh pr merge` commands in Step 5. Step 6 already handles cleanup in the correct order (worktree removal → local branch deletion). Add `git push origin --delete <branch>` to Step 6 for remote branch cleanup since `--delete-branch` no longer handles it.

### 2. Review doesn't catch stale versions
When multiple branches are in flight, the second PR to merge always has a stale base version (e.g., bumps 0.5.2 → 0.6.0 when main is already at 0.6.1). This causes merge conflicts every time.

**Fix:** Add a review check (Step 3e) that compares the PR's base version in `marketplace.json` against current main. If they differ, flag it as "needs rebase" before approving.
