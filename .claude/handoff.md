---
trigger: "Deep Linear integration: graceful degradation, issue status management through pipeline, and a create-triage skill that routes between GH Issues and Linear."
type: feat
branch: feat/linear-integration
base-branch: main
created: 2026-03-27
version-bump: minor
---

## Related Files
- plugins/swe/skills/run-triage/SKILL.md
- plugins/swe/skills/run-open-pr/SKILL.md
- plugins/swe/skills/run-finish/SKILL.md
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- docs/swe-config.json
- docs/specs/integration-wiring.md
- docs/specs/skill-contracts.md

## Relevant Docs
- docs/specs/integration-wiring.md — authoritative spec for all integration wiring
- docs/specs/skill-contracts.md — skill input/output contracts
- docs/specs/orchestrator-pipeline.md — orchestrator pipeline steps
- docs/decisions/handoff-artifact-pattern.md — handoff frontmatter schema
- docs/specs/work-lifecycle.md — full work lifecycle

## Related Issues
None — no related issues found.

## Scope
Four deliverables:

1. **Graceful degradation in run-triage**: Wrap Linear MCP calls with error handling. If Linear MCP is unavailable, log a warning and proceed without Linear issues. Also, if user didn't provide an issue number, search Linear for existing issues matching the trigger keywords and let the agent pick the best match.

2. **Orchestrator status management**: When Linear integration is on, orchestrators should update Linear issue status at key pipeline stages. Set to "In Progress" at start, "In Review" before opening PR. Use Linear MCP tools (mcp__linear__updateIssue or similar).

3. **run-finish Linear completion**: When run-finish successfully merges, mark the linked Linear issue as "Done" and post a comment with the PR URL.

4. **New skill: run-create-triage**: A user-invocable skill that creates a new issue (bug report or feature request) and routes to the correct backend based on integration config — `gh issue create` for GitHub Issues, Linear MCP for Linear. Then hands off to run-triage with the created issue.
