---
title: "Handoff Artifact Pattern"
type: decision
tags: [handoff, triage, orchestrator, contract, artifact]
created: 2026-03-26
updated: 2026-04-20
---

## Decision

A structured markdown file at `docs/handoffs/<worktree-folder>.md` serves as the contract between the triage skill and the orchestrator agent. The file is named after the worktree folder (e.g., `docs/handoffs/feat-user-auth.md` for the `.worktrees/feat-user-auth` worktree).

## Context

The triage skill runs in one session and the orchestrator runs in another. There is no shared memory or state between sessions. A persistent, file-based contract is needed to transfer context. Using named handoff files (one per worktree) instead of a single `.claude/handoff.md` enables parallel work across multiple worktrees without path collisions.

## Rationale

- **Structured format** -- YAML frontmatter carries machine-readable fields (`trigger`, `type`, `branch`, `base-branch`, `created`, `version-bump`). Markdown body carries human-readable sections (Related Files, Relevant Docs, Scope).
- **Single source of truth** -- The orchestrator reads only this file to understand what to build. It does not re-explore the codebase from scratch.
- **Auditable** -- The handoff is committed to git, so the exact instructions given to the orchestrator are part of the branch history.
- **Disposable** -- The handoff is removed (`git rm`) before the PR is opened, so it never appears in the final diff against main.
- **Parallel-safe** -- Each worktree gets its own named handoff file, so multiple features/fixes can be triaged and worked on simultaneously without overwriting each other.

## Naming Convention

The handoff file name matches the worktree folder name:
- Worktree folder: `.worktrees/<type>-<short-description>`
- Handoff file: `docs/handoffs/<type>-<short-description>.md`

Example: branch `feat/user-auth` with worktree `.worktrees/feat-user-auth` produces `docs/handoffs/feat-user-auth.md`.

## Lifecycle

1. **Created by triage** -- `/run-triage` pipes the handoff content into `setup-worktree.sh`, which writes it to `docs/handoffs/<folder>.md` inside the worktree and commits it on the feature branch.
2. **Consumed by start** -- `/run-start` determines the worktree folder name via `basename "$PWD"`, reads `docs/handoffs/<folder>.md`, and dispatches the matching orchestrator based on the `type` field.
3. **Removed before PR** -- The orchestrator runs `git rm docs/handoffs/<folder>.md` as its second-to-last step, ensuring the artifact does not appear in the PR.

## Frontmatter Schema

```yaml
---
trigger: "<original user request>"
type: <feat|fix|refactor|docs>
branch: <type>/<short-description>
base-branch: <branch worktree was derived from>
created: <YYYY-MM-DD>
version-bump: <major|minor|patch|none>  # optional override
linear-issue: <LINEAR-ID>              # optional — set when a Linear issue is matched during triage
milestone: <milestone-title>           # optional — set when user assigns work to a GitHub milestone during triage
---
```

The `base-branch` field records the branch that was current when triage created the worktree. Orchestrators and `run-open-pr` use this value for the `--base` flag when creating PRs, ensuring the PR targets the correct branch instead of hardcoding `main`.

The `milestone` field records the GitHub milestone title assigned during triage. When present, `run-open-pr` assigns the PR to this milestone, and `run-finish` uses the milestone's title as a target version for version bumping (if the title is a valid semver string). This enables multiple features within the same milestone to converge to a single target version instead of auto-incrementing independently.

## Body Sections

- **Related Files** -- Files discovered during triage exploration
- **Relevant Docs** -- Matched knowledge docs from `docs/`, or "None" if the knowledge base does not cover the area
- **Scope** -- Summary of what needs to be done and why
