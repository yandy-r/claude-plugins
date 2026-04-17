---
description: 'Convert research, feature specs, and implementation plans into structured
  GitHub issues with tracking hierarchy, labels, and priority. Supports deep-research
  output, feature-spec documents, parallel-plan plans, and PRP plans. Creates detailed,
  agentic-engineering-friendly issues with mandatory reading, scope, and validation
  criteria. Usage: [--dry-run] [--source PATH] [--type TYPE] [--skip-anti-scope] [--skip-gaps]'
---

# Research to Issues Command

Convert research and planning output into structured GitHub issues.

## User's Request

$ARGUMENTS

## Process

1. **Load the research-to-issues skill** - Read and follow the `research-to-issues` skill instructions. The skill contains the complete multi-phase workflow.

2. **Parse arguments** from `$ARGUMENTS`:
   - **--dry-run**: Preview issues without creating them
   - **--source PATH**: Path to source file or directory (alias: `--research-dir`)
   - **--type TYPE**: Explicit source type (`deep-research`, `feature-spec`, `parallel-plan`, `prp-plan`)
   - **--skip-anti-scope**: Skip creating issues for anti-scope items
   - **--skip-gaps**: Skip creating issues for research gaps

3. **Follow the skill workflow** through all phases:
   - Phase 0: Validate prerequisites and detect source type
   - Phase 1: Parse source document using type-specific reference
   - Phase 2: Plan issue creation (display plan, stop if --dry-run)
   - Phase 3: Create issues (labels first, child issues, then tracking issues)
   - Phase 4: Display summary with all created issues

4. **Present the summary** with issue numbers, labels, and next steps.

If no arguments provided, search for source documents in common locations and ask the user to confirm.

```
Usage: /research-to-issues [--dry-run] [--source PATH] [--type TYPE] [--skip-anti-scope] [--skip-gaps]

Supported source types:
  deep-research   - Directory from deep-research (RESEARCH-REPORT.md + synthesis/ + analysis/)
  feature-spec    - feature-spec.md from feature-research
  parallel-plan   - parallel-plan.md from parallel-plan or plan-workflow
  prp-plan        - *.plan.md from prp-plan

Examples:
  /research-to-issues --dry-run                                         # Auto-detect and preview
  /research-to-issues --source docs/plans/auth/feature-spec.md          # From feature spec
  /research-to-issues --source docs/plans/auth/parallel-plan.md         # From parallel plan
  /research-to-issues --source docs/prps/plans/auth.plan.md             # From PRP plan
  /research-to-issues --source docs/research/ --type deep-research      # From deep research
  /research-to-issues --source docs/plans/auth/feature-spec.md --dry-run  # Preview feature spec issues
  /research-to-issues --skip-anti-scope --skip-gaps                     # Only core items
```
