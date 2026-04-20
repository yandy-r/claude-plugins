---
description: Execute a parallel implementation plan by deploying implementor agents in dependency-resolved batches. Defaults to standalone sub-agents; pass --team (Claude Code only) to dispatch via an agent team with shared TaskList and up-front dep wiring. Worktree isolation is ON by default; pass --no-worktree to opt out. --worktree is accepted as a legacy no-op. Step 3 of the planning workflow, requires parallel-plan.md from plan-workflow.
argument-hint: '[--team] [--dry-run] [--worktree] [--no-worktree] <feature-name>'
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
- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Accepted as a silent no-op. Worktree isolation is on by default.
- `--no-worktree` — Force worktree mode **OFF** regardless of plan annotations. Tasks run directly in the current checkout.

```
Usage: /ycc:implement-plan [--team] [--dry-run] [--worktree] [--no-worktree] <feature-name>

Examples:
  /ycc:implement-plan user-authentication
    # default: worktree isolation ON; plan annotations used when present, derived paths otherwise

  /ycc:implement-plan --team user-authentication
    # agent-team dispatch (worktree still on by default)

  /ycc:implement-plan --dry-run payment-integration
  /ycc:implement-plan --team --dry-run payment-integration

  /ycc:implement-plan --no-worktree my-feature
    # opt out of worktree isolation; tasks run directly in the current checkout

  /ycc:implement-plan --team --no-worktree my-feature
    # agent-team dispatch without worktrees
```
