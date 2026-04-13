---
trigger: "Rename arcana:swe to arcana:ritual"
type: refactor
branch: refactor/rename-swe-to-ritual
base-branch: main
created: 2026-04-13
version-bump: patch
---

## Related Files
- .claude-plugin/marketplace.json
- plugins/swe/.claude-plugin/plugin.json
- plugins/swe/skills/ (all SKILL.md files reference "swe")
- plugins/swe/agents/ (all orchestrator agents reference "swe")
- plugins/swe/hooks/ (hooks.json and hook scripts)
- plugins/swe/scripts/setup-worktree.sh
- docs/swe-config.json
- docs/domain/plugin-system-rules.md
- docs/specs/ (multiple specs reference "swe")
- .claude/settings.json
- CLAUDE.md
- README.md
- tests/ (test scripts reference "swe")

## Relevant Docs
- docs/domain/plugin-system-rules.md

## Related Issues
None — no related issues found.

## Scope
Rename the `swe` plugin to `ritual` across the entire repository. This is a pure rename/reorganization with no behavior changes:

1. Move `plugins/swe/` directory to `plugins/ritual/`
2. Update `marketplace.json`: plugin name → "ritual", source → "./plugins/ritual", update tags
3. Update `plugin.json`: name → "ritual", update keywords
4. Update all internal references in skills, agents, hooks, and scripts from "swe" to "ritual"
5. Rename `docs/swe-config.json` → `docs/ritual-config.json` and update internal references
6. Update `CLAUDE.md`, `README.md`, and all docs/specs referencing "swe"
7. Update `.claude/settings.json` references
8. Update test scripts referencing "swe"
9. Update `docs/swe-config.json` versioning entry paths
10. Bump version to next patch in both manifests
