---
name: run-resume
description: "Use when entering a worktree to resume work — reads handoff artifact and dispatches the matching orchestrator agent"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Bash, Agent
---

# Resume

You are resuming work in a worktree. Follow these steps exactly.

## Step 1: Validate worktree

Check that you're in a git worktree (not the main repo):

```bash
test -f .git && echo "WORKTREE" || echo "NOT_WORKTREE"
```

If NOT_WORKTREE, tell the user: "This doesn't appear to be a git worktree. Please cd into a worktree under .worktrees/ first."

## Step 2: Read handoff

Read `.claude/handoff.md` in the current directory. If it doesn't exist, tell the user: "No handoff artifact found. Run /run-triage in the project root first."

## Step 3: Dispatch orchestrator

Based on the `type` field in the handoff frontmatter, dispatch the matching orchestrator agent:

- `feat` → use the Agent tool with the `feat-orchestrator` agent
- `fix` → use the Agent tool with the `fix-orchestrator` agent
- `refactor` → use the Agent tool with the `refactor-orchestrator` agent
- `docs` → use the Agent tool with the `docs-orchestrator` agent

Pass the full handoff content as context to the agent.

The orchestrator will run autonomously to PR. Do not interfere.
