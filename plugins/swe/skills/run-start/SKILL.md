---
name: run-start
description: "Use when entering a worktree to start work — reads handoff artifact and dispatches the matching orchestrator agent"
user-invocable: true
allowed-tools: Read, Bash, Agent
---

# Start

You are starting work in a worktree. Follow these steps exactly.

## Step 1: Validate worktree

Check that you're in a git worktree (not the main repo):

```bash
test -f .git && echo "WORKTREE" || echo "NOT_WORKTREE"
```

If NOT_WORKTREE (`.git` is a directory, not a file), tell the user: "This skill must run from a worktree, not the project root. Please cd into a worktree under .worktrees/ first."

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
