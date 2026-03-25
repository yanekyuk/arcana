#!/usr/bin/env bash
# PreToolUse hook: validates conventional commit format on git commit -m
# Matches: Bash
# Exit 0 = allow, Exit 2 = block
set -euo pipefail

INPUT="$(cat)"

TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // empty')"
[ -n "$COMMAND" ] || exit 0

# Only inspect git commit -m commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit\s+.*-m\s'; then
  exit 0
fi

# Extract the commit message — handle both direct quotes and HEREDOC patterns
# For HEREDOC: git commit -m "$(cat <<'EOF'\nfeat: message\nEOF\n)"
# For direct: git commit -m "feat: message"
MSG=""

# Try to extract from HEREDOC pattern first
if echo "$COMMAND" | grep -q 'cat <<'; then
  # Extract the line after the HEREDOC delimiter
  MSG="$(echo "$COMMAND" | sed -n '/cat <</{n;s/^[[:space:]]*//;s/\\n.*//;p;}')"
  # If sed-based extraction fails, try another approach
  if [ -z "$MSG" ]; then
    MSG="$(echo -e "$COMMAND" | sed -n '/cat <</{n;p;}' | head -1 | sed 's/^[[:space:]]*//')"
  fi
fi

# Fall back to direct -m "message" extraction
if [ -z "$MSG" ]; then
  # Extract message between quotes after -m
  MSG="$(echo "$COMMAND" | sed -nE 's/.*git\s+commit\s+.*-m\s+"([^"]*).*/\1/p')"
  # Try single quotes if double quotes didn't match
  if [ -z "$MSG" ]; then
    MSG="$(echo "$COMMAND" | sed -nE "s/.*git\s+commit\s+.*-m\s+'([^']*)'.*/\1/p")"
  fi
fi

[ -n "$MSG" ] || exit 0

# Validate conventional commit format: type(optional-scope): description
VALID_TYPES="feat|fix|refactor|docs|chore|test|ci|perf|style|build"
if ! echo "$MSG" | grep -qE "^($VALID_TYPES)(\([a-zA-Z0-9_-]+\))?: .+"; then
  echo "Blocked: commit message does not follow Conventional Commits format." >&2
  echo "Expected: <type>: <description>" >&2
  echo "Valid types: feat, fix, refactor, docs, chore, test, ci, perf, style, build" >&2
  echo "Got: $MSG" >&2
  exit 2
fi

exit 0
