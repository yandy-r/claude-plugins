# Fix Report: pr-192-review

**Source**: docs/prps/reviews/pr-192-review.md
**Applied**: 2026-09-30
**Mode**: Sequential (2 severity batches, worktree mode)
**Severity threshold**: LOW

## Summary

- **Total findings in source**: 5
- **Already processed before this run**:
  - Fixed: 0
  - Failed: 0
- **Eligible this run**: 5
- **Applied this run**:
  - Fixed: 5
  - Failed: 0
- **Skipped this run**:
  - Below severity threshold: 0
  - No suggested fix: 0
  - Missing file: 0

## Fixes Applied

| ID   | Severity | File                                               | Line | Status | Notes                                                         |
| ---- | -------- | -------------------------------------------------- | ---- | ------ | ------------------------------------------------------------- |
| F002 | MEDIUM   | ycc/skills/\_shared/scripts/backport-audit.sh      | 237  | Fixed  | Same-file group with F001; rows parsed on `\x1f`; test added  |
| F001 | MEDIUM   | ycc/skills/\_shared/scripts/backport-audit.sh      | 191  | Fixed  | `require_below_limit` after each query; test added            |
| F003 | LOW      | ycc/skills/backport/scripts/find-pending.sh        | 191  | Fixed  | Same `\x1f` parsing; empty-SHA skip guard now reachable; test |
| F004 | LOW      | ycc/skills/releaser/references/release-branches.md | 49   | Fixed  | Retry path for `closed unmerged` rows                         |
| F005 | LOW      | ycc/skills/backport/SKILL.md                       | 108  | Fixed  | `--audit` accepts only `MAINTENANCE` lines                    |

## Files Changed

- `ycc/skills/_shared/scripts/backport-audit.sh` (Fixed F001, F002)
- `ycc/skills/backport/scripts/find-pending.sh` (Fixed F003)
- `ycc/skills/releaser/references/release-branches.md` (Fixed F004)
- `ycc/skills/backport/SKILL.md` (Fixed F005)
- `scripts/test-release-backport-audit.sh`, `scripts/test-release-backport.sh` (regression tests; both fail on the pre-fix code)
- Regenerated Cursor/Codex/opencode bundles

## Failed Fixes

_None._

## Validation Results

| Check                           | Result                                                    |
| ------------------------------- | --------------------------------------------------------- |
| Type check                      | Skipped (no TypeScript)                                   |
| Tests (`./scripts/validate.sh`) | Pass (backport-audit 22/22, backport 39/39, all 0 failed) |

## Next Steps

- CI on PR #192 re-runs `./scripts/validate.sh` on the pushed fixes.

## Worktree Summary

- **Parent**: ~/.claude-worktrees/claude-plugins-feat-backport-release-gate/ (branch: feat/backport-release-gate)
