---
description: Lightweight conversational planner. Restates requirements, identifies risks, outlines phases, then WAITS for explicit user confirmation before touching any code.
argument-hint: '<what you want to plan>'
allowed-tools:
  - Read
  - Grep
  - Glob
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

```
Usage: /ycc:plan <what you want to plan>

Example:
  /ycc:plan add real-time notifications when a market resolves

The skill will:
  1. Restate requirements in clear terms
  2. Identify risks and dependencies
  3. Break implementation into phases
  4. WAIT for explicit user confirmation before any code is written
```
