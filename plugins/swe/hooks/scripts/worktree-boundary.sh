#!/usr/bin/env bash
# PreToolUse hook: prevents agent from navigating between worktrees
# Matches: Bash, EnterWorktree, ExitWorktree
# Exit 0 = allow, Exit 2 = block
set -euo pipefail

INPUT="$(cat)"

TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

# Block EnterWorktree and ExitWorktree unconditionally
if [ "$TOOL_NAME" = "EnterWorktree" ] || [ "$TOOL_NAME" = "ExitWorktree" ]; then
  echo "Worktree navigation is a user action. Stop and instruct the user to open a new terminal session in the worktree." >&2
  exit 2
fi

# Only inspect Bash commands
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"
[ -n "$COMMAND" ] || exit 0

# Block cd into .worktrees/ paths
if echo "$COMMAND" | grep -qE '\bcd\s+[^;|&]*\.worktrees/'; then
  echo "Worktree navigation is a user action. Stop and instruct the user to open a new terminal session in the worktree." >&2
  exit 2
fi

exit 0
