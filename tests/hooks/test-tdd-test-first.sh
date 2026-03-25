#!/usr/bin/env bash
# Tests for tdd-test-first.sh (PreToolUse) and tdd-test-tracker.sh (PostToolUse)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PRE_HOOK="$SCRIPT_DIR/../../plugins/swe/hooks/scripts/tdd-test-first.sh"
POST_HOOK="$SCRIPT_DIR/../../plugins/swe/hooks/scripts/tdd-test-tracker.sh"
PASS=0
FAIL=0

# Use a temp dir for CLAUDE_PLUGIN_DATA and a fixed session ID for deterministic state files
export CLAUDE_PLUGIN_DATA="$(mktemp -d)"
export CLAUDE_SESSION_ID="test-session"
trap 'rm -rf "$CLAUDE_PLUGIN_DATA"' EXIT

assert_blocks() {
  local desc="$1" input="$2"
  if echo "$input" | bash "$PRE_HOOK" 2>/dev/null; then
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
  if echo "$input" | bash "$PRE_HOOK" 2>/dev/null; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    local code=$?
    echo "FAIL: $desc — expected exit 0, got exit $code"
    FAIL=$((FAIL + 1))
  fi
}

run_post_hook() {
  local input="$1"
  echo "$input" | bash "$POST_HOOK" 2>/dev/null
}

reset_state() {
  rm -f "$CLAUDE_PLUGIN_DATA/tdd-state-$CLAUDE_SESSION_ID"
}

# --- Test Sequence 1: Clean state allows implementation writes ---
reset_state

assert_allows "allows implementation write in clean state" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/index.ts","content":"code"}}'

# --- Test Sequence 2: After writing a test, must run test before implementation ---
reset_state

# Write a test file (should be allowed and set state to test-written)
assert_allows "allows writing a test file" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/index.test.ts","content":"test code"}}'

# Now try to write implementation (should be blocked — test not yet run)
assert_blocks "blocks implementation write after test write without running test" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/index.ts","content":"impl code"}}'

# Also blocks Edit on implementation
assert_blocks "blocks implementation edit after test write without running test" \
  '{"tool_name":"Edit","tool_input":{"file_path":"src/utils.ts","old_string":"old","new_string":"new"}}'

# --- Test Sequence 3: After running test, allows implementation ---
reset_state

# Write test
assert_allows "allows writing test file (seq 3)" \
  '{"tool_name":"Write","tool_input":{"file_path":"tests/foo.test.js","content":"test"}}'

# Simulate running the test via PostToolUse
run_post_hook '{"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"stdout":"FAIL tests/foo.test.js"}}'

# Now implementation write should be allowed
assert_allows "allows implementation write after running test" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/foo.js","content":"impl"}}'

# --- Test Sequence 4: Writing another test resets the cycle ---
reset_state

# Write test, run test, write impl (all should work)
assert_allows "write test (seq 4)" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/bar.spec.ts","content":"test"}}'
run_post_hook '{"tool_name":"Bash","tool_input":{"command":"bun test"},"tool_response":{"stdout":"1 test"}}'
assert_allows "write impl after test run (seq 4)" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/bar.ts","content":"impl"}}'

# Write another test
assert_allows "write new test (seq 4)" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/baz.test.ts","content":"new test"}}'

# Implementation should be blocked again
assert_blocks "blocks impl after new test without running (seq 4)" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/baz.ts","content":"impl"}}'

# --- Test Sequence 5: Non-Write/Edit tools are not affected ---
reset_state

assert_allows "allows Read tool always" \
  '{"tool_name":"Read","tool_input":{"file_path":"src/index.ts"}}'

assert_allows "allows Bash tool (not Write/Edit)" \
  '{"tool_name":"Bash","tool_input":{"command":"ls"}}'

# --- Test Sequence 6: Test file patterns ---
reset_state

# Various test file patterns should be recognized
assert_allows "recognizes .test.ts" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/foo.test.ts","content":"test"}}'
reset_state
assert_allows "recognizes .spec.ts" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/foo.spec.ts","content":"test"}}'
reset_state
assert_allows "recognizes __tests__/ directory" \
  '{"tool_name":"Write","tool_input":{"file_path":"src/__tests__/foo.ts","content":"test"}}'
reset_state
assert_allows "recognizes test_ prefix (python)" \
  '{"tool_name":"Write","tool_input":{"file_path":"tests/test_foo.py","content":"test"}}'
reset_state
assert_allows "recognizes _test.go suffix" \
  '{"tool_name":"Write","tool_input":{"file_path":"pkg/foo_test.go","content":"test"}}'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
