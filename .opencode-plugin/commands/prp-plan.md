---
description: 'Create a single-pass implementation plan from a feature description
  or PRD. Runs codebase pattern extraction and optional external research, then writes
  docs/prps/plans/{name}.plan.md. Pass --parallel to fan out research and emit a dependency-batched
  plan. Pass --team (Claude Code only) to run the same fan-out as a coordinated agent
  team with shared the todo tracker. Usage: [--parallel | --team] [--dry-run] <feature
  description | path/to/prd.md>'
---

# PRP Plan Command

Create a detailed, self-contained implementation plan.

**Load and follow the `prp-plan` skill, passing through `$ARGUMENTS`.**

The skill detects whether the argument is a PRD file (selects the next pending phase) or a free-form feature description, runs a deep codebase exploration via the `prp-researcher` agent, and writes a plan that captures every pattern, convention, and gotcha needed for single-pass implementation.

**Flags**:

- `--parallel` — Fan out research across 3 **standalone sub-agent** `prp-researcher` instances and emit a dependency-batched task list with `Depends on [...]` annotations and a `Batches` summary section. Ready for parallel execution via `/prp-implement --parallel`. Default is a single researcher and a sequential task list. Works in opencode, Cursor, and Codex.
- `--team` — (Claude Code only) Fan out the same 3 researchers as **teammates** under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown via `send follow-up instructions`. Same plan output as `--parallel`, but with shared task-graph observability. Cursor and Codex bundles lack team tools; use `--parallel` there instead.
- `--dry-run` — Only valid with `--team`. Prints the team name and teammate roster, then exits without spawning any teammates.

`--parallel` and `--team` are **mutually exclusive** — pick one.

```
Usage: /prp-plan [--parallel | --team] [--dry-run] <feature | path/to/prd.md>

Examples:
  /prp-plan add rate limiting to the API gateway
  /prp-plan docs/prps/prds/notifications.prd.md             # PRD-driven (next pending phase)
  /prp-plan --parallel add rate limiting to the API gateway # parallel sub-agent research + batched tasks
  /prp-plan --team add rate limiting to the API gateway     # team research + batched tasks
  /prp-plan --parallel docs/prps/prds/notifications.prd.md

Next step after plan is written:
  /prp-implement docs/prps/plans/{name}.plan.md              # sequential execution
  /prp-implement --parallel docs/prps/plans/{name}.plan.md   # parallel sub-agent batch execution
  /prp-implement --team docs/prps/plans/{name}.plan.md       # agent-team batch execution
```
