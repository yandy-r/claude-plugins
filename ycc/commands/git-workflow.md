---
description: Git commit and documentation workflow manager. Analyzes changes, determines commit strategy (direct vs agents), writes conventional commit messages, coordinates documentation updates, and creates pull requests. Use when completing features, making commits, pushing changes, creating PRs, or when the user says "It's time to push commits."
argument-hint: '[--commit] [--push] [--pr] [--dry-run] [--no-docs] [--draft]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Task
  - TodoWrite
  - Bash(git:*)
  - Bash(gh:*)
  - 'mcp__github__*'
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/scripts/*.sh:*)'
---

# Git Workflow Command

Intelligent git commit and documentation workflow orchestration.

## User's Request

$ARGUMENTS

## Process

1. **Load the git-workflow skill** - Read and follow the `git-workflow` skill instructions. The skill contains the complete multi-phase workflow.

2. **Parse arguments** from `$ARGUMENTS`. At least one action flag is required; if none provided, the skill prompts with a numbered menu (see Phase 0.5).

   **Action flags** (cumulative — `--pr` implies `--push` implies `--commit`):
   - **--commit**: Commit only (no push, no PR)
   - **--push**: Commit and push (implies `--commit`)
   - **--pr**: Commit, push, and create PR (implies `--push` and `--commit`)

   **Modifier flags** (do not satisfy the action requirement):
   - **--dry-run**: Show analysis and plan without making changes
   - **--no-docs**: Skip documentation updates (commits only)
   - **--draft**: Create PR as draft (requires `--pr`)

3. **Follow the skill workflow** through all phases:
   - Phase 0: Analyze changes (git status, categorize files)
   - Phase 1: Determine strategy (direct commit vs agent deployment)
   - Phase 2: Documentation decision
   - Phase 3a/3b: Execute commit (direct or via agents)
   - Phase 4: Summary and push
   - Phase 5: Pull request creation (if --pr flag)

4. **Present the summary** with commit details, documentation updates, and next steps.

If no action flag (`--commit`, `--push`, or `--pr`) is provided, the skill prompts with a numbered menu (commit / commit & push / commit, push & PR). Modifier flags (`--dry-run`, `--no-docs`, `--draft`) do not satisfy this requirement on their own.

```
Usage: /ycc:git-workflow [--commit] [--push] [--pr] [--dry-run] [--no-docs] [--draft]

Action flags (at least one required, or pick from the interactive prompt):
  --commit                                Commit only
  --push                                  Commit and push (implies --commit)
  --pr                                    Commit, push, and create PR (implies --push and --commit)
  --pr --draft                            ... as a draft PR

Modifier flags:
  --dry-run                               Show analysis and plan without making changes
  --no-docs                               Skip documentation updates

Examples:
  /ycc:git-workflow                       # Prompts: commit / push / PR?
  /ycc:git-workflow --commit              # Commit only
  /ycc:git-workflow --push                # Commit and push
  /ycc:git-workflow --pr                  # Commit, push, create PR
  /ycc:git-workflow --pr --draft          # ... as a draft
  /ycc:git-workflow --commit --dry-run    # Show commit plan, no changes
  /ycc:git-workflow --push --no-docs      # Skip docs, commit and push
```
