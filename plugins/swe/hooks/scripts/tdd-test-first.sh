#!/usr/bin/env bash
# PreToolUse hook: enforces test-first TDD discipline
# Matches: Write, Edit
# Exit 0 = allow, Exit 2 = block
#
# State machine:
#   clean -> test-written (when a test file is written/edited)
#   test-written -> test-run (when PostToolUse detects test execution via tdd-test-tracker.sh)
#   test-run -> clean (when implementation is written)
#
# Blocks: writing/editing a non-test file while state is "test-written"
set -euo pipefail

INPUT="$(cat)"

TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"

# Only inspect Write and Edit
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

STATE_FILE="${CLAUDE_PLUGIN_DATA:-/tmp}/tdd-state"

# Determine the file path being written/edited
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')"
[ -n "$FILE_PATH" ] || exit 0

# Check if this is a test file
is_test_file() {
  local f="$1"
  # Match common test file patterns
  echo "$f" | grep -qE '(\.test\.|\.spec\.|__tests__/|/tests?/test_|_test\.go$|_test\.rs$|Test\.java$|test_[^/]*\.py$)'
}

if is_test_file "$FILE_PATH"; then
  # Writing a test file — set state to test-written
  echo "test-written" > "$STATE_FILE"
  exit 0
fi

# This is a non-test (implementation) file
CURRENT_STATE=""
if [ -f "$STATE_FILE" ]; then
  CURRENT_STATE="$(cat "$STATE_FILE")"
fi

if [ "$CURRENT_STATE" = "test-written" ]; then
  echo "Run the failing test before writing implementation code." >&2
  exit 2
fi

# State is clean or test-run — allow and reset to clean
rm -f "$STATE_FILE"
exit 0
