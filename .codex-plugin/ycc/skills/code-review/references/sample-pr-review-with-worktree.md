# Sample: PR Review Artifact With `## Worktree Setup`

This is a reference fixture showing the artifact shape emitted by
`$code-review --worktree <N>`. Downstream `$review-fix --worktree`
consumes the `## Worktree Setup` section to create one child worktree per
severity that has at least one Open finding.

Rules for the `## Worktree Setup` block:

- Only emitted when `WORKTREE_ACTIVE=true` (PR mode with `--worktree`).
- Placed between `**Decision**:` and `## Summary`.
- Only lists severity levels that have at least one Open finding. An absent
  severity row means that severity has no eligible findings — `$review-fix`
  will not create a child worktree for it.
- Parent branch is the PR head branch (checked out via
  `setup-worktree.sh parent … --base-ref <pr-head>`), not `feat/pr-<N>`.
- Child branches use the `feat/pr-<N>-<severity>` convention and are created
  by `$review-fix` at batch time, not by `$code-review`.

---

## PR Review #42 — Add widget rendering pipeline

**Reviewed**: 2026-04-19T10:00:00-04:00
**Mode**: PR
**Author**: @contributor
**Branch**: feat/add-widget-rendering → main
**Decision**: REQUEST CHANGES

## Worktree Setup

- **Parent**: ~/.claude-worktrees/myrepo-pr-42/ (branch: feat/add-widget-rendering)
- **Children** (per severity; created by $review-fix --worktree):
  - CRITICAL → ~/.claude-worktrees/myrepo-pr-42-critical/ (branch: feat/pr-42-critical)
  - HIGH → ~/.claude-worktrees/myrepo-pr-42-high/ (branch: feat/pr-42-high)
  - MEDIUM → ~/.claude-worktrees/myrepo-pr-42-medium/ (branch: feat/pr-42-medium)

## Summary

Good overall shape. Two critical issues block merge: a missing auth check and a
use-after-free in the widget renderer. Three high-severity correctness issues
and two medium-severity maintainability notes follow. No low-severity findings.

## Findings

### CRITICAL

- **[F001]** `src/api/widget.ts:42` — Missing authentication check on POST /widget
  - **Status**: Open
  - **Category**: Security
  - **Suggested fix**: Wrap the handler with `requireAuth()` middleware before the body parser runs.

- **[F002]** `src/render/widget.ts:118` — Use-after-free of buffer pointer when renderer is disposed mid-render
  - **Status**: Open
  - **Category**: Correctness
  - **Suggested fix**: Capture `this.buffer` into a local at the top of `render()` and guard with `if (!this.disposed)` before each write.

### HIGH

- **[F003]** `src/db/widget.ts:17` — Unhandled rejection when `findByOwner` returns null
  - **Status**: Open
  - **Category**: Correctness
  - **Suggested fix**: Narrow with `if (result === null) return []` before the `.filter()` call.

- **[F004]** `src/db/widget.ts:89` — Race condition: two concurrent inserts can produce duplicate slugs
  - **Status**: Open
  - **Category**: Correctness
  - **Suggested fix**: Wrap the slug-existence check + insert in a transaction, or add a `UNIQUE` constraint on the `slug` column.

- **[F005]** `src/utils/slug.ts:34` — `toSlug()` does not strip zero-width characters
  - **Status**: Open
  - **Category**: Correctness
  - **Suggested fix**: Normalize with `.replace(/[\u200B-\u200D\uFEFF]/g, '')` before the ASCII filter.

### MEDIUM

- **[F006]** `src/render/widget.ts:205` — Dead code branch after `return`
  - **Status**: Open
  - **Category**: Maintainability
  - **Suggested fix**: Delete lines 205–212; they are unreachable after the early return on line 204.

- **[F007]** `src/api/widget.ts:67` — Magic number `30_000` for timeout
  - **Status**: Open
  - **Category**: Maintainability
  - **Suggested fix**: Extract to a module-level `const WIDGET_TIMEOUT_MS = 30_000` and reference it.

### LOW

_(none)_

## Validation Results

| Check      | Result |
| ---------- | ------ |
| Type check | Pass   |
| Lint       | Pass   |
| Tests      | Fail   |
| Build      | Pass   |

## Files Reviewed

- `src/api/widget.ts` (Modified)
- `src/db/widget.ts` (Modified)
- `src/render/widget.ts` (Added)
- `src/utils/slug.ts` (Modified)
