---
description: Code review — local uncommitted changes or a GitHub PR (pass PR number/URL for PR mode). Runs security + quality checks, executes validation commands, writes an artifact, and posts the review. Pass --parallel to fan out the review phase across 3 specialized reviewer agents (correctness, security, quality) and merge findings.
argument-hint: '[pr-number | pr-url | blank for local review] [--approve | --request-changes] [--parallel]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Agent
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

**Flags**:

- `--approve` — Force the final decision to APPROVE (still reports all findings)
- `--request-changes` — Force the final decision to REQUEST CHANGES
- `--parallel` — Fan out the REVIEW phase across 3 `ycc:code-reviewer` agents dispatched in parallel:
  - `correctness-reviewer` → Correctness, Type Safety, Completeness (PR mode) / Code Quality (local mode)
  - `security-reviewer` → Security, Performance (PR mode) / Security Issues (local mode)
  - `quality-reviewer` → Pattern Compliance, Maintainability (PR mode) / Best Practices (local mode)

  Findings are merged and de-duplicated before the REPORT phase. Validation commands (type-check/lint/test/build) still run sequentially.

```
Usage: /ycc:code-review [pr-number | pr-url | blank] [--approve | --request-changes] [--parallel]

Examples:
  /ycc:code-review                                  # local uncommitted review
  /ycc:code-review --parallel                       # local review, 3 parallel reviewers
  /ycc:code-review 42                               # PR #42
  /ycc:code-review 42 --parallel                    # PR #42, 3 parallel reviewers
  /ycc:code-review https://github.com/owner/repo/pull/42
  /ycc:code-review 42 --request-changes             # force request-changes decision
  /ycc:code-review 42 --parallel --request-changes  # parallel review + force decision
```
