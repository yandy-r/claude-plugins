---
description: 'Lightweight conversational planner. Restates requirements, identifies
  risks, outlines phases, then WAITS for explicit confirmation before any code is
  written. Lighter than /plan-workflow (parallel research) and /prp-plan (PRD-driven,
  artifact-producing). Usage: [--parallel] [--enhanced] [--dry-run] [--no-worktree]
  [--visual] <what you want to plan>'
---

# Plan Command

> **OpenCode V2 compatibility:** `--team` is unsupported. If it is supplied, abort before setup or dispatch and ask the caller to rerun without it. This target uses native standalone `subagent` calls only.

Create a quick implementation plan and wait for user approval.

**Load and follow the `plan` skill, passing through `$ARGUMENTS`.**

This is the lightweight planner. For an artifact-producing plan with codebase pattern extraction, use `/prp-plan`. For parallel-agent planning, use `/plan-workflow`.

**Flags**:

- `--parallel` — Instruct the `planner` agent to shape its output for parallel execution: adds a `Batches` summary section, uses hierarchical step IDs (`1.1`, `1.2`, `2.1`), and populates `Depends on [...]` annotations on every step. After confirmation, execute in-conversation via `implementor` agents per batch, or save to a file and hand off to `/prp-implement --parallel`. Does NOT fan out research agents — the planner still does its own codebase reads. For research fan-out, use `/prp-plan --parallel`.
- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Worktree annotations are emitted by default. This flag is accepted as a silent no-op so existing pipelines continue to work.
- `--no-worktree` — Opt out of worktree annotations. The plan will not contain a `## Worktree Setup` section or per-task `**Worktree**:` annotations.
- `--visual` — Force-write the plan to a file, then render it as an Agent-Native visual artifact (MDX) via `visual-plan`; local-files by default, hosted link requires `--share`. Because `/plan` writes no file by default, `--visual` forces a plan-file write first. Orthogonal to the dispatch flags; `--dry-run` short-circuits it (prints intent only).


```
Usage: /plan [--parallel] [--enhanced] [--dry-run] [--no-worktree] [--visual] <what you want to plan>

Examples:
  /plan add real-time notifications when a market resolves
  /plan --parallel refactor the auth middleware to use the new session store
  /plan --enhanced add a public webhook endpoint for billing events # 5 standalone parallel sub-agents (Path C)
  /plan --enhanced --dry-run add a public webhook endpoint          # preview 5-persona standalone roster
  /plan --enhanced --parallel add a public webhook endpoint         # 5 standalone subs + parallel-shaped plan
  /plan --parallel add a billing dashboard                          # worktree annotations included by default
  /plan --no-worktree --parallel add a billing dashboard            # skip worktree annotations
  /plan --visual add a billing dashboard                            # force-write plan, then render visual artifact

The skill will:
  1. Parse flags and restate requirements in clear terms
  2. Identify risks and dependencies
  3. Break implementation into phases (with batches if --parallel)
  4. WAIT for explicit user confirmation before any code is written
```
