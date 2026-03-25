#!/usr/bin/env bash
# Content tests for run-triage SKILL.md
# Ensures skill instructions don't conflict with worktree-boundary hook
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL="$SCRIPT_DIR/../../plugins/swe/skills/run-triage/SKILL.md"
PASS=0
FAIL=0

assert_no_match() {
  local desc="$1" pattern="$2"
  if grep -qE "$pattern" "$SKILL"; then
    echo "FAIL: $desc — found forbidden pattern in SKILL.md"
    grep -nE "$pattern" "$SKILL" | head -3
    FAIL=$((FAIL + 1))
  else
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  fi
}

assert_match() {
  local desc="$1" pattern="$2"
  if grep -qE "$pattern" "$SKILL"; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc — expected pattern not found in SKILL.md"
    FAIL=$((FAIL + 1))
  fi
}

# Step 7 code blocks must not use cd/pushd into .worktrees/
# Note: prose instructions to the user (e.g., "Run `cd .worktrees/...`") are fine;
# we only check lines that start with cd/pushd (i.e., agent-executed commands in code blocks)
assert_no_match "no cd into .worktrees/ in code blocks" '^\s*(cd|pushd)\s+[^;|&]*\.worktrees/'

# Step 7 should use git -C for worktree operations
assert_match "uses git -C for worktree git commands" 'git -C \.worktrees/'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
