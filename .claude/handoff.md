---
trigger: "Rename run-resume to run-start with explicit worktree validation, and remove user-invocable from 9 internal-only skills"
type: refactor
branch: refactor/skill-cleanup
created: 2026-03-26
version-bump: patch
---

## Related Files
- plugins/swe/skills/run-resume/SKILL.md (rename to run-start, add worktree-only guard)
- plugins/swe/skills/run-tdd/SKILL.md (remove user-invocable)
- plugins/swe/skills/run-self-review/SKILL.md (remove user-invocable)
- plugins/swe/skills/run-arch-check/SKILL.md (remove user-invocable)
- plugins/swe/skills/run-open-pr/SKILL.md (remove user-invocable)
- plugins/swe/skills/run-sync-docs/SKILL.md (remove user-invocable)
- plugins/swe/skills/run-spec/SKILL.md (remove user-invocable)
- plugins/swe/skills/run-domain-knowledge/SKILL.md (remove user-invocable)
- plugins/swe/skills/run-design-decision/SKILL.md (remove user-invocable)
- plugins/swe/skills/run-clash-check/SKILL.md (remove user-invocable)
- README.md (references run-resume)
- CLAUDE.md (references run-resume)
- docs/specs/skill-contracts.md (run-resume entry)
- docs/specs/work-lifecycle.md (references run-resume)
- docs/decisions/handoff-artifact-pattern.md (references run-resume)
- docs/decisions/two-session-model.md (references run-resume)
- plugins/swe/skills/run-triage/SKILL.md (final instruction mentions run-resume)

## Relevant Docs
- docs/specs/skill-contracts.md — documents all skill contracts
- docs/specs/work-lifecycle.md — references run-resume in Phase 2
- docs/decisions/two-session-model.md — references run-resume

## Scope

### Change 1: Rename run-resume → run-start
1. Rename directory: `plugins/swe/skills/run-resume/` → `plugins/swe/skills/run-start/`
2. Update SKILL.md frontmatter: name → `run-start`, description updated
3. Add explicit worktree validation: check `test -f .git` (file not directory — worktrees have .git as a file). If it's a directory (main repo), deny with: "This skill must run from a worktree, not the project root."
4. Update all references across: README.md, CLAUDE.md, docs/specs/skill-contracts.md, docs/specs/work-lifecycle.md, docs/decisions/handoff-artifact-pattern.md, docs/decisions/two-session-model.md, plugins/swe/skills/run-triage/SKILL.md

### Change 2: Remove user-invocable from internal skills
Remove `user-invocable: true` from these 9 skills (they are only dispatched by orchestrators or other skills):
- run-tdd, run-self-review, run-arch-check, run-open-pr, run-sync-docs, run-spec, run-domain-knowledge, run-design-decision, run-clash-check

Update docs/specs/skill-contracts.md invocation fields accordingly.

### Version bump
0.8.4 → 0.8.5 in both plugin.json and marketplace.json.
