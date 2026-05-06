---
description: 'Plan and apply fixes for findings from a /code-review artifact. Parses
  the review file, filters by severity, dispatches review-fixer agents, updates Status
  in place (Open → Fixed/Failed), runs validation, and writes a fix report. The artifact
  is read from the PR branch (committed there by /code-review). Usage: [--parallel
  | --team] [--severity <level>] [--no-worktree] [--dry-run] <path/to/review.md |
  pr-number | blank>'
---

# Review Fix Command

Apply fixes for findings from a code-review artifact.

**Load and follow the `review-fix` skill, passing through `$ARGUMENTS`.**

The skill parses the review file produced by `/code-review`, filters findings by severity, groups them into dependency-safe batches (same-file findings stay together, different files can run in parallel), dispatches `review-fixer` agents to apply each fix, updates the `Status` field in the source review file in place (`Open` → `Fixed` or `Failed`), and writes a fix report to `docs/prps/reviews/fixes/`.

## Input forms

| Input                     | Meaning                                                              |
| ------------------------- | -------------------------------------------------------------------- |
| `<path/to/review.md>`     | Explicit review artifact path                                        |
| `<pr-number>` (e.g. `42`) | Resolves to `docs/prps/reviews/pr-42-review.md`                      |
| blank                     | Finds the latest file in `docs/prps/reviews/` and prompts to confirm |

## Flags

- **`--parallel`** — Dispatch `review-fixer` agents as **standalone sub-agents** in parallel per batch. Level 1+2 (type-check + tests) validation runs between batches. Fail-stop with user-driven recovery via `ask the user` on validation failure. Works in opencode, Cursor, and Codex.
- **`--team`** — (Claude Code only) Same per-batch fixer fan-out as `--parallel`, but under a single `spawn coordinated subagents` with all eligible findings registered as tasks up front (`track the task`) and coordinated per-batch shutdown via `send follow-up instructions`. Provides shared task-graph observability across all batches. Cursor and Codex bundles lack team tools — use `--parallel` there. `--parallel` and `--team` are **mutually exclusive**.
- **`--severity <level>`** — Minimum severity to fix: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`. Default `HIGH` (fixes CRITICAL + HIGH, skips MEDIUM + LOW). Findings below the threshold remain `Status: Open` in the source review file.
- **`--dry-run`** — Print the fix plan (batches, files, severity distribution) and stop. No files are modified. Combine with `--team` to also preview the team name and per-batch teammate roster.
- **`--worktree`** — (legacy — now default; pass `--no-worktree` to opt out) Accepted as a no-op. Worktree mode is auto-detected from the `## Worktree Setup` section in the artifact and is on by default.

- **`--no-worktree`** — Opt out of worktree isolation. Skip child-worktree creation and merge-back. All fixes are applied directly in the current working tree.

> **Note**: The artifact is now read from the PR branch (committed there by `/code-review`), not from the main repo. When running from a worktree of the PR branch, the artifact is found at `<worktree>/docs/prps/reviews/pr-<N>-review.md`. A fallback to the main repo's `docs/prps/reviews/` is attempted for in-flight artifacts written under the previous contract.

## What the skill does NOT do

- Does NOT commit changes. After fixes land, run `/git-workflow --commit` when ready.
- Does NOT re-run `/code-review`. Run it again manually to verify fixes resolved the findings.
- Does NOT retry failed fixes. Failed fixes are logged with their blocker and recommendation; the user decides how to proceed.
- Does NOT touch findings that are already `Status: Fixed` or `Status: Failed` from a prior run — this skill is resumable.

```
Usage: /review-fix [<path/to/review.md> | <pr-number> | blank] [--parallel | --team] [--severity <level>] [--no-worktree] [--dry-run]

Examples:
  /review-fix docs/prps/reviews/pr-42-review.md
  /review-fix 42                                           # PR #42 — resolves to pr-42-review.md (worktree on by default)
  /review-fix 42 --parallel                                # parallel sub-agent batch execution
  /review-fix 42 --team                                    # agent-team batch execution (Claude Code only)
  /review-fix 42 --severity CRITICAL                       # only fix critical findings
  /review-fix 42 --parallel --severity MEDIUM              # parallel, include medium
  /review-fix 42 --team --severity CRITICAL                # team, critical only
  /review-fix 42 --team --dry-run                          # preview team + task graph, no changes
  /review-fix docs/prps/reviews/local-20260408-143022-review.md --dry-run
  /review-fix                                              # use latest review file
  /review-fix 42 --no-worktree                             # opt out of worktree isolation (legacy behavior)
  /review-fix 42 --severity CRITICAL --dry-run             # preview critical-only plan, no changes
  /review-fix 42 --parallel --no-worktree                  # parallel sub-agents, no worktree isolation

Next steps after fixes land:
  /code-review <same target>   # re-review to verify
  /git-workflow --commit       # commit the fixes (in --no-worktree mode)
  # In worktree mode, fixes are committed and pushed automatically with each batch
```
