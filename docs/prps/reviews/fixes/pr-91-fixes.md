# Fix Report: pr-91-review

**Source**: docs/prps/reviews/pr-91-review.md
**Applied**: 2026-05-06T00:43:38Z
**Mode**: Parallel sub-agents (1 batch, max width 2)
**Severity threshold**: MEDIUM

## Summary

- **Total findings in source**: 17
- **Already processed before this run**:
  - Fixed: 0
  - Failed: 0
- **Eligible this run**: 13
- **Applied this run**:
  - Fixed: 13
  - Failed: 0
- **Skipped this run**:
  - Below severity threshold: 4
  - No suggested fix: 0
  - Missing file: 0

## Fixes Applied

| ID   | Severity | File                                                                                                   | Line    | Status | Notes                                      |
| ---- | -------- | ------------------------------------------------------------------------------------------------------ | ------- | ------ | ------------------------------------------ |
| F001 | HIGH     | ycc/skills/\_shared/scripts/prepare-feature-branch.sh                                                  | 131-185 | Fixed  | Idempotent branch check moved earlier.     |
| F002 | HIGH     | ycc/skills/prp-implement/SKILL.md                                                                      | 206     | Fixed  | Removed quoted helper path.                |
| F003 | MEDIUM   | ycc/skills/\_shared/scripts/prepare-feature-branch.sh                                                  | 8-13    | Fixed  | Header behavior now matches code.          |
| F004 | MEDIUM   | ycc/skills/\_shared/scripts/prepare-feature-branch.sh                                                  | 38-40   | Fixed  | Usage text documents non-trunk reuse.      |
| F005 | MEDIUM   | ycc/skills/\_shared/scripts/prepare-feature-branch.sh                                                  | 69-71   | Fixed  | `--` now preserves positional args.        |
| F006 | MEDIUM   | ycc/skills/\_shared/scripts/prepare-feature-branch.sh                                                  | 91      | Fixed  | Added slug format guard.                   |
| F007 | MEDIUM   | ycc/skills/\_shared/scripts/prepare-feature-branch.sh                                                  | 120-128 | Fixed  | Allows `docs/orchestration/<slug>*`.       |
| F008 | MEDIUM   | ycc/skills/\_shared/scripts/prepare-feature-branch.sh                                                  | 159-185 | Fixed  | Tracks existing `origin/feat/<slug>`.      |
| F009 | MEDIUM   | ycc/skills/\_shared/scripts/prepare-feature-branch.sh                                                  | 176-185 | Fixed  | Warns when local feature branch is stale.  |
| F010 | MEDIUM   | ycc/skills/implement-plan/SKILL.md                                                                     | 259-263 | Fixed  | Uses unconditional branch prep convention. |
| F011 | MEDIUM   | ycc/skills/implement-plan/SKILL.md                                                                     | 265     | Fixed  | Removed `GitHub #TBD`.                     |
| F012 | MEDIUM   | ycc/skills/implement-plan/SKILL.md, ycc/skills/prp-implement/SKILL.md, ycc/skills/orchestrate/SKILL.md | 267-274 | Fixed  | Extracted shared branch-prep reference.    |
| F013 | MEDIUM   | ycc/skills/implement-plan/SKILL.md, ycc/skills/prp-implement/SKILL.md, ycc/skills/orchestrate/SKILL.md | 271     | Fixed  | Shared reference includes `develop`.       |

## Files Changed

- `ycc/skills/_shared/scripts/prepare-feature-branch.sh` (F001, F003-F009)
- `ycc/skills/_shared/references/branch-prep.md` (F010, F012, F013)
- `ycc/skills/implement-plan/SKILL.md` (F010-F013)
- `ycc/skills/orchestrate/SKILL.md` (F012, F013)
- `ycc/skills/prp-implement/SKILL.md` (F002, F012, F013)
- Generated Cursor, Codex, and opencode mirrors from `./scripts/sync.sh`
- `docs/prps/reviews/pr-91-review.md` (status updates)

## Failed Fixes

None.

## Validation Results

| Check                   | Result |
| ----------------------- | ------ |
| `./scripts/sync.sh`     | Pass   |
| `./scripts/validate.sh` | Pass   |
| `npm run lint`          | Pass   |

## Next Steps

- Re-run `$code-review 91` to verify the remaining open findings and confirm these fixes resolved the issues.
- Address the remaining LOW findings if they are in scope for this PR.
- Run `$git-workflow` to commit the changes when satisfied.
