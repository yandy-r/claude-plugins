---
description: Convert deep-research output into structured GitHub issues with tracking hierarchy, labels, and priority. Reads research documents, extracts features and deliverables, and creates well-organized GitHub issues. Use when you want to turn research reports into actionable GitHub issues.
argument-hint: '[--dry-run] [--research-dir PATH] [--skip-anti-scope] [--skip-gaps]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Task
  - TodoWrite
  - Bash(gh:*)
  - Bash(git:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(find:*)
  - Bash(wc:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/research-to-issues/scripts/*.sh:*)'
---

# Research to Issues Command

Convert deep-research output into structured GitHub issues.

## User's Request

$ARGUMENTS

## Process

1. **Load the research-to-issues skill** - Read and follow the `research-to-issues` skill instructions. The skill contains the complete multi-phase workflow.

2. **Parse arguments** from `$ARGUMENTS`:
   - **--dry-run**: Preview issues without creating them
   - **--research-dir PATH**: Path to research output directory (default: `docs/research`)
   - **--skip-anti-scope**: Skip creating issues for anti-scope items
   - **--skip-gaps**: Skip creating issues for research gaps

3. **Follow the skill workflow** through all phases:
   - Phase 0: Validate prerequisites (gh CLI, git repo, research dir)
   - Phase 1: Parse research documents (features, deliverables, anti-scope, gaps)
   - Phase 2: Plan issue creation (display plan, stop if --dry-run)
   - Phase 3: Create issues (labels first, features, then tracking issues)
   - Phase 4: Display summary with all created issues

4. **Present the summary** with issue numbers, labels, and next steps.

If no arguments provided, proceed with default research directory (`docs/research`).

```
Usage: /git-workflow:research-to-issues [--dry-run] [--research-dir PATH] [--skip-anti-scope] [--skip-gaps]

Examples:
  /git-workflow:research-to-issues --dry-run                        # Preview what would be created
  /git-workflow:research-to-issues                                  # Create all issues
  /git-workflow:research-to-issues --research-dir ./docs/research   # Specify research path
  /git-workflow:research-to-issues --skip-anti-scope --skip-gaps    # Only core features
  /git-workflow:research-to-issues --dry-run --skip-gaps            # Preview without gaps
```
