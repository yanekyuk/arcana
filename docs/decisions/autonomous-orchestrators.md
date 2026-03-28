---
title: "Autonomous Orchestrators"
type: decision
tags: [orchestrator, agent, autonomous, pipeline, progress-tracking, knowledge-alignment]
created: 2026-03-26
updated: 2026-03-28
---

## Decision

Orchestrator agents run autonomously from handoff to PR. Progress is tracked via TaskCreate/TaskUpdate so users can monitor status. The sole exception to full autonomy is the knowledge alignment check, where the orchestrator pauses and uses `AskUserQuestion` to brainstorm with the user when misalignment with the knowledge base is detected.

## Context

The plugin's goal is to automate the full software engineering workflow. Human intervention at each step (write test, run test, implement, review, etc.) defeats the purpose. The agent needs to execute the entire pipeline independently, except when the knowledge alignment check detects a conflict between the planned work and the existing knowledge base -- in that case, the user's input is required to resolve the conflict before proceeding.

## Rationale

- **End-to-end automation** -- The agent handles every phase: reading the handoff, discovering tooling, fetching docs, implementing (via TDD), self-reviewing, syncing docs, bumping versions, cleaning up, and opening the PR.
- **Progress visibility** -- TaskCreate/TaskUpdate provide real-time status updates. Users see which step is in progress, which are complete, and which are pending via the task list (Ctrl+T). When marking a task completed, orchestrators report what actually happened (decisions, files touched, test outcomes) in the task description for a clear audit trail.
- **Graceful degradation** -- When the agent cannot complete a step (tests fail after retries, blocking self-review issues), it falls back to a WIP draft PR rather than hanging or crashing silently.
- **Deterministic pipeline** -- Every orchestrator follows a numbered step sequence. This makes behavior predictable and debuggable.

## Orchestrator Variants

Four orchestrators exist, each tailored to a work type:

| Orchestrator | Type | Default Version Bump | Max Turns | Unique Steps |
|---|---|---|---|---|
| feat-orchestrator | feat | MINOR | 100 | Knowledge alignment check, Draft spec, TDD cycle |
| fix-orchestrator | fix | PATCH | 100 | Knowledge alignment check, Root cause investigation, TDD reproduce |
| refactor-orchestrator | refactor | PATCH | 80 | Knowledge alignment check, TDD guard (pre-check), incremental refactor |
| docs-orchestrator | docs | none | 60 | Write/update docs, clash check |

## Constraints

- Orchestrators must not ask the user questions or wait for input **except** during the knowledge alignment check, where misalignment with the knowledge base triggers a brainstorming session with the user
- All orchestrators must remove the handoff artifact before opening the PR
- WIP draft PRs are the fallback for any unrecoverable failure
