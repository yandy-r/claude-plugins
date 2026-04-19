---
description: 'Execute a PRP plan file with per-task validation loops. Detects package
  manager, prepares git branch, runs 5 validation levels, writes docs/prps/reports/,
  and archives the plan. Auto-detects parallel-capable plans and prompts the user;
  pass --parallel to force standalone sub-agent batch execution, or --team (Claude
  Code only) to force agent-team batch execution with shared the todo tracker and
  up-front dependency wiring. Pass --worktree to force per-task git worktree isolation
  (plans with worktree annotations are auto-detected and need no flag). Usage: [--parallel
  | --team] [--worktree] [--dry-run] <path/to/plan.md>'
---

# PRP Implement Command

Execute a PRP plan file with rigorous per-task validation.

**Load and follow the `prp-implement` skill, passing through `$ARGUMENTS`.**

The skill walks the plan's Step-by-Step Tasks, runs immediate validation after each change, drives all 5 validation levels (static, unit, build, integration, edge cases) at the end, writes an implementation report, and archives the plan.

**Execution modes**:

- **Sequential** (default) — Process one task at a time with per-task type-check.
- **Parallel sub-agents** — Process batches sequentially, with tasks in each batch dispatched to standalone `implementor` sub-agents in parallel. Between batches, runs type-check + unit tests. Requires a plan with a `## Batches` section (produced by `/prp-plan --parallel` or `--team`). Works in opencode, Cursor, and Codex.
- **Agent team** — (Claude Code only) Same batch flow as parallel sub-agents, but under a single `spawn coordinated subagents` with all tasks registered up front (`track the task` + `addBlockedBy` dep wiring) and coordinated per-batch shutdown via `send follow-up instructions`. Shared task-graph observability across all batches. Cursor and Codex bundles lack team tools; use `--parallel` there.

**Flags**:

- `--parallel` — Force parallel sub-agent execution. Skips the interactive prompt when the plan is parallel-capable. Falls back to sequential with a warning if the plan has no `Batches` section.
- `--team` — (Claude Code only) Force agent-team execution. **Aborts** (does not fall back) if the plan has no `Batches` section — agent-team mode requires a parallel-capable plan.
- `--worktree` — Force git worktree isolation per parallel task, even when the plan has no `## Worktree Setup` annotations. When the plan already contains worktree annotations (produced by `/prp-plan --worktree` or `/parallel-plan --worktree`), they are used automatically — no flag needed. Each parallel task runs in its own child worktree; after each batch validates, child branches are merged back into the parent. Sequential tasks always run in the parent worktree. Combines freely with `--parallel` and `--team`.
- `--dry-run` — Only valid with `--team`. Prints the team name, full task graph with dependencies, and per-batch teammate roster, then exits without spawning any teammates.

`--parallel` and `--team` are **mutually exclusive** — pick one.

**Auto-detection**: If you omit both flags and the plan is parallel-capable, the skill prompts you to choose sequential / parallel sub-agents / agent team before executing. If the plan contains a `## Worktree Setup` section, worktree mode activates automatically regardless of whether `--worktree` is passed.

```
Usage: /prp-implement [--parallel | --team] [--worktree] [--dry-run] <path/to/plan.md>

Examples:
  /prp-implement docs/prps/plans/rate-limiting.plan.md
    # auto-detect mode; if plan has ## Worktree Setup, worktree mode activates automatically

  /prp-implement --parallel docs/prps/plans/rate-limiting.plan.md
    # force parallel sub-agent batch execution

  /prp-implement --team docs/prps/plans/rate-limiting.plan.md
    # force agent-team batch execution

  /prp-implement --worktree docs/prps/plans/rate-limiting.plan.md
    # force worktree isolation per parallel task even though the plan has no annotations

  /prp-implement --team --worktree docs/prps/plans/rate-limiting.plan.md
    # agent-team execution with per-task child worktrees and fan-in merge after each batch

  /prp-implement --team --dry-run docs/prps/plans/rate-limiting.plan.md
    # preview team graph (no agents spawned)

Next step after implementation completes:
  /prp-pr            # Create a pull request
  /code-review       # Review changes locally first
```
