---
trigger: "Add .mcp.json to the fal plugin so the MCP server is declared at the plugin level (like context7) instead of relying on `claude mcp add` at runtime. Use HTTP transport with ${FAL_KEY} env var interpolation for the Bearer token. Update fal-setup skill to guide users to set the env var instead of running `claude mcp add`."
type: feat
branch: feat/fal-plugin-mcp
base-branch: main
created: 2026-04-14
version-bump: patch
---

## Related Files
- plugins/fal/.claude-plugin/plugin.json
- plugins/fal/skills/fal-setup/SKILL.md
- plugins/fal/skills/fal-image/SKILL.md
- .claude-plugin/marketplace.json

## Relevant Docs
- docs/domain/plugin-system-rules.md
- docs/specs/skill-contracts.md

## Related Issues
None — no related issues found.

## Scope
Add a `.mcp.json` file to `plugins/fal/` that declares the fal.ai MCP server using HTTP transport with `${FAL_KEY}` env var interpolation for the Bearer token. This makes the MCP server appear nested under the fal plugin in the `/plugin` list (like context7) instead of as a separate "Local" entry.

Update the `fal-setup` skill to guide users to set the `FAL_KEY` environment variable instead of running `claude mcp add`. The skill should check whether `FAL_KEY` is set and help users configure it in their shell profile.

Bump fal plugin version in both `plugin.json` and `marketplace.json`.
