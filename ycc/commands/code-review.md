---
description: Code review — local uncommitted changes or a GitHub PR (pass PR number/URL for PR mode). Runs security + quality checks, executes validation commands, writes an artifact, and posts the review.
argument-hint: '[pr-number | pr-url | blank for local review] [--approve | --request-changes]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Bash(git:*)
  - Bash(gh:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(find:*)
  - Bash(npm:*)
  - Bash(pnpm:*)
  - Bash(yarn:*)
  - Bash(bun:*)
  - Bash(npx:*)
  - Bash(cargo:*)
  - Bash(go:*)
  - Bash(pytest:*)
  - Bash(python:*)
  - Bash(python3:*)
  - Bash(make:*)
  - 'mcp__github__*'
---

# Code Review Command

Run a code review in either local or PR mode.

**Load and follow the `ycc:code-review` skill, passing through `$ARGUMENTS`.**

- **Local mode** (no args): reviews uncommitted changes against CLAUDE.md standards and common vulnerability patterns.
- **PR mode** (arg is PR number, URL, or branch): fetches the PR, reads full files at the head revision, runs validation for the detected stack, writes an artifact to `docs/prps/reviews/pr-{N}-review.md`, and posts the review.

```
Usage: /ycc:code-review [pr-number | pr-url | blank]

Examples:
  /ycc:code-review                     # local uncommitted review
  /ycc:code-review 42                  # PR #42
  /ycc:code-review https://github.com/owner/repo/pull/42
  /ycc:code-review 42 --request-changes  # force request-changes decision
```
