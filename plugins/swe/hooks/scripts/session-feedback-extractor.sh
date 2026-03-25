#!/usr/bin/env bash
# SessionEnd hook: extracts user corrections and learnings from transcript
# Reads transcript_path from stdin JSON, writes memory files
# Exit 0 always (side-effect hook, never blocks)
set -euo pipefail

INPUT="$(cat)"

TRANSCRIPT_PATH="$(echo "$INPUT" | jq -r '.transcript_path // empty')"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // "unknown"')"

# Bail if no transcript or file doesn't exist
[ -n "$TRANSCRIPT_PATH" ] || exit 0
[ -f "$TRANSCRIPT_PATH" ] || exit 0

DATA_DIR="${CLAUDE_PLUGIN_DATA:-/tmp/claude-plugin-data}"
MEMORY_DIR="$DATA_DIR/memory"
mkdir -p "$MEMORY_DIR"

# Extract user messages that contain correction/learning signals
# Patterns: "no,", "actually,", "that's wrong", "instead", "always", "never", "don't"
CORRECTIONS="$(jq -r '
  [.[] | select(.role == "user") |
    select(.content |
      test("(?i)(^no[,.]|actually[,.]|that.s wrong|instead of|always use|never use|don.t use|not that|wrong approach|should be|must be)")
    ) | .content
  ] | join("\n---\n")
' "$TRANSCRIPT_PATH" 2>/dev/null || echo "")"

# Skip if no actionable feedback found
if [ -z "$CORRECTIONS" ] || [ "$CORRECTIONS" = "" ]; then
  exit 0
fi

# Write structured memory file
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DATE_SLUG="$(date -u +%Y%m%d-%H%M%S)"
MEMORY_FILE="$MEMORY_DIR/feedback-${DATE_SLUG}-${SESSION_ID:0:8}.md"

cat > "$MEMORY_FILE" <<EOF
---
title: "Session Feedback"
type: feedback
session_id: "$SESSION_ID"
created: "$TIMESTAMP"
---

## User Corrections and Learnings

$CORRECTIONS
EOF

exit 0
