---
name: run-open-pr
description: "Use to finalize work — commits remaining changes, pushes branch, opens a PR with conventional title and structured body"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Bash, Grep
---

# Open PR

You are finalizing work and opening a pull request.

## Step 1: Stage and commit any remaining changes

```bash
git status
```

If there are unstaged changes, review `git status` output first. Do NOT stage files matching `.env`, `credentials*`, `*.key`, or other sensitive patterns. Stage specific files:
```bash
git add <specific-changed-files>
git commit -m "<type>: <final changes description>"
```

Use [Conventional Commits](https://www.conventionalcommits.org/) format. Valid types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `style`, `build`. The `<type>` should match the handoff classification.

## Step 2: Push

```bash
git push -u origin HEAD
```

If push fails, retry once. If still failing, report the error and stop.

## Step 3: Determine PR content

Read `.claude/handoff.md` for trigger and scope context.

**Title format:** `<type>: <short description>` where type comes from the handoff `type` field.

**Body:** Use this template:

```markdown
## Summary
<What changed and why, derived from handoff scope>

## Changes
<Bulleted list of key changes>

## Test Plan
<How this was tested — list test files and what they cover>

## Knowledge Warnings
<Any clash-check warnings from the pipeline, or "None">
```

If `run-sync-docs` detected that `CLAUDE.md` might need updating, add a section:

```markdown
## Recommended CLAUDE.md Updates
<Suggested changes for human review>
```

## Step 4: Create PR

```bash
gh pr create --title "<title>" --body "<body>" --base main
```

Target the repository's default branch (typically `main`).

If this is a WIP (pipeline stopped early), use:
```bash
gh pr create --title "[WIP] <title>" --body "<body>" --base main --draft
```

Report the PR URL when done.
