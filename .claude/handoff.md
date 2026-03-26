---
trigger: "Skills without user-invocable: true still appear in the / slash command menu. The previous refactor removed user-invocable from 9 internal skills, but the field defaults to true when omitted."
type: fix
branch: fix/skill-invocable-default
created: 2026-03-26
version-bump: patch
---

## Related Files
- plugins/swe/skills/run-arch-check/SKILL.md
- plugins/swe/skills/run-clash-check/SKILL.md
- plugins/swe/skills/run-design-decision/SKILL.md
- plugins/swe/skills/run-domain-knowledge/SKILL.md
- plugins/swe/skills/run-open-pr/SKILL.md
- plugins/swe/skills/run-self-review/SKILL.md
- plugins/swe/skills/run-spec/SKILL.md
- plugins/swe/skills/run-sync-docs/SKILL.md
- plugins/swe/skills/run-tdd/SKILL.md
- plugins/swe/.claude-plugin/plugin.json
- .claude-plugin/marketplace.json

## Relevant Docs
- docs/claude-code-extensions-reference.md — documents that `user-invocable` defaults to `true` when omitted

## Scope
Add `user-invocable: false` to the YAML frontmatter of all 9 internal-only skills listed above. The previous refactor (commit 55c3bf0) removed the field entirely, but per the Claude Code extensions spec, omitting it causes it to default to `true`, which means the skills still appear in the `/` slash command menu. Bump version in plugin.json and marketplace.json.
