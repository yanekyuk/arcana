---
trigger: "Implement bounded retry loops in orchestrator agents. Add consistent retry patterns across all four orchestrators (feat, fix, refactor, docs): TDD/implement step retry loops, self-review retry loops (max 3), and arch check retry loops (max 3). All loops must preserve the escape hatch to draft PR pattern on exhaustion."
type: feat
branch: feat/orchestrator-retry-loops
base-branch: main
created: 2026-03-28
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- docs/specs/orchestrator-pipeline.md
- docs/decisions/tdd-first-development.md
- docs/decisions/autonomous-orchestrators.md

## Relevant Docs
- docs/specs/orchestrator-pipeline.md
- docs/decisions/autonomous-orchestrators.md
- docs/decisions/tdd-first-development.md

## Related Issues
None — no related issues found.

## Scope

Add bounded retry loops to three pipeline steps across all four orchestrators:

### 1. TDD / implement step retry loops
- **feat-orchestrator**: Add a re-plan loop (max 2) — if a unit fails 3 attempts, re-read the spec and reconsider the unit decomposition before bailing to draft PR
- **fix-orchestrator**: Formalize the existing investigate → TDD loop as a bounded loop (max 2 re-investigations) with clear loop structure
- **refactor-orchestrator**: Add a re-approach loop (max 2) — if a refactor breaks tests after 3 attempts, reconsider the approach before bailing
- **docs-orchestrator**: No TDD cycle, no loop needed here

### 2. Self-review step retry loops (ALL four orchestrators)
- Change from 1 retry to a bounded loop of max 3 iterations
- Pattern: review → find issues → fix → re-review → repeat up to 3 times
- Bail to draft PR after 3 failed iterations

### 3. Arch check step retry loops (ALL four orchestrators)
- Change from 1 retry to a bounded loop of max 3 iterations
- Pattern: check → find violations → fix → re-check → repeat up to 3 times
- Bail to draft PR after 3 failed iterations

All loops preserve the existing escape hatch to draft PR pattern on exhaustion. Update the orchestrator-pipeline spec and tdd-first-development decision doc to reflect the new retry behavior.
