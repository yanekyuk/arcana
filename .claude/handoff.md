---
trigger: "Add initial setup process for swe plugin: detect/select tech stack, architecture presets with flat rule expansion, integration toggles (CodeRabbit, Linear, GitHub Issues, auto-docs), custom directives. Add architecture enforcement gate before PR creation. Hard-require setup config in all orchestrators."
type: feat
branch: feat/project-setup
created: 2026-03-26
version-bump: minor
---

## Related Files
- plugins/swe/skills/run-resume/SKILL.md
- plugins/swe/skills/run-open-pr/SKILL.md
- plugins/swe/skills/run-triage/SKILL.md
- plugins/swe/skills/run-finish/SKILL.md
- plugins/swe/skills/run-self-review/SKILL.md
- plugins/swe/skills/run-tdd/SKILL.md
- plugins/swe/skills/run-sync-docs/SKILL.md
- plugins/swe/skills/run-clash-check/SKILL.md
- plugins/swe/skills/run-domain-knowledge/SKILL.md
- plugins/swe/skills/run-design-decision/SKILL.md
- plugins/swe/skills/run-spec/SKILL.md
- plugins/swe/agents/feat-orchestrator.md
- plugins/swe/agents/fix-orchestrator.md
- plugins/swe/agents/refactor-orchestrator.md
- plugins/swe/agents/docs-orchestrator.md
- docs/specs/orchestrator-pipeline.md
- docs/specs/skill-contracts.md
- docs/specs/work-lifecycle.md

## Relevant Docs
- docs/specs/orchestrator-pipeline.md — shared pipeline structure, per-type variations
- docs/specs/skill-contracts.md — input/output/tools for all skills
- docs/specs/work-lifecycle.md — full triage→resume→orchestrator→finish flow
- docs/decisions/autonomous-orchestrators.md — why zero-intervention pipelines
- docs/decisions/tdd-first-development.md — TDD enforcement context
- docs/domain/plugin-system-rules.md — manifest structure, version sync

## Scope

### New skill: `run-setup`
Interactive project configuration wizard that:
1. Auto-detects tech stack (language, runtime, package manager, test runner, linter/formatter) from project files (package.json, go.mod, Cargo.toml, pyproject.toml, etc.)
2. Presents detected values, lets user confirm or override
3. Offers architecture presets (Layered, Hexagonal, Vertical Slices, Custom) — selecting a preset expands it into a flat list of concrete rules. The preset is a setup-time convenience, not a runtime concept.
4. Allows user to add custom directives (style preferences, patterns to favor)
5. Offers integration toggles: CodeRabbit PR reviews, Linear, GitHub Issues, auto-docs
6. Writes everything to `docs/swe-config.json` in the target project

### Config schema (`docs/swe-config.json`)
```json
{
  "stack": {
    "language": "typescript",
    "runtime": "bun",
    "packageManager": "bun",
    "test": "bun test",
    "lint": "bun run lint",
    "format": "bun run format",
    "typecheck": "bun run typecheck"
  },
  "sourceRoot": "src",
  "integrations": {
    "coderabbit": true,
    "linear": false,
    "githubIssues": true,
    "autoDocs": true
  },
  "architecture": {
    "rules": [
      "Domain layer (src/domain/) must not import from infrastructure",
      "All external dependencies must be wrapped behind interfaces in ports/",
      "Feature modules must not import from each other directly"
    ]
  },
  "directives": [
    "Prefer composition over inheritance",
    "Use result types instead of throwing exceptions for expected failures"
  ]
}
```

### New skill: `run-arch-check`
Architecture enforcement gate that:
1. Reads `docs/swe-config.json` architecture rules
2. Reads the diff about to be PR'd
3. Validates each rule against the changes
4. Returns pass/fail — violations must be fixed before PR creation
5. This is a hard gate, not a warning

### Orchestrator modifications (all 4)
1. **Config gate** — New step after "Read handoff": read `docs/swe-config.json`. If missing, abort with message: "No project config found. Run `/run-setup` in the target project first."
2. **Use config for tooling** — Replace dynamic tooling discovery (Step 2) with config values from `stack.*`
3. **Arch check step** — New step after self-review (or after sync-docs for docs orchestrator): dispatch `run-arch-check`. If violations found, attempt fix. If fix fails, proceed as draft PR.

### Design decisions
- Architecture rules are flat strings — no preset concept at runtime
- `architecture.rules` = hard-enforced by `run-arch-check`; `directives` = soft guidance read by orchestrators during implementation
- Config lives in `docs/` (version controlled, human-editable, visible in PRs)
- Hard-require: no config = orchestrator aborts immediately
