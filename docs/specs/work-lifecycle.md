---
title: "Work Lifecycle"
type: spec
tags: [lifecycle, triage, resume, orchestrator, finish, workflow]
created: 2026-03-26
updated: 2026-03-26
---

## Behavior

The complete work lifecycle flows through four phases across two sessions. Each phase has explicit entry conditions, actions, and exit conditions.

## Phase 1: Triage (`/run-triage`)

**Session:** Main (project root)

**Entry conditions:**
- User provides a ticket, idea, or bug report
- Working tree is clean on the main branch

**Actions:**
1. Read the user's request (no clarifying questions)
2. Explore related code via Grep/Glob (read max 5 files)
3. Fetch relevant knowledge docs from `docs/` if they exist (top 5 by tag match)
4. Propose classification: feat, fix, refactor, or docs
5. Wait for user confirmation or override
6. Create branch (`<type>/<short-description>`) and worktree (`.worktrees/<type>-<short-description>`)
7. Write `.claude/handoff.md` into the worktree and commit

**Exit conditions:**
- Branch and worktree exist
- Handoff artifact is committed in the worktree
- User is instructed to `cd` into the worktree and start a new session

## Phase 2: Resume (`/run-resume`)

**Session:** Worktree

**Entry conditions:**
- Current directory is a git worktree (`.git` is a file, not a directory)
- `.claude/handoff.md` exists

**Actions:**
1. Validate worktree context
2. Read handoff artifact
3. Dispatch the matching orchestrator agent based on the `type` field

**Exit conditions:**
- Orchestrator agent is dispatched and running autonomously

## Phase 3: Orchestrator (autonomous agent)

**Session:** Worktree (same session as resume)

**Entry conditions:**
- Handoff content is provided as context
- Worktree is on the correct branch

**Actions:** (vary by orchestrator type, but shared structure)
1. Initialize progress tracking (TaskCreate for all steps)
2. Read handoff
3. Discover project tooling (feat/fix/refactor only)
4. Fetch relevant knowledge docs
5. Type-specific work (spec drafting, TDD, investigation, doc writing)
6. Self-review (feat/fix/refactor only)
7. Sync docs
8. Version bump
9. Remove handoff artifact (`git rm .claude/handoff.md`)
10. Push and open PR via `gh pr create`

**Exit conditions:**
- PR is open (regular or WIP draft)
- Handoff artifact is removed from the branch
- User is instructed to return to main session and run `/run-finish`

## Phase 4: Finish (`/run-finish`)

**Session:** Main (project root)

**Entry conditions:**
- Current directory is the main repo (not a worktree)
- At least one open PR exists

**Actions:**
1. Validate main repo context
2. Identify the PR (auto-select if only one, prompt if multiple)
3. Review: conventional commits compliance, diff quality, scope alignment, test coverage
4. If issues found: present structured review with fix prompt, stop
5. If clean: proceed to merge (ask user for squash vs merge commit, default squash)
6. Clean up: pull main, remove worktree, delete local branch

**Exit conditions:**
- PR is merged
- Remote and local branches are deleted
- Worktree is removed
- Main branch is up to date
