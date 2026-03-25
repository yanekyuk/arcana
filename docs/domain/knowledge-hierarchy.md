---
title: "Knowledge Hierarchy"
type: domain
tags: [knowledge, docs, domain, decisions, specs, clash-check, cascade]
created: 2026-03-26
updated: 2026-03-26
---

## Three-Tier System

Project knowledge is organized into three tiers with strict authority ordering:

1. **Domain** (`docs/domain/`) -- Business rules, invariants, and constraints. Highest authority.
2. **Decisions** (`docs/decisions/`) -- Architecture choices, patterns, and rationale. Mid-tier authority.
3. **Specs** (`docs/specs/`) -- Feature and fix specifications with acceptance criteria. Lowest authority.

A document at a higher tier always takes precedence over a document at a lower tier in case of conflict.

## Cascade Rules

When a document is created or modified, changes may invalidate documents in lower tiers:

- **Domain changes** cascade to both decisions and specs. A new domain rule may contradict existing decisions or specs, requiring review.
- **Decision changes** cascade to specs only. A revised architectural choice may invalidate spec assumptions.
- **Spec changes** do not cascade. Specs are leaf-level documents with no dependents.

Cascade direction is always downward (higher authority to lower authority), never upward.

## Clash Check

After any documentation change, a clash-check is dispatched as a subagent to detect:

- **Contradictions** -- rules, decisions, or specs that directly conflict
- **Overlaps** -- documents covering the same topic with divergent details
- **Ambiguity** -- vague language open to conflicting interpretations
- **Alignment violations** -- lower-tier docs that violate higher-tier rules

### Depth-1 Constraint

Clash-check runs at cascade depth 1. It must not trigger further cascades or dispatch additional skills/agents. This constraint prevents unbounded recursive checking and keeps token costs isolated.

### Warnings, Not Errors

Clashes are surfaced as warnings in the PR description for human review. They do not block the pipeline.

## Document Format

All knowledge documents use YAML frontmatter:

```yaml
---
title: "<descriptive title>"
type: <domain|decision|spec>
tags: [<lowercase, hyphen-separated, matching module/directory names>]
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---
```

Tags must be lowercase and hyphen-separated, matching module or directory names from the codebase to enable keyword-based discovery.
