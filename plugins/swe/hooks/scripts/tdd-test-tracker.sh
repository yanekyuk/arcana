#!/usr/bin/env bash
# PostToolUse hook: tracks test execution for TDD state machine
# Matches: Bash
# Paired with tdd-test-first.sh (PreToolUse)
#
# When a Bash command looks like a test execution, transitions state
# from "test-written" to "test-run"
set -euo pipefail

INPUT="$(cat)"

TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"
[ "$TOOL_NAME" = "Bash" ] || exit 0

STATE_DIR="${CLAUDE_PLUGIN_DATA:-/tmp}"
STATE_FILE="$STATE_DIR/tdd-state-${CLAUDE_SESSION_ID:-$$}"

# Only act if we're in test-written state
[ -f "$STATE_FILE" ] || exit 0
CURRENT_STATE="$(cat "$STATE_FILE")"
[ "$CURRENT_STATE" = "test-written" ] || exit 0

COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"
[ -n "$COMMAND" ] || exit 0

# Detect test runner commands
if echo "$COMMAND" | grep -qE '(npm\s+test|npx\s+(jest|vitest|mocha)|bun\s+test|yarn\s+test|pytest|python\s+-m\s+(pytest|unittest)|go\s+test|cargo\s+test|make\s+test|\.test\.|\.spec\.)'; then
  echo "test-run" > "$STATE_FILE"
fi

exit 0
