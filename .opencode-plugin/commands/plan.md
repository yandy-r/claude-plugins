---
description: 'Lightweight conversational planner. Restates requirements, identifies
  risks, outlines phases, then WAITS for explicit user confirmation before touching
  any code. Pass --parallel to shape the planner''s output for parallel execution
  (Batches section + dependency annotations). Pass --team (Claude Code only) to dispatch
  a 3-persona planning team (architect / risk-analyst / test-strategist) and merge
  their outputs into a richer plan. Usage: [--parallel] [--team] [--dry-run] [--worktree]
  <what you want to plan>'
---

# Plan Command

Create a quick implementation plan and wait for user approval.

**Load and follow the `plan` skill, passing through `$ARGUMENTS`.**

This is the lightweight planner. For an artifact-producing plan with codebase pattern extraction, use `/prp-plan`. For parallel-agent planning, use `/plan-workflow`.

**Flags**:

- `--parallel` — Instruct the `planner` agent to shape its output for parallel execution: adds a `Batches` summary section, uses hierarchical step IDs (`1.1`, `1.2`, `2.1`), and populates `Depends on [...]` annotations on every step. After confirmation, execute in-conversation via `implementor` agents per batch, or save to a file and hand off to `/prp-implement --parallel`. Does NOT fan out research agents — the planner still does its own codebase reads. For research fan-out, use `/prp-plan --parallel`.
- `--team` — (Claude Code only) Dispatch a 3-persona planning team under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown: `architect` (`planner`) for the structural plan, `risk-analyst` (`codebase-research-analyst`) for risks and edge cases, `test-strategist` (`test-strategy-planner`) for the testing strategy. All 3 outputs are merged into one unified plan. Heavier than the default single-agent path — use for complex features where you want multiple perspectives. Cursor and Codex bundles lack team tools; use `--parallel` there instead.
- `--dry-run` — Only valid with `--team`. Prints the team name and teammate roster, then exits without spawning any teammates.
- `--worktree` — Instruct the planner to emit worktree annotations: a `## Worktree Setup` block (parent + per-parallel-task child paths) and a `**Worktree**:` field on every parallel task. The plan consumer (e.g., `/prp-implement --worktree`) uses these annotations to run each parallel task in an isolated git worktree with auto fan-in merge after each batch. Combines freely with `--parallel` and `--team`.

`--parallel` and `--team` are **independent and combinable**. `--parallel` shapes the plan's output format; `--team` switches the dispatch mechanism. Pass both for a multi-perspective plan formatted for parallel execution.

```
Usage: /plan [--parallel] [--team] [--dry-run] <what you want to plan>

Examples:
  /plan add real-time notifications when a market resolves
  /plan --parallel refactor the auth middleware to use the new session store
  /plan --team add rate limiting to the API gateway
  /plan --parallel --team add rate limiting to the API gateway
  /plan --team --dry-run add rate limiting to the API gateway   # preview team only
  /plan --worktree --parallel add a billing dashboard

The skill will:
  1. Parse flags and restate requirements in clear terms
  2. Identify risks and dependencies
  3. Break implementation into phases (with batches if --parallel)
  4. WAIT for explicit user confirmation before any code is written
```
