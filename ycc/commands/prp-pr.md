---
description: Create a GitHub PR from the current branch — discovers templates, analyzes commits, references PRP artifacts, pushes, and opens the PR via gh.
argument-hint: '[base-branch] [--draft] [--ci] [--ci-max-pushes=N] [--ci-max-same-failure=N] [--ci-timeout-min=N] [--ci-yes]'
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
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
---

# PRP PR Command

Create a pull request from the current feature branch.

**Load and follow the `ycc:prp-pr` skill, passing through `$ARGUMENTS`.**

For commit + push + PR in one flow with documentation orchestration, use `/ycc:git-workflow --pr` instead.

```
Usage: /ycc:prp-pr [base-branch] [--draft] [--ci] [--ci-max-pushes=N] [--ci-max-same-failure=N] [--ci-timeout-min=N] [--ci-yes]

Modifier flags:
  --draft                  Open the PR in draft mode.
  --ci                     After PR creation, monitor CI and auto-fix until green
                           (or until a bail condition fires). No-op if no PR was created.
  --ci-max-pushes=N        Cap on auto-pushes per invocation (default 5).
  --ci-max-same-failure=N  Bail if the same failure recurs N times (default 3).
  --ci-timeout-min=N       Wall-clock cap in minutes from first iteration (default 30).
  --ci-yes                 Skip the one-time auth prompt (non-interactive).

Examples:
  /ycc:prp-pr                    # PR against main
  /ycc:prp-pr develop            # PR against develop
  /ycc:prp-pr main --draft       # Draft PR against main
  /ycc:prp-pr --ci               # PR against main, then monitor CI and auto-fix
  /ycc:prp-pr main --draft --ci --ci-yes  # Draft PR, CI loop, non-interactive
```
