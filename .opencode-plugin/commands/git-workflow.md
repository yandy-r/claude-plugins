---
description: 'Git commit and documentation workflow manager. Analyzes changes, determines
  commit strategy (direct vs agents), writes conventional commit messages, coordinates
  documentation updates, and creates pull requests. Use when completing features,
  making commits, pushing changes, creating PRs, or when the user says "It''s time
  to push commits." Usage: [--dry-run] [--no-docs] [--push] [--pr] [--draft]'
---

# Git Workflow Command

Intelligent git commit and documentation workflow orchestration.

## User's Request

$ARGUMENTS

## Process

1. **Load the git-workflow skill** - Read and follow the `git-workflow` skill instructions. The skill contains the complete multi-phase workflow.

2. **Parse arguments** from `$ARGUMENTS`:
   - **--dry-run**: Show analysis and plan without making changes
   - **--no-docs**: Skip documentation updates (commits only)
   - **--push**: Automatically push after committing
   - **--pr**: Create pull request after pushing (implies --push)
   - **--draft**: Create PR as draft (requires --pr)

3. **Follow the skill workflow** through all phases:
   - Phase 0: Analyze changes (git status, categorize files)
   - Phase 1: Determine strategy (direct commit vs agent deployment)
   - Phase 2: Documentation decision
   - Phase 3a/3b: Execute commit (direct or via agents)
   - Phase 4: Summary and push
   - Phase 5: Pull request creation (if --pr flag)

4. **Present the summary** with commit details, documentation updates, and next steps.

If no arguments provided, proceed with default analysis and commit workflow.

```
Usage: /git-workflow [--dry-run] [--no-docs] [--push] [--pr] [--draft]

Examples:
  /git-workflow                    # Analyze and commit
  /git-workflow --dry-run          # Show plan without changes
  /git-workflow --push             # Commit and push
  /git-workflow --pr               # Commit, push, and create PR
  /git-workflow --pr --draft       # Commit, push, create draft PR
  /git-workflow --no-docs --push   # Skip docs, commit and push
```
