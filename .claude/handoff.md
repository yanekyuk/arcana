---
trigger: "Move knowledge docs path from .claude/docs/ to ./docs/ so they are git-tracked and available in worktrees"
type: refactor
branch: refactor/docs-path
created: 2026-03-26
version-bump: patch
---

## Related Files
- CLAUDE.md — line 68: documents `.claude/docs/` hierarchy
- README.md — lines 44, 90: references `.claude/docs/`
- plugins/swe/skills/run-triage/SKILL.md — lines 25, 30, 80
- plugins/swe/skills/run-sync-docs/SKILL.md — lines 3, 11, 25, 26, 27
- plugins/swe/skills/run-spec/SKILL.md — lines 3, 17, 19, 54
- plugins/swe/skills/run-domain-knowledge/SKILL.md — lines 3, 16, 34, 45, 53
- plugins/swe/skills/run-design-decision/SKILL.md — lines 3, 16, 17, 43, 60
- plugins/swe/skills/run-clash-check/SKILL.md — lines 19, 20, 21, 29
- plugins/swe/agents/feat-orchestrator.md — lines 26, 31, 38, 63, 110
- plugins/swe/agents/fix-orchestrator.md — lines 25, 30, 94
- plugins/swe/agents/refactor-orchestrator.md — lines 23, 26, 27, 79
- plugins/swe/agents/docs-orchestrator.md — lines 19, 30, 47

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope
Replace all `.claude/docs/` references with `docs/` across all skills, agents, CLAUDE.md, and README.md (~40 occurrences in 13 files). This is a pure find-and-replace refactor — no logic changes.

The motivation: `.claude/` is not git-tracked, so knowledge docs never land in worktrees. Moving to `./docs/` (already in the repo layout) means worktree sessions get the knowledge docs automatically, and any doc updates become part of the PR diff.

Also update CLAUDE.md to reflect the new path in the knowledge hierarchy section.
