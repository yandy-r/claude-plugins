---
description: Execute a PRP plan file with per-task validation loops. Detects package manager, prepares git branch, runs 5 validation levels, writes docs/prps/reports/, and archives the plan. Auto-detects parallel-capable plans and prompts the user; pass --parallel to force parallel batch execution via ycc:implementor agents.
argument-hint: '[--parallel] <path/to/plan.md>'
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
- **Parallel** — Process batches sequentially, with tasks in each batch dispatched to `ycc:implementor` agents in parallel. Between batches, runs type-check + unit tests. Requires a plan with a `## Batches` section (produced by `/ycc:prp-plan --parallel`).

**Flags**:

- `--parallel` — Force parallel execution. Skips the interactive prompt when the plan is parallel-capable. Falls back to sequential with a warning if the plan has no `Batches` section.

**Auto-detection**: If you omit the flag and the plan is parallel-capable, the skill prompts you to choose sequential or parallel mode before executing.

```
Usage: /ycc:prp-implement [--parallel] <path/to/plan.md>

Examples:
  /ycc:prp-implement docs/prps/plans/rate-limiting.plan.md              # auto-detect, prompt if parallel-capable
  /ycc:prp-implement --parallel docs/prps/plans/rate-limiting.plan.md   # force parallel batch execution

Next step after implementation completes:
  /ycc:prp-pr            # Create a pull request
  /ycc:code-review       # Review changes locally first
```
