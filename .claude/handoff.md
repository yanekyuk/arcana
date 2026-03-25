---
trigger: "Add visualization to agents and tasks — user cannot tell which agent is running or what the plan is"
type: feat
branch: feat/orchestrator-progress
created: 2026-03-25
version-bump: minor
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- plugins/swe/.claude-plugin/plugin.json
- .claude-plugin/marketplace.json

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope

### Problem
Users cannot tell which orchestrator agent is running or what step it's on during execution.

### Solution
Each orchestrator self-seeds its pipeline tasks via TaskCreate in Step 0, then updates progress via TaskUpdate throughout execution. Visible in the Claude Code task list panel (Ctrl+T).

### Implementation

1. **Step 0 in each orchestrator**: Agent creates all pipeline tasks as `pending` via TaskCreate on startup.

2. **TaskUpdate calls in agent instructions**: Each orchestrator marks tasks `in_progress` when starting a step and `completed` when done.

3. **Tool list updates**: Add `TaskCreate, TaskUpdate` to the `tools` frontmatter of each orchestrator agent.

### Orchestrator step maps
- **feat**: read handoff → discover tooling → fetch docs → draft spec → TDD cycle → self-review → sync docs → version bump → open PR (9 steps)
- **fix**: read handoff → discover tooling → fetch docs → investigate root cause → TDD reproduce → self-review → sync docs → version bump → open PR (9 steps)
- **refactor**: read handoff → discover tooling → fetch docs → TDD guard → refactor incrementally → self-review → sync docs → version bump → open PR (9 steps)
- **docs**: read handoff → fetch docs → write/update documentation → clash check → sync docs → version bump → open PR (7 steps)
