---
name: run-create-triage
description: "Use to create a new issue (bug report or feature request) and route to the correct backend, then hand off to run-triage"
user-invocable: true
allowed-tools: Read, Bash, Write
---

# Create and Triage

You are creating a new issue and routing it to the correct issue tracker backend, then handing off to the triage pipeline. Follow these steps exactly.

## Step 1: Validate context

Confirm you are in the main repo (not a worktree):

```bash
test -f .git && echo "WORKTREE — wrong context" || echo "MAIN REPO — correct"
```

If in a worktree, tell the user: "This skill must run from the project root (main session), not from inside a worktree."

## Step 2: Load project config

Check that the target project has been configured:

```bash
test -f docs/swe-config.json && echo "CONFIG FOUND" || echo "CONFIG MISSING"
```

If `docs/swe-config.json` does not exist, stop immediately and tell the user:

> No project config found. Run `/run-setup` in the target project first.

Do NOT proceed with any further steps.

Read `docs/swe-config.json` and extract the `integrations` object. Check which issue backends are available:
- `integrations.githubIssues` — GitHub Issues via `gh` CLI
- `integrations.linear` — Linear via MCP tools

## Step 3: Determine available backends

Evaluate which backends are enabled:

- **Both enabled:** Proceed to Step 4 with both options.
- **Only `githubIssues`:** Use GitHub Issues. Skip backend selection in Step 4.
- **Only `linear`:** Use Linear. Skip backend selection in Step 4.
- **Neither enabled:** Tell the user: "No issue backend is configured. Enable `githubIssues` or `linear` in `docs/swe-config.json` (or run `/run-setup`)." Stop here.

## Step 4: Gather issue details

Ask the user:

1. **Issue type:** Bug report or feature request?
2. **Title:** A short, descriptive title for the issue.
3. **Description:** What is the issue about? For bugs: steps to reproduce, expected vs actual behavior. For features: what the feature should do and why.

If both backends are enabled, also ask:

3. **Backend:** Where should this issue be created — GitHub Issues or Linear?

Wait for the user to respond before proceeding.

## Step 5: Create the issue

### If using GitHub Issues:

```bash
gh issue create --title "<title>" --body "<description>" --label "<bug|enhancement>"
```

Use the label `bug` for bug reports, `enhancement` for feature requests. If the label does not exist, omit the `--label` flag.

Record the created issue number from the output.

### If using Linear:

Use Linear MCP tools to create the issue. **Wrap all Linear MCP calls in error handling** — if the call fails, log a warning and offer the user the option to create via GitHub Issues instead (if available).

1. Use `mcp__linear__createIssue` with:
   - `title`: the issue title
   - `description`: the issue description
2. Record the created issue identifier (e.g., `ENG-123`) from the response.

Graceful degradation: if the Linear MCP call fails and `githubIssues` is also enabled, ask the user: "Linear MCP is unavailable. Would you like to create the issue via GitHub Issues instead?" If yes, fall back to the GitHub Issues path above.

## Step 6: Confirm and hand off

Tell the user the issue was created:

> Issue created: <issue-reference> — "<title>"
>
> Handing off to `/run-triage` to classify and begin work.

Then instruct the user to run `/run-triage` with the created issue as context. For example:

> Run `/run-triage` and provide: "<issue-reference>: <title> — <description summary>"

The triage skill will take over from here — classifying the work, creating the branch and worktree, and writing the handoff artifact.
