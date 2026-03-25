---
trigger: "Hook scripts fail with 'PreToolUse:Bash hook error' because they use relative paths (./scripts/) that resolve against user CWD, not the plugin directory"
type: fix
branch: fix/hook-relative-paths
created: 2026-03-25
version-bump: patch
---

## Related Files
- plugins/swe/hooks/hooks.json
- plugins/swe/hooks/scripts/sensitive-file-blocker.sh
- plugins/swe/hooks/scripts/commit-msg-validator.sh
- plugins/swe/hooks/scripts/worktree-boundary.sh
- plugins/swe/hooks/scripts/tdd-test-first.sh
- plugins/swe/hooks/scripts/tdd-test-tracker.sh
- plugins/swe/hooks/scripts/orchestrator-completion-check.sh
- plugins/swe/hooks/scripts/session-feedback-extractor.sh
- plugins/swe/.claude-plugin/plugin.json
- .claude-plugin/marketplace.json

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope

### Problem
All hook commands in `hooks.json` use relative paths (`./scripts/foo.sh`). Claude Code runs hook commands with the user's project directory as CWD, not the plugin directory. This means every hook fails with "no such file or directory" when invoked from any project that installs the plugin.

### Root Cause
The `command` field in hooks.json resolves relative to CWD. The plugin hook execution model provides `${CLAUDE_PLUGIN_ROOT}` as an environment variable pointing to the plugin's installation directory.

### Fix
Replace all `./scripts/` prefixes in `hooks.json` with `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/`. The plugin root is `plugins/swe/`, and hooks live at `plugins/swe/hooks/`, so the full path from root is `hooks/scripts/`.

### Files to Change
1. `plugins/swe/hooks/hooks.json` — Update all 7 command paths from `./scripts/` to `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/`
2. `plugins/swe/.claude-plugin/plugin.json` — Bump version (patch)
3. `.claude-plugin/marketplace.json` — Bump version to match
