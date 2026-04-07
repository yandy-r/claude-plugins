---
description: Generate structured implementation reports documenting changes made during plan execution. Use as optional Step 4 after implement-plan to create reports in docs/plans/[feature-name]/report.md with overview, files changed, features, and test guidance.
argument-hint: '[feature-name] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(git:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/code-report/scripts/*.sh:*)'
---

# Code Report Command

Generate a structured implementation report for a completed feature.

## User's Request

$ARGUMENTS

## Process

1. **Load the code-report skill** - Read and follow the `code-report` skill instructions. The skill contains the complete multi-phase workflow.

2. **Parse arguments** from `$ARGUMENTS`:
   - **feature-name**: First non-flag argument (required)
   - **--dry-run**: Show what would be created without making changes

3. **Follow the skill workflow** through all phases:
   - Phase 0: Prerequisites check (validate planning documents exist)
   - Phase 1: Gather context (read plans, identify changed files)
   - Phase 2: Generate report (create docs/plans/[feature-name]/report.md)
   - Phase 3: Validation and summary

4. **Present the summary** with report location, statistics, and next steps.

If no arguments provided, display usage instructions:

```
Usage: /code-report [feature-name] [--dry-run]

Examples:
  /code-report user-authentication
  /code-report payment-integration --dry-run
```
