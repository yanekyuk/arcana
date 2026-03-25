#!/usr/bin/env bash
# Tests for commit-msg-validator.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../../plugins/swe/hooks/scripts/commit-msg-validator.sh"
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

# Valid conventional commits
assert_allows "allows feat: message" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: add hooks system\""}}'

assert_allows "allows fix: message" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"fix: resolve null pointer\""}}'

assert_allows "allows refactor: message" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"refactor: extract method\""}}'

assert_allows "allows docs: message" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"docs: update README\""}}'

assert_allows "allows chore: message" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"chore: bump version\""}}'

assert_allows "allows test: message" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"test: add hook tests\""}}'

assert_allows "allows scoped commit" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat(hooks): add blocker\""}}'

# Invalid commits
assert_blocks "blocks missing type" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"add hooks system\""}}'

assert_blocks "blocks invalid type" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feature: add hooks\""}}'

assert_blocks "blocks missing colon" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat add hooks\""}}'

assert_blocks "blocks empty description" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: \""}}'

# Non-commit commands should pass through
assert_allows "allows git status" \
  '{"tool_name":"Bash","tool_input":{"command":"git status"}}'

assert_allows "allows non-Bash tool" \
  '{"tool_name":"Write","tool_input":{"file_path":"foo.txt"}}'

# HEREDOC commits should be validated too
assert_allows "allows HEREDOC conventional commit" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"$(cat <<'"'"'EOF'"'"'\nfeat: add hooks\nEOF\n)\""}}'

assert_blocks "blocks HEREDOC non-conventional commit" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"$(cat <<'"'"'EOF'"'"'\nadd hooks\nEOF\n)\""}}'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
