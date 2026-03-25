---
title: "Plugin System Rules"
type: domain
tags: [plugin, marketplace, manifest, cache, versioning]
created: 2026-03-26
updated: 2026-03-26
---

## Marketplace Manifest

The marketplace index at `.claude-plugin/marketplace.json` lists all available plugins. Each entry must include:

- `name` -- unique plugin identifier
- `description` -- one-line summary
- `version` -- semver string that must match the plugin's own `plugin.json` version
- `source` -- relative path to the plugin directory (e.g., `./plugins/swe`)

The marketplace file also carries top-level `name`, `metadata.description`, and `owner.name` fields identifying the marketplace itself.

## Plugin Manifest

Each plugin has its own manifest at `plugins/<name>/.claude-plugin/plugin.json`. Required fields:

- `name` -- must match the marketplace entry name
- `version` -- semver string, must be identical to the version in `marketplace.json`
- `skills` -- relative path to the skills directory, must use `./` prefix (e.g., `"./skills"`). Bare names like `"skills"` cause validation errors.

Agents are auto-discovered from the `agents/` directory within the plugin and do not need explicit registration.

## Version Synchronization

The version string must be identical in two places:
1. `plugins/<name>/.claude-plugin/plugin.json` `"version"` field
2. `.claude-plugin/marketplace.json` plugin entry `"version"` field

A mismatch between these two values is an error. Any version bump must update both files atomically.

## Cache Behavior

Plugin cache is version-keyed at `~/.claude/plugins/cache/`. Consequences:

- Bumping the version in both manifests forces a re-fetch on `/plugin` install
- `/reload-plugins` re-reads cache but does not re-download from source
- Stale cache entries persist until a new version is published

## Installation

Users install the marketplace via: `/plugin` then `Add Marketplace` then `yanekyuk/arcana`. Individual plugins within the marketplace are then available automatically.
