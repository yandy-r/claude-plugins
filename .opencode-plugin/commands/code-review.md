---
description: 'Code review — local uncommitted changes or a GitHub PR (pass PR number/URL
  for PR mode). Runs security + quality checks, executes validation commands, writes
  an artifact, and posts the review. Pass --parallel to fan out the review phase across
  3 specialized reviewer agents (correctness, security, quality) and merge findings.
  Pass --team (Claude Code only) to run the same 3-reviewer fan-out as a coordinated
  agent team with shared the todo tracker and per-reviewer task tracking. Pass --worktree
  to check out the PR into an isolated worktree and emit severity-keyed worktree annotations
  for /review-fix. Usage: [--approve | --request-changes] [--parallel | --team] [--worktree]
  [pr-number | pr-url | blank for local review]'
---

# Code Review Command

Run a code review in either local or PR mode.

**Load and follow the `code-review` skill, passing through `$ARGUMENTS`.**

- **Local mode** (no args): reviews uncommitted changes against AGENTS.md standards and common vulnerability patterns.
- **PR mode** (arg is PR number, URL, or branch): fetches the PR, reads full files at the head revision, runs validation for the detected stack, writes an artifact to `docs/prps/reviews/pr-{N}-review.md`, and posts the review.

**Flags**:

- `--approve` — Force the final decision to APPROVE (still reports all findings)
- `--request-changes` — Force the final decision to REQUEST CHANGES
- `--parallel` — Fan out the REVIEW phase across 3 standalone `code-reviewer` sub-agents dispatched in parallel:
  - `correctness-reviewer` → Correctness, Type Safety, Completeness (PR mode) / Code Quality (local mode)
  - `security-reviewer` → Security, Performance (PR mode) / Security Issues (local mode)
  - `quality-reviewer` → Pattern Compliance, Maintainability (PR mode) / Best Practices (local mode)

  Findings are merged and de-duplicated before the REPORT phase. Validation commands (type-check/lint/test/build) still run sequentially.

- `--team` — (Claude Code only) Same 3-reviewer fan-out as `--parallel`, but dispatched under a single `spawn coordinated subagents` with each reviewer registered as a task in the shared `the todo tracker` up front. Provides task-graph observability, inter-reviewer coordination via `send follow-up instructions`, and coordinated shutdown before the merge. Heavier dispatch, better communication — pick this when reviews may overlap (e.g., a security finding that implies a correctness bug) and you want reviewers to cross-reference each other. Cursor and Codex bundles lack the team tools — use `--parallel` there instead.

- `--worktree` — Check out the PR head branch into an isolated worktree at `~/.claude-worktrees/<repo>-pr-<N>/` before reading files. Prevents branch collisions when multiple reviews run simultaneously. Emits a `## Worktree Setup` section in the review artifact so `/review-fix --worktree` can create one child worktree per severity for its fix batches. **Local mode**: `--worktree` is ignored with a notice (uncommitted changes can't be branch-isolated). **Cursor bundle**: prints setup commands as docs (no auto-create). **Codex / opencode / opencode**: full auto-create.

`--parallel` and `--team` are **mutually exclusive** — pick one.

```
Usage: /code-review [pr-number | pr-url | blank] [--approve | --request-changes] [--parallel | --team] [--worktree]

Examples:
  /code-review                                  # local uncommitted review
  /code-review --parallel                       # local review, 3 parallel sub-agent reviewers
  /code-review --team                           # local review, 3-reviewer agent team (Claude Code only)
  /code-review 42                               # PR #42
  /code-review 42 --parallel                    # PR #42, 3 parallel sub-agent reviewers
  /code-review 42 --team                        # PR #42, 3-reviewer agent team
  /code-review https://github.com/owner/repo/pull/42
  /code-review 42 --request-changes             # force request-changes decision
  /code-review 42 --parallel --request-changes  # parallel review + force decision
  /code-review 42 --team --approve              # agent team + force approve
  /code-review 42 --worktree                    # isolate PR #42 into its own worktree
  /code-review 42 --parallel --worktree         # parallel reviewers inside an isolated worktree
```
