---
trigger: "Force orchestrators to report what happened, decided, written, tested etc in tasks"
type: feat
branch: feat/task-result-reporting
base-branch: main
created: 2026-03-28
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md

## Relevant Docs
None — knowledge base does not cover this area yet.

## Related Issues
None — no related issues found.

## Scope
Add a "Result reporting" mandate to Step 0 of all four orchestrator agents (feat, fix, refactor, docs). When marking a task as `completed` via TaskUpdate, orchestrators must update the task `description` with a concise summary of what actually happened at that step — key decisions made, files created/modified, tests written and their outcome, commands run, or notable findings. Each orchestrator gets a tailored example matching its pipeline type. The stashed changes on main (`git stash list` → "feat: add result reporting to orchestrators") contain the implementation — apply them in the worktree.
