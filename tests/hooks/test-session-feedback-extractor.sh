#!/usr/bin/env bash
# Tests for session-feedback-extractor.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../../plugins/ritual/hooks/scripts/session-feedback-extractor.sh"
PASS=0
FAIL=0

export CLAUDE_PLUGIN_DATA="$(mktemp -d)"
trap 'rm -rf "$CLAUDE_PLUGIN_DATA"' EXIT

assert_pass() {
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

# Create a mock transcript with user corrections
TRANSCRIPT_DIR="$(mktemp -d)"
cat > "$TRANSCRIPT_DIR/transcript.json" <<'TXEOF'
[
  {"role": "user", "content": "No, that's wrong. Use the factory pattern instead of direct instantiation."},
  {"role": "assistant", "content": "You're right, I'll switch to the factory pattern."},
  {"role": "user", "content": "Please fix the tests"},
  {"role": "assistant", "content": "Done, tests are fixed."},
  {"role": "user", "content": "Actually, always use absolute paths in this project, not relative ones."},
  {"role": "assistant", "content": "Noted, switching to absolute paths."}
]
TXEOF

assert_pass "processes transcript with corrections" \
  "{\"transcript_path\":\"$TRANSCRIPT_DIR/transcript.json\",\"reason\":\"user_exit\",\"session_id\":\"test-123\"}"

# Check that memory file was created
if [ -d "$CLAUDE_PLUGIN_DATA/memory" ] && ls "$CLAUDE_PLUGIN_DATA/memory/"*.md >/dev/null 2>&1; then
  echo "PASS: memory file created"
  PASS=$((PASS + 1))

  # Check content includes corrections
  CONTENT="$(cat "$CLAUDE_PLUGIN_DATA/memory/"*.md)"
  if echo "$CONTENT" | grep -qi "factory\|absolute"; then
    echo "PASS: memory file contains extracted feedback"
    PASS=$((PASS + 1))
  else
    echo "FAIL: memory file missing expected feedback content"
    FAIL=$((FAIL + 1))
  fi
else
  echo "FAIL: no memory file created"
  FAIL=$((FAIL + 1))
  echo "FAIL: (skipped content check)"
  FAIL=$((FAIL + 1))
fi

# Test with transcript that has no corrections
rm -rf "$CLAUDE_PLUGIN_DATA/memory"
BLAND_DIR="$(mktemp -d)"
cat > "$BLAND_DIR/transcript.json" <<'TXEOF'
[
  {"role": "user", "content": "Add a README file"},
  {"role": "assistant", "content": "Created README.md with project description."},
  {"role": "user", "content": "Thanks, looks good"},
  {"role": "assistant", "content": "You're welcome!"}
]
TXEOF

assert_pass "handles bland transcript gracefully" \
  "{\"transcript_path\":\"$BLAND_DIR/transcript.json\",\"reason\":\"user_exit\",\"session_id\":\"test-456\"}"

# Test with missing transcript
assert_pass "handles missing transcript file" \
  '{"transcript_path":"/nonexistent/transcript.json","reason":"user_exit","session_id":"test-789"}'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
