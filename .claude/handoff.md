---
trigger: "Triage skill triggers 3 separate permission prompts (branch creation, handoff write, commit). Consolidate into a single script so only one permission rule is needed."
type: feat
branch: feat/triage-script
created: 2026-03-26
version-bump: minor
---

## Related Files
- plugins/swe/skills/run-triage/SKILL.md — steps 7-9 need refactoring to call the script
- plugins/swe/.claude-plugin/plugin.json — version bump
- .claude-plugin/marketplace.json — version bump

## Relevant Docs
- docs/claude-code-extensions-reference.md — skill format and allowed-tools reference

## Scope
Create `plugins/swe/scripts/setup-worktree.sh` that consolidates triage steps 7-9 (branch creation, worktree setup, handoff write, commit) into a single script. The script takes branch name, worktree folder name, and commit message as args, and reads handoff content from stdin. Update the run-triage skill to call this script instead of issuing 3 separate tool calls. This reduces permission prompts from 3 to 1 and enables a single permission rule like `Bash(bash plugins/swe/scripts/setup-worktree.sh:*)`.

Path resolution note: in the arcana repo the script is at `./plugins/swe/scripts/`. For projects using the installed plugin, the script is in the cache at `~/.claude/plugins/cache/arcana/swe/<version>/scripts/`. The skill instructions should handle both cases.
