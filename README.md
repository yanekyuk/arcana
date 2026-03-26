```
   ___    ____  _____   ___    _   __   ___
  / _ |  / __ \/ ___/  / _ |  / | / /  / _ |
 / __ | / /_/ / /__   / __ | /  |/ /  / __ |
/_/ |_|/_/ \_/\___/  /_/ |_|/_/|___/ /_/ |_|
```

**Opinionated workflow plugins for Claude Code.**

Skills, agents, and MCP servers that encode domain-specific processes — from triage to PR.

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
| `feat-orchestrator` | handoff → config → spec → TDD → self-review → arch check → docs → PR |
| `fix-orchestrator` | handoff → config → investigate → TDD fix → self-review → arch check → docs → PR |
| `refactor-orchestrator` | handoff → config → test guard → incremental refactor → self-review → arch check → docs → PR |
| `docs-orchestrator` | handoff → config → write/update docs → clash-check → arch check → PR |

**Skills** — standalone or orchestrator-invoked:

| Skill | What it does |
|---|---|
| `/run-setup` | Interactive project config wizard — tech stack, architecture rules, integrations |
| `/run-triage` | Explore codebase, classify work, create branch + worktree + handoff |
| `/run-start` | Read handoff, dispatch the right orchestrator |
| `/run-finish` | Review PR, merge, clean up worktree and branches |
| `/run-tdd` | Red → green → refactor → commit cycle |
| `/run-self-review` | Diff-based review against spec, domain rules, code quality |
| `/run-arch-check` | Validate architecture rules against diff — hard gate before PR |
| `/run-open-pr` | Safe staging, conventional commit, PR with template |
| `/run-sync-docs` | Detect implicit knowledge in diffs, update `docs/` |
| `/run-spec` | Create/update specs, check alignment with parent docs |
| `/run-domain-knowledge` | Create/update domain rules, cascade clash-check |
| `/run-design-decision` | Create/update architecture decisions, check alignment |
| `/run-clash-check` | Detect contradictions across the knowledge hierarchy |

### `gamedev` — Game Development

*Coming soon.*

### `research` — Academic Research

*Coming soon.*

## Getting Started

### 1. Configure your project

```
/run-setup
```

Interactive wizard that auto-detects your tech stack, lets you pick architecture presets (Layered, Hexagonal, Vertical Slices, or custom), toggle integrations, and add custom directives. Writes `docs/swe-config.json` — required before any other skill will run.

### 2. Start work

```
/run-triage
```

Describe what you want to build or fix. Triage classifies it (feat/fix/refactor/docs), creates a branch + worktree, and writes a handoff artifact.

### 3. Run the pipeline

```
cd .worktrees/<branch-folder>
# start a new Claude session
/run-start
```

The correct orchestrator picks up the handoff and runs autonomously: spec → TDD → self-review → arch check → docs → PR.

### 4. Review and merge

```
# back in your main session (project root)
/run-finish
```

Reviews the PR (commits, diff quality, scope, version staleness), merges, and cleans up the worktree.

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
            /run-start (in worktree)
                    │
    ┌───────────────┴───────────────┐
    │  fix-orchestrator             │
    │                               │
    │  1. Read handoff              │
    │  2. Load project config       │
    │  3. Fetch knowledge docs      │
    │  4. Investigate root cause    │
    │  5. TDD: reproduce → fix     │
    │  6. Self-review              │
    │  7. Arch check               │
    │  8. Sync docs                │
    │  9. Open PR                  │
    └───────────────┬───────────────┘
                    │
            /run-finish (in main session)
                    │
    ┌───────────────┴───────────────┐
    │  Review → merge → cleanup    │
    └───────────────────────────────┘
```

Two-session model: **Session 1** (project root) runs `/run-setup` (once), `/run-triage`, and `/run-finish`. **Session 2** (in worktree) runs `/run-start` which dispatches the autonomous pipeline.

## Knowledge Hierarchy

The SWE domain maintains a three-tier knowledge base in `docs/`:

```
domain/     ← business rules, invariants (highest authority)
decisions/  ← architecture choices, pattern rationale
specs/      ← feature/fix specifications (most specific)
```

Changes cascade downward. `/run-clash-check` detects contradictions across tiers.

## License

MIT
