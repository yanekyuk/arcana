---
name: run-design-decision
description: "Use to create or update design decision docs (architecture, patterns, rationale) in .claude/docs/decisions/ — checks alignment with domain knowledge, triggers clash-check on specs"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Grep, Glob, Agent
---

# Design Decision Management

You are creating or updating a design decision document — architectural choices, patterns, and their rationale.

## Creating a new decision doc

1. Determine the topic from context or user request
2. Check alignment upward: grep `.claude/docs/domain/` for related tags and read matches. Verify the decision doesn't violate any domain rules.
3. Write to `.claude/docs/decisions/<kebab-case-title>.md`:

```yaml
---
title: "<descriptive title>"
type: decision
tags: [<lowercase, hyphen-separated, matching module/directory names>]
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---

## Decision
<What was decided>

## Context
<Why this decision was needed>

## Rationale
<Why this option was chosen over alternatives>

## Constraints
<Domain rules that influenced this decision>
```

4. Commit:
```bash
git add .claude/docs/decisions/<filename>.md
git commit -m "docs: add design decision — <title>"
```

## Updating an existing decision doc

1. Read the existing doc
2. Check alignment with domain knowledge (upward)
3. Make the update
4. Update the `updated` date
5. Commit

## After writing (cascade)

Design decisions sit in the middle tier. Check both directions:

1. **Upward check** (already done): alignment with domain knowledge
2. **Downward cascade**: dispatch `run-clash-check` as a subagent targeting `.claude/docs/specs/`. This is a depth-1 cascade — `run-clash-check` must NOT trigger further cascades.

Report:
- What was created/updated
- Any alignment issues with domain knowledge
- Any clashes with specs detected by the subagent
