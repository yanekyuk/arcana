---
title: "Categorized Directives"
type: spec
tags: [directives, setup, skills, orchestrator, config]
created: 2026-03-27
updated: 2026-03-27
---

## Behavior

Custom directives are categorized by skill group so each skill receives only the directives relevant to its function. This replaces the flat `directives: string[]` with a structured object keyed by group.

### Directive Groups

| Group | Skills | Purpose |
|---|---|---|
| `implementation` | run-tdd | Coding style, patterns to favor, implementation preferences |
| `review` | run-self-review | Review focus areas, quality thresholds, things to watch for |
| `documentation` | run-sync-docs, run-spec, run-domain-knowledge, run-design-decision | Doc style, detail level, terminology preferences |
| `delivery` | run-open-pr, run-finish | PR conventions, merge preferences, changelog notes |
| `triage` | run-triage | Classification preferences, branch naming, scope boundaries |

Skills that remain directive-free: run-setup, run-start, run-arch-check, run-clash-check.

### Schema

```json
{
  "directives": {
    "implementation": ["string"],
    "review": ["string"],
    "documentation": ["string"],
    "delivery": ["string"],
    "triage": ["string"]
  }
}
```

All groups default to empty arrays. Missing groups are treated as empty.

### run-setup Collection Flow

When collecting directives, run-setup walks through each group in order:

1. Explain which skills the group covers and what kind of directives are appropriate
2. Accept zero or more directive strings for that group
3. When updating existing config, show current directives per group as defaults

### Skill Consumption

Each skill reads only its group's directives from `docs/swe-config.json`:
- Read config at startup
- Extract `directives.<group>` array
- Apply as soft guidance during execution

### Orchestrator Distribution

Orchestrators read the full directives object and:
- Apply relevant group directives during their own implementation steps (e.g., `implementation` directives during TDD)
- Pass the appropriate group when dispatching skills

## Constraints

- Directives remain soft guidance -- they do not hard-block any pipeline step
- All five groups must exist in the schema even if empty
- Backward compatibility: if a flat `directives: string[]` is encountered, treat all entries as `implementation` directives
- Group keys are fixed -- no user-defined groups

## Acceptance Criteria

1. `docs/swe-config.json` schema uses categorized directives object instead of flat array
2. `run-setup` collects directives per group with explanations
3. `run-setup` handles updating existing categorized directives
4. Each skill reads only its group's directives
5. Orchestrators pass correct directive groups when dispatching skills
6. `project-setup.md` schema docs reflect the new structure
7. `skill-contracts.md` inputs reflect directive group consumption
