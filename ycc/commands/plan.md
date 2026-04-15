---
description: Lightweight conversational planner. Restates requirements, identifies risks, outlines phases, then WAITS for explicit user confirmation before touching any code. Pass --parallel to shape the planner's output for parallel execution (Batches section + dependency annotations). Pass --team (Claude Code only) to dispatch a 3-persona planning team (architect / risk-analyst / test-strategist) and merge their outputs into a richer plan.
argument-hint: '[--parallel] [--team] [--dry-run] <what you want to plan>'
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
- `--dry-run` — Only valid with `--team`. Prints the team name and teammate roster, then exits without spawning any teammates.

`--parallel` and `--team` are **independent and combinable**. `--parallel` shapes the plan's output format; `--team` switches the dispatch mechanism. Pass both for a multi-perspective plan formatted for parallel execution.

```
Usage: /ycc:plan [--parallel] [--team] [--dry-run] <what you want to plan>

Examples:
  /ycc:plan add real-time notifications when a market resolves
  /ycc:plan --parallel refactor the auth middleware to use the new session store
  /ycc:plan --team add rate limiting to the API gateway
  /ycc:plan --parallel --team add rate limiting to the API gateway
  /ycc:plan --team --dry-run add rate limiting to the API gateway   # preview team only

The skill will:
  1. Parse flags and restate requirements in clear terms
  2. Identify risks and dependencies
  3. Break implementation into phases (with batches if --parallel)
  4. WAIT for explicit user confirmation before any code is written
```
