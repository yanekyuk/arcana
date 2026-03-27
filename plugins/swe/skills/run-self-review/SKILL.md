---
name: run-self-review
description: "Use to review your own changes — diffs against base branch, checks alignment with spec and domain knowledge"
user-invocable: false
allowed-tools: Read, Bash, Grep, Glob
---

# Self-Review

You are reviewing your own changes before opening a PR. Be rigorous — pretend you're reviewing someone else's code.

## Prerequisites

**Directives:** If `docs/swe-config.json` exists, read `directives.review` from the config. These are soft guidelines that influence your review focus areas and quality thresholds. Apply them throughout the review process. If the field is missing or empty, proceed without directives.

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
