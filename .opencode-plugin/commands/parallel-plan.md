---
description: 'Generate a detailed parallel implementation plan with task dependencies,
  file ownership, and batch ordering. Step 2 of the planning workflow — requires shared-context
  output. Produces parallel-plan.md ready for implement-plan. Defaults to standalone
  parallel sub-agents via the native `subagent` tool. Usage: [--no-worktree] [--visual]
  [feature-name] [--dry-run]'
---

# Parallel Plan Command

> **OpenCode V2 compatibility:** `--team` is unsupported. If it is supplied, abort before setup or dispatch and ask the caller to rerun without it. This target uses native standalone `subagent` calls only.

Thin alias for `plan-workflow --plan-only` (planning stage with `--no-checkpoint`).

Generate a parallel implementation plan for the specified feature.

**Load and follow the `parallel-plan` skill**, passing through `$ARGUMENTS`.

The skill analyzes the shared context, designs independent task batches with explicit dependencies, and produces `parallel-plan.md` ready for `implement-plan` to execute.

**Flags** (pass before the feature name):

- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Worktree annotations are emitted by default. This flag is accepted as a silent no-op so existing pipelines continue to work.
- `--no-worktree` — Opt out of worktree annotations. The plan will not contain a `## Worktree Setup` section or per-task `**Worktree**:` annotations.
- `--visual` — Render the finished plan as an Agent-Native visual artifact (MDX) via `visual-plan`; local-files by default, hosted link requires `--share`. Runs only after the plan is written and validated; `--dry-run` short-circuits it (prints intent only).

**Examples**:

```
/parallel-plan user-authentication
/parallel-plan add a billing dashboard                    # worktree annotations included by default
/parallel-plan --no-worktree add a billing dashboard      # skip worktree annotations
/parallel-plan --visual user-authentication               # also render the plan as a visual artifact
/parallel-plan payment-integration --dry-run
```
