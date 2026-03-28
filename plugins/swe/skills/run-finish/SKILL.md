---
name: run-finish
description: "Use after a PR is opened — reviews the PR, suggests changes or merges to main, then cleans up worktree and branches"
user-invocable: true
allowed-tools: Read, Bash, Grep
---

# Finish

You are reviewing and completing a PR lifecycle. This skill runs from the **main session** (project root, not a worktree) after an orchestrator has opened a PR.

## Prerequisites

**Directives:** If `docs/swe-config.json` exists, read `directives.delivery` from the config. These are soft guidelines that influence review standards and merge preferences. Apply them during PR review and merge decisions. If the field is missing or empty, proceed without directives.

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

## Step 3f: CodeRabbit review check

Read `docs/swe-config.json` and check if `integrations.coderabbit` is true.

If enabled, check CodeRabbit's review status on this PR:

```bash
gh pr reviews <number> --json author,state
```

Look for a review from CodeRabbit (author containing "coderabbit"). Evaluate the result:

- **If CodeRabbit has approved:** Proceed normally to Step 4.
- **If CodeRabbit has requested changes:** Include CodeRabbit's review comments in the review report. Present them to the user alongside your own review findings.
- **If CodeRabbit has not reviewed yet:** Warn the user: "CodeRabbit review is pending. You may want to wait for it before merging." Proceed to Step 4 — do not block the pipeline.

If `integrations.coderabbit` is false or the config file does not exist, skip this check.

## Step 4: Deliver verdict

### If changes are needed:

Present a structured review using the template below. **You MUST fill in the Suggested Fix Prompt section with a concrete, actionable prompt.** Do not leave it blank, do not use a generic placeholder, and do not simply restate the issue list. The prompt must be a ready-to-paste instruction that tells the developer exactly what to change, in which files, and how.

```
## PR Review: <PR title>

### Issues Found
1. <issue description>
2. <issue description>

### Suggested Fix Prompt

Copy and paste the following into your orchestrator session (in the worktree):

> <GENERATE A CONCRETE PROMPT HERE — see rules below>
```

**Prompt generation rules** (mandatory):
- The prompt MUST be a single, self-contained instruction that can be copy-pasted verbatim into a Claude session.
- It MUST reference the specific file(s) and line(s) or section(s) that need to change.
- It MUST describe the expected change (e.g., "rename X to Y", "remove the debug line at line 42", "add a guard clause for null input in function Z").
- It MUST NOT simply repeat the issues list — it should synthesize the issues into one clear fix instruction.
- Format it as a direct imperative (e.g., "In `src/api.ts`, fix the error handler on line 35 to return a 401 instead of 500 when the token is expired, and remove the `console.log` on line 22.").

Then tell the user:

> Fix the issues above, then run `/run-finish` again to re-review.

**Stop here.** Do not merge or clean up.

### If PR looks good:

Tell the user the PR passes review, then proceed to Step 5.

## Step 4b: Check Linear issue reference

Read `docs/swe-config.json` and check if `integrations.linear` is true.

If enabled, check the PR body and branch commits for a Linear issue reference. Linear issue IDs typically appear in the PR body under "Linear Issues" or in the handoff frontmatter (`linear-issue` field). Record the Linear issue ID if found — it will be used in Step 5b.

If `integrations.linear` is false or the config file does not exist, skip this check.

## Step 5: Merge

Ask the user for merge strategy preference (merge commit or squash). If the user has already expressed a preference, use it. Default to merge commit if not specified.

```bash
gh pr merge <number> --merge
```

Or with squash:

```bash
gh pr merge <number> --squash
```

Do **not** pass `--delete-branch` — the worktree still holds the branch at this point, so `gh` would exit with code 1. Remote and local branch cleanup is handled in Step 6.

## Step 5b: Complete Linear issue

If `integrations.linear` is true and a Linear issue ID was found in Step 4b, update the Linear issue after successful merge. **All Linear MCP calls must be wrapped in error handling** — log a warning on failure but never block the finish pipeline.

1. **Mark as Done:** Update the Linear issue status to **"Done"** using `mcp__linear__updateIssue`.
2. **Post a comment:** Add a comment to the Linear issue with the merged PR URL using `mcp__linear__createComment`. Example comment: "Merged in PR #<number> — <pr-url>"

Graceful degradation: if either MCP call fails, log "Warning: Linear MCP unavailable — skipping Linear issue completion." and continue to Step 6.

If `integrations.linear` is false or no Linear issue was found, skip this step.

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
