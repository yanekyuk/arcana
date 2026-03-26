---
name: run-arch-check
description: "Use to validate architecture rules against a diff -- hard gate that blocks PR creation on violations"
allowed-tools: Read, Bash, Grep, Glob
---

# Architecture Check

You are validating architecture rules against the current changes. This is a **hard gate** -- violations must be fixed before a PR can be created.

## Step 1: Load config

Read `docs/swe-config.json` in the current project directory.

If the file does not exist, report: "No project config found. Run `/run-setup` first." and stop.

Extract `architecture.rules` from the config. If the array is empty or the `architecture` key is missing, report: "No architecture rules configured. Arch check passed (no rules to enforce)." and stop with a pass result.

## Step 2: Get the diff

Get the diff that will be included in the PR:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git diff $BASE...HEAD
```

If the diff is empty, report: "No changes to check. Arch check passed." and stop.

## Step 3: Validate each rule

For each rule in `architecture.rules`:

1. Read the rule text carefully -- it describes a structural constraint
2. Analyze the diff to determine if any changed files or new imports violate the rule
3. If the rule references specific directories or layers (e.g., "domain must not import from infrastructure"), check import/require/use statements in changed files within those directories
4. Use Grep to inspect the full file content when import analysis requires more context than the diff provides

For each rule, record one of:
- **PASS** -- No violations found in the changed files
- **VIOLATION** -- Specific violation found, with file path, line, and explanation
- **NOT APPLICABLE** -- The rule references areas not touched by this diff

## Step 4: Report results

### All rules pass

Report:
```
Architecture check passed.
  Rules checked: <N>
  Passed: <N>
  Not applicable: <N>
```

Return a pass result to the caller.

### Violations found

Report each violation:
```
Architecture check FAILED.

Violations:
  1. Rule: "<rule text>"
     File: <file path>
     Line: <line number>
     Details: <what violates the rule and why>

  2. ...

Rules checked: <N>
Passed: <N>
Violations: <N>
Not applicable: <N>
```

Return a fail result with the full violation report. The caller (orchestrator or user) is responsible for deciding what to do -- fix the violations or proceed as a draft PR.

## Important notes

- This is a hard gate, not a warning. When dispatched by an orchestrator, violations block PR creation.
- Only check files that appear in the diff. Do not audit the entire codebase.
- Be precise about violations -- false positives erode trust in the gate.
- When a rule is ambiguous, favor passing. Only flag clear, unambiguous violations.
- Architecture rules are plain-language strings. Use your judgment to interpret them against actual code patterns.
