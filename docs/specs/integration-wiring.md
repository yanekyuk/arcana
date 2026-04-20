---
title: "Integration Wiring"
type: spec
tags: [integrations, coderabbit, linear, github-issues, auto-docs, context7, orchestrator, triage, open-pr, finish, setup, create-triage, graceful-degradation, milestones, version-sync]
created: 2026-03-27
updated: 2026-04-20
---

## Behavior

Integration toggles in `docs/ritual-config.json` control optional pipeline behaviors across skills and orchestrators. Each toggle gates specific functionality that is skipped when the integration is disabled.

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

**Context7 tool guidance (eager):** When `integrations.context7` is true, orchestrators and the `run-tdd` skill MUST proactively use Context7 MCP tools (`mcp__context7__resolve-library-id`, `mcp__context7__get-library-docs`) to fetch documentation for any language, library, or framework encountered in the work. The guidance is directive, not advisory. Specific requirements:

- **Proactive, not reactive** -- Resolve and fetch docs for detected dependencies at the start of relevant steps, not only when an attempt has already failed.
- **Multi-stage coverage** -- Eager lookups apply across pipeline stages where library or framework knowledge matters: fetching knowledge docs (when fetched docs reference external libraries), knowledge alignment (when specs mention specific versions), investigation (for fix orchestrator), implementation/TDD, refactoring, and documentation writing.
- **Version-aware** -- When a project pins a language, runtime, or package manager version (e.g., via `stack.*` in `docs/ritual-config.json` or lockfiles), pass version information to `mcp__context7__get-library-docs` via the `topic` parameter or select version-specific library IDs from `mcp__context7__resolve-library-id` results.
- **Broad scope** -- Covers not just third-party libraries but also languages (e.g., TypeScript syntax), frameworks (e.g., Next.js, Django), runtimes (e.g., Node.js, Bun), and CLI tools relevant to the work.
- **Prefer Context7 over web search** -- When a library, framework, or language is involved, prefer Context7 lookups over web search or training-data recall.
- **Directive language** -- Skill and agent prompts use "MUST look up" rather than "you may use" to reinforce the eager behavior.

When `integrations.context7` is false, Context7 guidance is omitted and orchestrators rely on training data and other references.

**Linear status management:** When `integrations.linear` is true and the handoff contains a `linear-issue` frontmatter field, orchestrators update the Linear issue status at two pipeline stages:
- **After config load:** Set to "In Progress" via `mcp__linear__updateIssue`
- **Before opening PR:** Set to "In Review" via `mcp__linear__updateIssue`

All Linear MCP calls are wrapped in error handling -- failures log a warning but never block the pipeline.

### Triage Wiring (run-triage)

After classification (Step 5), if integrations are configured:

- **githubIssues:** Search GitHub Issues via `gh issue list --search "<query>"` for related issues. Include matches in handoff.
- **linear:** Search Linear via MCP tools (`mcp__linear__searchIssues`) for related issues. Include matches in handoff. If the user provided a specific Linear issue ID, fetch it directly via `mcp__linear__getIssue`. If no issue number was provided, search by trigger keywords and pick the best match. All Linear MCP calls use graceful degradation -- failures log a warning and the pipeline continues without Linear data.

The handoff template gains a "Related Issues" section listing any discovered issues. When a Linear issue is matched, its identifier is stored in the `linear-issue` frontmatter field for downstream use by orchestrators and run-finish.

### Open PR Wiring (run-open-pr)

Before PR creation:

- **githubIssues:** If handoff contains related GitHub issue numbers, add `Closes #N` lines to PR body.
- **linear:** If handoff contains Linear issue refs, add Linear issue links to PR body.
- **coderabbit:** Add a note to PR body that CodeRabbit review has been requested.

### Finish Wiring (run-finish)

Before approving merge:

- **coderabbit:** Check CodeRabbit review status via `gh pr reviews <pr-number>`. If CodeRabbit has not approved, warn the user before proceeding.

After successful merge:

- **linear:** If the PR references a Linear issue (from the PR body or handoff `linear-issue` field), mark the issue as "Done" via `mcp__linear__updateIssue` and post a comment with the PR URL via `mcp__linear__createComment`. Wrapped in error handling -- failures log a warning but do not block cleanup.

### Milestone Wiring

GitHub milestones enable version-targeted development. When a milestone title is a valid semver string (e.g., `0.10.0`), it acts as a target version for all PRs assigned to it.

**Triage (run-triage):** After issue search (Step 5b), if `integrations.githubIssues` is true, search for open milestones via `gh api`. Present them to the user and allow assignment. If assigned, store the milestone title in the `milestone` handoff frontmatter field.

**Create-Triage (run-create-triage):** After issue creation, offer to assign the issue to an existing milestone or create a new one. New milestones are created via `gh api repos/:owner/:repo/milestones -X POST`.

**Open PR (run-open-pr):** After PR creation, if the handoff contains a `milestone` field, look up the milestone number by title and assign it to the PR via `gh api repos/:owner/:repo/issues/<pr-number> -X PATCH`.

**Finish (run-finish):** During version bumping (Step 5), check the PR's milestone. If the milestone title is a valid semver string:
- Compare the current version against the milestone target version
- If current < target: set the version directly to the milestone target (skip standard increment)
- If current >= target: fall through to standard bump logic (the milestone version has already been reached)

This ensures multiple features within the same milestone all converge to the target version. The first feature to merge bumps the version to the target; subsequent features in the same milestone see that the target is already reached and use standard incrementing.

### Create-Triage Wiring (run-create-triage)

A user-invocable skill that creates issues and routes to the correct backend:

- **githubIssues:** Creates via `gh issue create` with appropriate labels.
- **linear:** Creates via `mcp__linear__createIssue`. Falls back to GitHub Issues if Linear MCP is unavailable and `githubIssues` is also enabled.
- If both backends are enabled, the user chooses which to use.
- After creation, hands off to run-triage with the new issue reference.

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
4. All 4 orchestrators and the `run-tdd` skill include eager, directive Context7 tool guidance when `integrations.context7` is true, covering languages, libraries, frameworks, and runtimes at all relevant pipeline stages
5. `run-triage` searches GitHub Issues and/or Linear when enabled
6. `run-triage` handoff template includes "Related Issues" section
7. `run-open-pr` adds issue closing refs and CodeRabbit notes when enabled
8. `run-finish` checks CodeRabbit review status when enabled
9. All 4 orchestrators update Linear issue status ("In Progress" at start, "In Review" before PR) when `linear-issue` is present
10. `run-triage` gracefully handles Linear MCP unavailability (logs warning, continues)
11. `run-triage` searches Linear by keywords when no issue number is provided
12. `run-finish` marks Linear issue as "Done" and posts PR URL comment after merge
13. `run-create-triage` creates issues via GitHub Issues or Linear and hands off to run-triage
14. All Linear MCP calls across all skills and orchestrators use graceful degradation
15. `run-triage` offers milestone assignment when `githubIssues` is enabled, storing the milestone title in handoff frontmatter
16. `run-create-triage` offers milestone creation and issue-to-milestone assignment when `githubIssues` is enabled
17. `run-open-pr` assigns the PR to the handoff's milestone after PR creation
18. `run-finish` checks the PR milestone for a semver target version and bumps to it when current version < target, falling through to standard bump when already at or past the target
