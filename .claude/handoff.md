---
trigger: "PRs sometimes target the wrong branch. They should always target the branch the worktree was derived from."
type: fix
branch: fix/pr-base-branch
base-branch: main
created: 2026-03-27
version-bump: patch
---

## Related Files
- plugins/swe/scripts/setup-worktree.sh
- plugins/swe/skills/run-triage/SKILL.md
- plugins/swe/skills/run-open-pr/SKILL.md
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- docs/decisions/handoff-artifact-pattern.md
- docs/specs/triage-script.md
- docs/specs/skill-contracts.md

## Relevant Docs
- docs/decisions/handoff-artifact-pattern.md — handoff frontmatter schema (needs base-branch field)
- docs/specs/triage-script.md — setup-worktree.sh behavior spec
- docs/decisions/worktree-isolation.md — worktree creation context
- docs/specs/skill-contracts.md — skill input/output contracts

## Related Issues
None — no related issues found.

## Scope
The `gh pr create` command in run-open-pr and all 4 orchestrator fallbacks hardcodes `--base main`. When the worktree is derived from a non-main branch, the PR targets the wrong base. Fix by:
1. Recording the current branch as `base-branch` in the handoff frontmatter (setup-worktree.sh)
2. Adding `base-branch` to the handoff schema (run-triage)
3. Reading `base-branch` from handoff and using it in `--base` (run-open-pr)
4. Replacing `--base main` with `--base <base-branch>` in all 4 orchestrator fallbacks
5. Updating handoff-artifact-pattern decision doc with the new field
