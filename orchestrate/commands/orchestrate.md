---
name: orchestrate
description: Orchestrate multiple specialized agents to accomplish complex tasks through intelligent task decomposition, parallel execution, and result synthesis.
argument-hint: '[task-description] [--dry-run] [--plan-only] [--sequential]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/orchestrate/scripts/*.sh:*)'
---

Invoke the `orchestrate:orchestrate` skill with the provided arguments.
