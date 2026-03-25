#!/usr/bin/env bash
# Tests for worktree-boundary.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../../plugins/swe/hooks/scripts/worktree-boundary.sh"
PASS=0
FAIL=0

assert_blocks() {
  local desc="$1" input="$2"
  if echo "$input" | bash "$HOOK" 2>/dev/null; then
    echo "FAIL: $desc — expected block (exit 2), got exit 0"
    FAIL=$((FAIL + 1))
  else
    local code=$?
    if [ "$code" -eq 2 ]; then
      echo "PASS: $desc"
      PASS=$((PASS + 1))
    else
      echo "FAIL: $desc — expected exit 2, got exit $code"
      FAIL=$((FAIL + 1))
    fi
  fi
}

assert_allows() {
  local desc="$1" input="$2"
  if echo "$input" | bash "$HOOK" 2>/dev/null; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    local code=$?
    echo "FAIL: $desc — expected exit 0, got exit $code"
    FAIL=$((FAIL + 1))
  fi
}

# Bash: blocks cd into .worktrees/
assert_blocks "blocks cd .worktrees/feat-branch" \
  '{"tool_name":"Bash","tool_input":{"command":"cd .worktrees/feat-branch"}}'

assert_blocks "blocks cd into absolute worktree path" \
  '{"tool_name":"Bash","tool_input":{"command":"cd /home/user/project/.worktrees/feat-branch && ls"}}'

assert_blocks "blocks cd .worktrees/ with subdir" \
  '{"tool_name":"Bash","tool_input":{"command":"cd .worktrees/feat-branch/src"}}'

# EnterWorktree / ExitWorktree: blocks unconditionally
assert_blocks "blocks EnterWorktree" \
  '{"tool_name":"EnterWorktree","tool_input":{"path":".worktrees/feat-branch"}}'

assert_blocks "blocks ExitWorktree" \
  '{"tool_name":"ExitWorktree","tool_input":{}}'

# Should allow normal Bash commands
assert_allows "allows git status" \
  '{"tool_name":"Bash","tool_input":{"command":"git status"}}'

assert_allows "allows cd into src" \
  '{"tool_name":"Bash","tool_input":{"command":"cd src && ls"}}'

assert_allows "allows non-Bash tool" \
  '{"tool_name":"Read","tool_input":{"file_path":"foo.txt"}}'

# Should block pushd into .worktrees/ paths
assert_blocks "blocks pushd .worktrees/feat-branch" \
  '{"tool_name":"Bash","tool_input":{"command":"pushd .worktrees/feat-branch"}}'

# Should allow commands that mention worktrees but don't cd into them
assert_allows "allows git worktree list" \
  '{"tool_name":"Bash","tool_input":{"command":"git worktree list"}}'

assert_allows "allows ls .worktrees" \
  '{"tool_name":"Bash","tool_input":{"command":"ls .worktrees/"}}'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
