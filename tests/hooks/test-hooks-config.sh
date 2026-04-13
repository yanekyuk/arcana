#!/usr/bin/env bash
# Tests for hooks.json configuration and plugin.json integration
#
# Hypothesis: hooks.json fails validation because Claude Code expects a record
# keyed by event name (e.g. {"hooks": {"PreToolUse": [...]}}), not an array
# (e.g. {"hooks": [...]}).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SCRIPT_DIR/../.."
HOOKS_JSON="$ROOT/plugins/ritual/hooks/hooks.json"
PLUGIN_JSON="$ROOT/plugins/ritual/.claude-plugin/plugin.json"
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

# --- Basic validity ---

assert_true "hooks.json is valid JSON" jq empty "$HOOKS_JSON"
assert_true "plugin.json is valid JSON" jq empty "$PLUGIN_JSON"

HOOKS_PATH="$(jq -r '.hooks' "$PLUGIN_JSON")"
assert_eq "plugin.json has hooks field" "./hooks/hooks.json" "$HOOKS_PATH"

# --- Record-based format validation ---

# .hooks must be an object (record), not an array
HOOKS_TYPE="$(jq -r '.hooks | type' "$HOOKS_JSON")"
assert_eq "hooks is a record (object), not array" "object" "$HOOKS_TYPE"

# Expected event keys
for EVENT in PreToolUse PostToolUse SubagentStop SessionEnd; do
  HAS_KEY="$(jq --arg e "$EVENT" 'has("hooks") and (.hooks | has($e))' "$HOOKS_JSON")"
  assert_eq "hooks has event key '$EVENT'" "true" "$HAS_KEY"
done

# Each event key maps to an array of rule objects
for EVENT in PreToolUse PostToolUse SubagentStop SessionEnd; do
  EVENT_TYPE="$(jq -r --arg e "$EVENT" '.hooks[$e] | type' "$HOOKS_JSON")"
  assert_eq "hooks.$EVENT is an array" "array" "$EVENT_TYPE"
done

# Each rule object has a nested hooks array with type+command entries
TOTAL_COMMANDS=0
for EVENT in PreToolUse PostToolUse SubagentStop SessionEnd; do
  RULE_COUNT="$(jq --arg e "$EVENT" '.hooks[$e] | length' "$HOOKS_JSON")"
  for i in $(seq 0 $((RULE_COUNT - 1))); do
    # Rule must have a hooks array
    INNER_TYPE="$(jq -r --arg e "$EVENT" --argjson i "$i" '.hooks[$e][$i].hooks | type' "$HOOKS_JSON")"
    assert_eq "hooks.$EVENT[$i].hooks is an array" "array" "$INNER_TYPE"

    # Each inner hook must have type=command and a command field
    INNER_COUNT="$(jq --arg e "$EVENT" --argjson i "$i" '.hooks[$e][$i].hooks | length' "$HOOKS_JSON")"
    for j in $(seq 0 $((INNER_COUNT - 1))); do
      H_TYPE="$(jq -r --arg e "$EVENT" --argjson i "$i" --argjson j "$j" '.hooks[$e][$i].hooks[$j].type' "$HOOKS_JSON")"
      H_CMD="$(jq -r --arg e "$EVENT" --argjson i "$i" --argjson j "$j" '.hooks[$e][$i].hooks[$j].command' "$HOOKS_JSON")"

      assert_eq "hooks.$EVENT[$i].hooks[$j].type is command" "command" "$H_TYPE"
      assert_true "hooks.$EVENT[$i].hooks[$j].command is non-empty" [ -n "$H_CMD" ]

      # Script file exists and is executable
      SCRIPT_PATH="$ROOT/plugins/ritual/hooks/$H_CMD"
      assert_true "script exists: $H_CMD" [ -f "$SCRIPT_PATH" ]
      assert_true "script is executable: $H_CMD" [ -x "$SCRIPT_PATH" ]

      TOTAL_COMMANDS=$((TOTAL_COMMANDS + 1))
    done
  done
done

assert_eq "total hook commands across all events" "7" "$TOTAL_COMMANDS"

# --- Matcher validation ---

# PreToolUse rules: sensitive-file-blocker(Bash), commit-msg-validator(Bash),
#   worktree-boundary(Bash|EnterWorktree|ExitWorktree), tdd-test-first(Write|Edit)
HAS_BASH_MATCHER="$(jq '[.hooks.PreToolUse[].matcher] | any(. == "Bash")' "$HOOKS_JSON")"
assert_eq "PreToolUse has Bash matcher" "true" "$HAS_BASH_MATCHER"

HAS_WRITE_EDIT_MATCHER="$(jq '[.hooks.PreToolUse[].matcher] | any(. == "Write|Edit")' "$HOOKS_JSON")"
assert_eq "PreToolUse has Write|Edit matcher" "true" "$HAS_WRITE_EDIT_MATCHER"

# SessionEnd has no matcher (applies to all)
SESSION_MATCHER="$(jq -r '.hooks.SessionEnd[0].matcher // "null"' "$HOOKS_JSON")"
assert_eq "SessionEnd rule has no matcher" "null" "$SESSION_MATCHER"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
