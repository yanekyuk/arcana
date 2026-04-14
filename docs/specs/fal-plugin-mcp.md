---
title: "fal Plugin MCP Declaration"
type: spec
tags: [fal, mcp, plugin, http-transport]
created: 2026-04-14
updated: 2026-04-14
---

## Behavior

The fal plugin declares its MCP server via a `.mcp.json` file at `plugins/fal/.mcp.json`, using HTTP transport pointing to `https://mcp.fal.ai/mcp`. The Bearer token is injected via `${FAL_KEY}` environment variable interpolation in the `Authorization` header.

When users install the fal plugin through the marketplace, the MCP server appears nested under the fal plugin entry in the `/plugin` list -- not as a separate "Local" entry that would result from manual `claude mcp add`.

The `fal-setup` skill guides users to set the `FAL_KEY` environment variable in their shell profile instead of running `claude mcp add` manually.

## Constraints

- The `.mcp.json` file must follow the Claude Code plugin MCP declaration format (top-level key = server name, with `type`, `url`, and `headers` fields)
- The Authorization header must use `${FAL_KEY}` env var interpolation -- no hardcoded keys
- The fal-setup skill must not use `claude mcp add` -- the MCP server is already declared by the plugin manifest
- Version must be bumped in both `plugin.json` and `marketplace.json` (domain rule: version synchronization)

## Acceptance Criteria

- `plugins/fal/.mcp.json` exists with correct HTTP transport configuration and env var interpolation
- `fal-setup` skill checks for `FAL_KEY` env var and guides users to set it in their shell profile
- `fal-setup` skill no longer references `claude mcp add`
- `plugin.json` version is bumped (patch increment from 0.1.4 to 0.1.5)
- `marketplace.json` fal entry version matches `plugin.json` (0.1.5)
