---
name: run-triage
description: "Use when starting new work — explores codebase, classifies as feat/fix/refactor/docs, creates branch + worktree + handoff artifact"
model: sonnet
effort: medium
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Write, Agent
---

# Triage

You are triaging a new piece of work. Follow these steps exactly.

## Step 1: Validate context

Confirm you are in the main repo (not a worktree):

```bash
test -f .git && echo "WORKTREE — wrong context" || echo "MAIN REPO — correct"
```

If in a worktree, tell the user: "This skill must run from the project root (main session), not from inside a worktree."

## Step 2: Load project config

Check that the target project has been configured:

```bash
test -f docs/ritual-config.json && echo "CONFIG FOUND" || echo "CONFIG MISSING"
```

If `docs/ritual-config.json` does not exist, stop immediately and tell the user:

> No project config found. Run `/run-setup` in the target project first.

Do NOT proceed with any further steps.

If the config exists, also read `directives.triage` from the config. These are soft guidelines that influence classification preferences, branch naming, and scope boundaries. Apply them throughout the triage process. If the field is missing or empty, proceed without directives.

## Step 3: Understand the trigger

The user has provided a ticket, idea, or bug report. Read it carefully. Ask NO clarifying questions — work with what you have.

## Step 4: Explore related code

- Use Grep and Glob to find files related to the trigger
- Read the most relevant files (max 5)
- Check recent git history: `git log --oneline -20`

## Step 5: Fetch relevant knowledge docs

If `docs/` exists, scan for relevant docs:

1. Extract keywords from the trigger and related file paths
2. Exclude noise: src, lib, utils, helpers, index, test, tests, __tests__, dist, build
3. Normalize: lowercase, split on hyphens and camelCase
4. Grep `docs/` frontmatter `tags` for matches
5. Read the top 5 matching docs. If more than 5 match, log the skipped doc paths for transparency.

## Step 5b: Search for related issues

Read `docs/ritual-config.json` and check integration flags.

**If `integrations.githubIssues` is true:**

Search GitHub Issues for related issues using keywords from the trigger:

```bash
gh issue list --search "<keywords from trigger>" --limit 10
```

Record any relevant matches (issue number, title, state).

**If `integrations.linear` is true:**

Search Linear for related issues using Linear MCP tools. **All Linear MCP calls must be wrapped in error handling** — if the Linear MCP server is unavailable or any call fails, log a warning and continue without Linear data. Never let a Linear failure block the triage pipeline.

1. If the user provided a specific Linear issue identifier (e.g., `ENG-123`), fetch it directly using `mcp__linear__getIssue`.
2. If the user did NOT provide an issue number, search Linear for existing issues matching trigger keywords:
   - Use `mcp__linear__searchIssues` with keywords extracted from the trigger text
   - Review the returned matches and pick the best match based on title/description relevance
   - If no good match exists, proceed with no Linear issue linked
3. Record any matched issue (issue ID, title, state) for inclusion in the handoff.

**Graceful degradation pattern:**

```
Attempt Linear MCP call:
  - Success → use the result
  - Failure → log "Warning: Linear MCP unavailable — proceeding without Linear issues." and continue
```

**If neither integration is enabled**, skip this step.

Store discovered issues for inclusion in the handoff artifact (Step 8).

## Step 5c: Search for milestones

**If `integrations.githubIssues` is true:**

Search for open GitHub milestones that could be associated with this work:

```bash
gh api repos/:owner/:repo/milestones --jq '.[] | select(.state=="open") | "\(.number)\t\(.title)\t\(.description // "no description")"'
```

If milestones exist, present them to the user and ask:

> The following milestones are open:
> <list of milestones with number, title, and description>
>
> Would you like to assign this work to a milestone? If so, which one? (Enter the milestone title, or "none" to skip)

If the user selects a milestone, record its title for inclusion in the handoff frontmatter as the `milestone` field.

If no milestones exist or the user declines, proceed without a milestone.

**If `integrations.githubIssues` is false**, skip this step.

## Step 6: Propose classification

Based on your exploration, propose one of:
- **feat** — new functionality
- **fix** — bug fix
- **refactor** — restructuring without behavior change
- **docs** — documentation only

Present your reasoning and **wait for the user to confirm or override**.

## Step 7: Determine branch name

After user confirms the classification:

1. Determine a short kebab-case description (2-4 words max)
2. Check for collisions:
   ```bash
   git branch --list <type>/<short-description> | grep -q . && echo "BRANCH EXISTS" || echo "OK"
   test -d .worktrees/<type>-<short-description> && echo "WORKTREE EXISTS" || echo "OK"
   ```
   If branch or worktree already exists, offer the user two options: resume the existing worktree, or create with a numeric suffix (e.g., `feat/user-auth-2`).

## Step 8: Create branch, worktree, and handoff artifact

First, capture the current branch name — this is the branch the worktree will be derived from:

```bash
git branch --show-current
```

Store the output as `<base-branch>` for use in the handoff frontmatter below.

Compose the handoff content as a string (do not write it to a file):

```yaml
---
trigger: "<original user request>"
type: <feat|fix|refactor|docs>
branch: <type>/<short-description>
base-branch: <base-branch>
created: <YYYY-MM-DD>
version-bump: <major|minor|patch|none>  # optional — overrides the orchestrator's default semver bump
linear-issue: <LINEAR-ID>              # optional — set when a Linear issue is matched in Step 5b
milestone: <milestone-title>           # optional — set when user assigns work to a GitHub milestone in Step 5c
---

## Related Files
<list of files discovered in step 2>

## Relevant Docs
<list of matched docs/ paths, or "None — knowledge base does not cover this area yet.">

## Related Issues
<list of related issues discovered in Step 5b, or "None — no related issues found.">
Format: "- #<number> <title> (<state>)" for GitHub Issues, "- <ID> <title> (<state>)" for Linear issues.

## Scope
<summary of what needs to be done and why>
```

Then pipe the handoff content into the setup-worktree script via a **single Bash call**. The script creates the branch, worktree, writes the handoff to `docs/handoffs/<folder>.md`, and commits it in one operation. This reduces 3 permission prompts (branch, write, commit) to 1.

Combine path resolution and invocation into one command:

```bash
SCRIPT="./plugins/ritual/scripts/setup-worktree.sh"
if [ ! -f "$SCRIPT" ]; then
  SCRIPT="$(find ~/.claude/plugins/cache/arcana/ritual -name setup-worktree.sh 2>/dev/null | head -1)"
fi
cat <<'HANDOFF' | bash "$SCRIPT" "<type>/<short-description>" "<type>-<short-description>" "chore: add handoff artifact for <type>/<short-description>"
<handoff content here>
HANDOFF
```

## Step 9: Instruct the user

Tell the user:

> Worktree ready. Run `cd .worktrees/<folder>` and start a new Claude session. Then run `/run-start` to begin.
