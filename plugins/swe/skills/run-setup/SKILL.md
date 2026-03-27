---
name: run-setup
description: "Use to configure a project for the swe plugin -- detects tech stack, sets architecture rules, discovers versioning manifests, integration toggles, and custom directives"
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Project Setup

You are configuring a project for the swe plugin. This is an interactive wizard -- you WILL ask the user questions and wait for responses.

## Step 1: Check for existing config

```bash
test -f docs/swe-config.json && echo "CONFIG EXISTS" || echo "NO CONFIG"
```

If config exists, read it and ask the user: "Existing config found. Do you want to reconfigure from scratch or edit the current config?" If they want to edit, load the existing values as defaults for each step below.

## Step 2: Auto-detect tech stack

Scan project files to detect the tech stack. Check these files in order:

**Language and runtime:**
- `package.json` exists → language is likely TypeScript (check for `typescript` in devDependencies) or JavaScript
- `Cargo.toml` exists → Rust
- `go.mod` exists → Go
- `pyproject.toml` or `setup.py` or `requirements.txt` exists → Python
- `build.gradle` or `pom.xml` exists → Java/Kotlin
- `mix.exs` exists → Elixir

**Runtime detection (for JS/TS projects):**
- `bun.lockb` or `bunfig.toml` → Bun
- `pnpm-lock.yaml` → pnpm (Node)
- `yarn.lock` → Yarn (Node)
- `package-lock.json` → npm (Node)
- `deno.json` or `deno.lock` → Deno

**Package manager:** Infer from lockfile (same as runtime detection above).

**Test runner:**
- Read `package.json` `scripts.test` if present
- Check for `jest.config.*`, `vitest.config.*`, `.mocharc.*`, `pytest.ini`, `Cargo.toml` (cargo test)
- For Go: `go test`
- For Python: check for pytest in dependencies

**Linter/formatter:**
- Check for `.eslintrc*`, `eslint.config.*`, `biome.json`, `.prettierrc*`, `rustfmt.toml`, `.golangci.yml`, `ruff.toml`
- Read `package.json` for `scripts.lint`, `scripts.format`, `scripts.typecheck`

**Source root:**
- Check for `src/`, `lib/`, `app/` directories
- Default to `src` if `src/` exists, otherwise `.`

Present all detected values to the user in a clear table:

```
Detected tech stack:
  Language:        TypeScript
  Runtime:         Bun
  Package manager: bun
  Test command:    bun test
  Lint command:    bun run lint
  Format command:  bun run format
  Typecheck:       bun run typecheck
  Source root:     src
```

Ask: "Does this look correct? You can confirm, or tell me what to change."

Wait for the user to confirm or provide overrides. Apply any overrides they specify.

## Step 3: Architecture presets

Present the architecture preset options:

```
Architecture presets:

1. Layered — Classic layered architecture with domain/application/infrastructure separation
2. Hexagonal — Ports and adapters with strict dependency inversion
3. Vertical Slices — Feature-based modules with minimal cross-feature coupling
4. Custom — Define your own rules from scratch
5. None — Skip architecture rules entirely
```

Ask: "Which architecture preset would you like? (1-5)"

Wait for user response. Expand the selected preset into flat rules:

**Layered:**
- "Domain layer must not import from infrastructure or application layers"
- "Application layer must not import from infrastructure layer"
- "Infrastructure layer implements interfaces defined in the domain layer"
- "Shared kernel types live in a dedicated shared/ directory"

**Hexagonal:**
- "Domain layer must not import from infrastructure"
- "All external dependencies must be wrapped behind interfaces in ports/"
- "Adapters implement port interfaces and live in adapters/"
- "Application services orchestrate domain logic through ports, never directly through adapters"
- "No framework-specific types in the domain layer"

**Vertical Slices:**
- "Feature modules must not import from each other directly"
- "Shared code lives in a dedicated shared/ directory"
- "Each feature module contains its own routes, handlers, and data access"
- "Cross-feature communication happens through events or a shared message bus"

**Custom:**
- Ask: "Enter your architecture rules, one per line. Send an empty line when done."
- Collect rules until the user sends an empty response or says they are done.

**None:**
- Set `architecture.rules` to an empty array.

After expanding, show the user the resulting rules and ask: "These are the architecture rules that will be enforced. Add, remove, or modify any? Or confirm to proceed."

Wait for user response. Apply any changes.

## Step 4: Versioning rules

Auto-discover version-bearing files across the project tree. Search for these manifest types:

- `**/package.json` -- look for `"version"` field (skip `node_modules/`)
- `**/Cargo.toml` -- look for `version` under `[package]`
- `**/pyproject.toml` -- look for `version` under `[project]` or `[tool.poetry]`
- `**/setup.cfg` -- look for `version` under `[metadata]`
- `**/build.gradle` / `**/build.gradle.kts` -- look for `version = "X.Y.Z"`
- `**/version.txt` -- entire file content is the version string

Use Glob to find candidate files, then Read each to confirm it contains a version field. Skip files in `node_modules/`, `dist/`, `build/`, `.git/`, and vendor directories.

**Generate rule prompts from detected layout:**

- **Single manifest at root:** Generate one rule: `"Bump <manifest> version for all changes"`
- **Multiple manifests (monorepo):** Generate one rule per manifest with path-based conditions:
  - `"Bump <path>/<manifest> version for changes under <path>/"`
- **No manifests found:** Set `versioning` to an empty array and inform the user: "No version manifests detected. Versioning rules will be empty -- orchestrators will skip version bumps."

Present the generated rules to the user:

```
Detected versioning rules:
  1. Bump package.json version for all changes
```

Or for monorepos:

```
Detected versioning rules:
  1. Bump frontend/package.json version for changes under frontend/
  2. Bump api/pyproject.toml version for changes under api/
```

Ask: "These are the versioning rules that tell orchestrators which version files to bump. Add, remove, or modify any? Or confirm to proceed."

Wait for user response. Apply any changes.

**When editing an existing config:** Load the current `versioning` array as defaults. Show them alongside any newly detected manifests. If new manifests are found that are not covered by existing rules, highlight them: "New version manifest detected at `<path>` -- not covered by existing rules. Add a rule for it?"

## Step 5: Custom directives

Ask: "Do you have any custom directives? These are soft guidelines for the AI during implementation -- style preferences, patterns to favor, conventions to follow. Enter one per line, or say 'none' to skip."

Wait for user response. Collect directives until the user indicates they are done.

## Step 6: Integration toggles

Present integration options:

```
Integration toggles (y/n for each):

1. CodeRabbit PR reviews — Automated AI code review on PRs
2. Linear — Issue tracking integration
3. GitHub Issues — Link PRs to GitHub Issues
4. Auto-docs — Automatically update documentation on changes
```

For each integration, ask the user and wait for their response. Default to the most common setup if they say "use defaults": CodeRabbit on, Linear off, GitHub Issues on, auto-docs on.

## Step 7: Write config

Assemble the final config object:

```json
{
  "stack": {
    "language": "<detected or overridden>",
    "runtime": "<detected or overridden>",
    "packageManager": "<detected or overridden>",
    "test": "<detected or overridden>",
    "lint": "<detected or overridden>",
    "format": "<detected or overridden>",
    "typecheck": "<detected or overridden>"
  },
  "sourceRoot": "<detected or overridden>",
  "integrations": {
    "coderabbit": true,
    "linear": false,
    "githubIssues": true,
    "autoDocs": true
  },
  "architecture": {
    "rules": [
      "<expanded flat rules>"
    ]
  },
  "versioning": [
    "<generated or user-edited versioning rules>"
  ],
  "directives": [
    "<user-provided directives>"
  ]
}
```

Write to `docs/swe-config.json`:

```bash
# Ensure docs/ directory exists
mkdir -p docs
```

Use the Write tool to write the JSON file. Format it with 2-space indentation.

Show the user the final config and confirm: "Config written to `docs/swe-config.json`. You can edit this file directly at any time. Orchestrators will read it at the start of every pipeline run."
