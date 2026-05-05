---
description: 'Create a GitHub PR from the current branch — discovers templates, analyzes
  commits, references PRP artifacts, pushes, and opens the PR via gh. Usage: [base-branch]
  [--draft] [--ci] [--ci-max-pushes=N] [--ci-max-same-failure=N] [--ci-timeout-min=N]
  [--ci-yes]'
---

# PRP PR Command

Create a pull request from the current feature branch.

**Load and follow the `prp-pr` skill, passing through `$ARGUMENTS`.**

For commit + push + PR in one flow with documentation orchestration, use `/git-workflow --pr` instead.

```
Usage: /prp-pr [base-branch] [--draft] [--ci] [--ci-max-pushes=N] [--ci-max-same-failure=N] [--ci-timeout-min=N] [--ci-yes]

Modifier flags:
  --draft                  Open the PR in draft mode.
  --ci                     After PR creation, monitor CI and auto-fix until green
                           (or until a bail condition fires). No-op if no PR was created.
  --ci-max-pushes=N        Cap on auto-pushes per invocation (default 5).
  --ci-max-same-failure=N  Bail if the same failure recurs N times (default 3).
  --ci-timeout-min=N       Wall-clock cap in minutes from first iteration (default 30).
  --ci-yes                 Skip the one-time auth prompt (non-interactive).

Examples:
  /prp-pr                    # PR against main
  /prp-pr develop            # PR against develop
  /prp-pr main --draft       # Draft PR against main
  /prp-pr --ci               # PR against main, then monitor CI and auto-fix
  /prp-pr main --draft --ci --ci-yes  # Draft PR, CI loop, non-interactive
```
