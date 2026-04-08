---
description: Lightweight conversational planner. Restates requirements, identifies risks, outlines phases, then WAITS for explicit user confirmation before touching any code. Pass --parallel to shape the planner's output for parallel execution (Batches section + dependency annotations).
argument-hint: '<what you want to plan> [--parallel]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Agent
  - TodoWrite
  - AskUserQuestion
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

```
Usage: /ycc:plan [--parallel] <what you want to plan>

Examples:
  /ycc:plan add real-time notifications when a market resolves
  /ycc:plan --parallel refactor the auth middleware to use the new session store

The skill will:
  1. Parse flags and restate requirements in clear terms
  2. Identify risks and dependencies
  3. Break implementation into phases (with batches if --parallel)
  4. WAIT for explicit user confirmation before any code is written
```
