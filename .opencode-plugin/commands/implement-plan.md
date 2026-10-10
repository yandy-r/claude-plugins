---
description: 'Execute a parallel implementation plan by deploying implementor agents
  in dependency-resolved batches. Step 3 of the planning workflow — requires parallel-plan.md
  from /plan-workflow. Usage: [--dry-run] [--worktree] [--no-worktree] <feature-name>'
---

# Implement Plan Command

> **OpenCode V2 compatibility:** `--team` is unsupported. If it is supplied, abort before setup or dispatch and ask the caller to rerun without it. This target uses native standalone `subagent` calls only.

Execute the parallel implementation plan for the specified feature by loading the implement-plan skill.

**Load and follow the `implement-plan` skill, passing through `$ARGUMENTS`.**

Parallelism is the baseline — every batch's implementor agents dispatch concurrently. The only choice is **how** they are dispatched:

- **Standalone sub-agents** (default) — plain native `subagent` calls per batch, no shared task list. Works in opencode, Cursor, and Codex.

**Flags**:

- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Accepted as a silent no-op. Worktree isolation is on by default. Cannot be combined with `--no-worktree`.
- `--no-worktree` — Force worktree mode **OFF** regardless of plan annotations. Create/use `feat/<feature-name>` in the current checkout and run tasks there.

```
Usage: /implement-plan [--dry-run] [--worktree] [--no-worktree] <feature-name>

Examples:
  /implement-plan user-authentication
    # default: create/reuse one feature worktree on feat/user-authentication

    # agent-team dispatch (worktree still on by default)

  /implement-plan --dry-run payment-integration

  /implement-plan --no-worktree my-feature
    # opt out of worktree isolation; create/use feat/my-feature in the current checkout

    # agent-team dispatch on the current-checkout feature branch

  /goal Execute docs/plans/<feature>/parallel-plan.md via the implement-plan workflow;
        done when the transcript shows ALL_BATCHES_DONE / FILES_CHANGED_NONEMPTY / LINT_PASS
        all PASS; stop after 25 turns.
    # loop to completion across every batch without re-prompting (Anthropic terminal / Codex CLI only)

Tip: for unattended loop-to-completion, pair with /goal — see the skill's ## /goal pairing section for the full condition template and caveats.
```
