---
description: Execute a parallel implementation plan by deploying implementor agents in dependency-resolved batches. Step 3 of the planning workflow — requires parallel-plan.md from /ycc:plan-workflow.
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
- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Accepted as a silent no-op. Worktree isolation is on by default. Cannot be combined with `--no-worktree`.
- `--no-worktree` — Force worktree mode **OFF** regardless of plan annotations. Create/use `feat/<feature-name>` in the current checkout and run tasks there.

```
Usage: /ycc:implement-plan [--team] [--dry-run] [--worktree] [--no-worktree] <feature-name>

Examples:
  /ycc:implement-plan user-authentication
    # default: create/reuse one feature worktree on feat/user-authentication

  /ycc:implement-plan --team user-authentication
    # agent-team dispatch (worktree still on by default)

  /ycc:implement-plan --dry-run payment-integration
  /ycc:implement-plan --team --dry-run payment-integration

  /ycc:implement-plan --no-worktree my-feature
    # opt out of worktree isolation; create/use feat/my-feature in the current checkout

  /ycc:implement-plan --team --no-worktree my-feature
    # agent-team dispatch on the current-checkout feature branch

  /goal Execute docs/plans/<feature>/parallel-plan.md via the ycc:implement-plan workflow;
        done when the transcript shows ALL_BATCHES_DONE / FILES_CHANGED_NONEMPTY / LINT_PASS
        all PASS; stop after 25 turns.
    # loop to completion across every batch without re-prompting (Anthropic terminal / Codex CLI only)

Tip: for unattended loop-to-completion, pair with /goal — see the skill's ## /goal pairing section for the full condition template and caveats.
```
