---
trigger: "Orchestrators sometimes skip their final Open PR step, ad-libbing a message instead of running gh pr create. Observed on feat-orchestrator during feat/project-setup."
type: fix
branch: fix/orchestrator-pr-step
created: 2026-03-26
version-bump: patch
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md (Step 11: Open PR)
- plugins/swe/agents/fix-orchestrator.md (Step 11: Open PR)
- plugins/swe/agents/refactor-orchestrator.md (Step 11: Open PR)
- plugins/swe/agents/docs-orchestrator.md (Step 10: Open PR)
- plugins/swe/skills/run-open-pr/SKILL.md (existing skill that handles PR creation robustly)

## Relevant Docs
- docs/specs/orchestrator-pipeline.md — shared pipeline structure, documents the Open PR delivery phase
- docs/specs/skill-contracts.md — run-open-pr contract (input, output, tools, invocation)
- docs/specs/work-lifecycle.md — documents the full lifecycle including PR creation

## Scope

### Problem
The feat-orchestrator completed all implementation steps (TDD, self-review, sync docs, version bump, handoff cleanup) but skipped the final "Open PR" step entirely. Instead of executing `git push` and `gh pr create`, it ad-libbed a message telling the user to run `/run-finish` to open the PR — which is wrong since `run-finish` reviews and merges existing PRs, it doesn't create them.

The root cause is that the inline Open PR instructions in the orchestrator are long and come at the very end of a large prompt, making them easy for the LLM to skip or summarize away, especially when running near token limits.

### Fix
Replace the inline "Open PR" step in all 4 orchestrators with a dispatch to the existing `run-open-pr` skill via the Skill tool. This:
1. Makes the step atomic and harder to skip (it's a tool call, not prose to follow)
2. Reuses the existing `run-open-pr` skill which already handles edge cases (unstaged changes, push retry, WIP/draft detection)
3. Reduces orchestrator prompt length

### Changes needed
1. **All 4 orchestrators**: Replace the inline Open PR step body with a skill dispatch instruction. Keep the step header and task tracking, but the body should instruct the agent to invoke the `run-open-pr` skill. Note: the handoff artifact is already removed by this point, so `run-open-pr` should read the PR context from the git log and diff rather than from the handoff. Add a note that if the skill dispatch is not available, fall back to the inline commands.
2. **run-open-pr skill**: May need a small update — currently reads `.claude/handoff.md` for context (Step 3), but by the time it runs in the orchestrator pipeline, the handoff has been `git rm`'d. It should fall back to reading context from git log and diff when handoff is missing.
3. **Version bump**: 0.8.1 → 0.8.2 in both plugin.json and marketplace.json.
