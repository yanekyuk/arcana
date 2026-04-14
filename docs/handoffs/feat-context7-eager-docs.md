---
trigger: "If the user enabled Context7, the skills should be way more eager to use Context7 whenever possible to fetch correct documentations based on versions. It applies to languages, libraries, frameworks, etc."
type: feat
branch: feat/context7-eager-docs
base-branch: main
created: 2026-04-14
---

## Related Files
- plugins/ritual/agents/feat-orchestrator.md
- plugins/ritual/agents/fix-orchestrator.md
- plugins/ritual/agents/refactor-orchestrator.md
- plugins/ritual/agents/docs-orchestrator.md
- plugins/ritual/skills/run-tdd/SKILL.md
- docs/specs/integration-wiring.md
- docs/specs/orchestrator-pipeline.md

## Relevant Docs
- docs/specs/integration-wiring.md — Context7 integration wiring spec (authoritative)
- docs/specs/orchestrator-pipeline.md — Orchestrator pipeline spec with Context7 notes

## Related Issues
None — no related issues found.

## Scope
When `integrations.context7` is true, all 4 orchestrators (feat/fix/refactor/docs) and the run-tdd skill should proactively and eagerly use Context7 MCP tools to fetch documentation for any language, library, or framework encountered in the codebase — not just passively mention the tools during implementation. This means:

1. Proactively resolve and fetch docs for detected dependencies at the start of relevant steps (not just when stuck)
2. Apply Context7 lookups across multiple pipeline stages (e.g., exploration, spec reading, implementation, refactoring) wherever library/framework knowledge is relevant
3. Make the guidance explicit and directive: "MUST look up docs" rather than "you may use these tools"
4. Update the integration-wiring spec and orchestrator-pipeline spec to reflect the new eager behavior
5. Keep the run-setup prerequisite check and toggle behavior unchanged
