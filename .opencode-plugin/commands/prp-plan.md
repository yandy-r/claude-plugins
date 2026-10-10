---
description: 'Create a single-pass implementation plan from a feature description
  or PRD. Runs codebase pattern extraction and optional external research, then writes
  docs/prps/plans/{name}.plan.md. Use --enhanced to grow research from 3 to 7 specialized
  researchers (same dimensions as feature-research) while keeping a single PRP-compliant
  plan file. Usage: [--parallel] [--enhanced] [--no-worktree] [--visual] [--dry-run]
  <feature description | path/to/prd.md>'
---

# PRP Plan Command

> **OpenCode V2 compatibility:** `--team` is unsupported. If it is supplied, abort before setup or dispatch and ask the caller to rerun without it. This target uses native standalone `subagent` calls only.

Create a detailed, self-contained implementation plan.

**Load and follow the `prp-plan` skill, passing through `$ARGUMENTS`.**

The skill detects whether the argument is a PRD file (selects the next pending phase) or a free-form feature description, runs a deep codebase exploration via the `prp-researcher` agent, and writes a plan that captures every pattern, convention, and gotcha needed for single-pass implementation.

**Flags**:

- `--parallel` — Fan out research across 3 **standalone sub-agent** `prp-researcher` instances dispatched via the foreground native `subagent` call (`background=false`) (each call returns candidate findings for independent validation, plus each researcher writes a `docs/prps/plans/.prp-research/<feature-slug>/<role>.md` backstop file as a disk fallback) and emit a dependency-batched task list with `Depends on [...]` annotations and a `Batches` summary section. Ready for parallel execution via `/prp-implement --parallel`. Default is a single researcher and a sequential task list. Works in opencode, Cursor, and Codex.
- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Worktree annotations are emitted by default. This flag is accepted as a silent no-op so existing pipelines continue to work.
- `--no-worktree` — Opt out of worktree annotations. The plan will not contain a `## Worktree Setup` section or per-task `**Worktree**:` annotations.
- `--visual` — Render the finished plan as an Agent-Native visual artifact (MDX) via `visual-plan`; local-files by default, hosted shareable link requires `--share`.

`--parallel` are **mutually exclusive** — pick one. `--no-worktree` is orthogonal and may be combined with either.

```
Usage: /prp-plan [--parallel] [--enhanced] [--no-worktree] [--visual] [--dry-run] <feature | path/to/prd.md>

Examples:
  /prp-plan add rate limiting to the API gateway
  /prp-plan docs/prps/prds/notifications.prd.md                           # PRD-driven (next pending phase)
  /prp-plan --parallel add rate limiting to the API gateway                # parallel sub-agent research + batched tasks (worktree annotations included by default)
  /prp-plan --no-worktree "add JWT refresh flow"                           # plan without git worktree annotations
  /prp-plan --parallel --no-worktree add rate limiting to the API gateway  # parallel research, no worktree annotations
  /prp-plan --parallel docs/prps/prds/notifications.prd.md
  /prp-plan --enhanced "add JWT refresh flow"
  /prp-plan --enhanced --no-worktree "add rate limiting"
  /prp-plan --visual "add JWT refresh flow"                                # render the finished plan as a visual artifact

Next step after plan is written:
  /prp-implement docs/prps/plans/{name}.plan.md              # sequential execution
  /prp-implement --parallel docs/prps/plans/{name}.plan.md   # parallel sub-agent batch execution
```
