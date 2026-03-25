---
trigger: "Enhance orchestrator task lists with description and activeForm fields for better Ctrl+T progress display"
type: feat
branch: feat/enhanced-task-tracking
created: 2026-03-26
---

## Related Files
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- docs/specs/orchestrator-pipeline.md

## Relevant Docs
- docs/specs/orchestrator-pipeline.md — documents shared pipeline structure and per-type variations

## Scope

Update Step 0 (Initialize progress tracking) in all four orchestrators to include `description` and `activeForm` fields in each `TaskCreate` call.

### What to add

For each task in Step 0, add:
- **`activeForm`**: Present continuous verb form shown in the spinner when the task is `in_progress` (e.g. "Reading handoff artifact" instead of "Read handoff")
- **`description`**: Brief explanation of what the step does, providing context in the Ctrl+T task list

### Per-orchestrator task lists

**feat-orchestrator** (10 tasks):
1. Read handoff → activeForm: "Reading handoff artifact", description: "Parse .claude/handoff.md frontmatter and all sections — source of truth for what to build."
2. Discover tooling → activeForm: "Discovering project tooling", description: "Detect test runner, build tools, and package manager from project config files."
3. Fetch docs → activeForm: "Fetching knowledge docs", description: "Extract keywords from handoff, grep docs/ frontmatter tags for matches, read top 5 relevant docs."
4. Draft spec → activeForm: "Drafting spec", description: "Check for existing spec in docs/specs/. If none, create one with behavior, constraints, and acceptance criteria."
5. TDD cycle → activeForm: "Running TDD cycle", description: "For each unit of work: write failing test, implement minimally, verify green, commit. Repeat until feature complete."
6. Self-review → activeForm: "Running self-review", description: "Diff against main. Check scope compliance, spec alignment, domain rules, test coverage, and code quality."
7. Sync docs → activeForm: "Syncing knowledge docs", description: "Review diff for undocumented domain rules, design decisions, or spec gaps. Update docs/ and run clash-check if changed."
8. Version bump → activeForm: "Bumping version", description: "Apply semver MINOR bump following the semver bump procedure. Skip if no version manifest found."
9. Clean up handoff → activeForm: "Cleaning up handoff", description: "Remove .claude/handoff.md so it doesn't appear in the final PR."
10. Open PR → activeForm: "Opening pull request", description: "Push branch, build PR title/body from handoff scope, create PR via gh cli."

**fix-orchestrator** (10 tasks):
1. Read handoff → activeForm: "Reading handoff artifact", description: "Parse .claude/handoff.md frontmatter and all sections — source of truth for what to fix."
2. Discover tooling → activeForm: "Discovering project tooling", description: "Detect test runner, build tools, and package manager from project config files."
3. Fetch docs → activeForm: "Fetching knowledge docs", description: "Extract keywords from handoff, grep docs/ frontmatter tags for matches, read top 5 relevant docs."
4. Investigate root cause → activeForm: "Investigating root cause", description: "Trace backward from symptoms through code paths. Form a written hypothesis about why the bug exists."
5. TDD reproduce → activeForm: "Reproducing bug via TDD", description: "Write a failing test that reproduces the bug, then implement the minimum fix to make it pass."
6. Self-review → activeForm: "Running self-review", description: "Diff against main. Verify fix addresses the reported bug with no regressions or scope creep."
7. Sync docs → activeForm: "Syncing knowledge docs", description: "Review diff for undocumented domain rules, design decisions, or spec gaps. Update docs/ and run clash-check if changed."
8. Version bump → activeForm: "Bumping version", description: "Apply semver PATCH bump following the semver bump procedure. Skip if no version manifest found."
9. Clean up handoff → activeForm: "Cleaning up handoff", description: "Remove .claude/handoff.md so it doesn't appear in the final PR."
10. Open PR → activeForm: "Opening pull request", description: "Push branch, build PR title/body from handoff scope, create PR via gh cli."

**refactor-orchestrator** (10 tasks):
1. Read handoff → activeForm: "Reading handoff artifact", description: "Parse .claude/handoff.md frontmatter and all sections — source of truth for what to refactor."
2. Discover tooling → activeForm: "Discovering project tooling", description: "Detect test runner, build tools, and package manager from project config files."
3. Fetch docs → activeForm: "Fetching knowledge docs", description: "Extract keywords from handoff, grep docs/ frontmatter tags for matches, read top 5 relevant docs."
4. TDD guard → activeForm: "Running TDD guard", description: "Run the full test suite before any changes. Abort if tests are not green — cannot refactor on a red suite."
5. Refactor incrementally → activeForm: "Refactoring incrementally", description: "One conceptual change at a time. Tests must stay green after each change. Commit per change."
6. Self-review → activeForm: "Running self-review", description: "Diff against main. Verify no behavior changes — only structural improvements aligned with design decisions."
7. Sync docs → activeForm: "Syncing knowledge docs", description: "Review diff for undocumented domain rules, design decisions, or spec gaps. Update docs/ and run clash-check if changed."
8. Version bump → activeForm: "Bumping version", description: "Apply semver PATCH bump following the semver bump procedure. Skip if no version manifest found."
9. Clean up handoff → activeForm: "Cleaning up handoff", description: "Remove .claude/handoff.md so it doesn't appear in the final PR."
10. Open PR → activeForm: "Opening pull request", description: "Push branch, build PR title/body from handoff scope, create PR via gh cli."

**docs-orchestrator** (8 tasks):
1. Read handoff → activeForm: "Reading handoff artifact", description: "Parse .claude/handoff.md frontmatter and all sections — source of truth for what to document."
2. Fetch docs → activeForm: "Fetching knowledge docs", description: "Extract keywords from handoff, grep all tiers (domain, decisions, specs) for tag matches, read top 5."
3. Write/update documentation → activeForm: "Writing documentation", description: "Create or update docs across tiers with proper frontmatter. Commit each doc individually."
4. Clash check → activeForm: "Running clash check", description: "Dispatch clash-check subagent on modified tiers to detect contradictions across the knowledge base."
5. Sync docs → activeForm: "Syncing knowledge docs", description: "Check if documentation changes affect other tiers. Update affected docs and run another clash-check if needed."
6. Version bump → activeForm: "Bumping version", description: "Apply semver bump only if handoff has explicit version-bump directive or docs ship as part of a versioned package."
7. Clean up handoff → activeForm: "Cleaning up handoff", description: "Remove .claude/handoff.md so it doesn't appear in the final PR."
8. Open PR → activeForm: "Opening pull request", description: "Push branch, build PR title/body from handoff scope, create PR via gh cli."

### Format in orchestrator markdown

Replace the current numbered list of bare strings with a structured format that makes descriptions and activeForm explicit to the LLM. Use a clear key-value format per task.

### Version bump

Bump swe plugin version from 0.7.4 to 0.7.5 in both `plugins/swe/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
