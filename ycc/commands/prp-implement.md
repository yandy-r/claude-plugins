---
description: Execute a PRP plan file with per-task validation loops. Detects package manager, prepares git branch, runs 5 validation levels, writes docs/prps/reports/, and archives the plan.
argument-hint: '<path/to/plan.md>'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - MultiEdit
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - Bash(mv:*)
  - Bash(git:*)
  - Bash(npm:*)
  - Bash(pnpm:*)
  - Bash(yarn:*)
  - Bash(bun:*)
  - Bash(uv:*)
  - Bash(python:*)
  - Bash(python3:*)
  - Bash(pytest:*)
  - Bash(cargo:*)
  - Bash(go:*)
  - Bash(make:*)
  - Bash(curl:*)
---

# PRP Implement Command

Execute a PRP plan file with rigorous per-task validation.

**Load and follow the `ycc:prp-implement` skill, passing through `$ARGUMENTS`.**

The skill walks the plan's Step-by-Step Tasks one at a time, runs immediate validation after each change, drives all 5 validation levels (static, unit, build, integration, edge cases) at the end, writes an implementation report, and archives the plan.

```
Usage: /ycc:prp-implement <path/to/plan.md>

Example:
  /ycc:prp-implement docs/prps/plans/rate-limiting.plan.md

Next step after implementation completes:
  /ycc:prp-pr            # Create a pull request
  /ycc:code-review       # Review changes locally first
```
