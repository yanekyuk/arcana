---
trigger: "Add hooks system to the SWE plugin — guard rails, workflow enforcement, and automated side effects"
type: feat
branch: feat/swe-hooks
created: 2026-03-25
---

## Related Files
- plugins/swe/.claude-plugin/plugin.json
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- plugins/swe/skills/run-tdd/SKILL.md
- plugins/swe/skills/run-triage/SKILL.md
- plugins/swe/skills/run-resume/SKILL.md
- docs/claude-code-extensions-reference.md (hooks reference, section 5)

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope

Add a `hooks/` directory to `plugins/swe/` with `hooks.json` config and shell scripts. Register hooks in `plugin.json`. Six hooks total:

### Guard Rails (PreToolUse — command hooks, exit 2 to block)

1. **sensitive-file-blocker.sh** — Matches `Bash`. Parses `tool_input.command` from stdin JSON. Blocks `git add` of `.env`, `credentials*`, `*.key`, `*.pem`. Exit 2 with explanation on stderr.

2. **commit-msg-validator.sh** — Matches `Bash`. Parses `git commit -m` from `tool_input.command`. Validates conventional commit format (`type: description` where type is feat|fix|refactor|docs|chore|test). Exit 2 if malformed.

3. **worktree-boundary.sh** — Matches `Bash`, `EnterWorktree`, `ExitWorktree`. For Bash: blocks commands containing `cd .worktrees/` or `cd` into any worktree path. For EnterWorktree/ExitWorktree: blocks unconditionally. Worktree entry is a user action, not an agent action. Exit 2 with "Worktree navigation is a user action. Stop and instruct the user to open a new terminal session in the worktree."

### Workflow Enforcement

4. **orchestrator-completion-check** — `SubagentStop` prompt hook matching orchestrator agent types (`feat-orchestrator`, `fix-orchestrator`, `refactor-orchestrator`, `docs-orchestrator`). Checks `last_assistant_message` for a PR URL (github.com pattern). If missing, blocks with "Orchestrator finished without opening a PR."

5. **tdd-test-first.sh** — `PreToolUse` on `Write` and `Edit`. Tracks TDD state via a temp file in `$CLAUDE_PLUGIN_DATA`. Logic: when a test file is written/edited, sets state to "test-written". When a Bash command runs tests, sets state to "test-run". If an implementation file (non-test) is written/edited while state is "test-written" (test not yet run), blocks with "Run the failing test before writing implementation code." Requires a paired PostToolUse hook on Bash to detect test execution.

### Automated Side Effects

6. **session-feedback-extractor** — `SessionEnd` agent hook. Reads `transcript_path` from stdin JSON. Extracts user corrections, confirmations, and non-obvious learnings. Writes structured feedback/memory files to `$CLAUDE_PLUGIN_DATA/memory/`. Skips if no actionable feedback found.

### Plugin Integration
- Create `plugins/swe/hooks/hooks.json` with all hook configurations
- Create `plugins/swe/hooks/scripts/` with shell scripts
- Update `plugins/swe/.claude-plugin/plugin.json` to add `"hooks": "./hooks/hooks.json"`

### Hook Input Contract
All command hooks receive JSON on stdin with:
- `session_id`, `transcript_path`, `cwd`, `hook_event_name`
- PreToolUse adds: `tool_name`, `tool_input`
- PostToolUse adds: `tool_name`, `tool_input`, `tool_response`
- SubagentStop adds: `agent_type`, `last_assistant_message`
- SessionEnd adds: `reason`

Shell scripts should parse stdin with `jq`. Exit 0 = proceed, exit 2 = block (stderr → Claude feedback).
