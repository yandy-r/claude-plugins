---
description: Conduct strategic multi-perspective research using the Asymmetric Research Squad methodology with 8 specialized personas. Deploys parallel research agents covering historical, contrarian, analogical, systems, journalistic, archaeological, futurist, and negative-space perspectives. Use for comprehensive research on complex topics requiring diverse viewpoints, competitive analysis, or strategic intelligence gathering.
argument-hint: '[research-subject] [--output-dir "..."] [--dry-run]'
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
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/deep-research/scripts/*.sh:*)'
---

# Deep Research - Asymmetric Research Squad

## User's Request

$ARGUMENTS

## Process

1. **Load the deep-research skill** using the Skill tool to get the full workflow
2. **Parse arguments** from `$ARGUMENTS`:
   - **research-subject**: Required - the topic to research
   - **--output-dir "..."**: Optional custom output directory
   - **--dry-run**: Optional flag to preview research plan
3. **Follow the skill workflow** through all 4 phases:
   - Phase 0: Research Definition & Setup
   - Phase 1: Asymmetric Persona Deployment (8 parallel agents)
   - Phase 2: The Crucible - Structured Analysis (2 parallel agents)
   - Phase 3: Emergent Insight Generation (4 parallel agents)
   - Phase 4: Strategic Report Synthesis
4. **Present the completion summary** with key findings and research quality metrics
