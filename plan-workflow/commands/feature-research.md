---
name: feature-research
description: Deep research for application features including external APIs, business logic, technical specifications, UX analysis, and recommendations. Creates feature-spec.md ready for plan-workflow.
argument-hint: '[feature-name] [--description "..."] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
  - TodoWrite
  - WebSearch
  - WebFetch
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/feature-research/scripts/*.sh:*)'
---

# Feature Research Command

Conduct comprehensive research for a new application feature by deploying parallel research agents.

## User's Request

$ARGUMENTS

## Process

1. **Load the feature-research skill** - Read and follow the `feature-research` skill instructions. The skill contains the complete multi-phase workflow.

2. **Parse arguments** from `$ARGUMENTS`:
   - **feature-name**: First non-flag argument (required)
   - **--description "..."**: Brief feature description (optional but recommended)
   - **--dry-run**: Show execution plan without running

3. **Follow the skill workflow** through all phases:
   - Phase 0: Initialize (parse args, create directory, handle dry-run)
   - Phase 1: Research (deploy 5 parallel agents using prompts from `${CLAUDE_PLUGIN_ROOT}/skills/feature-research/templates/research-agents.md`)
   - Phase 2: Consolidate (validate, read results, generate feature-spec.md using template from `${CLAUDE_PLUGIN_ROOT}/skills/feature-research/templates/spec-structure.md`)
   - Phase 3: Validate and complete (run spec validator, display summary)

4. **Present the summary** with files created, key findings, and next steps.

If no arguments provided, display usage instructions with examples.
