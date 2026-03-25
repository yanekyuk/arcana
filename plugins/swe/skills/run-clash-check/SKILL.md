---
name: run-clash-check
description: "Use to scan knowledge docs for contradictions, overlaps, and misalignments — dispatched as subagent to isolate token cost"
user-invocable: true
disable-model-invocation: true
context: fork
allowed-tools: Read, Bash, Grep, Glob
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
