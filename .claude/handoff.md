---
trigger: "Orchestrators fetch knowledge docs but treat them as passive context. They should validate alignment before implementation and pause for a brainstorming session with the user when conflicts are detected."
type: feat
branch: feat/knowledge-alignment-gate
created: 2026-03-26
version-bump: minor
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/.claude-plugin/plugin.json
- .claude-plugin/marketplace.json

## Relevant Docs
- docs/claude-code-extensions-reference.md — agent format reference

## Scope

Add a new pipeline step ("Knowledge alignment check") to the feat, fix, and refactor orchestrators. This step runs after "Fetch docs" (Step 3) and before the first implementation step. It validates the planned work against the knowledge base and, if misalignment is detected, pauses autonomy to enter a brainstorming session — asking the user targeted questions until all issues are resolved.

### Flow-specific rules

**fix orchestrator:**
- Domain knowledge: READ-ONLY. The fix must not break any domain rules. If the planned fix would violate a domain rule, block and ask the user.
- Specs: Primary focus. Bugs are deviations from spec — validate the fix aligns with the existing spec.
- Design decisions: READ-ONLY. Fixes should not alter design patterns.
- On conflict: Block the pipeline. Present the conflict and ask the user clarifying questions until resolved.

**feat orchestrator:**
- Domain knowledge: CAN ADD. New features may introduce new domain rules. If the feature implies new domain knowledge, ask the user to confirm before proceeding.
- Specs: CAN CREATE. New features may need new specs (already handled in Step 4).
- Design decisions: CAN CREATE NEW or ALIGN WITH EXISTING. New features can introduce new patterns or should align with existing ones. Ask the user if a new pattern is needed or if an existing one applies.
- On conflict: Pause and brainstorm with the user about what to add or how to align.

**refactor orchestrator:**
- Domain knowledge: CAN EDIT. Refactors may restructure how domain rules are expressed. Ask the user to confirm any domain knowledge changes.
- Specs: Not primary concern for refactors (behavior should not change).
- Design decisions: CAN EDIT or FORCE ALIGNMENT. Refactors can update design patterns or force existing code to align with them. Ask the user to confirm changes to design decisions.
- On conflict: Pause and brainstorm with the user about what to edit and why.

### Brainstorming session format

When misalignment is detected, the orchestrator should:
1. Present the specific conflict (quote the relevant doc section and the planned work that conflicts)
2. Ask targeted questions (not open-ended) to resolve the conflict
3. Wait for user responses
4. Continue asking until all conflicts are resolved
5. Document any decisions made during brainstorming in the appropriate docs/ tier
6. Only then proceed with implementation
