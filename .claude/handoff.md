---
trigger: "Remove disable-model-invocation: true from all user-invocable skills so the LLM can see them in its available skills list. Users currently get 'I don't see that skill' when mentioning skills like /run-finish."
type: refactor
branch: refactor/enable-model-invocation
created: 2026-03-26
version-bump: patch
---

## Related Files
- plugins/swe/skills/run-setup/SKILL.md
- plugins/swe/skills/run-arch-check/SKILL.md
- plugins/swe/skills/run-finish/SKILL.md
- plugins/swe/skills/run-tdd/SKILL.md
- plugins/swe/skills/run-sync-docs/SKILL.md
- plugins/swe/skills/run-spec/SKILL.md
- plugins/swe/skills/run-self-review/SKILL.md
- plugins/swe/skills/run-resume/SKILL.md
- plugins/swe/skills/run-open-pr/SKILL.md
- plugins/swe/skills/run-domain-knowledge/SKILL.md
- plugins/swe/skills/run-design-decision/SKILL.md
- plugins/swe/skills/run-clash-check/SKILL.md
- docs/specs/skill-contracts.md

## Relevant Docs
- docs/specs/skill-contracts.md — documents invocation type for each skill

## Scope

### Problem
All skills except `run-triage` have `disable-model-invocation: true` in their YAML frontmatter. This hides them from the LLM's available skills list, so when a user mentions `/run-finish` the LLM responds "I don't see that skill." The flag was originally added to prevent the LLM from auto-invoking skills at inappropriate times, but it also prevents the LLM from knowing the skills exist at all.

### Fix
Remove `disable-model-invocation: true` from all 12 remaining skills. The `run-triage` precedent (PR #15) already proved this works — triage retains user control via its confirmation step, and other skills have similar guardrails built into their instructions.

### Changes needed
1. Remove `disable-model-invocation: true` (line 5) from all 12 SKILL.md files listed above
2. Update `docs/specs/skill-contracts.md` invocation fields to reflect that all skills are now model-invocable
3. Version bump 0.8.3 → 0.8.4 in both plugin.json and marketplace.json
