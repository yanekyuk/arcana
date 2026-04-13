---
trigger: "Singular handoff.md can get confusing when we are working on multiple features in parallel. Let's instead use docs/handoffs folder and name the handoff with the same name of the worktree (i.e. feat-worktree-gitignore-copy.md, refactor-rename-swe-to-ritual.md). run-start command should check the name of the worktree (or folder) and fetch the correct handoff."
type: refactor
branch: refactor/named-handoffs
base-branch: main
created: 2026-04-14
---

## Related Files
- plugins/swe/scripts/setup-worktree.sh
- plugins/swe/skills/run-start/SKILL.md
- plugins/swe/skills/run-triage/SKILL.md
- plugins/swe/skills/run-open-pr/SKILL.md
- plugins/swe/skills/run-self-review/SKILL.md
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- docs/decisions/handoff-artifact-pattern.md
- docs/specs/triage-script.md
- docs/specs/work-lifecycle.md
- docs/specs/orchestrator-pipeline.md
- CLAUDE.md

## Relevant Docs
- docs/decisions/handoff-artifact-pattern.md
- docs/decisions/two-session-model.md
- docs/specs/triage-script.md
- docs/specs/work-lifecycle.md
- docs/specs/orchestrator-pipeline.md

## Related Issues
None — no related issues found.

## Scope
Move handoff artifacts from per-worktree `.claude/handoff.md` to centralized `docs/handoffs/<worktree-name>.md` in the main repo. Changes required:

1. **setup-worktree.sh**: Write handoff to `docs/handoffs/<folder>.md` in the main repo instead of `.worktrees/<folder>/.claude/handoff.md` in the worktree. Commit in the main repo, not the worktree.
2. **run-triage**: Update the handoff path references and script invocation to use the new location.
3. **run-start**: Instead of reading `.claude/handoff.md` from CWD, determine the worktree folder name (from the directory name or git worktree metadata), then read `docs/handoffs/<folder-name>.md` from the main repo root. The main repo root can be found via `git worktree list` or by reading the `.git` file which points back to the main repo.
4. **run-open-pr**: Update handoff read path — read from main repo's `docs/handoffs/` using the same folder-name lookup.
5. **run-self-review**: Update handoff read path similarly.
6. **All 4 orchestrators**: Change `git rm .claude/handoff.md` cleanup to remove the handoff from the main repo's `docs/handoffs/` instead. This may require a different cleanup strategy (e.g., cleanup during `/run-finish` instead of in the orchestrator).
7. **docs/decisions/handoff-artifact-pattern.md**: Update to reflect new location, naming convention, and lifecycle.
8. **docs/specs/**: Update triage-script.md, work-lifecycle.md, orchestrator-pipeline.md references.
9. **CLAUDE.md**: Update handoff path references.
10. **.gitignore**: Ensure `docs/handoffs/` is NOT gitignored (it needs to be tracked).
