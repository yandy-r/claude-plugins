---
description: 'Execute a parallel implementation plan by deploying implementor agents
  in dependency-resolved batches. Defaults to standalone sub-agents; pass --team (Claude
  Code only) to dispatch via an agent team with shared the todo tracker and up-front
  dep wiring. Worktree isolation is ON by default and creates/reuses one feature worktree
  on a feature branch; pass --no-worktree to opt out and create/use only the current-checkout
  feature branch. --worktree is accepted as a legacy no-op. Step 3 of the planning
  workflow, requires parallel-plan.md from plan-workflow. Usage: [--team] [--dry-run]
  [--worktree] [--no-worktree] <feature-name>'
---

# Implement Plan Command

Execute the parallel implementation plan for the specified feature by loading the implement-plan skill.

**Load and follow the `implement-plan` skill, passing through `$ARGUMENTS`.**

Parallelism is the baseline — every batch's implementor agents dispatch concurrently. The only choice is **how** they are dispatched:

- **Standalone sub-agents** (default) — plain `Agent` calls per batch, no shared task list. Works in opencode, Cursor, and Codex.
- **Agent team** (`--team`, Claude Code only) — single `spawn coordinated subagents` with all tasks registered up front (`track the task` + `addBlockedBy` dep wiring), per-batch teammate spawn, coordinated inter-batch shutdown via `send follow-up instructions`, and `end the coordinated run` at the end. Shared task-graph observability across all batches. Cursor and Codex bundles lack team tools — `--team` aborts there.

**Flags**:

- `--team` — (Claude Code only) Force agent-team dispatch.
- `--dry-run` — Print the execution plan without deploying agents. With `--team`, also prints the team name and per-batch teammate roster.
- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Accepted as a silent no-op. Worktree isolation is on by default. Cannot be combined with `--no-worktree`.
- `--no-worktree` — Force worktree mode **OFF** regardless of plan annotations. Create/use `feat/<feature-name>` in the current checkout and run tasks there.

```
Usage: /implement-plan [--team] [--dry-run] [--worktree] [--no-worktree] <feature-name>

Examples:
  /implement-plan user-authentication
    # default: create/reuse one feature worktree on feat/user-authentication

  /implement-plan --team user-authentication
    # agent-team dispatch (worktree still on by default)

  /implement-plan --dry-run payment-integration
  /implement-plan --team --dry-run payment-integration

  /implement-plan --no-worktree my-feature
    # opt out of worktree isolation; create/use feat/my-feature in the current checkout

  /implement-plan --team --no-worktree my-feature
    # agent-team dispatch on the current-checkout feature branch
```
