# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin marketplace (`arcana`) containing plugins that deliver agents and skills as markdown files. There is no build system, test runner, or compiled code — plugins are pure configuration (JSON manifests + markdown definitions).

Install: `/plugin → Add Marketplace → yanekyuk/arcana`

## Repository Layout

```
.claude-plugin/marketplace.json      # Marketplace index — lists all plugins
plugins/<name>/
  .claude-plugin/plugin.json         # Plugin manifest (name, version, skills path)
  agents/<name>.md                   # Autonomous pipeline agents
  skills/<name>/SKILL.md             # User-invocable skill definitions
docs/                                # Reference documentation
```

Currently one plugin exists: `ritual` (software engineering workflows).

## Plugin Manifests

**Marketplace** (`.claude-plugin/marketplace.json`): Lists plugins with `source` pointing to plugin directory. Version here must match the plugin's own `plugin.json` version.

**Plugin** (`plugins/<name>/.claude-plugin/plugin.json`): Must include `"skills": "./skills"` (relative path with `./` prefix — bare names like `"skills"` cause validation errors). Agents are auto-discovered from the `agents/` directory.

**Cache behavior**: Plugin cache is version-keyed at `~/.claude/plugins/cache/`. Bump the version in both `plugin.json` and `marketplace.json` to force re-fetch on `/plugin`. `/reload-plugins` re-reads cache but does not re-download.

## Agent Format

```yaml
---
name: <name>
description: "<one-line description>"
model: opus
tools: Read, Write, Edit, Bash, Grep, Glob, Agent
maxTurns: <number>
---
# Instructions in markdown
```

Agents are autonomous multi-step pipelines (feat/fix/refactor/docs orchestrators) that run end-to-end.

## Skill Format

```yaml
---
name: <name>
description: "<one-line description>"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---
# Instructions in markdown
```

Skills are composable building blocks invoked via slash commands (e.g., `/run-tdd`). They can also be dispatched by orchestrator agents.

## Ritual Plugin Workflow

Two-session model:
1. **Session 1** (project root): `/run-triage` classifies work, creates branch + worktree + handoff artifact (`docs/handoffs/<worktree-folder>.md`). After the orchestrator opens a PR, `/run-finish` reviews and merges it.
2. **Session 2** (worktree): `/run-start` reads the named handoff (determined by worktree folder name) and dispatches the correct orchestrator.

**Root-session rule:** Session 1 must always run from the project root, never from inside a worktree. Both `/run-triage` and `/run-finish` enforce this with a context validation step. The `worktree-boundary.sh` hook additionally blocks `cd`/`pushd` into `.worktrees/` from the main session.

Knowledge hierarchy in target projects (`docs/`):
- `domain/` — Business rules (highest authority, cascades to decisions + specs)
- `decisions/` — Architecture choices (cascades to specs)
- `specs/` — Feature/fix specifications (no cascade)

## Conventions

- Conventional Commits: `<type>: <description>` — types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `style`, `build`
- Knowledge docs use YAML frontmatter with `title`, `type`, `tags`, `created`, `updated`
- Tags are lowercase, hyphen-separated, matching module/directory names
