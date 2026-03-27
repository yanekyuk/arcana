---
trigger: "Change the default merge strategy from squash to normal merge commit"
type: refactor
branch: refactor/default-merge-strategy
created: 2026-03-27
---

## Related Files
- plugins/swe/skills/run-finish/SKILL.md
- docs/specs/work-lifecycle.md

## Relevant Docs
- docs/specs/work-lifecycle.md

## Related Issues
None — no related issues found.

## Scope
Change the default merge strategy from squash to normal merge commit in two places:
1. `plugins/swe/skills/run-finish/SKILL.md` (lines 128-134): Flip the default so merge commit is shown first and squash is the alternative. Update the default `gh pr merge` command to use `--merge` instead of `--squash`.
2. `docs/specs/work-lifecycle.md` (line 93): Change "default squash" to "default merge commit".
The skill should still ask for user preference — only the default changes.
