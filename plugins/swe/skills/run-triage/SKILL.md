---
name: run-triage
description: "Use when starting new work — explores codebase, classifies as feat/fix/refactor/docs, creates branch + worktree + handoff artifact"
user-invocable: true
disable-model-invocation: true
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

## Step 2: Understand the trigger

The user has provided a ticket, idea, or bug report. Read it carefully. Ask NO clarifying questions — work with what you have.

## Step 3: Explore related code

- Use Grep and Glob to find files related to the trigger
- Read the most relevant files (max 5)
- Check recent git history: `git log --oneline -20`

## Step 4: Fetch relevant knowledge docs

If `docs/` exists, scan for relevant docs:

1. Extract keywords from the trigger and related file paths
2. Exclude noise: src, lib, utils, helpers, index, test, tests, __tests__, dist, build
3. Normalize: lowercase, split on hyphens and camelCase
4. Grep `docs/` frontmatter `tags` for matches
5. Read the top 5 matching docs. If more than 5 match, log the skipped doc paths for transparency.

## Step 5: Propose classification

Based on your exploration, propose one of:
- **feat** — new functionality
- **fix** — bug fix
- **refactor** — restructuring without behavior change
- **docs** — documentation only

Present your reasoning and **wait for the user to confirm or override**.

## Step 6: Determine branch name

After user confirms the classification:

1. Determine a short kebab-case description (2-4 words max)
2. Check for collisions:
   ```bash
   git branch --list <type>/<short-description> | grep -q . && echo "BRANCH EXISTS" || echo "OK"
   test -d .worktrees/<type>-<short-description> && echo "WORKTREE EXISTS" || echo "OK"
   ```
   If branch or worktree already exists, offer the user two options: resume the existing worktree, or create with a numeric suffix (e.g., `feat/user-auth-2`).

## Step 7: Create branch and worktree

```bash
git branch <type>/<short-description>
mkdir -p .worktrees
git worktree add .worktrees/<type>-<short-description> <type>/<short-description>
```

## Step 8: Write handoff artifact, commit, and instruct

Write the handoff directly into the worktree at `.worktrees/<folder>/.claude/handoff.md` using the Write tool. Do **not** run `mkdir -p` for the `.claude/` directory — the Write tool creates parent directories automatically:

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

Then commit:

```bash
git -C .worktrees/<folder> add -f .claude/handoff.md
git -C .worktrees/<folder> commit -m "chore: add handoff artifact for <type>/<short-description>"
```

Then tell the user:

> Worktree ready. Run `cd .worktrees/<folder>` and start a new Claude session. Then run `/run-resume` to begin.
