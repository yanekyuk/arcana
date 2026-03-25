---
trigger: "Remove project memories by embedding their knowledge into skills, agents, hooks, or CLAUDE.md — memories should not exist separately from the plugin system"
type: refactor
branch: refactor/remove-memories
created: 2026-03-26
version-bump: patch
---

## Related Files
- plugins/swe/skills/run-triage/SKILL.md — triage skill (main session, project root)
- plugins/swe/skills/run-finish/SKILL.md — finish skill (main session, project root)
- plugins/swe/skills/run-resume/SKILL.md — resume skill (worktree session)
- plugins/swe/skills/run-sync-docs/SKILL.md — already has Step 5 for CLAUDE.md suggestions
- plugins/swe/skills/run-open-pr/SKILL.md — already includes CLAUDE.md update section in PR body
- plugins/swe/agents/feat-orchestrator.md — Step 7 sync docs already checks CLAUDE.md
- plugins/swe/agents/fix-orchestrator.md — same
- plugins/swe/agents/refactor-orchestrator.md — same
- plugins/swe/agents/docs-orchestrator.md — same
- plugins/swe/hooks/scripts/worktree-boundary.sh — blocks cd/pushd into .worktrees/
- CLAUDE.md — project conventions

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope

Audit four project memories and either embed them into the plugin system or confirm they're already covered, then delete all memory files.

### Memory 1: "Project Goal" — custom marketplace for skills and MCPs
Already covered by `CLAUDE.md` "What This Is" section and `marketplace.json` metadata. **Action:** Delete memory. No code changes needed.

### Memory 2: "Tech Stack" — TypeScript/Bun, no Python
This is a per-project preference, not a global arcana rule. Each target project has its own stack. The plugin already discovers project tooling (Step 2 in every orchestrator). **Action:** Delete memory. No code changes needed — this belongs in target project CLAUDE.md files, not in arcana itself.

### Memory 3: "Handoff Cleanup" — orchestrators must git-rm handoff.md before PR
Already fully implemented. All four orchestrators have "Step 9: Clean up handoff" with `git rm .claude/handoff.md`. **Action:** Delete memory. No code changes needed.

### Memory 4: "Stay in Root" — main session stays in project root
Partially implemented:
- `run-finish` Step 1 validates it's not a worktree
- `run-triage` implicitly runs from root (creates worktrees relative to `.`)
- `worktree-boundary.sh` hook blocks `cd`/`pushd` into `.worktrees/`

**Gaps to fill:**
1. `run-triage` should have an explicit Step 0 or Step 1 check (like run-finish has) that validates it's running from the main repo, not a worktree
2. `CLAUDE.md` "SWE Plugin Workflow" section should explicitly state the root-session rule so Claude always has it in context

After embedding, delete all memory files:
- `~/.claude/projects/-home-yanek-Projects-claude-plugins/memory/project_goal.md`
- `~/.claude/projects/-home-yanek-Projects-claude-plugins/memory/tech_stack.md`
- `~/.claude/projects/-home-yanek-Projects-claude-plugins/memory/feedback_handoff_artifact.md`
- `~/.claude/projects/-home-yanek-Projects-claude-plugins/memory/feedback_stay_in_root.md`
- `~/.claude/projects/-home-yanek-Projects-claude-plugins/memory/MEMORY.md`
