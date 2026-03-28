---
trigger: "Brainstorming sessions never trigger in orchestrators — missing AskUserQuestion tool, contradictory zero-intervention framing, and vague instructions in Step 4c"
type: fix
branch: fix/brainstorming-trigger
base-branch: main
created: 2026-03-28
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- docs/specs/knowledge-alignment-gate.md
- docs/specs/orchestrator-pipeline.md
- docs/decisions/autonomous-orchestrators.md

## Relevant Docs
- docs/specs/knowledge-alignment-gate.md
- docs/specs/orchestrator-pipeline.md
- docs/decisions/autonomous-orchestrators.md

## Related Issues
None — no related issues found.

## Scope
The knowledge alignment brainstorming session (Step 4c in feat/fix/refactor orchestrators) never triggers due to three issues:

1. **Missing tool**: `AskUserQuestion` is not in orchestrator `tools:` frontmatter — the agent cannot pause for user input.
2. **Contradictory framing**: Opening paragraphs say "zero human intervention" which biases the agent to always take the no-conflict fast path. The user wants orchestrators to be open to interventions in specific steps, especially when there is new domain knowledge, changes to domain knowledge, or a need for new design patterns.
3. **Vague instructions**: Step 4c says "wait for responses" without referencing a specific tool.

Fix: Add `AskUserQuestion` to all three orchestrator tool lists, update opening paragraphs to acknowledge user interaction during knowledge alignment, make Step 4c explicitly use `AskUserQuestion`, and update related specs/decisions.
