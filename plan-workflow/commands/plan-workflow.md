---
name: plan-workflow
description: Unified planning workflow - research, analyze, and generate parallel implementation plans in one command. Combines shared-context and parallel-plan with checkpoint support and optimized agent deployment.
argument-hint: '[feature-name] [--research-only] [--plan-only] [--no-checkpoint] [--optimized] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
  - TodoWrite
  - AskUserQuestion
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/**/*.sh:*)'
---

# Plan Workflow Command

Unified command to research, analyze, and generate a parallel implementation plan.

## User's Request

$ARGUMENTS

## Process

1. **Load the plan-workflow skill** - Read and follow the `plan-workflow` skill instructions. The skill contains the complete multi-phase workflow.

2. **Parse arguments** from `$ARGUMENTS`:
   - **feature-name**: First non-flag argument (required)
   - **--research-only**: Stop after research phase
   - **--plan-only**: Skip research, use existing shared.md
   - **--no-checkpoint**: No pause between research and planning
   - **--optimized**: Use 7-agent optimized deployment
   - **--dry-run**: Show execution plan without running

3. **Follow the skill workflow** through all phases:
   - Phase 0: Initialize (parse args, detect state, handle dry-run)
   - Phase 1: Research (deploy 4 parallel agents, generate shared.md)
   - Phase 2: Checkpoint (pause for user review)
   - Phase 3: Analysis (deploy 3 analysis agents)
   - Phase 4: Plan Generation (create parallel-plan.md)
   - Phase 5: Validation (deploy validation agents)
   - Phase 6: Summary

4. **Present the summary** with files created, agent deployment stats, and next steps.

If no arguments provided, display usage instructions with examples.
