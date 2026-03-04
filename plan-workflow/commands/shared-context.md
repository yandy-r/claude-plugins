---
name: shared-context
description: Create shared context document with relevant files, patterns, tables, and docs for a new feature. Step 1 of the planning workflow.
argument-hint: '[feature-name] [--dry-run]'
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
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/shared-context/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*.sh:*)'
---

# Shared Context Command

Create a shared context document capturing relevant files, tables, patterns, and documentation for a new feature.

## User's Request

$ARGUMENTS

## Process

1. **Load the shared-context skill** - Read and follow the `shared-context` skill instructions. The skill contains the complete workflow.

2. **Parse arguments** from `$ARGUMENTS`:
   - **feature-name**: First non-flag argument (required)
   - **--dry-run**: Show what would be created without running

3. **Follow the skill workflow** through all phases:
   - Phase 0: Initialize (parse args, create directory)
   - Phase 1: Context Gathering (read existing research)
   - Phase 2: Parallel Research (deploy 4 agents)
   - Phase 3: Consolidate (generate shared.md)
   - Phase 4: Validate and display summary

4. **Present the summary** with files created and next steps.

If no arguments provided, display usage instructions with examples.
