---
description: Vendor-neutral PR comment auto-fix — discover every review thread, file-level review comment, and top-level PR comment from any author, dispatch per-comment fix agents, resolve threads on success or reply-then-resolve on skip, and optionally drive the PR to green via the bounded CI auto-fix loop (--ci).
argument-hint: '[<pr-number|pr-url>] [--include-resolved] [--include-outdated] [--author <pattern>] [--bot-only|--human-only] [--severity <level>] [--yes|-y] [--dry-run] [--parallel] [--no-resolve] [--no-reply-on-skip] [--no-push] [--commit-style one|per-comment] [--ci] [--ci-confirm] [--ci-max-pushes=N] [--ci-max-same-failure=N] [--ci-timeout-min=N] [--ci-yes]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - MultiEdit
  - Agent
  - AskUserQuestion
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(find:*)
  - Bash(mkdir:*)
  - Bash(git:*)
  - Bash(gh:*)
  - Bash(jq:*)
  - Bash(date:*)
  - Bash(bash:*)
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
---

# PR Autofix Command

Vendor-neutral counterpart to `coderabbit:autofix`. Apply fixes for **every** comment surface on a GitHub PR — review threads, file-level review comments, and top-level conversation — from **any** author (bot or human), then resolve the threads it touched.

**Load and follow the `ycc:pr-autofix` skill, passing through `$ARGUMENTS`.**

The skill pulls every actionable comment via GitHub GraphQL, filters by author and severity, dispatches `ycc:pr-comment-fixer` agents per comment (sequential by default; `--parallel` for fan-out), commits + pushes the fixes, **resolves each thread** on a successful fix, **replies-then-resolves** on a user-skipped comment, leaves Failed threads open with a reply explaining the blocker, and optionally enters the bounded CI auto-fix loop (`--ci`) to drive the PR to green.

## Input forms

| Input         | Meaning                                                                                          |
| ------------- | ------------------------------------------------------------------------------------------------ |
| `<pr-number>` | Numeric PR number (e.g. `42`).                                                                   |
| `<pr-url>`    | Full GitHub URL like `https://github.com/owner/repo/pull/42`.                                    |
| blank         | Resolves to the open PR for the current branch via `gh pr list --head <branch>`. Aborts if none. |

## Flag groups

### Discovery (which comments to process)

- `--include-resolved` — Include already-resolved threads. Default: off.
- `--include-outdated` — Include outdated threads (line anchor rebased away). Default: off.
- `--author <pattern>` — Glob filter on author login (e.g. `coderabbit*`, `sonar*`).
- `--bot-only` — Only `*[bot]` accounts and known bot logins. Mutually exclusive with `--human-only`.
- `--human-only` — Only non-bot accounts. Mutually exclusive with `--bot-only`.
- `--severity <min>` — Minimum severity: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`. Default: `LOW` (process everything).

### Execution

- `--yes` / `-y` — Skip per-comment approval; apply all eligible. Implied by `--ci` unless `--ci-confirm` is also set.
- `--dry-run` — Print the plan, no edits, no thread mutations, no push.
- `--parallel` — Dispatch `ycc:pr-comment-fixer` agents in parallel per batch (same-file groups stay sequential). Default: sequential.

### Closure (how threads are mutated)

- `--no-resolve` — Don't auto-resolve threads after Fixed. Default: resolve.
- `--no-reply-on-skip` — Don't reply when skipping. Default: reply with reason then resolve.

### Commit & push

- `--no-push` — Apply + commit but don't push. Mutually exclusive with `--ci`.
- `--commit-style one|per-comment` — `one` (default): one consolidated commit. `per-comment`: one commit per Fixed comment.

### CI loop (mirrors `/ycc:prp-pr` and `/ycc:git-workflow`)

- `--ci` — After push, enter the bounded CI auto-fix loop. Implies `--yes` unless `--ci-confirm` is also set. Authoritative policy lives in `${CLAUDE_PLUGIN_ROOT}/skills/_shared/references/ci-monitoring.md`.
- `--ci-confirm` — With `--ci`, reintroduce per-comment approval (escape hatch).
- `--ci-max-pushes=N` — Hard cap on autonomous pushes per invocation (default 5).
- `--ci-max-same-failure=N` — Bail after the same failure signature recurs N times (default 3).
- `--ci-timeout-min=N` — Wall-clock cap in minutes (default 30).
- `--ci-yes` — Skip the one-time CI authorization prompt.

## What the skill does NOT do

- Does NOT call GitHub's "Apply suggestion" REST endpoint. Vendor suggestion blocks are untrusted; fixes are always re-derived locally.
- Does NOT approve or dismiss PR reviews. It only mutates threads (resolve / reply / react) and posts one consolidated summary comment.
- Does NOT batch across multiple PRs.
- Does NOT push to the default branch. Refuses if PR head equals the repository default branch.
- Does NOT auto-retry Failed fixes. Failed comments get a reply with the blocker; the user decides what to do next.

## Usage

```
Usage: /ycc:pr-autofix [<pr-number|pr-url>] [flags]

Examples:
  /ycc:pr-autofix 42                                            # interactive per-comment approval
  /ycc:pr-autofix 42 --dry-run                                  # plan only, no edits
  /ycc:pr-autofix 42 --yes                                      # apply all, sequential
  /ycc:pr-autofix 42 --yes --parallel                           # apply all, parallel per batch
  /ycc:pr-autofix 42 --bot-only --severity HIGH                 # only HIGH+ bot comments
  /ycc:pr-autofix 42 --author 'coderabbit*' --yes               # CodeRabbit-only, apply all
  /ycc:pr-autofix 42 --ci                                       # apply all + CI loop until green
  /ycc:pr-autofix 42 --ci --ci-confirm                          # CI loop but ask per-comment first
  /ycc:pr-autofix 42 --ci --ci-max-pushes=2 --ci-timeout-min=15 # tight CI caps
  /ycc:pr-autofix --ci                                          # auto-detect PR from current branch
  /ycc:pr-autofix https://github.com/o/r/pull/42 --no-push      # apply + commit locally, no push

Next steps after the run lands:
  gh pr view 42 --web      # inspect PR + resolved threads
  /ycc:pr-autofix 42       # re-run after new comments arrive
```

## Related skills

| Skill                | Input                             | Resolves PR threads? | Has CI loop? |
| -------------------- | --------------------------------- | -------------------- | ------------ |
| `/ycc:pr-autofix`    | GitHub PR comments (all surfaces) | Yes                  | Yes          |
| `/ycc:review-fix`    | `/ycc:code-review` artifact       | No (artifact-driven) | No           |
| `/ycc:quick-fix`     | Inline `quick-review` findings    | No                   | No           |
| `coderabbit:autofix` | CodeRabbit threads only           | No                   | No           |
