---
description: Create a single-pass implementation plan from a feature description or PRD. Runs codebase pattern extraction and optional external research, then writes docs/prps/plans/{name}.plan.md.
argument-hint: '<feature description | path/to/prd.md>'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Agent
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - Bash(git:*)
---

# PRP Plan Command

Create a detailed, self-contained implementation plan.

**Load and follow the `ycc:prp-plan` skill, passing through `$ARGUMENTS`.**

The skill detects whether the argument is a PRD file (selects the next pending phase) or a free-form feature description, runs a deep codebase exploration via the `ycc:prp-researcher` agent, and writes a plan that captures every pattern, convention, and gotcha needed for single-pass implementation.

```
Usage: /ycc:prp-plan <feature | path/to/prd.md>

Examples:
  /ycc:prp-plan add rate limiting to the API gateway
  /ycc:prp-plan docs/prps/prds/notifications.prd.md    # PRD-driven (next pending phase)

Next step after plan is written:
  /ycc:prp-implement docs/prps/plans/{name}.plan.md
```
