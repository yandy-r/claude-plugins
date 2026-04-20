---
description: 'Code review — local uncommitted changes or a GitHub PR (pass PR number/URL
  for PR mode). Runs security + quality checks, executes validation commands, writes
  an artifact, and posts the review. Pass --parallel to fan out the review phase across
  3 specialized reviewer agents (correctness, security, quality) and merge findings.
  Pass --team (Claude Code only) to run the same 3-reviewer fan-out as a coordinated
  agent team with shared the todo tracker and per-reviewer task tracking. Worktree
  mode is on by default in PR mode — pass --no-worktree to opt out. Pass --keep-draft
  to skip automatic draft→ready promotion. Pass --keep-worktree to skip worktree removal
  after the review is posted. Usage: [--approve | --request-changes] [--parallel |
  --team] [--no-worktree] [--keep-draft] [--keep-worktree] [pr-number | pr-url | blank
  for local review]'
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

- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Check out the PR head branch into an isolated worktree at `~/.claude-worktrees/<repo>-pr-<N>/` before reading files.

- `--no-worktree` — Opt out of worktree isolation in PR mode. Skip worktree creation, artifact commit+push, and cleanup. Files are read directly from the main checkout (the previous default behavior).

- `--keep-draft` — Skip the automatic draft→ready promotion in PR mode. The PR remains a draft and the review is posted as a COMMENT (not approve/block).

- `--keep-worktree` — Skip removal of the PR worktree after the review is posted. The artifact is still committed and pushed to the PR branch. Useful when you want to inspect the worktree afterward.

`--parallel` and `--team` are **mutually exclusive** — pick one.

```
Usage: /code-review [pr-number | pr-url | blank] [--approve | --request-changes] [--parallel | --team] [--no-worktree] [--keep-draft] [--keep-worktree]

Examples:
  /code-review                                  # local uncommitted review
  /code-review --parallel                       # local review, 3 parallel sub-agent reviewers
  /code-review --team                           # local review, 3-reviewer agent team (Claude Code only)
  /code-review 42                               # PR #42 (worktree on by default)
  /code-review 42 --parallel                    # PR #42, 3 parallel sub-agent reviewers
  /code-review 42 --team                        # PR #42, 3-reviewer agent team
  /code-review https://github.com/owner/repo/pull/42
  /code-review 42 --request-changes             # force request-changes decision
  /code-review 42 --parallel --request-changes  # parallel review + force decision
  /code-review 42 --team --approve              # agent team + force approve
  /code-review 42 --keep-draft                  # review a draft PR without auto-promoting it
  /code-review 42 --keep-worktree               # review and inspect the worktree afterward
  /code-review 42 --no-worktree                 # review against the main checkout (legacy behavior)
  /code-review 42 --parallel --no-worktree      # parallel reviewers, no worktree isolation
```
