---
trigger: "Allow model invocation for run-triage so the LLM can proactively run it when ready, with user agreement"
type: refactor
branch: refactor/triage-model-invocation
created: 2026-03-26
version-bump: patch
---

## Related Files
- plugins/swe/skills/run-triage/SKILL.md
- docs/specs/skill-contracts.md

## Relevant Docs
- docs/specs/skill-contracts.md — skill input/output/tools contracts
- docs/specs/work-lifecycle.md — full triage→resume→orchestrator→finish flow

## Scope

Remove `disable-model-invocation: true` from `run-triage/SKILL.md` frontmatter. This allows the LLM to proactively invoke triage when it determines work is ready, rather than requiring the user to explicitly type `/run-triage`.

The skill description already explains when to use it ("Use when starting new work"), which will guide model invocation decisions. The triage flow itself includes a user confirmation step (Step 4: propose classification and wait for confirmation), so the user retains control even when the model initiates.

Update `docs/specs/skill-contracts.md` to reflect that run-triage is now model-invocable.
