# SWE Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the SWE domain plugin — 10 micro-skills and 4 orchestrator agents that automate development workflows from triage to PR.

**Architecture:** Orchestrator + micro-skills pattern. Skills are SKILL.md prompt files for standalone user invocation. Orchestrator agents are self-contained agent prompts that embed pipeline logic and use tools directly. A two-session model bridges triage (project root) and execution (worktree).

**Tech Stack:** Claude Code plugin system (SKILL.md, agent .md), git worktrees, Bash, gh CLI

**Spec:** `docs/specs/2026-03-25-swe-domain-design.md`

---

## File Structure

```
skills/swe/
├── run-triage/SKILL.md          # Dispatch: triage → branch → worktree → handoff
├── run-resume/SKILL.md          # Dispatch: read handoff → launch orchestrator
├── run-tdd/SKILL.md             # Pipeline: TDD cycle
├── run-self-review/SKILL.md     # Pipeline: diff review against spec/domain
├── run-open-pr/SKILL.md         # Pipeline: commit → push → PR
├── run-sync-docs/SKILL.md       # Pipeline: detect & update .claude/docs/
├── run-spec/SKILL.md            # Pipeline: create/update specs
├── run-domain-knowledge/SKILL.md # Standalone: create/update domain docs
├── run-design-decision/SKILL.md  # Standalone: create/update decision docs
└── run-clash-check/SKILL.md      # Standalone: detect contradictions

agents/swe/
├── feat-orchestrator.md          # Full feat pipeline agent
├── fix-orchestrator.md           # Full fix pipeline agent
├── refactor-orchestrator.md      # Full refactor pipeline agent
└── docs-orchestrator.md          # Full docs pipeline agent
```

Each skill is a single SKILL.md file (no supporting files needed — all logic is in the prompt). Each agent is a single .md file with YAML frontmatter and a system prompt body.

---

### Task 1: run-triage skill

**Files:**
- Create: `skills/swe/run-triage/SKILL.md`

- [ ] **Step 1: Create the SKILL.md with frontmatter**

```markdown
---
name: run-triage
description: "Use when starting new work — explores codebase, classifies as feat/fix/refactor/docs, creates branch + worktree + handoff artifact"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Write, Agent
---

# Triage

You are triaging a new piece of work. Follow these steps exactly.

## Step 1: Understand the trigger

The user has provided a ticket, idea, or bug report. Read it carefully. Ask NO clarifying questions — work with what you have.

## Step 2: Explore related code

- Use Grep and Glob to find files related to the trigger
- Read the most relevant files (max 5)
- Check recent git history: `git log --oneline -20`

## Step 3: Fetch relevant knowledge docs

If `.claude/docs/` exists, scan for relevant docs:

1. Extract keywords from the trigger and related file paths
2. Exclude noise: src, lib, utils, helpers, index, test, tests, __tests__, dist, build
3. Normalize: lowercase, split on hyphens and camelCase
4. Grep `.claude/docs/` frontmatter `tags` for matches
5. Read the top 5 matching docs. If more than 5 match, log the skipped doc paths for transparency.

## Step 4: Propose classification

Based on your exploration, propose one of:
- **feat** — new functionality
- **fix** — bug fix
- **refactor** — restructuring without behavior change
- **docs** — documentation only

Present your reasoning and **wait for the user to confirm or override**.

## Step 5: Create branch and worktree

After user confirms the classification:

1. Determine a short kebab-case description (2-4 words max)
2. Check for collisions:
   ```bash
   git branch --list <type>/<short-description>
   test -d .worktrees/<type>-<short-description>
   ```
   If branch or worktree already exists, offer the user two options: resume the existing worktree, or create with a numeric suffix (e.g., `feat/user-auth-2`).
3. Create the branch:
   ```bash
   git branch <type>/<short-description>
   ```
4. Create worktree:
   ```bash
   mkdir -p .worktrees
   git worktree add .worktrees/<type>-<short-description> <type>/<short-description>
   ```

## Step 6: Write handoff artifact

Create the `.claude/` directory in the worktree and write the handoff:

```bash
mkdir -p .worktrees/<folder>/.claude
```

Write to `.worktrees/<folder>/.claude/handoff.md`:

```yaml
---
trigger: "<original user request>"
type: <feat|fix|refactor|docs>
branch: <type>/<short-description>
created: <YYYY-MM-DD>
---

## Related Files
<list of files discovered in step 2>

## Relevant Docs
<list of matched .claude/docs/ paths, or "None — knowledge base does not cover this area yet.">

## Scope
<summary of what needs to be done and why>
```

## Step 7: Commit and instruct

```bash
cd .worktrees/<folder>
git add .claude/handoff.md
git commit -m "chore: add handoff artifact for <type>/<short-description>"
```

Then tell the user:

> Worktree ready. Run `cd .worktrees/<folder>` and start a new Claude session. Then run `/run-resume` to begin.
```

- [ ] **Step 2: Verify the skill file is well-formed**

Run: `cat skills/swe/run-triage/SKILL.md | head -5`
Expected: frontmatter starts with `---`

- [ ] **Step 3: Commit**

```bash
git add skills/swe/run-triage/SKILL.md
git commit -m "feat: add run-triage skill"
```

---

### Task 2: run-resume skill

**Files:**
- Create: `skills/swe/run-resume/SKILL.md`

- [ ] **Step 1: Create the SKILL.md**

```markdown
---
name: run-resume
description: "Use when entering a worktree to resume work — reads handoff artifact and dispatches the matching orchestrator agent"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Bash, Agent
---

# Resume

You are resuming work in a worktree. Follow these steps exactly.

## Step 1: Validate worktree

Check that you're in a git worktree (not the main repo):

```bash
test -f .git && echo "WORKTREE" || echo "NOT_WORKTREE"
```

If NOT_WORKTREE, tell the user: "This doesn't appear to be a git worktree. Please cd into a worktree under .worktrees/ first."

## Step 2: Read handoff

Read `.claude/handoff.md` in the current directory. If it doesn't exist, tell the user: "No handoff artifact found. Run /run-triage in the project root first."

## Step 3: Dispatch orchestrator

Based on the `type` field in the handoff frontmatter, dispatch the matching orchestrator agent:

- `feat` → use the Agent tool with the `feat-orchestrator` agent
- `fix` → use the Agent tool with the `fix-orchestrator` agent
- `refactor` → use the Agent tool with the `refactor-orchestrator` agent
- `docs` → use the Agent tool with the `docs-orchestrator` agent

Pass the full handoff content as context to the agent.

The orchestrator will run autonomously to PR. Do not interfere.
```

- [ ] **Step 2: Commit**

```bash
git add skills/swe/run-resume/SKILL.md
git commit -m "feat: add run-resume skill"
```

---

### Task 3: run-tdd skill

**Files:**
- Create: `skills/swe/run-tdd/SKILL.md`

- [ ] **Step 1: Create the SKILL.md**

```markdown
---
name: run-tdd
description: "Use for test-driven development — write failing test, implement until green, repeat per unit of work"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# TDD Cycle

You are doing test-driven development. Follow this cycle strictly.

## Prerequisites

Before starting, discover the test runner:
- Check `package.json` scripts for `test` command
- Check for `Makefile`, `Cargo.toml`, `pyproject.toml`, `go.mod`
- If unclear and used standalone, ask the user. Within a pipeline (orchestrator context), infer the best available option — check for common test runner binaries on PATH.

## The Cycle

For each unit of work:

### 1. Write a failing test

- Write the smallest test that describes the next piece of behavior
- The test MUST fail before you write implementation code
- Run the test to confirm it fails:
  ```
  <test-command> <specific-test-file-or-filter>
  ```
- If the test passes without implementation, your test isn't testing anything new — revise it

### 2. Implement minimally

- Write the minimum code to make the failing test pass
- Do NOT write code for behavior that isn't tested yet
- Run the test to confirm it passes

### 3. Refactor (if needed)

- Clean up the implementation while keeping tests green
- Run all related tests after refactoring

### 4. Commit

```bash
git add <test-file> <implementation-file>
git commit -m "<type>: <what this unit does>"
```

## Failure handling

If a test won't pass after 3 attempts for a single unit of work:
1. Stop the TDD cycle
2. Commit what you have with message: `wip: <what was attempted>`
3. Report what failed and why
```

- [ ] **Step 2: Commit**

```bash
git add skills/swe/run-tdd/SKILL.md
git commit -m "feat: add run-tdd skill"
```

---

### Task 4: run-self-review skill

**Files:**
- Create: `skills/swe/run-self-review/SKILL.md`

- [ ] **Step 1: Create the SKILL.md**

```markdown
---
name: run-self-review
description: "Use to review your own changes — diffs against base branch, checks alignment with spec and domain knowledge"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Bash, Grep, Glob
---

# Self-Review

You are reviewing your own changes before opening a PR. Be rigorous — pretend you're reviewing someone else's code.

## Step 1: Detect base branch and get the diff

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git diff $BASE...HEAD --stat
git diff $BASE...HEAD
```

## Step 2: Load context

Read the handoff artifact (`.claude/handoff.md`) to understand the original scope.

Read any specs or domain docs referenced in the handoff's "Relevant Docs" section.

## Step 3: Check alignment

For each changed file, verify:

1. **Scope compliance** — Does this change serve the stated scope? Flag any scope creep.
2. **Spec alignment** — If a spec exists, does the implementation match it?
3. **Domain rule compliance** — Do the changes violate any domain knowledge docs?
4. **Test coverage** — Is every behavior change covered by a test?
5. **Code quality** — No debug code, no commented-out code, no TODOs that should be resolved.

## Step 4: Report

If all checks pass: report "Self-review passed. No issues found."

If issues found:
- List each issue with file path and line reference
- Classify as **blocking** (must fix before PR) or **non-blocking** (note in PR)
- Attempt to fix blocking issues
- If fix fails after 1 retry, report the blocking issue for the pipeline to handle
```

- [ ] **Step 2: Commit**

```bash
git add skills/swe/run-self-review/SKILL.md
git commit -m "feat: add run-self-review skill"
```

---

### Task 5: run-open-pr skill

**Files:**
- Create: `skills/swe/run-open-pr/SKILL.md`

- [ ] **Step 1: Create the SKILL.md**

```markdown
---
name: run-open-pr
description: "Use to finalize work — commits remaining changes, pushes branch, opens a PR with conventional title and structured body"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Bash, Grep
---

# Open PR

You are finalizing work and opening a pull request.

## Step 1: Stage and commit any remaining changes

```bash
git status
```

If there are unstaged changes, review `git status` output first. Do NOT stage files matching `.env`, `credentials*`, `*.key`, or other sensitive patterns. Stage specific files:
```bash
git add <specific-changed-files>
git commit -m "<type>: <final changes description>"
```

## Step 2: Push

```bash
git push -u origin HEAD
```

If push fails, retry once. If still failing, report the error and stop.

## Step 3: Determine PR content

Read `.claude/handoff.md` for trigger and scope context.

**Title format:** `<type>: <short description>` where type comes from the handoff `type` field.

**Body:** Use this template:

```markdown
## Summary
<What changed and why, derived from handoff scope>

## Changes
<Bulleted list of key changes>

## Test Plan
<How this was tested — list test files and what they cover>

## Knowledge Warnings
<Any clash-check warnings from the pipeline, or "None">
```

If `run-sync-docs` detected that `CLAUDE.md` might need updating, add a section:

```markdown
## Recommended CLAUDE.md Updates
<Suggested changes for human review>
```

## Step 4: Create PR

```bash
gh pr create --title "<title>" --body "<body>" --base main
```

Target the repository's default branch (typically `main`).

If this is a WIP (pipeline stopped early), use:
```bash
gh pr create --title "[WIP] <title>" --body "<body>" --base main --draft
```

Report the PR URL when done.
```

- [ ] **Step 2: Commit**

```bash
git add skills/swe/run-open-pr/SKILL.md
git commit -m "feat: add run-open-pr skill"
```

---

### Task 6: run-sync-docs skill

**Files:**
- Create: `skills/swe/run-sync-docs/SKILL.md`

- [ ] **Step 1: Create the SKILL.md**

```markdown
---
name: run-sync-docs
description: "Use after implementation to detect if .claude/docs/ need updating based on changes made — updates docs, triggers clash-check"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent
---

# Sync Docs

You are checking whether the implementation work introduced knowledge that should be captured in `.claude/docs/`.

## Step 1: Understand what changed

```bash
git diff main...HEAD --stat
git diff main...HEAD
```

## Step 2: Scan for implicit knowledge

Review the diff for:

1. **New domain rules** — business logic, validation rules, constraints that were implemented but not documented in `.claude/docs/domain/`
2. **Design decisions** — architectural choices, pattern selections, trade-offs that were made but not captured in `.claude/docs/decisions/`
3. **Spec gaps** — behavior that was implemented but differs from or extends existing specs in `.claude/docs/specs/`

## Step 3: Update docs

For each piece of implicit knowledge found:

- If a relevant doc exists, update it (add the new rule/decision/behavior)
- If no relevant doc exists, create one with proper frontmatter:

```yaml
---
title: "<descriptive title>"
type: <domain|decision|spec>
tags: [<lowercase, hyphen-separated, matching module/directory names>]
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
---
```

## Step 4: Trigger clash-check

If any docs were created or updated, dispatch `run-clash-check` as a subagent (via the Agent tool) on the affected tiers. This is a depth-1 cascade — do NOT trigger further cascades from this invocation.

## Step 5: Check CLAUDE.md

Review changes for new conventions or patterns that might warrant `CLAUDE.md` updates. Do NOT modify `CLAUDE.md` directly. Instead, note any recommended changes — these will be included in the PR description for human review.

Report:
- Which docs were created/updated (if any)
- Any clash-check warnings
- Any recommended CLAUDE.md changes
```

- [ ] **Step 2: Commit**

```bash
git add skills/swe/run-sync-docs/SKILL.md
git commit -m "feat: add run-sync-docs skill"
```

---

### Task 7: run-spec skill

**Files:**
- Create: `skills/swe/run-spec/SKILL.md`

- [ ] **Step 1: Create the SKILL.md**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/swe/run-spec/SKILL.md
git commit -m "feat: add run-spec skill"
```

---

### Task 8: run-domain-knowledge skill

**Files:**
- Create: `skills/swe/run-domain-knowledge/SKILL.md`

- [ ] **Step 1: Create the SKILL.md**

```markdown
---
name: run-domain-knowledge
description: "Use to create or update domain knowledge docs (business rules, invariants, constraints) in .claude/docs/domain/ — triggers clash-check on decisions and specs"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Grep, Glob, Agent
---

# Domain Knowledge Management

You are creating or updating a domain knowledge document — business rules, invariants, and constraints that govern the system.

## Creating a new domain doc

1. Determine the topic from context or user request
2. Write to `.claude/docs/domain/<kebab-case-title>.md`:

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
git add .claude/docs/domain/<filename>.md
git commit -m "docs: add domain knowledge — <title>"
```

## Updating an existing domain doc

1. Read the existing doc
2. Make the update
3. Update the `updated` date
4. Commit:
```bash
git add .claude/docs/domain/<filename>.md
git commit -m "docs: update domain knowledge — <title>"
```

## After writing (cascade)

Domain knowledge is the highest tier. Changes here can invalidate design decisions and specs.

Dispatch `run-clash-check` as a subagent (via the Agent tool) targeting both `.claude/docs/decisions/` and `.claude/docs/specs/`. This is a depth-1 cascade — `run-clash-check` must NOT trigger further cascades.

Report:
- What was created/updated
- Any clashes detected by the subagent
```

- [ ] **Step 2: Commit**

```bash
git add skills/swe/run-domain-knowledge/SKILL.md
git commit -m "feat: add run-domain-knowledge skill"
```

---

### Task 9: run-design-decision skill

**Files:**
- Create: `skills/swe/run-design-decision/SKILL.md`

- [ ] **Step 1: Create the SKILL.md**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/swe/run-design-decision/SKILL.md
git commit -m "feat: add run-design-decision skill"
```

---

### Task 10: run-clash-check skill

**Files:**
- Create: `skills/swe/run-clash-check/SKILL.md`

- [ ] **Step 1: Create the SKILL.md**

```markdown
---
name: run-clash-check
description: "Use to scan knowledge docs for contradictions, overlaps, and misalignments — dispatched as subagent to isolate token cost"
user-invocable: true
disable-model-invocation: true
context: fork
allowed-tools: Read, Grep, Glob
---

# Clash Check

You are scanning knowledge documents for contradictions, overlaps, and misalignments. You run in an isolated context (`context: fork` means this skill executes as an isolated subagent with its own token budget, per the spec requirement that clash-check token cost stays out of the main pipeline).

**IMPORTANT:** You are executing as part of a cascade. Cascade depth is 1. Do NOT trigger any further cascades or dispatch any other skills/agents.

## Input

You will be given a target — one or more tiers to scan:
- `.claude/docs/domain/`
- `.claude/docs/decisions/`
- `.claude/docs/specs/`

If no specific target is provided, scan all tiers.

## Process

1. Read ALL documents in the targeted tier(s):
   ```bash
   find .claude/docs/<tier>/ -name "*.md" -type f
   ```
   Read each file.

2. For each pair of documents in the same tier, check for:
   - **Contradictions** — rules/decisions/specs that directly conflict
   - **Overlaps** — documents covering the same topic with divergent details
   - **Ambiguity** — vague language that could be interpreted differently

3. For cross-tier checks (when multiple tiers are targeted):
   - Specs that violate their parent decisions
   - Decisions that violate domain rules
   - Orphaned specs (no corresponding decision or domain knowledge)

## Output

If no clashes found:
> Clash check passed. No contradictions, overlaps, or misalignments detected across <N> documents in <tiers>.

If clashes found, report each one:
> **Clash detected:**
> - **Type:** contradiction | overlap | ambiguity | alignment-violation
> - **Documents:** `<path1>` vs `<path2>`
> - **Details:** <specific description of the clash>
> - **Suggestion:** <how to resolve>

These are **warnings, not errors**. The pipeline continues. Clashes are surfaced in the PR description for human review.
```

- [ ] **Step 2: Commit**

```bash
git add skills/swe/run-clash-check/SKILL.md
git commit -m "feat: add run-clash-check skill"
```

---

### Task 11: feat-orchestrator agent

**Files:**
- Create: `agents/swe/feat-orchestrator.md`

- [ ] **Step 1: Create the agent definition**

```markdown
---
name: feat-orchestrator
description: "Autonomous feature development pipeline — reads handoff, discovers tooling, fetches docs, drafts spec, TDD cycle, self-review, sync docs, opens PR"
model: opus
tools: Read, Write, Edit, Bash, Grep, Glob, Agent
maxTurns: 100
---

# Feature Orchestrator

You are an autonomous feature development agent. You will implement a feature from handoff to PR with zero human intervention. Follow every step precisely.

## Step 1: Read handoff

Read `.claude/handoff.md` in the current directory. Parse the frontmatter and all sections. This is your source of truth for what to build.

## Step 2: Discover project tooling

Detect the test runner and build tools:
- Check `package.json` for `scripts.test`, `scripts.build`
- Check for `Makefile`, `Cargo.toml`, `pyproject.toml`, `go.mod`
- Store the test command (e.g., `bun test`, `npm test`, `pytest`) for later use

## Step 3: Fetch relevant knowledge docs

If `.claude/docs/` exists:

1. Extract keywords from the handoff: file paths → module/directory names, trigger text → nouns and domain terms
2. Exclude noise: src, lib, utils, helpers, index, test, tests, __tests__, dist, build
3. Normalize: lowercase, split on hyphens and camelCase
4. Grep `.claude/docs/` frontmatter `tags` for matches
5. Rank by match count, read top 5. If more than 5 match, log the skipped doc paths for transparency.

Remember the content of these docs — they inform your implementation.

## Step 4: Draft spec (if needed)

Check if a relevant spec already exists in `.claude/docs/specs/`.

If not, create one:

```yaml
---
title: "<feature name>"
type: spec
tags: [<relevant tags>]
created: <today>
updated: <today>
---

## Behavior
<What the feature does, derived from handoff scope>

## Constraints
<Rules from domain knowledge docs>

## Acceptance Criteria
<Testable conditions>
```

Verify the spec doesn't contradict domain knowledge or design decisions.

Commit: `git add .claude/docs/specs/<file>.md && git commit -m "docs: add spec — <title>"`

## Step 5: TDD cycle

For each unit of work in the feature:

### 5a. Write a failing test
- Write the smallest test that describes the next behavior
- Run it: `<test-command> <specific-test>`
- Confirm it FAILS. If it passes, revise the test.

### 5b. Implement minimally
- Write minimum code to make the test pass
- Run the test to confirm it passes
- Run the full test suite to check for regressions

### 5c. Commit
```bash
git add <test-file> <implementation-file>
git commit -m "feat: <what this unit does>"
```

### 5d. Repeat for each unit

**Failure handling:** If a test won't pass after 3 attempts for a single unit:
1. Stop the TDD cycle
2. `git add -A && git commit -m "wip: <what was attempted>"`
3. Skip to Step 8 (Open PR) and create a draft PR with `[WIP]` prefix

## Step 6: Self-review

1. Get the full diff: `git diff main...HEAD`
2. Read the handoff and any referenced specs/domain docs
3. Check:
   - Scope compliance — no scope creep
   - Spec alignment — implementation matches spec
   - Domain rule compliance — no violations
   - Test coverage — all behavior changes tested
   - Code quality — no debug code, no stale TODOs
4. If blocking issues found: attempt to fix. If fix fails after 1 retry, proceed to Step 8 as draft PR.

## Step 7: Sync docs

1. Review the diff for implicit knowledge:
   - New domain rules not documented
   - Design decisions not captured
   - Spec gaps
2. Create or update docs in `.claude/docs/` as needed
3. If any docs changed, dispatch a clash-check subagent:
   - Use the Agent tool
   - Tell it which tiers to scan
   - It runs in a fork — its token cost is isolated
   - If clashes found, note them for the PR description
4. Check if `CLAUDE.md` might need updating. Do NOT modify it. Note any suggestions for the PR description.
5. Commit only the specific doc files that were created or updated: `git add <specific-doc-files> && git commit -m "docs: sync knowledge docs"`

## Step 8: Open PR

1. Push: `git push -u origin HEAD`
2. Build PR title: `feat: <short description from handoff>`
3. Build PR body:

```markdown
## Summary
<From handoff scope>

## Changes
<Bulleted list of key changes>

## Test Plan
<Test files and what they cover>

## Knowledge Warnings
<Clash-check warnings, or "None">
```

If `CLAUDE.md` updates were recommended, add:
```markdown
## Recommended CLAUDE.md Updates
<Suggestions>
```

4. Create PR:
```bash
gh pr create --title "<title>" --body "<body>" --base main
```

If this is a WIP:
```bash
gh pr create --title "[WIP] <title>" --body "<body>" --base main --draft
```

Report the PR URL.
```

- [ ] **Step 2: Commit**

```bash
git add agents/swe/feat-orchestrator.md
git commit -m "feat: add feat-orchestrator agent"
```

---

### Task 12: fix-orchestrator agent

**Files:**
- Create: `agents/swe/fix-orchestrator.md`

- [ ] **Step 1: Create the agent definition**

```markdown
---
name: fix-orchestrator
description: "Autonomous bug fix pipeline — reads handoff, discovers tooling, fetches docs, reproduces bug via TDD, fixes, self-review, sync docs, opens PR"
model: opus
tools: Read, Write, Edit, Bash, Grep, Glob, Agent
maxTurns: 80
---

# Fix Orchestrator

You are an autonomous bug fix agent. You will fix a bug from handoff to PR with zero human intervention. Follow every step precisely.

## Step 1: Read handoff

Read `.claude/handoff.md`. Parse frontmatter and all sections.

## Step 2: Discover project tooling

Detect test runner and build tools:
- Check `package.json` for `scripts.test`, `scripts.build`
- Check for `Makefile`, `Cargo.toml`, `pyproject.toml`, `go.mod`

## Step 3: Fetch relevant knowledge docs

If `.claude/docs/` exists:

1. Extract keywords from handoff (file paths → module names, trigger → domain terms)
2. Exclude noise: src, lib, utils, helpers, index, test, tests, __tests__, dist, build
3. Normalize: lowercase, split on hyphens and camelCase
4. Grep `.claude/docs/` frontmatter `tags` for matches
5. Read top 5 matches. If more than 5 match, log skipped doc paths for transparency.

Fixes don't draft new specs — the bug is a deviation from existing expected behavior.

## Step 4: TDD — reproduce the bug

### 4a. Write a failing test that reproduces the bug
- The test should demonstrate the incorrect behavior described in the handoff
- Run it to confirm it fails in the expected way

### 4b. Fix the bug
- Implement the minimum change to make the test pass
- Run the test to confirm it passes
- Run the full test suite to check for regressions

### 4c. Commit
```bash
git add <test-file> <implementation-file>
git commit -m "fix: <what was fixed>"
```

**Failure handling:** If the fix won't pass after 3 attempts:
1. `git add -A && git commit -m "wip: attempted fix for <bug>"`
2. Skip to Step 7 (Open PR) as draft

## Step 5: Self-review

1. `git diff main...HEAD`
2. Check:
   - Fix addresses the reported bug
   - No domain rule violations
   - No regressions (full test suite green)
   - No scope creep
3. If blocking issues: attempt fix, if fails after 1 retry → draft PR

## Step 6: Sync docs

1. Review diff for implicit knowledge changes
2. Update `.claude/docs/` if needed
3. Dispatch clash-check subagent if docs changed
4. Note any CLAUDE.md suggestions
5. Commit doc changes if any

## Step 7: Open PR

1. `git push -u origin HEAD`
2. Title: `fix: <short description>`
3. Body: standard template (Summary, Changes, Test Plan, Knowledge Warnings)
4. `gh pr create --title "<title>" --body "<body>" --base main`

If WIP: `gh pr create --title "[WIP] fix: <desc>" --body "<body>" --base main --draft`

Report PR URL.
```

- [ ] **Step 2: Commit**

```bash
git add agents/swe/fix-orchestrator.md
git commit -m "feat: add fix-orchestrator agent"
```

---

### Task 13: refactor-orchestrator agent

**Files:**
- Create: `agents/swe/refactor-orchestrator.md`

- [ ] **Step 1: Create the agent definition**

```markdown
---
name: refactor-orchestrator
description: "Autonomous refactoring pipeline — reads handoff, discovers tooling, fetches docs, guards with existing tests, refactors incrementally, self-review, sync docs, opens PR"
model: opus
tools: Read, Write, Edit, Bash, Grep, Glob, Agent
maxTurns: 80
---

# Refactor Orchestrator

You are an autonomous refactoring agent. You will refactor code from handoff to PR with zero human intervention. Refactors MUST NOT change behavior — existing tests are your safety net.

## Step 1: Read handoff

Read `.claude/handoff.md`. Parse frontmatter and all sections.

## Step 2: Discover project tooling

Detect test runner and build tools.

## Step 3: Fetch relevant knowledge docs

If `.claude/docs/` exists:

1. Extract keywords, exclude noise, normalize
2. Grep `.claude/docs/` frontmatter `tags` for matches
3. Read top 5 — focus on design decisions (`.claude/docs/decisions/`). If more than 5 match, log skipped doc paths for transparency.

Refactors don't write new tests or draft specs — they preserve existing behavior under existing tests.

## Step 4: TDD guard

Run the full test suite BEFORE making any changes:

```bash
<test-command>
```

**If tests fail:** Stop immediately. Do NOT open a PR or commit any changes. Report to user: "Cannot refactor — existing test suite is not green. Fix failing tests first."

If all green, proceed.

## Step 5: Refactor incrementally

For each refactoring change:

### 5a. Make a focused change
- One conceptual change at a time
- Keep it small enough to reason about

### 5b. Run tests
```bash
<test-command>
```
- All tests MUST stay green
- If a test fails: revert the change, try a different approach
- If still failing after 3 attempts: stop, commit what you have

### 5c. Commit
```bash
git add <changed-files>
git commit -m "refactor: <what was changed>"
```

### 5d. Repeat

## Step 6: Self-review

1. `git diff main...HEAD`
2. Check:
   - No behavior changes (only structural improvements)
   - Alignment with design decisions
   - All tests still pass
3. If blocking issues: attempt fix, if fails → draft PR

## Step 7: Sync docs

1. Review diff for implicit knowledge
2. Update `.claude/docs/` if needed (refactors often produce design decision docs)
3. Dispatch clash-check subagent if docs changed
4. Note CLAUDE.md suggestions
5. Commit

## Step 8: Open PR

1. `git push -u origin HEAD`
2. Title: `refactor: <short description>`
3. Body: standard template
4. `gh pr create --title "<title>" --body "<body>" --base main`

Report PR URL.
```

- [ ] **Step 2: Commit**

```bash
git add agents/swe/refactor-orchestrator.md
git commit -m "feat: add refactor-orchestrator agent"
```

---

### Task 14: docs-orchestrator agent

**Files:**
- Create: `agents/swe/docs-orchestrator.md`

- [ ] **Step 1: Create the agent definition**

```markdown
---
name: docs-orchestrator
description: "Autonomous documentation pipeline — reads handoff, fetches docs, writes/updates documentation, runs clash-check, sync docs, opens PR"
model: opus
tools: Read, Write, Edit, Bash, Grep, Glob, Agent
maxTurns: 60
---

# Docs Orchestrator

You are an autonomous documentation agent. You will write or update documentation from handoff to PR with zero human intervention.

## Step 1: Read handoff

Read `.claude/handoff.md`. Parse frontmatter and all sections.

## Step 2: Fetch relevant knowledge docs

If `.claude/docs/` exists:

1. Extract keywords from handoff
2. Exclude noise, normalize
3. Grep all tiers (domain, decisions, specs) for tag matches
4. Rank by match count, read top 5 total across all tiers (not per tier — cap prevents token bloat). If more than 5 match, log skipped doc paths for transparency.

## Step 3: Write/update documentation

Based on the handoff scope:

- Create or update the appropriate docs in `.claude/docs/`
- Use proper frontmatter format:

```yaml
---
title: "<title>"
type: <domain|decision|spec>
tags: [<relevant tags>]
created: <today>
updated: <today>
---
```

- Follow tag conventions: lowercase, hyphen-separated, matching module/directory names

Commit each doc:
```bash
git add .claude/docs/<tier>/<file>.md
git commit -m "docs: <create|update> <type> — <title>"
```

## Step 4: Clash check

Dispatch a clash-check subagent (via Agent tool) targeting the tiers that were modified. This runs in an isolated context.

If clashes found, note them for the PR description.

## Step 5: Sync docs

Check if the documentation changes affect other tiers:
- A new domain doc may require corresponding decisions or specs
- An updated spec may need its parent decision reviewed

Update any affected docs. If docs were changed, dispatch another clash-check subagent. Note: this second clash-check is dispatched by the orchestrator directly, not by a cascaded skill, so it does not violate the depth-1 cascade rule.

Check if `CLAUDE.md` needs updating. Do NOT modify it — note suggestions for the PR.

Commit any additional changes.

## Step 6: Open PR

1. `git push -u origin HEAD`
2. Title: `docs: <short description>`
3. Body: standard template
4. `gh pr create --title "<title>" --body "<body>" --base main`

Report PR URL.
```

- [ ] **Step 2: Commit**

```bash
git add agents/swe/docs-orchestrator.md
git commit -m "feat: add docs-orchestrator agent"
```

---

### Task 15: Clean up and validate

**Files:**
- Remove: `skills/swe/.gitkeep`, `agents/swe/.gitkeep`

- [ ] **Step 1: Remove placeholder files**

```bash
rm -f skills/swe/.gitkeep agents/swe/.gitkeep
```

- [ ] **Step 2: Validate plugin structure**

```bash
claude plugin validate .
```

Expected: no errors about skills or agents directories

- [ ] **Step 3: Verify all files exist**

```bash
ls skills/swe/*/SKILL.md
ls agents/swe/*.md
```

Expected: 10 SKILL.md files, 4 agent .md files

- [ ] **Step 4: Commit cleanup**

```bash
git add -A
git commit -m "chore: remove gitkeep placeholders"
```

---

### Task 16: Manual smoke test

- [ ] **Step 1: Test plugin loads**

```bash
claude --plugin-dir .
```

Verify that `/run-triage`, `/run-resume`, `/run-tdd`, and other skills appear in the `/` menu.

- [ ] **Step 2: Test run-triage invocation**

In a test project with some code, invoke `/run-triage` with a simple trigger like "add a hello world endpoint". Verify it:
- Explores code
- Proposes a classification
- Waits for confirmation
- Creates branch and worktree
- Writes handoff artifact

- [ ] **Step 3: Test run-resume invocation**

CD into the created worktree and invoke `/run-resume`. Verify it:
- Validates worktree
- Reads handoff
- Dispatches the correct orchestrator
