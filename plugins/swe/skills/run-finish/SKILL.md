---
name: run-finish
description: "Use after a PR is opened — reviews the PR, suggests changes or merges to main, then cleans up worktree and branches"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Bash, Grep
---

# Finish

You are reviewing and completing a PR lifecycle. This skill runs from the **main session** (project root, not a worktree) after an orchestrator has opened a PR.

## Step 1: Validate context

Confirm you are in the main repo (not a worktree):

```bash
test -f .git && echo "WORKTREE — wrong context" || echo "MAIN REPO — correct"
```

If in a worktree, tell the user: "This skill must run from the project root (main session), not from inside a worktree."

## Step 2: Identify the PR

List open PRs on this repo:

```bash
gh pr list --state open --limit 20
```

- If there is exactly one open PR, use it automatically.
- If there are multiple, present the list and ask the user which PR to review.
- If there are none, tell the user: "No open PRs found. Nothing to finish."

## Step 3: Review the PR

Fetch the PR details:

```bash
gh pr view <number> --json number,title,headRefName,body,commits,files,additions,deletions
gh pr diff <number>
```

Evaluate the following:

### 3a. Conventional Commits compliance
Check every commit message in the PR. Valid types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `style`, `build`. Each message must follow `<type>: <description>` or `<type>(<scope>): <description>`.

### 3b. Diff quality
- No debug code (`console.log`, `debugger`, `print(` used for debugging, `TODO`, `FIXME`, `HACK`)
- No commented-out code blocks
- No sensitive data (API keys, tokens, passwords)

### 3c. Scope alignment
- Read the PR body's Summary section
- Verify the diff only touches what the summary describes — flag scope creep

### 3d. Test coverage
- If the PR adds or changes behavior, check that corresponding test files are included
- For pure-config repos (no test runner), skip this check

### 3e. Version staleness
If the PR touches version files (e.g., `marketplace.json`, `plugin.json`), compare the base version in the PR diff against the current version on main:

```bash
git show main:marketplace.json 2>/dev/null | head -20
```

If the PR's base version (the `-` side of the diff) does not match main's current version, the branch needs a rebase before merging. Flag this as "needs rebase" and **stop** — do not approve or merge.

## Step 4: Deliver verdict

### If changes are needed:

Present a structured review:

```
## PR Review: <PR title>

### Issues Found
1. <issue description>
2. <issue description>

### Suggested Fix Prompt

Copy and paste the following into your orchestrator session (in the worktree):

> <ready-to-paste prompt describing exactly what to fix, formatted as an instruction>
```

Then tell the user:

> Fix the issues above, then run `/run-finish` again to re-review.

**Stop here.** Do not merge or clean up.

### If PR looks good:

Tell the user the PR passes review, then proceed to Step 5.

## Step 5: Merge

Ask the user for merge strategy preference (merge commit or squash). If the user has already expressed a preference, use it. Default to squash if not specified.

```bash
gh pr merge <number> --squash
```

Or with merge commit:

```bash
gh pr merge <number> --merge
```

Do **not** pass `--delete-branch` — the worktree still holds the branch at this point, so `gh` would exit with code 1. Remote and local branch cleanup is handled in Step 6.

## Step 6: Clean up local resources

After merge completes:

### 6a. Update main

```bash
git pull origin main
```

### 6b. Remove the worktree

Determine the worktree path from the branch name. The convention is `.worktrees/<type>-<short-description>` where the branch is `<type>/<short-description>`.

```bash
git worktree list
```

Find the worktree matching the merged branch and remove it:

```bash
git worktree remove .worktrees/<folder>
```

### 6c. Delete the remote branch

```bash
git push origin --delete <branch-name>
```

If the remote branch was already deleted, this may warn — that is fine.

### 6d. Delete the local branch

```bash
git branch -d <branch-name>
```

If the branch was already deleted by the merge, this may warn — that is fine.

## Step 7: Report completion

Tell the user:

> PR #<number> merged and cleaned up. Branch `<branch>` deleted. Worktree `.worktrees/<folder>` removed. Lifecycle complete.
