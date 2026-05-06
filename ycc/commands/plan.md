---
description: Lightweight conversational planner. Restates requirements, identifies risks, outlines phases, then WAITS for explicit confirmation before any code is written. Lighter than /ycc:plan-workflow (parallel research) and /ycc:prp-plan (PRD-driven, artifact-producing).
argument-hint: '[--parallel] [--team] [--enhanced] [--dry-run] [--no-worktree] <what you want to plan>'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Agent
  - TodoWrite
  - AskUserQuestion
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
  - Bash(git:*)
---

# Plan Command

Create a quick implementation plan and wait for user approval.

**Load and follow the `ycc:plan` skill, passing through `$ARGUMENTS`.**

This is the lightweight planner. For an artifact-producing plan with codebase pattern extraction, use `/ycc:prp-plan`. For parallel-agent planning, use `/ycc:plan-workflow`.

**Flags**:

- `--parallel` — Instruct the `ycc:planner` agent to shape its output for parallel execution: adds a `Batches` summary section, uses hierarchical step IDs (`1.1`, `1.2`, `2.1`), and populates `Depends on [...]` annotations on every step. After confirmation, execute in-conversation via `ycc:implementor` agents per batch, or save to a file and hand off to `/ycc:prp-implement --parallel`. Does NOT fan out research agents — the planner still does its own codebase reads. For research fan-out, use `/ycc:prp-plan --parallel`.
- `--team` — (Claude Code only) Dispatch a 3-persona planning team under a shared `TeamCreate`/`TaskList` with coordinated shutdown: `architect` (`ycc:planner`) for the structural plan, `risk-analyst` (`ycc:codebase-research-analyst`) for risks and edge cases, `test-strategist` (`ycc:test-strategy-planner`) for the testing strategy. All 3 outputs are merged into one unified plan. Heavier than the default single-agent path — use for complex features where you want multiple perspectives. Cursor and Codex bundles lack team tools; use `--parallel` there instead.
- `--enhanced` — Widen the roster from 3 to **5** personas, adding `security-reviewer` (`ycc:research-specialist`) for the threat model and `ux-reviewer` (`ycc:research-specialist`) for user-facing impact. When passed alone, dispatches the 5 personas as **standalone parallel sub-agents** (Path C — works in every bundle). Combine with `--team` (Claude Code only) for team-coordinated dispatch (Path B enhanced). Composes with `--parallel` and `--no-worktree`. Lighter than `/ycc:prp-plan --enhanced`, which fans out to 7 researchers and writes an artifact file.
- `--dry-run` — Only valid with `--team` or `--enhanced`. Prints the roster (3 baseline or 5 enhanced) and dispatch mode (standalone sub-agents or team), then exits without spawning any agents.
- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Worktree annotations are emitted by default. This flag is accepted as a silent no-op so existing pipelines continue to work.
- `--no-worktree` — Opt out of worktree annotations. The plan will not contain a `## Worktree Setup` section or per-task `**Worktree**:` annotations.

`--parallel`, `--team`, and `--enhanced` are **independent and combinable**. `--parallel` shapes the plan's output format; `--team` switches the dispatch mechanism to a coordinated team; `--enhanced` widens the persona roster (3 → 5). With `--enhanced` alone (no `--team`), the 5 personas run as standalone parallel sub-agents. Pass any combination for a richer or more parallel-ready plan.

```
Usage: /ycc:plan [--parallel] [--team] [--enhanced] [--dry-run] [--no-worktree] <what you want to plan>

Examples:
  /ycc:plan add real-time notifications when a market resolves
  /ycc:plan --parallel refactor the auth middleware to use the new session store
  /ycc:plan --team add rate limiting to the API gateway
  /ycc:plan --parallel --team add rate limiting to the API gateway
  /ycc:plan --team --dry-run add rate limiting to the API gateway       # preview 3-persona team
  /ycc:plan --enhanced add a public webhook endpoint for billing events # 5 standalone parallel sub-agents (Path C)
  /ycc:plan --enhanced --team add a public webhook endpoint             # 5-persona team (Claude Code only)
  /ycc:plan --enhanced --dry-run add a public webhook endpoint          # preview 5-persona standalone roster
  /ycc:plan --enhanced --team --dry-run add a public webhook endpoint   # preview 5-persona team
  /ycc:plan --enhanced --parallel add a public webhook endpoint         # 5 standalone subs + parallel-shaped plan
  /ycc:plan --parallel add a billing dashboard                          # worktree annotations included by default
  /ycc:plan --no-worktree --parallel add a billing dashboard            # skip worktree annotations

The skill will:
  1. Parse flags and restate requirements in clear terms
  2. Identify risks and dependencies
  3. Break implementation into phases (with batches if --parallel)
  4. WAIT for explicit user confirmation before any code is written
```
