---
description: Orchestrate multiple specialized agents to accomplish a complex task through intelligent decomposition and parallel execution. Defaults to standalone sub-agents; pass --team (Claude Code only) to dispatch via an agent team with shared TaskList and up-front dependency wiring.
argument-hint: '[--team] [--dry-run] [--plan-only] [--sequential] <task-description>'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - SendMessage
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/orchestrate/scripts/*.sh:*)'
---

# Orchestrate Command

Decompose and orchestrate a complex task across multiple specialized agents.

**Load and follow the `ycc:orchestrate` skill, passing through `$ARGUMENTS`.**

Parallelism is the baseline — every batch's agents dispatch concurrently. The only choice is **how** they are dispatched:

- **Standalone sub-agents** (default) — plain `Agent` calls per batch, no shared task list. Works in Claude Code, Cursor, and Codex.
- **Agent team** (`--team`, Claude Code only) — single `TeamCreate` with all subtasks registered up front (`TaskCreate` + `addBlockedBy` dep wiring), per-batch teammate spawn, coordinated inter-batch shutdown via `SendMessage`, and `TeamDelete` at the end. Shared task-graph observability across all batches. Cursor and Codex bundles lack team tools — `--team` aborts there.

**Flags**:

- `--team` — (Claude Code only) Dispatch each batch's agents under a shared team with up-front dependency wiring.
- `--dry-run` — Print the orchestration plan without deploying agents. With `--team`, also prints the team name and per-batch teammate roster.
- `--plan-only` — Write the orchestration plan to `docs/orchestration/[sanitized-task].md` without execution.
- `--sequential` — Force sequential execution (single-task batches) for tightly coupled work.

```
Usage: /ycc:orchestrate [--team] [--dry-run] [--plan-only] [--sequential] <task-description>

Examples:
  /ycc:orchestrate "Implement user authentication with tests and docs"
  /ycc:orchestrate --team "Implement user authentication with tests and docs"
  /ycc:orchestrate --dry-run "Debug payment processing failure"
  /ycc:orchestrate --plan-only "Refactor database layer"
  /ycc:orchestrate --sequential "Migrate legacy config"
  /ycc:orchestrate --team --dry-run "Update API documentation across all services"
```
