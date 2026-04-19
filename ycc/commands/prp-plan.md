---
description: Create a single-pass implementation plan from a feature description or PRD. Runs codebase pattern extraction and optional external research, then writes docs/prps/plans/{name}.plan.md. Pass --parallel to fan out research and emit a dependency-batched plan. Pass --team (Claude Code only) to run the same fan-out as a coordinated agent team with shared TaskList. Pass --worktree to annotate the plan with a ## Worktree Setup section and per-task git isolation paths.
argument-hint: '[--parallel | --team] [--worktree] [--dry-run] <feature description | path/to/prd.md>'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Agent
  - WebSearch
  - WebFetch
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
  - Bash(git:*)
---

# PRP Plan Command

Create a detailed, self-contained implementation plan.

**Load and follow the `ycc:prp-plan` skill, passing through `$ARGUMENTS`.**

The skill detects whether the argument is a PRD file (selects the next pending phase) or a free-form feature description, runs a deep codebase exploration via the `ycc:prp-researcher` agent, and writes a plan that captures every pattern, convention, and gotcha needed for single-pass implementation.

**Flags**:

- `--parallel` — Fan out research across 3 **standalone sub-agent** `ycc:prp-researcher` instances and emit a dependency-batched task list with `Depends on [...]` annotations and a `Batches` summary section. Ready for parallel execution via `/ycc:prp-implement --parallel`. Default is a single researcher and a sequential task list. Works in Claude Code, Cursor, and Codex.
- `--team` — (Claude Code only) Fan out the same 3 researchers as **teammates** under a shared `TeamCreate`/`TaskList` with coordinated shutdown via `SendMessage`. Same plan output as `--parallel`, but with shared task-graph observability. Cursor and Codex bundles lack team tools; use `--parallel` there instead.
- `--worktree` — Annotate the emitted plan with a top-level `## Worktree Setup` section (parent + per-parallel-task children) and a `**Worktree**:` field on every parallel task. The plan consumer (`/ycc:prp-implement --worktree` or auto-detect) uses these annotations to create per-task git-isolated worktrees. Combines freely with `--parallel` and `--team`.
- `--dry-run` — Only valid with `--team`. Prints the team name and teammate roster, then exits without spawning any teammates.

`--parallel` and `--team` are **mutually exclusive** — pick one. `--worktree` is orthogonal and may be combined with either.

```
Usage: /ycc:prp-plan [--parallel | --team] [--worktree] [--dry-run] <feature | path/to/prd.md>

Examples:
  /ycc:prp-plan add rate limiting to the API gateway
  /ycc:prp-plan docs/prps/prds/notifications.prd.md                       # PRD-driven (next pending phase)
  /ycc:prp-plan --parallel add rate limiting to the API gateway            # parallel sub-agent research + batched tasks
  /ycc:prp-plan --team add rate limiting to the API gateway                # team research + batched tasks
  /ycc:prp-plan --worktree "add JWT refresh flow"                          # plan with git worktree annotations
  /ycc:prp-plan --parallel --worktree add rate limiting to the API gateway # parallel research + worktree annotations
  /ycc:prp-plan --team --worktree "add JWT refresh flow"                   # team research + worktree annotations
  /ycc:prp-plan --parallel docs/prps/prds/notifications.prd.md

Next step after plan is written:
  /ycc:prp-implement docs/prps/plans/{name}.plan.md              # sequential execution
  /ycc:prp-implement --parallel docs/prps/plans/{name}.plan.md   # parallel sub-agent batch execution
  /ycc:prp-implement --team docs/prps/plans/{name}.plan.md       # agent-team batch execution
```
