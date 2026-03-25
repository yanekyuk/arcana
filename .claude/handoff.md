---
trigger: "Add a /run-finish skill for post-PR lifecycle: review open PR, suggest changes or merge to main, then clean up worktree and branches"
type: feat
branch: feat/run-finish
created: 2026-03-26
version-bump: minor
---

## Related Files
- plugins/swe/skills/run-triage/SKILL.md — creates worktree + branch (the setup side)
- plugins/swe/skills/run-open-pr/SKILL.md — opens PR (the step before finish)
- plugins/swe/skills/run-resume/SKILL.md — dispatches orchestrator (for format reference)
- plugins/swe/agents/feat-orchestrator.md — final step needs updating to mention /run-finish
- plugins/swe/agents/fix-orchestrator.md — same
- plugins/swe/agents/refactor-orchestrator.md — same
- plugins/swe/agents/docs-orchestrator.md — same
- plugins/swe/.claude-plugin/plugin.json — version bump
- .claude-plugin/marketplace.json — version bump

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope

### New skill: `/run-finish`
Create `plugins/swe/skills/run-finish/SKILL.md` — a user-invocable skill run from the **main session** (project root, not worktree) after an orchestrator opens a PR.

**Flow:**
1. List open PRs on the repo (or let user specify which)
2. Review the PR: diff, commit messages, test coverage, conventional commits compliance
3. If changes are needed:
   - Describe what needs fixing
   - Provide a ready-to-paste prompt the user can send to the orchestrator agent session in the worktree
   - Stop and wait — user will re-run `/run-finish` after fixes are applied
4. If PR looks good:
   - Merge to main (`gh pr merge --merge` or `--squash` based on preference)
   - Delete remote branch (`gh pr merge` handles this via `--delete-branch`)
   - Delete local branch (`git branch -d <branch>`)
   - Remove worktree (`git worktree remove .worktrees/<folder>`)
   - Report completion

### Update orchestrators
All four orchestrators' final step (Open PR) should append a message after reporting the PR URL:

> PR opened. Return to your **main session** (project root) and run `/run-finish` to review and merge.

This closes the triage → resume → orchestrate → finish lifecycle loop.
