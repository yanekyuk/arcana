---
name: run-domain-knowledge
description: "Use to create or update domain knowledge docs (business rules, invariants, constraints) in docs/domain/ — triggers clash-check on decisions and specs"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent
---

# Domain Knowledge Management

You are creating or updating a domain knowledge document — business rules, invariants, and constraints that govern the system.

## Creating a new domain doc

1. Determine the topic from context or user request
2. Write to `docs/domain/<kebab-case-title>.md`:

```yaml
---
title: "<descriptive title>"
type: domain
tags: [<lowercase, hyphen-separated, matching module/directory names>]
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---

<Document the business rules, invariants, or constraints clearly and concisely.
Each rule should be a separate paragraph or bullet point.
Include rationale where known.>
```

3. Commit:
```bash
git add docs/domain/<filename>.md
git commit -m "docs: add domain knowledge — <title>"
```

## Updating an existing domain doc

1. Read the existing doc
2. Make the update
3. Update the `updated` date
4. Commit:
```bash
git add docs/domain/<filename>.md
git commit -m "docs: update domain knowledge — <title>"
```

## After writing (cascade)

Domain knowledge is the highest tier. Changes here can invalidate design decisions and specs.

Dispatch `run-clash-check` as a subagent (via the Agent tool) targeting both `docs/decisions/` and `docs/specs/`. This is a depth-1 cascade — `run-clash-check` must NOT trigger further cascades.

Report:
- What was created/updated
- Any clashes detected by the subagent
