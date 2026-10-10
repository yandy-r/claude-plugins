---
description: 'Orchestrate multiple specialized agents to accomplish a complex task
  through intelligent decomposition and parallel execution. Defaults to standalone
  sub-agents. Worktree isolation is ON by default; all parallel and sequential agents
  share one feature worktree. Pass --no-worktree to opt out. Usage: [--dry-run] [--plan-only]
  [--sequential] [--worktree] [--no-worktree] <task-description>'
---

# Orchestrate Command

> **OpenCode V2 compatibility:** `--team` is unsupported. If it is supplied, abort before setup or dispatch and ask the caller to rerun without it. This target uses native standalone `subagent` calls only.

Decompose and orchestrate a complex task across multiple specialized agents.

**Load and follow the `orchestrate` skill, passing through `$ARGUMENTS`.**

Parallelism is the baseline — every batch's agents dispatch concurrently. The only choice is **how** they are dispatched:

- **Standalone sub-agents** (default) — plain native `subagent` calls per batch, no shared task list. Works in opencode, Cursor, and Codex.

**Flags**:

- `--plan-only` — Write the orchestration plan to `docs/orchestration/[sanitized-task].md` without execution. When worktree mode is active, the plan gains a `## Worktree Setup` section.
- `--sequential` — Force sequential execution (single-task batches) for tightly coupled work. When worktree mode is active, uses the parent worktree only.
- `--worktree` — (legacy — now default for parallel tasks; pass `--no-worktree` to opt out) Accepted as a silent no-op. Worktree isolation is on by default.
- `--no-worktree` — Force worktree mode **OFF**. All tasks run directly in the current checkout. No feature worktree is created.

```
Usage: /orchestrate [--dry-run] [--plan-only] [--sequential] [--worktree] [--no-worktree] <task-description>

Examples:
  /orchestrate "Implement user authentication with tests and docs"
    # default: all parallel and sequential tasks share one feature worktree

    # agent-team dispatch (worktree still on by default for parallel tasks)

  /orchestrate --dry-run "Debug payment processing failure"
  /orchestrate --plan-only "Refactor database layer"
  /orchestrate --sequential "Migrate legacy config"

  /orchestrate --no-worktree "Refactor the auth middleware"
    # opt out of worktree isolation; all tasks run in the current checkout

    # agent-team dispatch without worktrees
```
