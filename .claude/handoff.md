---
trigger: "Replace hardcoded version manifest detection with rule-based versioning prompts in swe-config.json. Support monorepos with multiple version manifests. Make /run-setup generate versioning rules dynamically and support updating existing configs."
type: feat
branch: feat/config-versioning-rules
created: 2026-03-27
---

## Related Files
- plugins/swe/docs/semver-bump.md
- plugins/swe/skills/run-setup/SKILL.md
- docs/swe-config.json
- docs/specs/project-setup.md
- docs/specs/orchestrator-pipeline.md

## Relevant Docs
- docs/specs/project-setup.md — config schema and run-setup behavior
- docs/specs/orchestrator-pipeline.md — version bump phase in shared pipeline
- docs/domain/plugin-system-rules.md — versioning tag match, but specific to this repo's plugin system

## Scope
1. Add a `versioning` array field to the swe-config.json schema. Each entry is a natural-language rule string that tells the orchestrator which manifest to bump and when (e.g., "For frontend updates, update frontend/package.json version"). This supports monorepos with multiple independent version manifests.
2. Rewrite `semver-bump.md` to read versioning rules from `docs/swe-config.json` instead of scanning a hardcoded list of manifest filenames. The orchestrator evaluates which rules apply to the current change and bumps accordingly.
3. Add a versioning detection step to `/run-setup` that auto-discovers version-bearing files (package.json, Cargo.toml, pyproject.toml, etc.) across the project tree, generates rule prompts from the detected layout, and lets the user confirm/edit them.
4. Ensure `/run-setup` properly supports updating an existing config — loading current versioning rules as defaults when editing.
5. Update the config schema in `docs/specs/project-setup.md` and the version bump description in `docs/specs/orchestrator-pipeline.md`.
