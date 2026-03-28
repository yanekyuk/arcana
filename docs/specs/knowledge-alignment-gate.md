---
title: "Knowledge Alignment Gate"
type: spec
tags: [orchestrator, knowledge, alignment, domain, decisions, specs, brainstorming, pipeline]
created: 2026-03-26
updated: 2026-03-28
---

## Behavior

A new pipeline step ("Knowledge alignment check") is inserted into the feat, fix, and refactor orchestrators between "Fetch docs" (Step 3) and the first implementation step. This step validates the planned work against the knowledge base (domain rules, design decisions, specs) and pauses autonomy when misalignment is detected, entering a brainstorming session with the user.

The docs orchestrator is excluded because it directly manipulates documentation and already has clash-check as its quality gate.

### Alignment Validation

After fetching knowledge docs, the orchestrator cross-references the handoff scope against each knowledge tier:

1. **Domain rules** (`docs/domain/`) -- Do any planned changes conflict with or imply changes to business rules?
2. **Design decisions** (`docs/decisions/`) -- Does the planned work conflict with or require new architectural patterns?
3. **Specs** (`docs/specs/`) -- Does the planned work deviate from or require updates to existing specifications?

### Flow-Specific Permissions

| Tier | feat | fix | refactor |
|---|---|---|---|
| Domain | CAN ADD | READ-ONLY | CAN EDIT |
| Decisions | CAN CREATE / ALIGN | READ-ONLY | CAN EDIT / FORCE ALIGN |
| Specs | CAN CREATE | Primary focus | Not primary concern |

### Conflict Triggers

- **fix**: Any planned change that would violate a domain rule, deviate from spec, or alter a design pattern triggers a block.
- **feat**: Implied new domain knowledge, need for a new design pattern, or conflict with existing patterns triggers a pause.
- **refactor**: Changes to how domain rules are expressed, or updates to design patterns trigger a pause.

### Brainstorming Session

When misalignment is detected, the orchestrator:

1. Presents the specific conflict (quotes the relevant doc section and the planned work that conflicts)
2. Asks targeted questions (not open-ended) to resolve the conflict
3. Uses the `AskUserQuestion` tool to collect user responses -- does not proceed until the user answers
4. Continues asking (via `AskUserQuestion`) until all conflicts are resolved
5. Documents any decisions made during brainstorming in the appropriate `docs/` tier
6. Only then proceeds with implementation

### No-Conflict Fast Path

If no misalignment is detected, the step passes silently and the pipeline continues autonomously.

## Constraints

- The brainstorming session is the only point where orchestrators pause for user input (via the `AskUserQuestion` tool). All other steps remain fully autonomous.
- The step must not modify any knowledge documents on its own -- it can only create/update docs to capture decisions made during the brainstorming session with user confirmation.
- The knowledge hierarchy authority order (domain > decisions > specs) must be respected: lower-tier docs cannot override higher-tier rules.
- The step runs after knowledge docs are fetched so it has full context, and before implementation so conflicts are caught early.

## Acceptance Criteria

- [ ] feat-orchestrator.md contains a "Knowledge alignment check" step between "Fetch docs" and "Draft spec"
- [ ] fix-orchestrator.md contains a "Knowledge alignment check" step between "Fetch docs" and "Investigate root cause"
- [ ] refactor-orchestrator.md contains a "Knowledge alignment check" step between "Fetch docs" and "TDD guard"
- [ ] Each orchestrator's Step 0 task list includes the new step
- [ ] Each orchestrator specifies flow-specific permissions (what it CAN ADD/EDIT vs READ-ONLY)
- [ ] The brainstorming session format is documented with the 6-step process
- [ ] No-conflict fast path is documented (silent pass when aligned)
- [ ] All subsequent step numbers are incremented to accommodate the new step
- [ ] Each orchestrator includes `AskUserQuestion` in its `tools:` frontmatter
- [ ] Step 4c explicitly references the `AskUserQuestion` tool for collecting user responses
- [ ] The orchestrator-pipeline spec is updated to reflect the new shared pipeline step
