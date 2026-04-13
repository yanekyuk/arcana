---
trigger: "Enhance worktree scripts so that everything that is gitignored is copied inside the worktree as well. Not just .claude."
type: feat
branch: feat/worktree-gitignore-copy
base-branch: main
created: 2026-04-14
version-bump: patch
---

## Related Files
- plugins/swe/scripts/setup-worktree.sh

## Relevant Docs
- docs/specs/triage-script.md
- docs/decisions/worktree-isolation.md

## Related Issues
None — no related issues found.

## Scope
Enhance `setup-worktree.sh` so that after creating the worktree, it copies ALL gitignored files from the main repo into the worktree (preserving directory structure), not just `.claude/`. Use `git ls-files --others --ignored --exclude-standard` (or similar) to enumerate gitignored files, then rsync/cp them into the worktree. The existing `.claude/handoff.md` write can then rely on the copied `.claude/` directory already existing. Update the triage-script spec to reflect the new behavior.
