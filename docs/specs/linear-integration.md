---
title: "Linear Integration"
type: spec
tags: [linear, integration, triage, orchestrator, finish, graceful-degradation, status, create-triage]
created: 2026-03-27
updated: 2026-03-27
---

## Behavior

Deep Linear integration across the SWE plugin pipeline: graceful degradation when Linear MCP is unavailable, issue status management through orchestrator lifecycle, completion on merge, and a new skill for creating and routing issues.

### 1. Graceful Degradation in run-triage

When `integrations.linear` is true, run-triage wraps all Linear MCP calls in error handling:

- If Linear MCP tools are unavailable or return errors, log a warning (e.g., "Linear MCP unavailable -- proceeding without Linear issues") and continue the triage pipeline without Linear data.
- If the user did not provide an issue number, search Linear for existing issues matching trigger keywords using `mcp__linear__searchIssues`. Present matches and let the agent pick the best match (or none if no good match).
- If the user provided an issue number, fetch it directly.

### 2. Orchestrator Status Management

When `integrations.linear` is true and the handoff contains a Linear issue reference (`linear-issue` frontmatter field):

- **Pipeline start (after config load):** Update Linear issue status to "In Progress" using `mcp__linear__updateIssue` with `stateId` for the "In Progress" state. Wrap in error handling -- log warning on failure but do not block the pipeline.
- **Before opening PR (after self-review/arch-check pass):** Update Linear issue status to "In Review". Same error handling.

All four orchestrators (feat, fix, refactor, docs) include this behavior.

### 3. run-finish Linear Completion

When `integrations.linear` is true and the merged PR references a Linear issue:

- After successful merge, update the Linear issue status to "Done" using `mcp__linear__updateIssue`.
- Post a comment on the Linear issue with the merged PR URL using `mcp__linear__createComment`.
- Wrap in error handling -- log warning on failure but do not block the finish pipeline.

### 4. New Skill: run-create-triage

A user-invocable skill that creates a new issue and routes to the correct backend:

- Asks the user for issue type (bug report or feature request) and details.
- Routes based on `integrations` config:
  - If `githubIssues` is true: creates via `gh issue create`
  - If `linear` is true: creates via Linear MCP tools (`mcp__linear__createIssue`)
  - If both are true: asks user which backend to use
  - If neither is true: warns and exits
- After successful creation, hands off to run-triage with the created issue reference.

### Handoff Frontmatter Extension

The handoff artifact gains an optional `linear-issue` field containing the Linear issue identifier (e.g., `ENG-123`). This is set by run-triage when a Linear issue is matched and used by orchestrators and run-finish for status updates.

## Constraints

- All Linear MCP calls must be wrapped in error handling -- Linear unavailability must never block the pipeline
- Linear status state IDs are team-specific; use semantic state names where possible or document that `mcp__linear__updateIssue` accepts state name resolution
- The `linear-issue` frontmatter field is optional -- its absence means no Linear status management
- run-create-triage must work when only one issue backend is enabled
- Integration behavior is always gated on the corresponding `integrations.*` flag

## Acceptance Criteria

1. run-triage gracefully handles Linear MCP unavailability (logs warning, continues)
2. run-triage searches Linear for matching issues when no issue number is provided
3. All four orchestrators set Linear issue to "In Progress" at pipeline start
4. All four orchestrators set Linear issue to "In Review" before opening PR
5. run-finish marks Linear issue as "Done" after successful merge
6. run-finish posts a comment with PR URL on the Linear issue
7. run-create-triage creates issues via GitHub Issues or Linear based on config
8. run-create-triage hands off to run-triage after issue creation
9. All Linear MCP calls are wrapped in error handling with warning logs
10. Handoff frontmatter supports optional `linear-issue` field
