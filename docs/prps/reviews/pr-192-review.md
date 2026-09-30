# PR Review #192 — feat(releaser): gate patch releases on a backport audit

**Reviewed**: 2026-09-30
**Mode**: PR
**Author**: yandy-r
**Branch**: feat/backport-release-gate → main
**Decision**: APPROVE

## Worktree Setup

- **Parent**: ~/.claude-worktrees/claude-plugins-feat-backport-release-gate/ (branch: feat/backport-release-gate)

## Summary

The gate is well scoped. It reuses the release state and twin matching, fails closed on
missing state, branches and `gh`, and is covered by a dedicated sandbox test suite. Two
script-level issues can make it fail open (silent `gh` result truncation, and TSV parsing
that shifts fields when a merge SHA is empty), and two doc gaps leave next steps
ambiguous. Fix both script issues before relying on the gate for releases.

## Findings

### CRITICAL

_None._

### HIGH

_None._

### MEDIUM

- **[F001]** `ycc/skills/_shared/scripts/backport-audit.sh:191` — Every `gh pr list` query uses `--limit 1000` and silently truncates. On a repo with more than 1000 PRs into `release/X.Y`, labelled PRs, or fixes in the window, the missing rows are simply not checked and the gate can report clean (fails open).
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: After each query, count the rows with `jq length`; when a count reaches `PR_LIMIT`, exit 1 with "more than N results for <query>; narrow the window with --since" instead of continuing.

- **[F002]** `ycc/skills/_shared/scripts/backport-audit.sh:237` — Rows are emitted with jq `@tsv` and parsed with `IFS=$'\t' read`. Tab is IFS whitespace, so consecutive tabs collapse: an empty `mergeCommit.oid` shifts the title into `sha` and the labels into `title` (verified: `12\t\tfix: t\tlabels` reads as `sha=[fix: t]`). The unlabelled loop then misreads the labels and can misclassify the PR.
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: Join fields with the non-whitespace unit separator (`join("\u001f")` in jq, `IFS=$'\x1f' read`) in both loops, and strip `\u001f` from titles.

### LOW

- **[F003]** `ycc/skills/backport/scripts/find-pending.sh:191` — Pre-existing: the same `@tsv` + `IFS=$'\t'` pattern means the `[[ -z "$sha" ]]` "no merge commit reported by GitHub" guard can never fire; an empty SHA shifts the title into `sha` and the PR is reported as pending with a bogus commit.
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: Use the same unit-separator parsing as F002 (share it through `backport-lib.sh`).

- **[F004]** `ycc/skills/releaser/references/release-branches.md:49` — The `missing` row's next step is `/ycc:backport --pending --to release/X.Y`, but `--pending` treats a closed-unmerged backport PR as handled, so rows with detail `backport #M closed unmerged` are never retried that way.
  - **Status**: Fixed
  - **Category**: Completeness
  - **Suggested fix**: Add: for `backport #M closed unmerged` rows, retry with `/ycc:backport <PR#> --to release/X.Y`.

- **[F005]** `ycc/skills/backport/SKILL.md:108` — Phase 2A accepts a line from the state's `frozen` list, but Phase 1 never records `frozen`, and a frozen line receives no patches, so auditing it has no use.
  - **Status**: Fixed
  - **Category**: Pattern Compliance
  - **Suggested fix**: Require the given `release/X.Y` to be in `MAINTENANCE`; otherwise stop with "not an active maintenance branch".

## Validation Results

| Check                                         | Result                                                                                     |
| --------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Type check                                    | Skipped (no TypeScript)                                                                    |
| Lint                                          | Pass for changed files; markdownlint fails only on 4 pre-existing lines in untouched files |
| Tests (`./scripts/validate.sh`, CI entry)     | Pass (463 pass, 0 fail; new suite 19/19)                                                   |
| Build (`./scripts/sync.sh` bundle generation) | Pass                                                                                       |

## Files Reviewed

- `ycc/skills/_shared/scripts/backport-audit.sh` (Added)
- `ycc/skills/_shared/scripts/lib/backport-lib.sh` (Added)
- `scripts/test-release-backport-audit.sh` (Added)
- `ycc/skills/_shared/scripts/pr-guard.sh` (Modified)
- `ycc/skills/backport/scripts/find-pending.sh` (Modified)
- `ycc/skills/backport/SKILL.md` (Modified)
- `ycc/commands/backport.md` (Modified)
- `ycc/skills/releaser/SKILL.md` (Modified)
- `ycc/skills/releaser/references/release-branches.md` (Modified)
- `ycc/skills/release-model/templates/RELEASING.md.tmpl` (Modified)
- `ycc/skills/release-model/references/upgrade-and-audit.md` (Modified)
- `ycc/skills/_shared/references/branching-model.md` (Modified)
- `docs/inventory.json`, `.cursor-plugin/`, `.codex-plugin/`, `.opencode-plugin/` (Modified, generated)
