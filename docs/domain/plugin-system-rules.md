---
title: "Plugin System Rules"
type: domain
tags: [plugin, marketplace, manifest, cache, versioning, mcp]
created: 2026-03-26
updated: 2026-04-14
---

## Marketplace Manifest

The marketplace index at `.claude-plugin/marketplace.json` lists all available plugins. Each entry must include:

- `name` -- unique plugin identifier
- `description` -- one-line summary
- `version` -- semver string that must match the plugin's own `plugin.json` version
- `source` -- relative path to the plugin directory (e.g., `./plugins/ritual`)

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

## MCP Server Declaration

Plugins that bundle MCP servers declare them at the plugin level via a `.mcp.json` file at `plugins/<name>/.mcp.json`. Declaring the server here (rather than relying on runtime `claude mcp add`) ensures the MCP server appears nested under the plugin in the `/plugin` list and installs automatically for any user of the plugin.

Supported transports:

- **HTTP** -- `type: "http"`, with `url` and optional `headers`
- **Local stdio** -- `command` and `args` for launching a local process

Format for HTTP transport with authentication:

```json
{
  "<server-name>": {
    "type": "http",
    "url": "https://<mcp-endpoint>",
    "headers": {
      "Authorization": "Bearer ${ENV_VAR_NAME}"
    }
  }
}
```

Rules:

- Headers support `${ENV_VAR_NAME}` interpolation -- secrets must never be hardcoded in `.mcp.json`
- Skills that depend on a plugin-declared MCP server must not run `claude mcp add` -- they guide the user to set the required environment variable instead, then rely on the plugin manifest for registration
- Multiple server definitions may live in one file; the top-level keys are the server names

## Cache Behavior

Plugin cache is version-keyed at `~/.claude/plugins/cache/`. Consequences:

- Bumping the version in both manifests forces a re-fetch on `/plugin` install
- `/reload-plugins` re-reads cache but does not re-download from source
- Stale cache entries persist until a new version is published

## Installation

Users install the marketplace via: `/plugin` then `Add Marketplace` then `yanekyuk/arcana`. Individual plugins within the marketplace are then available automatically.
