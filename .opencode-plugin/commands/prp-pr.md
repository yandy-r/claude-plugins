---
description: 'Create a GitHub PR from the current branch — discovers templates, analyzes
  commits, references PRP artifacts, pushes, and opens the PR via gh. Usage: [base-branch]
  [--draft]'
---

# PRP PR Command

Create a pull request from the current feature branch.

**Load and follow the `prp-pr` skill, passing through `$ARGUMENTS`.**

For commit + push + PR in one flow with documentation orchestration, use `/git-workflow --pr` instead.

```
Usage: /prp-pr [base-branch] [--draft]

Examples:
  /prp-pr                    # PR against main
  /prp-pr develop            # PR against develop
  /prp-pr main --draft       # Draft PR against main
```
