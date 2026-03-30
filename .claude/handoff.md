---
trigger: "Optimize model and effort assignments across all swe plugin agents and skills based on Claude model benchmark data (Opus 4.6, Sonnet 4.6, Haiku 4.5)"
type: refactor
branch: refactor/model-effort-tuning
base-branch: main
created: 2026-03-30
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- plugins/swe/skills/run-setup/SKILL.md
- plugins/swe/skills/run-triage/SKILL.md
- plugins/swe/skills/run-create-triage/SKILL.md
- plugins/swe/skills/run-start/SKILL.md
- plugins/swe/skills/run-tdd/SKILL.md
- plugins/swe/skills/run-self-review/SKILL.md
- plugins/swe/skills/run-arch-check/SKILL.md
- plugins/swe/skills/run-clash-check/SKILL.md
- plugins/swe/skills/run-sync-docs/SKILL.md
- plugins/swe/skills/run-spec/SKILL.md
- plugins/swe/skills/run-design-decision/SKILL.md
- plugins/swe/skills/run-domain-knowledge/SKILL.md
- plugins/swe/skills/run-open-pr/SKILL.md
- plugins/swe/skills/run-finish/SKILL.md

## Relevant Docs
- docs/domain/plugin-system-rules.md
- docs/specs/orchestrator-pipeline.md
- docs/specs/skill-contracts.md

## Related Issues
None — no related issues found.

## Scope
Assign optimal `model` and `effort` frontmatter values to each agent and skill based on benchmark analysis:

### Agents
| Agent | Model | Effort | Rationale |
|-------|-------|--------|-----------|
| feat-orchestrator | opus | high | Multi-step orchestration, knowledge alignment, complex decisions (GPQA 91.3%) |
| fix-orchestrator | opus | high | Root cause analysis, hypothesis formation, investigation re-loops |
| refactor-orchestrator | opus | high | Incremental restructuring with safety invariants |
| docs-orchestrator | sonnet | medium | No code writing, simpler orchestration — Sonnet handles doc workflows fine |

### Skills
| Skill | Model | Effort | Rationale |
|-------|-------|--------|-----------|
| run-setup | haiku | low | Interactive wizard, mechanical auto-detection |
| run-triage | sonnet | medium | Codebase exploration + classification |
| run-create-triage | haiku | low | Simple issue creation workflow |
| run-start | haiku | low | Trivial routing: read handoff → dispatch |
| run-tdd | sonnet | high | Writes code/tests — Sonnet is 79.6% SWE-bench |
| run-self-review | sonnet | medium | Code review checklist analysis |
| run-arch-check | haiku | medium | Rule-matching against diff |
| run-clash-check | sonnet | medium | Comprehension needed for contradiction detection |
| run-sync-docs | sonnet | medium | Analyze diffs for implicit knowledge |
| run-spec | sonnet | medium | Write specs with alignment checks |
| run-design-decision | sonnet | medium | Write decisions with alignment checks |
| run-domain-knowledge | sonnet | medium | Write domain docs with cascade checks |
| run-open-pr | haiku | low | Mechanical: stage, push, create PR |
| run-finish | sonnet | medium | PR review + version bump + merge |

Key principle: Opus only where the 17-point GPQA reasoning gap matters (orchestration). Sonnet for coding/review (99% of Opus coding ability at 60% cost). Haiku for mechanical routing/validation (5x cheaper).
