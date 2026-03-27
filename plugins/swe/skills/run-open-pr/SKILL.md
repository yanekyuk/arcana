---
name: run-open-pr
description: "Use to finalize work — commits remaining changes, pushes branch, opens a PR with conventional title and structured body"
user-invocable: false
allowed-tools: Read, Bash, Grep
---

# Open PR

You are finalizing work and opening a pull request.

## Step 0: Load integration config

Read `docs/swe-config.json` and extract the `integrations` object. Store these flags for use in later steps:
- `integrations.githubIssues` → add `Closes #N` lines to PR body
- `integrations.linear` → add Linear issue refs to PR body
- `integrations.coderabbit` → add CodeRabbit review-requested note to PR body

If the config file does not exist, proceed without integration features.

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

Read `.claude/handoff.md` for trigger and scope context. Extract the `base-branch` field from the frontmatter — this is the branch the PR should target. If `base-branch` is not present, default to `main`.

**If `.claude/handoff.md` does not exist** (e.g., it was already `git rm`'d by the orchestrator pipeline), derive context from git instead:
- Run `git log --oneline main..HEAD` to understand the commit history
- Run `git diff main...HEAD --stat` to see which files changed
- Infer the work type from commit prefixes (feat/fix/refactor/docs)
- Build the PR title and body from the commit messages and diff summary
- Use `main` as the base branch (handoff is unavailable to determine the original base)

**Title format:** `<type>: <short description>` where type comes from the handoff `type` field (or inferred from commits if handoff is missing).

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

**Integration-driven sections (add these when the corresponding integration is enabled):**

If `integrations.githubIssues` is true and the handoff (or Related Issues section) contains GitHub issue numbers:
```markdown
## Closes
Closes #<issue-number>
```
Add one `Closes #N` line per related GitHub issue. GitHub will automatically link and close these issues when the PR is merged.

If `integrations.linear` is true and the handoff contains Linear issue references:
```markdown
## Linear Issues
- <LINEAR-ID>: <issue title>
```

If `integrations.coderabbit` is true:
```markdown
## Review
CodeRabbit review has been requested for this PR.
```

If `run-sync-docs` detected that `CLAUDE.md` might need updating, add a section:

```markdown
## Recommended CLAUDE.md Updates
<Suggested changes for human review>
```

## Step 4: Create PR

```bash
gh pr create --title "<title>" --body "<body>" --base <base-branch>
```

Use the `base-branch` value extracted from the handoff frontmatter in Step 3. If no `base-branch` was found (handoff missing or field absent), use `main`.

If this is a WIP (pipeline stopped early), use:
```bash
gh pr create --title "[WIP] <title>" --body "<body>" --base <base-branch> --draft
```

Report the PR URL when done.
