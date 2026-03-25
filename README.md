```
   ___    ____  _____   ___    _   __   ___
  / _ |  / __ \/ ___/  / _ |  / | / /  / _ |
 / __ | / /_/ / /__   / __ | /  |/ /  / __ |
/_/ |_|/_/ \_/\___/  /_/ |_|/_/|___/ /_/ |_|
```

**Autonomous workflow plugins for Claude Code.**

Skills, agents, and MCP servers that give Claude Code domain-specific superpowers — from triage to PR, zero hand-holding required.

---

## Install

```
/plugin → Add Marketplace → yanekyuk/arcana
```

## Domains

### `swe` — Software Engineering

Autonomous pipelines that take work from triage to PR.

**Orchestrators** — dispatch one, walk away:

| Agent | Pipeline |
|---|---|
| `feat-orchestrator` | handoff → spec → TDD → self-review → docs → PR |
| `fix-orchestrator` | handoff → reproduce bug → TDD fix → self-review → docs → PR |
| `refactor-orchestrator` | handoff → test guard → incremental refactor → self-review → docs → PR |
| `docs-orchestrator` | handoff → write/update docs → clash-check → PR |

**Skills** — standalone or orchestrator-invoked:

| Skill | What it does |
|---|---|
| `/run-triage` | Explore codebase, classify work, create branch + worktree + handoff |
| `/run-resume` | Read handoff, dispatch the right orchestrator |
| `/run-tdd` | Red → green → refactor → commit cycle |
| `/run-self-review` | Diff-based review against spec, domain rules, code quality |
| `/run-open-pr` | Safe staging, conventional commit, PR with template |
| `/run-sync-docs` | Detect implicit knowledge in diffs, update `.claude/docs/` |
| `/run-spec` | Create/update specs, check alignment with parent docs |
| `/run-domain-knowledge` | Create/update domain rules, cascade clash-check |
| `/run-design-decision` | Create/update architecture decisions, check alignment |
| `/run-clash-check` | Detect contradictions across the knowledge hierarchy |

### `gamedev` — Game Development

*Coming soon.*

### `research` — Academic Research

*Coming soon.*

## How It Works

```
You: "Fix the auth bug in session handling"
                    │
            /run-triage
                    │
    ┌───────────────┴───────────────┐
    │  classify → fix               │
    │  branch  → fix/session-auth   │
    │  worktree + handoff artifact  │
    └───────────────┬───────────────┘
                    │
            /run-resume
                    │
    ┌───────────────┴───────────────┐
    │  fix-orchestrator             │
    │                               │
    │  1. Read handoff              │
    │  2. Discover tooling          │
    │  3. Fetch knowledge docs      │
    │  4. TDD: reproduce → fix      │
    │  5. Self-review               │
    │  6. Sync docs                 │
    │  7. Open PR                   │
    └───────────────────────────────┘
```

Two-session model: **Session 1** (project root) triages and creates the workspace. **Session 2** (in worktree) runs the full autonomous pipeline.

## Knowledge Hierarchy

The SWE domain maintains a three-tier knowledge base in `.claude/docs/`:

```
domain/     ← business rules, invariants (highest authority)
decisions/  ← architecture choices, pattern rationale
specs/      ← feature/fix specifications (most specific)
```

Changes cascade downward. `/run-clash-check` detects contradictions across tiers.

## License

MIT
