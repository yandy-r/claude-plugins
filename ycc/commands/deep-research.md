---
description: Conduct strategic multi-perspective research using the Asymmetric Research Squad methodology with 8 specialized personas. Deploys parallel research agents covering historical, contrarian, analogical, systems, journalistic, archaeological, futurist, and negative-space perspectives. Pass --team (Claude Code only) to deploy the 14 research agents as teammates under a shared TeamCreate/TaskList with coordinated shutdown; default is standalone parallel sub-agents. Use for comprehensive research on complex topics requiring diverse viewpoints, competitive analysis, or strategic intelligence gathering.
argument-hint: '[--team] [--output-dir "..."] [--dry-run] <research-subject>'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
  - Agent
  - TodoWrite
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - SendMessage
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
   - **--team**: Optional. (Claude Code only) Deploy the 14 research agents as teammates under a shared `TeamCreate`/`TaskList` with coordinated shutdown. Default is standalone parallel sub-agents. Cursor and Codex bundles lack team tools — do not pass `--team` there.
   - **--output-dir "..."**: Optional custom output directory
   - **--dry-run**: Optional flag to preview research plan. With `--team`, also prints the team name and teammate roster.
   - **research-subject**: Required - the topic to research (can be multi-word)
3. **Follow the skill workflow** through all 4 phases:
   - Phase 0: Research Definition & Setup
   - Phase 1: Asymmetric Persona Deployment (8 parallel agents)
   - Phase 2: The Crucible - Structured Analysis (2 parallel agents)
   - Phase 3: Emergent Insight Generation (4 parallel agents)
   - Phase 4: Strategic Report Synthesis
4. **Present the completion summary** with key findings and research quality metrics
