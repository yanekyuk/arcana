#!/usr/bin/env bash
# PreToolUse hook: blocks git add of sensitive files
# Matches: Bash
# Exit 0 = allow, Exit 2 = block (stderr -> Claude feedback)
set -euo pipefail

INPUT="$(cat)"

TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"
[ -n "$COMMAND" ] || exit 0

# Only inspect git add commands
if ! echo "$COMMAND" | grep -qE '\bgit\s+add\b'; then
  exit 0
fi

# Block broad adds that could sweep in sensitive files
if echo "$COMMAND" | grep -qE '\bgit\s+add\s+(-A|--all|\.|-)(\s|$)'; then
  echo "Blocked: 'git add' with broad patterns (-A, --all, .) may include sensitive files. Add specific files by name instead." >&2
  exit 2
fi

# Block specific sensitive file patterns
SENSITIVE_PATTERNS='\.env([[:space:]]|$)|credentials[^[:space:]]*([[:space:]]|$)|\.key([[:space:]]|$)|\.pem([[:space:]]|$)'
if echo "$COMMAND" | grep -qE "$SENSITIVE_PATTERNS"; then
  echo "Blocked: git add of sensitive file detected. Do not commit .env, credentials*, *.key, or *.pem files." >&2
  exit 2
fi

exit 0
