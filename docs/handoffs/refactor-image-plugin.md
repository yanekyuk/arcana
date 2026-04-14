---
trigger: "Refactor fal plugin to be a generic image generation skill that supports fal.ai as one of many image generation providers. Rename the plugin based on project conventions. Skills: fal-image → run-imagine (/run-imagine), fal-setup → run-imagine-setup (/run-imagine-setup). Add imagine-specific docs and an imagine config file similar to ritual-config.json."
type: refactor
branch: refactor/image-plugin
base-branch: main
created: 2026-04-14
version-bump: minor
---

## Related Files
- plugins/fal/.claude-plugin/plugin.json
- plugins/fal/skills/fal-image/SKILL.md
- plugins/fal/skills/fal-setup/SKILL.md
- plugins/fal/.mcp.json
- .claude-plugin/marketplace.json

## Relevant Docs
- docs/domain/plugin-system-rules.md

## Related Issues
None — no related issues found.

## Scope
Rename and restructure the `fal` plugin into a generic `imagine` plugin for image generation:

1. **Rename plugin directory**: `plugins/fal/` → `plugins/imagine/`
2. **Update plugin manifest** (`plugin.json`): name `fal` → `imagine`, update description to be provider-agnostic, update keywords
3. **Rename skills**:
   - `skills/fal-image/SKILL.md` → `skills/run-imagine/SKILL.md` (user-invocable as `/run-imagine`)
   - `skills/fal-setup/SKILL.md` → `skills/run-imagine-setup/SKILL.md` (user-invocable as `/run-imagine-setup`)
4. **Update skill frontmatter**: names `fal-image` → `run-imagine`, `fal-setup` → `run-imagine-setup`; update descriptions to be provider-agnostic (fal.ai is one of many providers)
5. **Update skill content**: replace fal-specific language with provider-agnostic language; `run-imagine` should reference the active provider (defaulting to fal.ai); `run-imagine-setup` should support configuring the provider
6. **Add imagine config file**: `plugins/imagine/imagine-config.json` (or similar) — defines the active provider, default model, default image size, and any provider-specific settings; similar structure to `docs/ritual-config.json`
7. **Add imagine-specific docs**: e.g., `docs/domain/imagine-system-rules.md` covering provider model, config schema, and how skills resolve the active provider
8. **Update marketplace.json**: update the `fal` entry name to `imagine`, update description, source path, and tags
9. **Bump versions**: minor bump (new structure) in both `plugin.json` and `marketplace.json`

The fal.ai MCP server (`.mcp.json`) stays as-is — it's the first supported provider. The refactor makes the skill layer provider-agnostic so future providers (e.g., Replicate, OpenAI Images) can be added by extending the config.
