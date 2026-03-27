---
title: "Project Setup and Architecture Enforcement"
type: spec
tags: [setup, architecture, config, orchestrator, skill]
created: 2026-03-26
updated: 2026-03-27
---

## Behavior

### run-setup skill

Interactive project configuration wizard that:
1. Auto-detects tech stack (language, runtime, package manager, test runner, linter/formatter) from project files
2. Presents detected values and lets the user confirm or override
3. Offers architecture presets (Layered, Hexagonal, Vertical Slices, Custom) that expand into flat rule lists at setup time -- presets are not a runtime concept
4. Auto-discovers version-bearing files (package.json, Cargo.toml, pyproject.toml, etc.) across the project tree and generates natural-language versioning rules for the user to confirm or edit
5. Allows custom directives (style preferences, patterns to favor)
6. Offers integration toggles: CodeRabbit, Linear, GitHub Issues, auto-docs
7. Writes config to `docs/swe-config.json` in the target project
8. Supports updating an existing config -- loads current values (including versioning rules) as defaults when editing

### run-arch-check skill

Architecture enforcement gate that:
1. Reads `docs/swe-config.json` architecture rules
2. Reads the diff about to be PR'd
3. Validates each rule against the changes
4. Returns pass/fail with violation details
5. Acts as a hard gate -- violations must be fixed before PR creation

### Orchestrator modifications

All four orchestrators gain:
1. **Config gate** after "Read handoff": reads `docs/swe-config.json`. If missing, aborts with: "No project config found. Run `/run-setup` in the target project first."
2. **Config-driven tooling** replaces dynamic tooling discovery with `stack.*` values from config
3. **Arch check step** after self-review (after sync-docs for docs orchestrator): dispatches `run-arch-check`. Violations trigger fix attempt; failed fix proceeds as draft PR.

## Constraints

- Architecture rules are flat strings at runtime -- no preset taxonomy
- `architecture.rules` are hard-enforced by `run-arch-check`; `directives` are soft guidance
- Config lives in `docs/` (version controlled, human-editable, visible in PRs)
- No config = orchestrator aborts immediately (hard requirement)
- Skill format must follow existing YAML frontmatter conventions
- Orchestrators must remain autonomous (no human prompts mid-pipeline) except for `run-setup` which is interactive by nature

## Config Schema

```json
{
  "stack": {
    "language": "string",
    "runtime": "string",
    "packageManager": "string",
    "test": "string",
    "lint": "string",
    "format": "string",
    "typecheck": "string"
  },
  "sourceRoot": "string",
  "integrations": {
    "coderabbit": "boolean",
    "linear": "boolean",
    "githubIssues": "boolean",
    "autoDocs": "boolean"
  },
  "architecture": {
    "rules": ["string"]
  },
  "versioning": ["string"],
  "directives": ["string"]
}
```

### Versioning Rules

The `versioning` array contains natural-language rule strings that tell orchestrators which version manifests to bump and under what conditions. This replaces hardcoded manifest detection and supports monorepos with multiple independent version manifests.

Each rule should specify:
- **Which manifest** to bump (e.g., `package.json`, `frontend/package.json`, `Cargo.toml`)
- **When** to bump it (e.g., "for frontend changes", "for API changes", "always")

Examples:
- `"Bump package.json version for all changes"` -- single-manifest project
- `"Bump frontend/package.json version for changes under frontend/"` -- monorepo frontend
- `"Bump api/pyproject.toml version for changes under api/"` -- monorepo backend
- `"Bump version.txt for all changes"` -- simple version file

If the `versioning` array is empty or absent, the orchestrator skips the version bump step entirely.

## Acceptance Criteria

1. `run-setup` SKILL.md exists at `plugins/swe/skills/run-setup/SKILL.md` with correct frontmatter
2. `run-arch-check` SKILL.md exists at `plugins/swe/skills/run-arch-check/SKILL.md` with correct frontmatter
3. All four orchestrators include a config gate step after reading the handoff
4. All four orchestrators use config values for tooling instead of dynamic discovery
5. feat, fix, refactor orchestrators include arch-check step after self-review
6. docs orchestrator includes arch-check step after sync-docs
7. Skill contracts spec is updated with run-setup and run-arch-check entries
8. Orchestrator pipeline spec is updated with new steps
