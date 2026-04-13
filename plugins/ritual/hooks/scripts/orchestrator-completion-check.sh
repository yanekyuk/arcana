#!/usr/bin/env bash
# SubagentStop hook: ensures orchestrators produce a PR URL before finishing
# Matches: feat-orchestrator, fix-orchestrator, refactor-orchestrator, docs-orchestrator
# Exit 0 = allow, Exit 2 = block
set -euo pipefail

INPUT="$(cat)"

AGENT_TYPE="$(echo "$INPUT" | jq -r '.agent_type // empty')"

# Only check orchestrator agents
case "$AGENT_TYPE" in
  feat-orchestrator|fix-orchestrator|refactor-orchestrator|docs-orchestrator)
    ;;
  *)
    exit 0
    ;;
esac

LAST_MSG="$(echo "$INPUT" | jq -r '.last_assistant_message // empty')"

# Check for a GitHub PR URL pattern
if echo "$LAST_MSG" | grep -qE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+'; then
  exit 0
fi

echo "Orchestrator finished without opening a PR. The orchestrator must create a pull request before completing." >&2
exit 2
