---
trigger: "Update fal plugin to not use fal-mcp. Instead, analyze fal-mcp and write it as a skill that uses bash commands instead."
type: refactor
branch: refactor/fal-no-mcp
base-branch: main
created: 2026-04-14
---

## Related Files
- plugins/fal/.claude-plugin/plugin.json
- plugins/fal/skills/fal-setup/SKILL.md
- plugins/fal/skills/fal-image/SKILL.md

## Relevant Docs
None — knowledge base does not cover this area yet.

## Related Issues
None — no related issues found.

## Scope
Replace fal.ai MCP server dependency with direct REST API calls via curl/bash.

**fal-setup**: Instead of registering an HTTP MCP transport via `claude mcp add`, store the API key in a local file (e.g., `~/.config/fal/credentials`) or verify `FAL_KEY` environment variable is set. Remove all MCP-related setup steps.

**fal-image**: Instead of calling `mcp__fal_ai__*` MCP tools, use `curl` to call the fal.ai REST API directly (`https://fal.run/<model-id>`). Auth via `Authorization: Key <API_KEY>` header. Parse JSON response with `jq` or similar. Keep all existing behavior: project context reading, prompt enrichment, model selection, size options.

The plugin description and keywords in plugin.json should be updated to remove MCP references.
