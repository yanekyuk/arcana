---
trigger: "Plugin diagnostics show hooks.json fails validation: expected record, received array"
type: fix
branch: fix/hooks-json-format
created: 2026-03-25
---

## Related Files
- plugins/swe/hooks/hooks.json — current array-based format that fails validation
- plugins/swe/.claude-plugin/plugin.json — references hooks via "hooks": "./hooks/hooks.json"
- plugins/swe/hooks/scripts/*.sh — 7 hook scripts (unchanged, but command paths must stay valid)
- tests/hooks/*.sh — 113 tests for the hook scripts

## Relevant Docs
None — knowledge base does not cover this area yet.

## Scope
Claude Code expects hooks.json to be a record keyed by event name, not an array. The current format:

```json
{"hooks": [ {event, matcher, type, command}, ... ]}
```

Must become a record where each event is a key mapping to an array of rule objects, each with an optional matcher and a nested hooks array:

```json
{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "..."}]}], ...}}
```

The fix is limited to hooks.json — no script changes needed. Existing tests should still pass since they test scripts directly, not the JSON schema.
