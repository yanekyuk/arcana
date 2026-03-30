---
trigger: "run-finish skill references semver-bump.md via relative link that breaks when plugin is installed in target projects, causing AI to improvise version bumping and modify files not in the versioning config"
type: fix
branch: fix/inline-semver-bump
base-branch: main
created: 2026-03-30
---

## Related Files
- plugins/swe/skills/run-finish/SKILL.md
- plugins/swe/docs/semver-bump.md
- docs/specs/orchestrator-pipeline.md

## Relevant Docs
- docs/domain/plugin-system-rules.md
- docs/specs/orchestrator-pipeline.md

## Related Issues
None — no related issues found.

## Scope
The `run-finish` skill (line 168) references `../../docs/semver-bump.md` via a relative markdown link. This resolves within the arcana repo but breaks when the plugin is served from the cache (`~/.claude/plugins/cache/`), because the relative path no longer points to the file. Without the procedure, the AI improvises and bumps files outside the `versioning` config.

Fix: inline the content of `plugins/swe/docs/semver-bump.md` into the run-finish skill's Step 5c, then remove the standalone `semver-bump.md` file. Also update `docs/specs/orchestrator-pipeline.md` which references the same file.
