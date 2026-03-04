---
name: parallel-plan
description: Create detailed parallel implementation plans with task dependencies and file paths. Step 2 of the planning workflow, requires shared.md from shared-context.
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
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*.sh:*)'
---

# Parallel Plan Command

Create a detailed parallel implementation plan from shared context.

## User's Request

$ARGUMENTS

## Process

1. **Load the parallel-plan skill** - Read and follow the `parallel-plan` skill instructions. The skill contains the complete workflow.

2. **Parse arguments** from `$ARGUMENTS`:
   - **feature-name**: First non-flag argument (required)
   - **--dry-run**: Show what would be created without running

3. **Follow the skill workflow** through all phases:
   - Phase 0: Prerequisites Check (verify shared.md exists)
   - Phase 1: Agent-Based Context Analysis (deploy 3 analysis agents)
   - Phase 2: Analysis Validation and persistence (`analysis-*.md` must exist)
   - Phase 3: Plan Generation (create parallel-plan.md)
   - Phase 4: Validation (deploy 3 validation agents)
   - Phase 5: Dry Run Check (if requested)
   - Phase 6: Output and summary

Do not generate `parallel-plan.md` until all `analysis-*.md` artifacts are present and non-empty.

4. **Present the summary** with plan overview, validation results, and next steps.

If no arguments provided, display usage instructions with examples.
