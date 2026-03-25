#!/usr/bin/env bash
# Tests for orchestrator-completion-check.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../../plugins/swe/hooks/scripts/orchestrator-completion-check.sh"
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

# Should block orchestrators that finish without a PR URL
assert_blocks "blocks feat-orchestrator without PR URL" \
  '{"agent_type":"feat-orchestrator","last_assistant_message":"I have completed the implementation and all tests pass."}'

assert_blocks "blocks fix-orchestrator without PR URL" \
  '{"agent_type":"fix-orchestrator","last_assistant_message":"The bug has been fixed."}'

assert_blocks "blocks refactor-orchestrator without PR URL" \
  '{"agent_type":"refactor-orchestrator","last_assistant_message":"Refactoring complete."}'

assert_blocks "blocks docs-orchestrator without PR URL" \
  '{"agent_type":"docs-orchestrator","last_assistant_message":"Documentation updated."}'

# Should allow orchestrators that include a PR URL
assert_allows "allows feat-orchestrator with PR URL" \
  '{"agent_type":"feat-orchestrator","last_assistant_message":"PR created: https://github.com/user/repo/pull/42"}'

assert_allows "allows fix-orchestrator with github.com URL" \
  '{"agent_type":"fix-orchestrator","last_assistant_message":"Opened https://github.com/org/repo/pull/123 for review."}'

# Should allow non-orchestrator agents
assert_allows "allows unknown agent type" \
  '{"agent_type":"custom-agent","last_assistant_message":"Done without PR."}'

assert_allows "allows empty agent type" \
  '{"agent_type":"","last_assistant_message":"Done."}'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
