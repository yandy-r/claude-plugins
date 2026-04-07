---
description: Orchestrate 5 specialized documentation agents in parallel to analyze codebase and create comprehensive documentation. Includes audit, gap analysis, parallel agent deployment, and quality assurance.
argument-hint: '[scope] [--update|--fresh|--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - MultiEdit
  - Task
  - TodoWrite
  - AskUserQuestion
  - Bash(ls:*)
  - Bash(find:*)
  - Bash(mkdir:*)
  - Bash(cat:*)
  - Bash(head:*)
  - Bash(wc:*)
  - Bash(stat:*)
  - Bash(tree:*)
  - Bash(date:*)
  - Bash(chmod:*)
  - Bash(pwd:*)
  - Bash(basename:*)
  - Bash(test:*)
  - Bash(echo:*)
  - Bash(tr:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/write-docs/scripts/*.sh:*)'
---

Invoke the `ycc:write-docs` skill with the provided arguments.
