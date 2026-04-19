---
description: 'Generate a detailed parallel implementation plan with task dependencies,
  file ownership, and batch ordering. Step 2 of the planning workflow — requires shared-context
  output. Produces parallel-plan.md ready for implement-plan. Defaults to standalone
  parallel sub-agents via the opencode `task` tool; pass --team (Claude Code only)
  to orchestrate the analysis and validation stages as teammates under a shared spawn
  coordinated subagents/the todo tracker with coordinated shutdown. Usage: [--team]
  [--worktree] [feature-name] [--dry-run]'
---

# Parallel Plan Command

Generate a parallel implementation plan for the specified feature.

**Load and follow the `parallel-plan` skill**, passing through `$ARGUMENTS`.

The skill analyzes the shared context, designs independent task batches with explicit dependencies, and produces `parallel-plan.md` ready for `implement-plan` to execute.

**Flags** (pass before the feature name):

- `--team` — (Claude Code only) Dispatch the 3 analysis agents and 3 validation agents as teammates under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown and inter-teammate `send follow-up instructions` coordination. Default is standalone parallel sub-agents via the `Task` tool. Cursor and Codex bundles lack team tools — do not pass `--team` there.
- `--worktree` — Emit worktree annotations in `parallel-plan.md`: a top-level `## Worktree Setup` block and per-parallel-task `**Worktree**:` fields. Downstream `/implement-plan --worktree` (or auto-detect) uses these annotations to run each parallel task in its own git worktree. Combines freely with `--team` and `--dry-run`.
- `--dry-run` — Preview the execution plan without deploying agents. With `--team`, also prints the team name and teammate roster.

**Examples**:

```
/parallel-plan user-authentication
/parallel-plan --team payment-integration
/parallel-plan --worktree add a billing dashboard
/parallel-plan --worktree --team user-authentication
/parallel-plan payment-integration --dry-run
```
