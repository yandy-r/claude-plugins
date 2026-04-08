---
description: Create a GitHub PR from the current branch — discovers templates, analyzes commits, references PRP artifacts, pushes, and opens the PR via gh.
argument-hint: '[base-branch] [--draft]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(git:*)
  - Bash(gh:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(find:*)
  - 'mcp__github__*'
---

# PRP PR Command

Create a pull request from the current feature branch.

**Load and follow the `ycc:prp-pr` skill, passing through `$ARGUMENTS`.**

For commit + push + PR in one flow with documentation orchestration, use `/ycc:git-workflow --pr` instead.

```
Usage: /ycc:prp-pr [base-branch] [--draft]

Examples:
  /ycc:prp-pr                    # PR against main
  /ycc:prp-pr develop            # PR against develop
  /ycc:prp-pr main --draft       # Draft PR against main
```
