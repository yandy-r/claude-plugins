---
description: 'Lightweight conversational planner. Restates requirements, identifies
  risks, outlines phases, then WAITS for explicit user confirmation before touching
  any code. Pass --parallel to shape the planner''s output for parallel execution
  (Batches section + dependency annotations). Pass --team (Claude Code only) to dispatch
  a 3-persona planning team (architect / risk-analyst / test-strategist) and merge
  their outputs into a richer plan. Pass --enhanced to widen the roster to 5 personas,
  adding security-reviewer and ux-reviewer — dispatched as 5 standalone parallel sub-agents
  by default; combine with --team (Claude Code only) for team-coordinated dispatch.
  Usage: [--parallel] [--team] [--enhanced] [--dry-run] [--no-worktree] <what you
  want to plan>'
---

# Plan Command

Create a quick implementation plan and wait for user approval.

**Load and follow the `plan` skill, passing through `$ARGUMENTS`.**

This is the lightweight planner. For an artifact-producing plan with codebase pattern extraction, use `/prp-plan`. For parallel-agent planning, use `/plan-workflow`.

**Flags**:

- `--parallel` — Instruct the `planner` agent to shape its output for parallel execution: adds a `Batches` summary section, uses hierarchical step IDs (`1.1`, `1.2`, `2.1`), and populates `Depends on [...]` annotations on every step. After confirmation, execute in-conversation via `implementor` agents per batch, or save to a file and hand off to `/prp-implement --parallel`. Does NOT fan out research agents — the planner still does its own codebase reads. For research fan-out, use `/prp-plan --parallel`.
- `--team` — (Claude Code only) Dispatch a 3-persona planning team under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown: `architect` (`planner`) for the structural plan, `risk-analyst` (`codebase-research-analyst`) for risks and edge cases, `test-strategist` (`test-strategy-planner`) for the testing strategy. All 3 outputs are merged into one unified plan. Heavier than the default single-agent path — use for complex features where you want multiple perspectives. Cursor and Codex bundles lack team tools; use `--parallel` there instead.
- `--enhanced` — Widen the roster from 3 to **5** personas, adding `security-reviewer` (`research-specialist`) for the threat model and `ux-reviewer` (`research-specialist`) for user-facing impact. When passed alone, dispatches the 5 personas as **standalone parallel sub-agents** (Path C — works in every bundle). Combine with `--team` (Claude Code only) for team-coordinated dispatch (Path B enhanced). Composes with `--parallel` and `--no-worktree`. Lighter than `/prp-plan --enhanced`, which fans out to 7 researchers and writes an artifact file.
- `--dry-run` — Only valid with `--team` or `--enhanced`. Prints the roster (3 baseline or 5 enhanced) and dispatch mode (standalone sub-agents or team), then exits without spawning any agents.
- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Worktree annotations are emitted by default. This flag is accepted as a silent no-op so existing pipelines continue to work.
- `--no-worktree` — Opt out of worktree annotations. The plan will not contain a `## Worktree Setup` section or per-task `**Worktree**:` annotations.

`--parallel`, `--team`, and `--enhanced` are **independent and combinable**. `--parallel` shapes the plan's output format; `--team` switches the dispatch mechanism to a coordinated team; `--enhanced` widens the persona roster (3 → 5). With `--enhanced` alone (no `--team`), the 5 personas run as standalone parallel sub-agents. Pass any combination for a richer or more parallel-ready plan.

```
Usage: /plan [--parallel] [--team] [--enhanced] [--dry-run] [--no-worktree] <what you want to plan>

Examples:
  /plan add real-time notifications when a market resolves
  /plan --parallel refactor the auth middleware to use the new session store
  /plan --team add rate limiting to the API gateway
  /plan --parallel --team add rate limiting to the API gateway
  /plan --team --dry-run add rate limiting to the API gateway       # preview 3-persona team
  /plan --enhanced add a public webhook endpoint for billing events # 5 standalone parallel sub-agents (Path C)
  /plan --enhanced --team add a public webhook endpoint             # 5-persona team (Claude Code only)
  /plan --enhanced --dry-run add a public webhook endpoint          # preview 5-persona standalone roster
  /plan --enhanced --team --dry-run add a public webhook endpoint   # preview 5-persona team
  /plan --enhanced --parallel add a public webhook endpoint         # 5 standalone subs + parallel-shaped plan
  /plan --parallel add a billing dashboard                          # worktree annotations included by default
  /plan --no-worktree --parallel add a billing dashboard            # skip worktree annotations

The skill will:
  1. Parse flags and restate requirements in clear terms
  2. Identify risks and dependencies
  3. Break implementation into phases (with batches if --parallel)
  4. WAIT for explicit user confirmation before any code is written
```
