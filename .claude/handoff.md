---
trigger: "run-finish sometimes asks for changes but doesn't provide a prompt to the user. We need to programmatically ensure that when run-finish suggests changes, it always provides an actionable prompt."
type: fix
branch: fix/finish-prompt
base-branch: main
created: 2026-03-28
---

## Related Files
- plugins/swe/skills/run-finish/SKILL.md

## Relevant Docs
- docs/specs/skill-contracts.md

## Related Issues
None — no related issues found.

## Scope
In Step 4 of run-finish, when changes are needed, the skill template includes a "Suggested Fix Prompt" section with a placeholder `<ready-to-paste prompt describing exactly what to fix, formatted as an instruction>`. The LLM executing the skill sometimes lists issues but omits or leaves the prompt vague. The fix should strengthen the instructions in the skill to make the prompt generation explicit and mandatory — ensuring the LLM always produces a concrete, copy-pasteable prompt when requesting changes.
