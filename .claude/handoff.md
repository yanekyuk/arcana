---
trigger: "run-triage should not work without docs/swe-config.json — it should fail fast like the orchestrators do, instead of letting users discover the missing config later in the worktree."
type: fix
branch: fix/triage-config-gate
created: 2026-03-26
version-bump: patch
---

## Related Files
- plugins/swe/skills/run-triage/SKILL.md (needs config gate added)
- plugins/swe/agents/feat-orchestrator.md (reference — has config gate at Step 2)

## Relevant Docs
- docs/specs/orchestrator-pipeline.md — shared pipeline structure, documents config gate
- docs/specs/project-setup.md — describes swe-config.json and run-setup
- docs/specs/skill-contracts.md — run-triage contract
- docs/specs/work-lifecycle.md — full lifecycle including triage phase

## Scope

### Problem
`run-triage` proceeds without checking for `docs/swe-config.json`. The orchestrators (feat/fix/refactor/docs) all gate on this file at Step 2 and abort if missing. But triage doesn't check, so a user can triage work, create a worktree, start a new session, run `/run-resume`, and only then discover the config is missing — wasting time.

### Fix
Add a config gate step to `run-triage` between Step 1 (Validate context) and Step 2 (Understand the trigger). If `docs/swe-config.json` does not exist, stop immediately and tell the user to run `/run-setup` first.

### Changes needed
1. **plugins/swe/skills/run-triage/SKILL.md**: Insert a new step after Step 1 that checks for `docs/swe-config.json`. If missing, report to user and stop. Renumber subsequent steps.
2. **Version bump**: 0.8.1 → 0.8.2 in both plugin.json and marketplace.json.
