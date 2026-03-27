---
trigger: "Wire up all integration toggles (CodeRabbit, Linear, GitHub Issues, auto-docs) and add Context7 support. Currently run-setup defines integrations in swe-config.json but nothing reads them. Need to: (1) add Context7 to run-setup integration list with prerequisite verification for all integrations, (2) wire autoDocs to gate sync-docs in orchestrators, (3) wire context7 for library doc lookups during implementation, (4) wire githubIssues/linear in triage and open-pr for issue linking, (5) wire coderabbit in open-pr and finish for review checks, (6) update specs."
type: feat
branch: feat/wire-integrations
created: 2026-03-27
version-bump: minor
---

## Related Files
- plugins/swe/skills/run-setup/SKILL.md — integration toggles defined here (Step 6), config schema (Step 7)
- plugins/swe/agents/feat-orchestrator.md — Step 2 (config loading), Step 6 (TDD), Step 9 (sync docs)
- plugins/swe/agents/fix-orchestrator.md — Step 2 (config loading), Step 6 (TDD reproduce), Step 9 (sync docs)
- plugins/swe/agents/refactor-orchestrator.md — Step 2 (config loading), Step 6 (refactor incrementally), Step 9 (sync docs)
- plugins/swe/agents/docs-orchestrator.md — Step 2 (config loading), Step 4 (write docs), Step 6 (sync docs)
- plugins/swe/skills/run-triage/SKILL.md — after Step 5 (issue search), Step 8 (handoff template)
- plugins/swe/skills/run-open-pr/SKILL.md — Step 3 (PR body), Step 4 (PR creation)
- plugins/swe/skills/run-finish/SKILL.md — Step 4 (review check before merge)
- docs/specs/project-setup.md — config schema docs
- docs/specs/orchestrator-pipeline.md — pipeline phase docs
- docs/specs/skill-contracts.md — skill contract docs

## Relevant Docs
- docs/specs/orchestrator-pipeline.md — shared pipeline structure, config gate, per-type variations
- docs/specs/project-setup.md — config schema with current integrations section
- docs/specs/skill-contracts.md — input/output/side-effects for each skill

## Scope
Wire up all 5 integration toggles so they actually control pipeline behavior:

1. **run-setup** — Add Context7 as 5th integration. Add Step 6b to verify prerequisites for each enabled integration: gh CLI for GitHub Issues, GitHub App advisory for CodeRabbit, MCP server check + install suggestion for Linear and Context7, no-op for auto-docs.

2. **All 4 orchestrators (feat/fix/refactor/docs)** — Step 2: store integration flags. Gate sync-docs step on integrations.autoDocs (skip when false). Add Context7 MCP tool guidance (mcp__context7__resolve-library-id, mcp__context7__get-library-docs) during implementation steps when integrations.context7 is true.

3. **run-triage** — Add Step 5b: if githubIssues enabled, search GitHub Issues via `gh issue list --search`. If linear enabled, search via Linear MCP tools. Add "Related Issues" section to handoff template.

4. **run-open-pr** — Add Step 0 to load integration config. If githubIssues: add `Closes #N` from handoff. If linear: add Linear issue refs. If coderabbit: add review-requested note to PR body.

5. **run-finish** — Add Step 4b: if coderabbit enabled, check CodeRabbit review status via `gh pr reviews` before approving merge.

6. **Specs** — Update project-setup.md schema (add context7, document prerequisites), orchestrator-pipeline.md (expand integrations docs, mark sync-docs as gated), skill-contracts.md (add integration notes to triage/open-pr/finish).
