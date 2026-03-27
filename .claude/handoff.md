---
trigger: "Ensure swe-config is used wherever it applies — remove redundant auto-detection fallbacks in skills that duplicate what swe-config already provides."
type: refactor
branch: refactor/tdd-config-reliance
created: 2026-03-27
---

## Related Files
- plugins/swe/skills/run-tdd/SKILL.md

## Relevant Docs
- docs/specs/project-setup.md — config schema and config gate behavior
- docs/specs/orchestrator-pipeline.md — config gate guarantees config exists in pipeline context
- docs/specs/skill-contracts.md — run-tdd contract

## Scope
Tighten `run-tdd` prerequisites to treat `swe-config.json` as the authoritative source for the test command. Currently lines 15-17 have a three-tier fallback (config → auto-detect → ask user). Since orchestrators guarantee config exists (they abort if missing), the auto-detection path only applies when `run-tdd` is used standalone. Restructure the prerequisites to make this distinction explicit:
1. In pipeline context: read `stack.test` from config, fail if missing (config is guaranteed by orchestrator).
2. In standalone context (no config): fall back to asking the user for the test command rather than duplicating the detection logic that belongs in `/run-setup`.
