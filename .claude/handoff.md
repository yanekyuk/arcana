---
trigger: "version bump should be part of run-finish, not orchestrator"
type: refactor
branch: refactor/version-bump-to-finish
base-branch: main
created: 2026-03-30
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- plugins/swe/skills/run-finish/SKILL.md
- plugins/swe/docs/semver-bump.md
- docs/specs/orchestrator-pipeline.md
- docs/specs/work-lifecycle.md

## Relevant Docs
- docs/specs/orchestrator-pipeline.md
- docs/specs/work-lifecycle.md
- docs/decisions/autonomous-orchestrators.md
- docs/decisions/handoff-artifact-pattern.md
- docs/domain/plugin-system-rules.md

## Related Issues
None — no related issues found.

## Scope
Move the version bump step from all four orchestrator agents (feat, fix, refactor, docs) into the run-finish skill. Currently each orchestrator runs the semver bump procedure as Step 10 (Step 8 for docs) with a type-specific default (feat=MINOR, fix=PATCH, refactor=PATCH, docs=none). After this refactor, run-finish will perform the version bump after PR review passes but before merge. The bump type default should be derived from the handoff type field or the PR branch prefix (feat/→MINOR, fix/→PATCH, refactor/→PATCH, docs/→none). The semver-bump.md procedure itself remains unchanged — only the caller moves. Update orchestrator-pipeline.md and work-lifecycle.md specs to reflect the new pipeline structure.
