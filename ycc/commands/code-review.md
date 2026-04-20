---
description: Code review — local uncommitted changes or a GitHub PR (pass PR number/URL for PR mode). Runs security + quality checks, executes validation commands, writes an artifact, and posts the review. Pass --parallel to fan out the review phase across 3 specialized reviewer agents (correctness, security, quality) and merge findings. Pass --team (Claude Code only) to run the same 3-reviewer fan-out as a coordinated agent team with shared TaskList and per-reviewer task tracking. Pass --worktree to check out the PR into an isolated worktree and emit severity-keyed worktree annotations for /ycc:review-fix.
argument-hint: '[--approve | --request-changes] [--parallel | --team] [--worktree] [pr-number | pr-url | blank for local review]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Agent
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - SendMessage
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
- `--parallel` — Fan out the REVIEW phase across 3 standalone `ycc:code-reviewer` sub-agents dispatched in parallel:
  - `correctness-reviewer` → Correctness, Type Safety, Completeness (PR mode) / Code Quality (local mode)
  - `security-reviewer` → Security, Performance (PR mode) / Security Issues (local mode)
  - `quality-reviewer` → Pattern Compliance, Maintainability (PR mode) / Best Practices (local mode)

  Findings are merged and de-duplicated before the REPORT phase. Validation commands (type-check/lint/test/build) still run sequentially.

- `--team` — (Claude Code only) Same 3-reviewer fan-out as `--parallel`, but dispatched under a single `TeamCreate` with each reviewer registered as a task in the shared `TaskList` up front. Provides task-graph observability, inter-reviewer coordination via `SendMessage`, and coordinated shutdown before the merge. Heavier dispatch, better communication — pick this when reviews may overlap (e.g., a security finding that implies a correctness bug) and you want reviewers to cross-reference each other. Cursor and Codex bundles lack the team tools — use `--parallel` there instead.

- `--worktree` — Check out the PR head branch into an isolated worktree at `~/.claude-worktrees/<repo>-pr-<N>/` before reading files. Prevents branch collisions when multiple reviews run simultaneously. Emits a `## Worktree Setup` section in the review artifact so `/ycc:review-fix --worktree` can create one child worktree per severity for its fix batches. **Local mode**: `--worktree` is ignored with a notice (uncommitted changes can't be branch-isolated). **Cursor bundle**: prints setup commands as docs (no auto-create). **Codex / opencode / Claude Code**: full auto-create.

`--parallel` and `--team` are **mutually exclusive** — pick one.

```
Usage: /ycc:code-review [pr-number | pr-url | blank] [--approve | --request-changes] [--parallel | --team] [--worktree]

Examples:
  /ycc:code-review                                  # local uncommitted review
  /ycc:code-review --parallel                       # local review, 3 parallel sub-agent reviewers
  /ycc:code-review --team                           # local review, 3-reviewer agent team (Claude Code only)
  /ycc:code-review 42                               # PR #42
  /ycc:code-review 42 --parallel                    # PR #42, 3 parallel sub-agent reviewers
  /ycc:code-review 42 --team                        # PR #42, 3-reviewer agent team
  /ycc:code-review https://github.com/owner/repo/pull/42
  /ycc:code-review 42 --request-changes             # force request-changes decision
  /ycc:code-review 42 --parallel --request-changes  # parallel review + force decision
  /ycc:code-review 42 --team --approve              # agent team + force approve
  /ycc:code-review 42 --worktree                    # isolate PR #42 into its own worktree
  /ycc:code-review 42 --parallel --worktree         # parallel reviewers inside an isolated worktree
```
