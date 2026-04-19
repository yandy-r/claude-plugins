---
description: Unified planning workflow — research, analyze, and generate parallel implementation plans in one command. Combines shared-context and parallel-plan with checkpoint support. Defaults to standalone parallel sub-agents via the Task tool; pass --team (Claude Code only) to orchestrate research, analysis, and validation stages as teammates under a shared TeamCreate/TaskList with coordinated shutdown.
argument-hint: '[--team] [--research-only] [--plan-only] [--no-checkpoint] [--optimized] [--dry-run] [--worktree] [feature-name]'
---

# Plan Workflow Command

Run the unified planning pipeline for the specified feature.

**Load and follow the `ycc:plan-workflow` skill**, passing through `$ARGUMENTS`.

The skill orchestrates research → shared-context → parallel-plan in a single coordinated flow.

**Flags** (pass before the feature name):

- `--team` — (Claude Code only) Dispatch the research, analysis, and validation stages as teammates under a shared `TeamCreate`/`TaskList` with coordinated shutdown and inter-teammate `SendMessage` coordination. Default is standalone parallel sub-agents via the `Task` tool. Cursor and Codex bundles lack team tools — do not pass `--team` there.
- `--research-only` — Stop after research phase (creates `shared.md` only).
- `--plan-only` — Skip research, use existing `shared.md`.
- `--no-checkpoint` — No pause between research and planning.
- `--optimized` — Use 7-agent optimized deployment (default: 10-agent standard).
- `--dry-run` — Preview the execution plan without deploying agents. With `--team`, also prints the team name and teammate roster.
- `--worktree` — Emit worktree annotations in the generated `parallel-plan.md`: a top-level `## Worktree Setup` block and per-parallel-task `**Worktree**:` fields. No effect with `--research-only`. Honored with `--plan-only`. See `ycc/skills/_shared/references/worktree-strategy.md`.

**Examples**:

```
/ycc:plan-workflow --worktree add a billing dashboard
/ycc:plan-workflow --team --worktree user-authentication
```
