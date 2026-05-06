---
description: 'Create a single-pass implementation plan from a feature description
  or PRD. Runs codebase pattern extraction and optional external research, then writes
  docs/prps/plans/{name}.plan.md. Use --enhanced to grow research from 3 to 7 specialized
  researchers (same dimensions as feature-research) while keeping a single PRP-compliant
  plan file. Usage: [--parallel | --team] [--enhanced] [--no-worktree] [--dry-run]
  <feature description | path/to/prd.md>'
---

# PRP Plan Command

Create a detailed, self-contained implementation plan.

**Load and follow the `prp-plan` skill, passing through `$ARGUMENTS`.**

The skill detects whether the argument is a PRD file (selects the next pending phase) or a free-form feature description, runs a deep codebase exploration via the `prp-researcher` agent, and writes a plan that captures every pattern, convention, and gotcha needed for single-pass implementation.

**Flags**:

- `--parallel` — Fan out research across 3 **standalone sub-agent** `prp-researcher` instances and emit a dependency-batched task list with `Depends on [...]` annotations and a `Batches` summary section. Ready for parallel execution via `/prp-implement --parallel`. Default is a single researcher and a sequential task list. Works in opencode, Cursor, and Codex.
- `--team` — (Claude Code only) Fan out the same 3 researchers as **teammates** under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown via `send follow-up instructions`. Same plan output as `--parallel`, but with shared task-graph observability. Cursor and Codex bundles lack team tools; use `--parallel` there instead.
- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Worktree annotations are emitted by default. This flag is accepted as a silent no-op so existing pipelines continue to work.
- `--no-worktree` — Opt out of worktree annotations. The plan will not contain a `## Worktree Setup` section or per-task `**Worktree**:` annotations.
- `--enhanced` — Enhanced research mode. Grows the research fan-out from 3 to 7 specialized researchers (api / business / tech / ux / security / practices / recommendations — same coverage as `feature-research`). Output remains a single PRP-compliant plan file at `docs/prps/plans/{name}.plan.md`. Composes orthogonally with `--parallel`, `--team`, and `--no-worktree`. When passed alone, defaults to standalone sub-agent dispatch (Path B at width 7); combine with `--team` (Claude Code only) for team-coordinated dispatch.
- `--dry-run` — Only valid with `--team`. Prints the team name and teammate roster, then exits without spawning any teammates.

`--parallel` and `--team` are **mutually exclusive** — pick one. `--no-worktree` is orthogonal and may be combined with either.

```
Usage: /prp-plan [--parallel | --team] [--no-worktree] [--dry-run] <feature | path/to/prd.md>

Examples:
  /prp-plan add rate limiting to the API gateway
  /prp-plan docs/prps/prds/notifications.prd.md                           # PRD-driven (next pending phase)
  /prp-plan --parallel add rate limiting to the API gateway                # parallel sub-agent research + batched tasks (worktree annotations included by default)
  /prp-plan --team add rate limiting to the API gateway                    # team research + batched tasks
  /prp-plan --no-worktree "add JWT refresh flow"                           # plan without git worktree annotations
  /prp-plan --parallel --no-worktree add rate limiting to the API gateway  # parallel research, no worktree annotations
  /prp-plan --team --no-worktree "add JWT refresh flow"                    # team research, no worktree annotations
  /prp-plan --parallel docs/prps/prds/notifications.prd.md
  /prp-plan --enhanced "add JWT refresh flow"
  /prp-plan --enhanced --team docs/prps/prds/notifications.prd.md
  /prp-plan --enhanced --no-worktree "add rate limiting"

Next step after plan is written:
  /prp-implement docs/prps/plans/{name}.plan.md              # sequential execution
  /prp-implement --parallel docs/prps/plans/{name}.plan.md   # parallel sub-agent batch execution
  /prp-implement --team docs/prps/plans/{name}.plan.md       # agent-team batch execution
```
