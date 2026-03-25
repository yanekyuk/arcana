---
trigger: "/reload-plugins shows 'Duplicate hooks file detected' — plugin.json declares hooks path that is already auto-loaded"
type: fix
branch: fix/duplicate-hooks-manifest
created: 2026-03-25
version-bump: patch
---

## Related Files
- `plugins/swe/.claude-plugin/plugin.json` — contains redundant `"hooks": "./hooks/hooks.json"` field
- `plugins/swe/hooks/hooks.json` — the hooks file (auto-discovered by Claude Code)
- `.claude-plugin/marketplace.json` — version must stay in sync with plugin.json

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope
Remove the `"hooks"` field from `plugins/swe/.claude-plugin/plugin.json`. Claude Code auto-discovers `hooks/hooks.json` from the standard path, so declaring it explicitly causes a "duplicate hooks file" load error. Bump version to 0.5.2 in both plugin.json and marketplace.json.
