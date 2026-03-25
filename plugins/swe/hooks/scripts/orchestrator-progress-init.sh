#!/usr/bin/env bash
# SubagentStart hook: creates task list for orchestrator pipeline visualization
# Matches: feat-orchestrator, fix-orchestrator, refactor-orchestrator, docs-orchestrator
# Reads agent_name from stdin JSON, outputs TaskCreate calls as tool_use messages
set -euo pipefail

INPUT="$(cat)"

AGENT_NAME="$(echo "$INPUT" | jq -r '.agent_name // empty')"

# Define step maps per orchestrator type
case "$AGENT_NAME" in
  feat-orchestrator)
    STEPS=(
      "Read handoff"
      "Discover tooling"
      "Fetch docs"
      "Draft spec"
      "TDD cycle"
      "Self-review"
      "Sync docs"
      "Version bump"
      "Open PR"
    )
    ;;
  fix-orchestrator)
    STEPS=(
      "Read handoff"
      "Discover tooling"
      "Fetch docs"
      "Investigate root cause"
      "TDD reproduce"
      "Self-review"
      "Sync docs"
      "Version bump"
      "Open PR"
    )
    ;;
  refactor-orchestrator)
    STEPS=(
      "Read handoff"
      "Discover tooling"
      "Fetch docs"
      "TDD guard"
      "Refactor incrementally"
      "Self-review"
      "Sync docs"
      "Version bump"
      "Open PR"
    )
    ;;
  docs-orchestrator)
    STEPS=(
      "Read handoff"
      "Fetch docs"
      "Write/update documentation"
      "Clash check"
      "Sync docs"
      "Version bump"
      "Open PR"
    )
    ;;
  *)
    # Not an orchestrator we track — exit silently
    exit 0
    ;;
esac

# Build TaskCreate JSON array for all steps
TASKS="[]"
for step in "${STEPS[@]}"; do
  TASKS=$(echo "$TASKS" | jq --arg name "$step" '. + [{"name": $name, "status": "pending"}]')
done

# Output the task creation payload
echo "$TASKS" | jq -c '{tasks: .}'
