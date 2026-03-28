---
title: "Task Result Reporting"
type: spec
tags: [orchestrator, task, reporting, pipeline, progress-tracking]
created: 2026-03-28
updated: 2026-03-28
---

## Behavior

When an orchestrator marks a pipeline task as `completed` via TaskUpdate, it must update the task `description` with a concise summary of what actually happened at that step. This enriches progress tracking with actionable context -- users and reviewers can inspect completed tasks to understand key decisions, files touched, tests written, commands run, and notable findings.

The mandate is added to Step 0 ("Initialize progress tracking") of all four orchestrator agents so it applies globally to every subsequent TaskUpdate call in the pipeline.

## Constraints

- The result summary is written to the `description` field of the TaskUpdate call that marks the task `completed`
- Summaries must be concise -- a few sentences, not a full log dump
- Each orchestrator provides a tailored example matching its pipeline type (feat, fix, refactor, docs)
- The mandate does not change the task creation step -- only the completion step
- No changes to pipeline step order, numbering, or task names

## Acceptance Criteria

- [ ] feat-orchestrator.md Step 0 includes a "Result reporting" mandate with a feat-specific example
- [ ] fix-orchestrator.md Step 0 includes a "Result reporting" mandate with a fix-specific example
- [ ] refactor-orchestrator.md Step 0 includes a "Result reporting" mandate with a refactor-specific example
- [ ] docs-orchestrator.md Step 0 includes a "Result reporting" mandate with a docs-specific example
- [ ] Each example demonstrates the `description` field usage in a TaskUpdate completion call
- [ ] The mandate text is consistent across all four orchestrators (only the example differs)
