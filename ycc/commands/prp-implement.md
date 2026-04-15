---
description: Execute a PRP plan file with per-task validation loops. Detects package manager, prepares git branch, runs 5 validation levels, writes docs/prps/reports/, and archives the plan. Auto-detects parallel-capable plans and prompts the user; pass --parallel to force standalone sub-agent batch execution, or --team (Claude Code only) to force agent-team batch execution with shared TaskList and up-front dependency wiring.
argument-hint: '[--parallel | --team] [--dry-run] <path/to/plan.md>'
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
  - Bash(mkdir:*)
  - Bash(mv:*)
  - Bash(git:*)
  - Bash(npm:*)
  - Bash(pnpm:*)
  - Bash(yarn:*)
  - Bash(bun:*)
  - Bash(uv:*)
  - Bash(python:*)
  - Bash(python3:*)
  - Bash(pytest:*)
  - Bash(cargo:*)
  - Bash(go:*)
  - Bash(make:*)
  - Bash(curl:*)
---

# PRP Implement Command

Execute a PRP plan file with rigorous per-task validation.

**Load and follow the `ycc:prp-implement` skill, passing through `$ARGUMENTS`.**

The skill walks the plan's Step-by-Step Tasks, runs immediate validation after each change, drives all 5 validation levels (static, unit, build, integration, edge cases) at the end, writes an implementation report, and archives the plan.

**Execution modes**:

- **Sequential** (default) — Process one task at a time with per-task type-check.
- **Parallel sub-agents** — Process batches sequentially, with tasks in each batch dispatched to standalone `ycc:implementor` sub-agents in parallel. Between batches, runs type-check + unit tests. Requires a plan with a `## Batches` section (produced by `/ycc:prp-plan --parallel` or `--team`). Works in Claude Code, Cursor, and Codex.
- **Agent team** — (Claude Code only) Same batch flow as parallel sub-agents, but under a single `TeamCreate` with all tasks registered up front (`TaskCreate` + `addBlockedBy` dep wiring) and coordinated per-batch shutdown via `SendMessage`. Shared task-graph observability across all batches. Cursor and Codex bundles lack team tools; use `--parallel` there.

**Flags**:

- `--parallel` — Force parallel sub-agent execution. Skips the interactive prompt when the plan is parallel-capable. Falls back to sequential with a warning if the plan has no `Batches` section.
- `--team` — (Claude Code only) Force agent-team execution. **Aborts** (does not fall back) if the plan has no `Batches` section — agent-team mode requires a parallel-capable plan.
- `--dry-run` — Only valid with `--team`. Prints the team name, full task graph with dependencies, and per-batch teammate roster, then exits without spawning any teammates.

`--parallel` and `--team` are **mutually exclusive** — pick one.

**Auto-detection**: If you omit both flags and the plan is parallel-capable, the skill prompts you to choose sequential / parallel sub-agents / agent team before executing.

```
Usage: /ycc:prp-implement [--parallel | --team] [--dry-run] <path/to/plan.md>

Examples:
  /ycc:prp-implement docs/prps/plans/rate-limiting.plan.md              # auto-detect, prompt if parallel-capable
  /ycc:prp-implement --parallel docs/prps/plans/rate-limiting.plan.md   # force parallel sub-agent batch execution
  /ycc:prp-implement --team docs/prps/plans/rate-limiting.plan.md       # force agent-team batch execution
  /ycc:prp-implement --team --dry-run docs/prps/plans/rate-limiting.plan.md  # preview team graph

Next step after implementation completes:
  /ycc:prp-pr            # Create a pull request
  /ycc:code-review       # Review changes locally first
```
