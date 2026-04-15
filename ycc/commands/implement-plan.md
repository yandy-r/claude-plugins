---
description: Execute a parallel implementation plan by deploying implementor agents in dependency-resolved batches. Defaults to standalone sub-agents; pass --team (Claude Code only) to dispatch via an agent team with shared TaskList and up-front dep wiring. Step 3 of the planning workflow, requires parallel-plan.md from plan-workflow.
argument-hint: '[--team] [--dry-run] <feature-name>'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - MultiEdit
  - Agent
  - AskUserQuestion
  - TodoWrite
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
  - Bash(grep:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/implement-plan/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
---

# Implement Plan Command

Execute the parallel implementation plan for the specified feature by loading the implement-plan skill.

**Load and follow the `ycc:implement-plan` skill, passing through `$ARGUMENTS`.**

Parallelism is the baseline — every batch's implementor agents dispatch concurrently. The only choice is **how** they are dispatched:

- **Standalone sub-agents** (default) — plain `Agent` calls per batch, no shared task list. Works in Claude Code, Cursor, and Codex.
- **Agent team** (`--team`, Claude Code only) — single `TeamCreate` with all tasks registered up front (`TaskCreate` + `addBlockedBy` dep wiring), per-batch teammate spawn, coordinated inter-batch shutdown via `SendMessage`, and `TeamDelete` at the end. Shared task-graph observability across all batches. Cursor and Codex bundles lack team tools — `--team` aborts there.

**Flags**:

- `--team` — (Claude Code only) Force agent-team dispatch.
- `--dry-run` — Print the execution plan without deploying agents. With `--team`, also prints the team name and per-batch teammate roster.

```
Usage: /ycc:implement-plan [--team] [--dry-run] <feature-name>

Examples:
  /ycc:implement-plan user-authentication
  /ycc:implement-plan --team user-authentication
  /ycc:implement-plan --dry-run payment-integration
  /ycc:implement-plan --team --dry-run payment-integration
```
