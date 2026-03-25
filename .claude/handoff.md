---
trigger: "Create project documentation across all three knowledge tiers (domain, decisions, specs) covering the arcana plugin system"
type: docs
branch: docs/project-knowledge
created: 2026-03-26
version-bump: none
---

## Related Files
- .claude-plugin/marketplace.json — marketplace index
- plugins/swe/.claude-plugin/plugin.json — plugin manifest
- plugins/swe/agents/feat-orchestrator.md — feature pipeline
- plugins/swe/agents/fix-orchestrator.md — fix pipeline
- plugins/swe/agents/refactor-orchestrator.md — refactor pipeline
- plugins/swe/agents/docs-orchestrator.md — docs pipeline
- plugins/swe/skills/run-triage/SKILL.md — triage skill (session 1)
- plugins/swe/skills/run-resume/SKILL.md — resume/dispatch skill (session 2)
- plugins/swe/skills/run-finish/SKILL.md — post-PR lifecycle skill (session 1)
- plugins/swe/skills/run-tdd/SKILL.md — TDD cycle skill
- plugins/swe/skills/run-self-review/SKILL.md — self-review skill
- plugins/swe/skills/run-open-pr/SKILL.md — PR opening skill
- plugins/swe/skills/run-sync-docs/SKILL.md — docs sync skill
- plugins/swe/skills/run-clash-check/SKILL.md — clash detection skill
- plugins/swe/skills/run-domain-knowledge/SKILL.md — domain knowledge management
- plugins/swe/skills/run-design-decision/SKILL.md — design decision management
- plugins/swe/skills/run-spec/SKILL.md — spec management
- plugins/swe/docs/semver-bump.md — shared semver procedure
- plugins/swe/hooks/scripts/ — hook scripts (7 total)
- CLAUDE.md — project conventions

## Relevant Docs
None — knowledge base does not cover this area yet. This work creates the initial knowledge base.

## Scope

Create the initial project knowledge base across all three tiers:

### docs/domain/ — Business rules and invariants
- **Plugin system rules** — Manifest structure requirements (marketplace.json schema, plugin.json `"skills": "./skills"` requirement), version-keyed caching at `~/.claude/plugins/cache/`, version sync between marketplace and plugin manifests
- **Knowledge hierarchy** — Three-tier system (domain > decisions > specs), cascade rules (domain cascades to decisions + specs, decisions cascade to specs, specs don't cascade), clash-check depth-1 constraint

### docs/decisions/ — Architecture choices
- **Two-session model** — Why work is split between main session (project root) and worktree session; main runs triage + finish, worktree runs orchestrator
- **Worktree isolation** — Why git worktrees are used for concurrent work, branch naming convention (`<type>/<desc>`), folder convention (`.worktrees/<type>-<desc>`)
- **Handoff artifact pattern** — Why `.claude/handoff.md` exists as the contract between triage and orchestrator; lifecycle (created by triage, consumed by resume, removed before PR)
- **TDD-first development** — Why orchestrators use test-driven development; failure handling (3 attempts → WIP draft PR)
- **Autonomous orchestrators** — Why agents run to PR with zero human intervention; progress tracking via TaskCreate/TaskUpdate

### docs/specs/ — Workflow specifications
- **Work lifecycle** — Full triage → resume → orchestrator → finish flow with entry/exit conditions for each phase
- **Orchestrator pipeline** — Shared pipeline structure across all four orchestrators (handoff → tooling → docs → implement → review → sync → version → cleanup → PR)
- **Skill contracts** — What each skill expects as input, what it produces as output, which tools it uses
