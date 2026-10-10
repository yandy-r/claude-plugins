---
description: 'Code review — local uncommitted changes or a GitHub PR (pass PR number/URL
  for PR mode). Runs security + quality checks, executes validation commands, writes
  an artifact under docs/prps/reviews/, and posts the review. Pass --quick as a thin
  alias for /quick-review (interactive inline review, no file unless confirmed). For
  direct access to --yes, --save, or --severity, invoke /quick-review instead. Usage:
  [--quick] [--approve | --request-changes] [--parallel] [--no-worktree] [--keep-draft]
  [--keep-worktree] [--save] [--yes] [pr-number | pr-url | blank for local review]'
---

# Code Review Command

> **OpenCode V2 compatibility:** `--team` is unsupported. If it is supplied, abort before setup or dispatch and ask the caller to rerun without it. This target uses native standalone `subagent` calls only.

Run a code review in either local or PR mode.

**Load and follow the `code-review` skill, passing through `$ARGUMENTS`.**

- **Local mode** (no args): reviews uncommitted changes against AGENTS.md standards and common vulnerability patterns.
- **PR mode** (arg is PR number, URL, or branch): fetches the PR, reads full files at the head revision, runs validation for the detected stack, writes an artifact to `docs/prps/reviews/pr-{N}-review.md`, and posts the review.

**Flags**:

- `--quick` — **Alias for `/quick-review`.** Interactive inline review of uncommitted changes — prints findings and prompts **Apply fixes** / **Save to file** / **Discard**. No artifact is written unless you confirm. On "Apply fixes", hands off to `/review-fix` automatically. Compatible with `--parallel`; mutually exclusive with a PR argument, `--approve`, and `--request-changes`. For direct access to `--yes`, `--save`, and `--severity`, invoke `/quick-review` instead.

- `--approve` — Force the final decision to APPROVE (still reports all findings)
- `--request-changes` — Force the final decision to REQUEST CHANGES
- `--parallel` — Fan out the REVIEW phase across 3 standalone `code-reviewer` sub-agents dispatched in parallel:
  - `correctness-reviewer` → Correctness, Type Safety, Completeness (PR mode) / Code Quality (local mode)
  - `security-reviewer` → Security, Performance (PR mode) / Security Issues (local mode)
  - `quality-reviewer` → Pattern Compliance, Maintainability (PR mode) / Best Practices (local mode)

  Findings are merged and de-duplicated before the REPORT phase. Validation commands (type-check/lint/test/build) still run sequentially.


- `--worktree` — (legacy — now default; pass `--no-worktree` to opt out) Check out the PR head branch into an isolated worktree at `<repo-root>/.config/opencode/worktrees/<repo>-pr-<N>/` before reading files.

- `--no-worktree` — Opt out of worktree isolation in PR mode. Skip worktree creation, artifact commit+push, and cleanup. Files are read directly from the main checkout (the previous default behavior).

- `--keep-draft` — Skip the automatic draft→ready promotion in PR mode. The PR remains a draft and the review is posted as a COMMENT (not approve/block).

- `--keep-worktree` — Skip removal of the PR worktree after the review is posted. The artifact is still committed and pushed to the PR branch. Useful when you want to inspect the worktree afterward.

`--parallel` are **mutually exclusive** — pick one.

```
Usage: /code-review [pr-number | pr-url | blank] [--quick] [--approve | --request-changes] [--parallel] [--no-worktree] [--keep-draft] [--keep-worktree]

Examples:
  /code-review --quick                          # fast on-the-fly review, no worktree/validation/publish
  /code-review --quick --parallel               # fast review with 3 parallel reviewer sub-agents
  /code-review                                  # local uncommitted review
  /code-review --parallel                       # local review, 3 parallel sub-agent reviewers
  /code-review 42                               # PR #42 (worktree on by default)
  /code-review 42 --parallel                    # PR #42, 3 parallel sub-agent reviewers
  /code-review https://github.com/owner/repo/pull/42
  /code-review 42 --request-changes             # force request-changes decision
  /code-review 42 --parallel --request-changes  # parallel review + force decision
  /code-review 42 --keep-draft                  # review a draft PR without auto-promoting it
  /code-review 42 --keep-worktree               # review and inspect the worktree afterward
  /code-review 42 --no-worktree                 # review against the main checkout (legacy behavior)
  /code-review 42 --parallel --no-worktree      # parallel reviewers, no worktree isolation
```
