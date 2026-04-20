---
trigger: "GitHub Issues and Milestones management — sync version bumps to milestone targets so that features assigned to milestone 0.10.0 end at 0.10.0, not auto-increment to 0.11.0"
type: feat
branch: feat/milestone-version-sync
base-branch: main
created: 2026-04-20
---

## Related Files
- plugins/ritual/skills/run-triage/SKILL.md
- plugins/ritual/skills/run-finish/SKILL.md
- plugins/ritual/skills/run-open-pr/SKILL.md
- plugins/ritual/skills/run-create-triage/SKILL.md
- docs/specs/integration-wiring.md
- docs/ritual-config.json

## Relevant Docs
- docs/specs/integration-wiring.md — GitHub Issues integration wiring
- docs/decisions/handoff-artifact-pattern.md — handoff frontmatter contract

## Related Issues
None — no related issues found.

## Scope

Add milestone-aware version bumping to the ritual plugin so that ANY project using this plugin can:

1. **Create milestones with target versions** — extend `run-create-triage` or add a new skill to create GitHub milestones with a target version (e.g., milestone "0.10.0" with target version 0.10.0)

2. **Assign work to milestones** — in `run-triage`, allow linking the handoff to a milestone; store `milestone` in handoff frontmatter

3. **Link PRs to milestones** — in `run-open-pr`, assign the PR to the milestone from the handoff

4. **Milestone-aware version bumping in run-finish**:
   - If a PR has a milestone with a target version, bump TO that version (not auto-increment)
   - Only bump when the current version < milestone target version
   - This ensures multiple features in the same milestone all land at the target version

5. **Update integration-wiring spec** — document the new milestone flow

Key insight: the version bump in `run-finish` should check milestone first. If milestone has a target version and current < target, bump to target. If no milestone or already at target, use existing auto-increment logic.
