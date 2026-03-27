---
title: "Integration Wiring"
type: spec
tags: [integrations, coderabbit, linear, github-issues, auto-docs, context7, orchestrator, triage, open-pr, finish, setup]
created: 2026-03-27
updated: 2026-03-27
---

## Behavior

Integration toggles in `docs/swe-config.json` control optional pipeline behaviors across skills and orchestrators. Each toggle gates specific functionality that is skipped when the integration is disabled.

### Integration Toggles

| Key | Default | Description |
|---|---|---|
| `coderabbit` | false | CodeRabbit AI review integration |
| `linear` | false | Linear issue tracker integration |
| `githubIssues` | true | GitHub Issues integration |
| `autoDocs` | true | Automatic documentation sync |
| `context7` | false | Context7 library documentation lookups |

### Prerequisite Verification (run-setup)

When an integration is enabled during setup, `run-setup` verifies prerequisites:

| Integration | Prerequisite Check |
|---|---|
| `githubIssues` | Verify `gh` CLI is available (`which gh`) |
| `coderabbit` | Advisory: remind user to install the CodeRabbit GitHub App |
| `linear` | Check for Linear MCP server; suggest installation if missing |
| `context7` | Check for Context7 MCP server; suggest installation if missing |
| `autoDocs` | No prerequisite (built-in behavior) |

### Orchestrator Wiring (feat/fix/refactor/docs)

**Config loading (Step 2):** All orchestrators store `integrations.*` flags from config alongside stack and architecture values.

**Sync-docs gating:** The sync-docs step is gated on `integrations.autoDocs`. When false, the step is skipped entirely with a log message.

**Context7 tool guidance:** When `integrations.context7` is true, implementation steps include guidance to use Context7 MCP tools (`mcp__context7__resolve-library-id`, `mcp__context7__get-library-docs`) for looking up library documentation during coding.

### Triage Wiring (run-triage)

After classification (Step 5), if integrations are configured:

- **githubIssues:** Search GitHub Issues via `gh issue list --search "<query>"` for related issues. Include matches in handoff.
- **linear:** Search Linear via MCP tools (`mcp__linear__searchIssues`) for related issues. Include matches in handoff.

The handoff template gains a "Related Issues" section listing any discovered issues.

### Open PR Wiring (run-open-pr)

Before PR creation:

- **githubIssues:** If handoff contains related GitHub issue numbers, add `Closes #N` lines to PR body.
- **linear:** If handoff contains Linear issue refs, add Linear issue links to PR body.
- **coderabbit:** Add a note to PR body that CodeRabbit review has been requested.

### Finish Wiring (run-finish)

Before approving merge:

- **coderabbit:** Check CodeRabbit review status via `gh pr reviews <pr-number>`. If CodeRabbit has not approved, warn the user before proceeding.

## Constraints

- Integration flags are always booleans in the config
- Missing integration keys default to false (except githubIssues and autoDocs which default to true for backward compatibility)
- Prerequisite verification is advisory, not blocking -- setup warns but does not prevent enabling
- Integration wiring must not break pipeline flow when the integration is disabled
- MCP tool references (Linear, Context7) are guidance only -- tools may not be available at runtime

## Acceptance Criteria

1. `run-setup` offers 5 integration toggles including context7
2. `run-setup` verifies prerequisites for each enabled integration
3. All 4 orchestrators gate sync-docs on `integrations.autoDocs`
4. All 4 orchestrators include Context7 tool guidance when `integrations.context7` is true
5. `run-triage` searches GitHub Issues and/or Linear when enabled
6. `run-triage` handoff template includes "Related Issues" section
7. `run-open-pr` adds issue closing refs and CodeRabbit notes when enabled
8. `run-finish` checks CodeRabbit review status when enabled
9. All 3 existing specs are updated to reflect integration wiring
