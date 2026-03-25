#!/usr/bin/env bash
# Tests for hooks.json configuration and plugin.json integration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SCRIPT_DIR/../.."
HOOKS_JSON="$ROOT/plugins/swe/hooks/hooks.json"
PLUGIN_JSON="$ROOT/plugins/swe/.claude-plugin/plugin.json"
PASS=0
FAIL=0

assert_true() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc — expected '$expected', got '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

# hooks.json is valid JSON
assert_true "hooks.json is valid JSON" jq empty "$HOOKS_JSON"

# plugin.json is valid JSON
assert_true "plugin.json is valid JSON" jq empty "$PLUGIN_JSON"

# plugin.json has hooks field
HOOKS_PATH="$(jq -r '.hooks' "$PLUGIN_JSON")"
assert_eq "plugin.json has hooks field" "./hooks/hooks.json" "$HOOKS_PATH"

# hooks.json has 7 hooks total
HOOK_COUNT="$(jq '.hooks | length' "$HOOKS_JSON")"
assert_eq "hooks.json has 7 hooks" "7" "$HOOK_COUNT"

# Check each hook has required fields
for i in $(seq 0 6); do
  EVENT="$(jq -r ".hooks[$i].event" "$HOOKS_JSON")"
  TYPE="$(jq -r ".hooks[$i].type" "$HOOKS_JSON")"
  COMMAND="$(jq -r ".hooks[$i].command" "$HOOKS_JSON")"

  assert_true "hook $i has event" [ -n "$EVENT" ]
  assert_true "hook $i has type=command" [ "$TYPE" = "command" ]
  assert_true "hook $i has command" [ -n "$COMMAND" ]

  # Check that the script file exists
  SCRIPT_PATH="$ROOT/plugins/swe/hooks/$COMMAND"
  assert_true "hook $i script exists: $COMMAND" [ -f "$SCRIPT_PATH" ]
  assert_true "hook $i script is executable: $COMMAND" [ -x "$SCRIPT_PATH" ]
done

# Verify specific hook events
assert_eq "hook 0 event" "PreToolUse" "$(jq -r '.hooks[0].event' "$HOOKS_JSON")"
assert_eq "hook 3 event" "SubagentStop" "$(jq -r '.hooks[3].event' "$HOOKS_JSON")"
assert_eq "hook 5 event" "PostToolUse" "$(jq -r '.hooks[5].event' "$HOOKS_JSON")"
assert_eq "hook 6 event" "SessionEnd" "$(jq -r '.hooks[6].event' "$HOOKS_JSON")"

# Verify matchers
assert_eq "sensitive-file-blocker matcher" "Bash" "$(jq -r '.hooks[0].matcher' "$HOOKS_JSON")"
assert_eq "worktree-boundary matcher includes multiple tools" "Bash|EnterWorktree|ExitWorktree" "$(jq -r '.hooks[2].matcher' "$HOOKS_JSON")"
assert_eq "tdd-test-first matcher" "Write|Edit" "$(jq -r '.hooks[4].matcher' "$HOOKS_JSON")"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
