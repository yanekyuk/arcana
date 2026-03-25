---
name: run-triage
description: "Use when starting new work — explores codebase, classifies as feat/fix/refactor/docs, creates branch + worktree + handoff artifact"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Write, Agent
---

# Triage

You are triaging a new piece of work. Follow these steps exactly.

## Step 1: Understand the trigger

The user has provided a ticket, idea, or bug report. Read it carefully. Ask NO clarifying questions — work with what you have.

## Step 2: Explore related code

- Use Grep and Glob to find files related to the trigger
- Read the most relevant files (max 5)
- Check recent git history: `git log --oneline -20`

## Step 3: Fetch relevant knowledge docs

If `.claude/docs/` exists, scan for relevant docs:

1. Extract keywords from the trigger and related file paths
2. Exclude noise: src, lib, utils, helpers, index, test, tests, __tests__, dist, build
3. Normalize: lowercase, split on hyphens and camelCase
4. Grep `.claude/docs/` frontmatter `tags` for matches
5. Read the top 5 matching docs. If more than 5 match, log the skipped doc paths for transparency.

## Step 4: Propose classification

Based on your exploration, propose one of:
- **feat** — new functionality
- **fix** — bug fix
- **refactor** — restructuring without behavior change
- **docs** — documentation only

Present your reasoning and **wait for the user to confirm or override**.

## Step 5: Determine branch name

After user confirms the classification:

1. Determine a short kebab-case description (2-4 words max)
2. Check for collisions:
   ```bash
   git branch --list <type>/<short-description>
   test -d .worktrees/<type>-<short-description>
   ```
   If branch or worktree already exists, offer the user two options: resume the existing worktree, or create with a numeric suffix (e.g., `feat/user-auth-2`).

## Step 6: Write handoff artifact

Write the handoff to the **project root** so it can be reviewed before the worktree exists.

First, check for a leftover handoff from a previous triage:

```bash
test -f .claude/handoff.md && echo "EXISTS" || echo "OK"
```

If EXISTS, warn the user: "A `.claude/handoff.md` already exists in the project root (likely from an interrupted triage). Overwrite it?" Wait for confirmation before proceeding.

```bash
mkdir -p .claude
```

Write to `.claude/handoff.md`:

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
<list of matched .claude/docs/ paths, or "None — knowledge base does not cover this area yet.">

## Scope
<summary of what needs to be done and why>
```

## Step 7: Create branch and worktree

```bash
git branch <type>/<short-description>
mkdir -p .worktrees
git worktree add .worktrees/<type>-<short-description> <type>/<short-description>
```

**Note:** `.claude/handoff.md` in the project root is transient — it exists only until Step 8 moves it into the worktree. If Step 7 fails, clean up manually: `rm .claude/handoff.md`.

## Step 8: Move handoff into worktree, commit, and instruct

Move the handoff artifact from the project root into the worktree and clean up:

```bash
mkdir -p .worktrees/<folder>/.claude
mv .claude/handoff.md .worktrees/<folder>/.claude/handoff.md
cd .worktrees/<folder>
git add .claude/handoff.md
git commit -m "chore: add handoff artifact for <type>/<short-description>"
```

Then tell the user:

> Worktree ready. Run `cd .worktrees/<folder>` and start a new Claude session. Then run `/run-resume` to begin.
