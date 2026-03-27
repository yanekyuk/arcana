---
trigger: "Custom directives should be categorized by skill group and globally available to applicable skills. Groups: implementation, review, documentation, delivery, triage. run-setup should collect directives per group. Skills read their group's directives. Schema changes from flat array to object with group keys."
type: feat
branch: feat/categorized-directives
created: 2026-03-27
---

## Related Files
- plugins/swe/skills/run-setup/SKILL.md (writes directives — needs per-group collection)
- plugins/swe/skills/run-tdd/SKILL.md (implementation group)
- plugins/swe/skills/run-self-review/SKILL.md (review group)
- plugins/swe/skills/run-sync-docs/SKILL.md (documentation group)
- plugins/swe/skills/run-spec/SKILL.md (documentation group)
- plugins/swe/skills/run-domain-knowledge/SKILL.md (documentation group)
- plugins/swe/skills/run-design-decision/SKILL.md (documentation group)
- plugins/swe/skills/run-open-pr/SKILL.md (delivery group)
- plugins/swe/skills/run-finish/SKILL.md (delivery group)
- plugins/swe/skills/run-triage/SKILL.md (triage group)
- plugins/swe/agents/feat-orchestrator.md (passes directives to skills)
- plugins/swe/agents/fix-orchestrator.md (passes directives to skills)
- plugins/swe/agents/refactor-orchestrator.md (passes directives to skills)
- plugins/swe/agents/docs-orchestrator.md (passes directives to skills)
- docs/swe-config.json (schema change: directives becomes object)
- docs/specs/project-setup.md (schema docs update)
- docs/specs/skill-contracts.md (skill input docs update)

## Relevant Docs
- docs/specs/project-setup.md — defines config schema and directives as soft guidance
- docs/specs/skill-contracts.md — defines skill inputs/outputs
- docs/specs/orchestrator-pipeline.md — defines how orchestrators dispatch skills

## Related Issues
None — no related issues found.

## Scope
Redesign the directives system from a flat string array to a categorized object keyed by skill group:

1. **Schema change**: `directives` in swe-config.json changes from `string[]` to `{ implementation: string[], review: string[], documentation: string[], delivery: string[], triage: string[] }`

2. **run-setup update**: Walk through each directive group during setup, explain what skills it covers, collect per-group directives. Support updating existing categorized directives.

3. **Skill updates**: Each skill in a group reads its group's directives from swe-config.json:
   - implementation → run-tdd
   - review → run-self-review
   - documentation → run-sync-docs, run-spec, run-domain-knowledge, run-design-decision
   - delivery → run-open-pr, run-finish
   - triage → run-triage

4. **Orchestrator updates**: Orchestrators already read directives — update them to pass relevant group(s) when dispatching skills, and apply relevant directives in their own implementation steps.

5. **Spec updates**: Update project-setup.md schema docs and skill-contracts.md inputs.

Skills that remain directive-free: run-setup, run-start, run-arch-check, run-clash-check.
