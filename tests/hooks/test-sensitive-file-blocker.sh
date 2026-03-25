#!/usr/bin/env bash
# Tests for sensitive-file-blocker.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../../plugins/swe/hooks/scripts/sensitive-file-blocker.sh"
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

# Should block git add of .env
assert_blocks "blocks git add .env" \
  '{"tool_name":"Bash","tool_input":{"command":"git add .env"}}'

# Should block git add of credentials file
assert_blocks "blocks git add credentials.json" \
  '{"tool_name":"Bash","tool_input":{"command":"git add credentials.json"}}'

# Should block git add of .key file
assert_blocks "blocks git add server.key" \
  '{"tool_name":"Bash","tool_input":{"command":"git add server.key"}}'

# Should block git add of .pem file
assert_blocks "blocks git add cert.pem" \
  '{"tool_name":"Bash","tool_input":{"command":"git add cert.pem"}}'

# Should block git add -A when .env is mentioned (git add -A could include sensitive files)
assert_blocks "blocks git add -A" \
  '{"tool_name":"Bash","tool_input":{"command":"git add -A"}}'

# Should block git add .
assert_blocks "blocks git add ." \
  '{"tool_name":"Bash","tool_input":{"command":"git add ."}}'

# Should allow git add of normal files
assert_allows "allows git add normal.txt" \
  '{"tool_name":"Bash","tool_input":{"command":"git add normal.txt"}}'

# Should allow git add of specific safe files
assert_allows "allows git add src/index.ts" \
  '{"tool_name":"Bash","tool_input":{"command":"git add src/index.ts"}}'

# Should allow non-git-add commands
assert_allows "allows git status" \
  '{"tool_name":"Bash","tool_input":{"command":"git status"}}'

# Should allow non-Bash tools
assert_allows "allows Write tool" \
  '{"tool_name":"Write","tool_input":{"file_path":"foo.txt","content":"bar"}}'

# Should block git add with multiple files including .env
assert_blocks "blocks git add with .env among multiple files" \
  '{"tool_name":"Bash","tool_input":{"command":"git add src/foo.ts .env bar.js"}}'

# Should block credentials with any extension
assert_blocks "blocks git add credentials.yaml" \
  '{"tool_name":"Bash","tool_input":{"command":"git add credentials.yaml"}}'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
