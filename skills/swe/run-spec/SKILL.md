---
name: run-spec
description: "Use to create or update specification docs in .claude/docs/specs/ — checks alignment with parent domain knowledge and design decisions"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Grep, Glob, Agent
---

# Spec Management

You are creating or updating a specification document.

## Creating a new spec

1. Determine the spec topic from context (handoff artifact, user request, or current work)
2. Read relevant parent docs:
   - Grep `.claude/docs/domain/` and `.claude/docs/decisions/` for related tags
   - Read the top matches to understand constraints
3. Write the spec to `.claude/docs/specs/<kebab-case-title>.md`:

```yaml
---
title: "<descriptive title>"
type: spec
tags: [<lowercase, hyphen-separated, matching module/directory names>]
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---

## Behavior
<What the feature/fix does>

## Constraints
<Rules derived from domain knowledge>

## Acceptance Criteria
<Testable conditions>
```

4. Check alignment: verify the spec doesn't contradict any domain knowledge or design decisions you read. If it does, report the conflict.

## Updating an existing spec

1. Read the existing spec
2. Read its parent docs (domain + decisions) by tag matching
3. Make the update
4. Update the `updated` date
5. Check alignment with parents

## After writing

Commit the spec:
```bash
git add .claude/docs/specs/<filename>.md
git commit -m "docs: add/update spec — <title>"
```
