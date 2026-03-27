---
trigger: "Orchestrator agents create all pipeline tasks in Step 0 but only mention TaskUpdate once. The agents lose track mid-execution, leaving tasks as open/in-progress even after work completes and the PR is opened."
type: fix
branch: fix/task-update-tracking
created: 2026-03-27
version-bump: patch
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md

## Relevant Docs
- docs/specs/orchestrator-pipeline.md — shared pipeline structure, progress tracking phase
- docs/decisions/autonomous-orchestrators.md — orchestrator design and progress tracking

## Scope
The single TaskUpdate instruction on line 65 (57 for docs) is insufficient — agents forget to update tasks as they progress through steps. Fix by adding explicit TaskUpdate reminders at each step boundary in all four orchestrators. Keep it concise (inline with step headers or as a one-liner at step start/end) to avoid bloating the prompts while making it impossible for the agent to skip updates.
