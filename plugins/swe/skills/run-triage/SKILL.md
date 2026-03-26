---
name: run-triage
description: "Use when starting new work — explores codebase, classifies as feat/fix/refactor/docs, creates branch + worktree + handoff artifact"
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
test -f docs/swe-config.json && echo "CONFIG FOUND" || echo "CONFIG MISSING"
```

If `docs/swe-config.json` does not exist, stop immediately and tell the user:

> No project config found. Run `/run-setup` in the target project first.

Do NOT proceed with any further steps.

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

Compose the handoff content as a string (do not write it to a file):

```yaml
---
trigger: "<original user request>"
type: <feat|fix|refactor|docs>
branch: <type>/<short-description>
created: <YYYY-MM-DD>
version-bump: <major|minor|patch|none>  # optional — overrides the orchestrator's default semver bump
---

## Related Files
<list of files discovered in step 2>

## Relevant Docs
<list of matched docs/ paths, or "None — knowledge base does not cover this area yet.">

## Scope
<summary of what needs to be done and why>
```

Then pipe the handoff content into the setup-worktree script via a **single Bash call**. The script creates the branch, worktree, writes the handoff, and commits it in one operation. This reduces 3 permission prompts (branch, write, commit) to 1.

Combine path resolution and invocation into one command:

```bash
SCRIPT="./plugins/swe/scripts/setup-worktree.sh"
if [ ! -f "$SCRIPT" ]; then
  SCRIPT="$(find ~/.claude/plugins/cache/arcana/swe -name setup-worktree.sh 2>/dev/null | head -1)"
fi
cat <<'HANDOFF' | bash "$SCRIPT" "<type>/<short-description>" "<type>-<short-description>" "chore: add handoff artifact for <type>/<short-description>"
<handoff content here>
HANDOFF
```

## Step 9: Instruct the user

Tell the user:

> Worktree ready. Run `cd .worktrees/<folder>` and start a new Claude session. Then run `/run-start` to begin.
