---
description: 'Conduct strategic multi-perspective research using the Asymmetric Research
  Squad methodology — 8 specialized personas (historical, contrarian, analogical,
  systems, journalistic, archaeological, futurist, negative-space) deployed in parallel.
  For comprehensive research on complex topics requiring diverse viewpoints, competitive
  analysis, or strategic intelligence gathering. Usage: [--output-dir "..."] [--dry-run]
  <research-subject>'
---

# Deep Research - Asymmetric Research Squad

> **OpenCode V2 compatibility:** `--team` is unsupported. If it is supplied, abort before setup or dispatch and ask the caller to rerun without it. This target uses native standalone `subagent` calls only.

## User's Request

$ARGUMENTS

## Process

1. **Load the deep-research skill** using the Skill tool to get the full workflow
2. **Parse arguments** from `$ARGUMENTS`:
   - **--output-dir "..."**: Optional custom output directory
   - **research-subject**: Required - the topic to research (can be multi-word)
3. **Follow the skill workflow** through all 4 phases:
   - Phase 0: Research Definition & Setup
   - Phase 1: Asymmetric Persona Deployment (8 parallel agents)
   - Phase 2: The Crucible - Structured Analysis (2 parallel agents)
   - Phase 3: Emergent Insight Generation (4 parallel agents)
   - Phase 4: Strategic Report Synthesis
4. **Present the completion summary** with key findings and research quality metrics
