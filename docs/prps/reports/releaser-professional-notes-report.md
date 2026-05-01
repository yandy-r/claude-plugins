# Implementation Report: Professional Release Notes for `ycc:releaser`

## Summary

Brought the generic `ycc:releaser` skill to feature parity with `ycc:bundle-release`
for release-notes quality and added an opt-in `--publish` affordance. The
`draft-changelog.sh` script was rewritten from inline `printf`-based output to a
placeholder-driven template-fill flow consuming
`references/release-notes-template.md`. Documentation, chore, test, build, ci,
style, and refactor commits are demoted into a single collapsed `<details>`
**Maintenance** section. A new confirmation-gated `publish-release.sh` helper detects
existing-vs-missing GitHub releases and previews/runs `gh release create` or
`gh release edit` accordingly.

## Assessment vs Reality

| Metric        | Predicted (Plan)                    | Actual                                             |
| ------------- | ----------------------------------- | -------------------------------------------------- |
| Complexity    | Medium                              | Medium — matched                                   |
| Tasks         | 6 across 3 batches                  | 6 across 3 batches — completed in order            |
| Files Changed | 4 source + 3 bundle copies + 1 plan | 4 source + 12 bundle mirrors (3 bundles × 4 files) |
| Mode          | Parallel sub-agents                 | Parallel sub-agents (`--parallel --no-worktree`)   |

## Tasks Completed

| #   | Task                                               | Status   | Notes                                                                                                                                                                        |
| --- | -------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.1 | Rewrite `draft-changelog.sh` to template-fill flow | Complete | Added `--exclude-internal` and `--template <path>`; range-aware `from-ref` validation (deviation noted below)                                                                |
| 1.2 | Restructure release-notes template                 | Complete | All 10 placeholders present; banned placeholders removed; redundant Highlights TODO removed in post-Batch-3 cleanup                                                          |
| 1.3 | Create `publish-release.sh` helper                 | Complete | Print-only default; `--confirm` gate; tag/release distinction via `git rev-parse` then `gh release view`; tag normalization works                                            |
| 2.1 | Update `SKILL.md` to wire new flags and flow       | Complete | argument-hint, intro prose, Phase 4 rewrite + nested "Internal vs. user-facing" subsection, Phase 7 dry-run note, Phase 8 publish branch, Phase 9 reporting, Important Notes |
| 3.1 | Regenerate bundles + run validators                | Complete | `sync.sh` and `validate.sh` exit 0; `publish-release.sh` propagated to all 3 bundles, executable                                                                             |
| 3.2 | End-to-end smoke test against this repo's history  | Complete | `chore(opencode): bump default model` (`dba6a2b`) routed to Maintenance; `--exclude-internal` removes the section; `publish-release.sh` print-only behaves as designed       |

## Validation Results

| Level           | Status | Notes                                                                                                 |
| --------------- | ------ | ----------------------------------------------------------------------------------------------------- |
| Static Analysis | Pass   | `scripts/lint.sh --python --shell` exits 0; ruff, black, shellcheck all clean                         |
| Unit Tests      | N/A    | No shell unit-test infra exists (per plan); smoke test in Task 3.2 served as functional verification  |
| Build           | Pass   | `./scripts/sync.sh` exits 0; bundles regenerated cleanly                                              |
| Integration     | Pass   | `./scripts/validate.sh` exits 0; opencode/cursor/codex bundle parity verified                         |
| Edge Cases      | Pass   | `--exclude-internal`, missing notes file, missing tag, mode conflicts, tag normalization all verified |

`npm run lint` reports markdownlint failures **exclusively** in
`docs/prps/plans/releaser-professional-notes.plan.md` (the plan artifact itself —
table alignment and emphasis style). Code-side lint (Python + Shell) is clean. Plan
file is being archived; the failures do not affect the implementation.

## Files Changed

| File                                                                                                                             | Action      | Lines                                       |
| -------------------------------------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------- |
| `ycc/skills/releaser/scripts/draft-changelog.sh`                                                                                 | UPDATED     | 324 (rewrite)                               |
| `ycc/skills/releaser/scripts/publish-release.sh`                                                                                 | CREATED     | 214                                         |
| `ycc/skills/releaser/references/release-notes-template.md`                                                                       | UPDATED     | 39 (rewrite)                                |
| `ycc/skills/releaser/SKILL.md`                                                                                                   | UPDATED     | 310 (was 269; +41 lines for new flags/flow) |
| `.cursor-plugin/skills/releaser/{SKILL.md,scripts/{draft-changelog,publish-release}.sh,references/release-notes-template.md}`    | REGENERATED | mirror of source                            |
| `.codex-plugin/ycc/skills/releaser/{SKILL.md,scripts/{draft-changelog,publish-release}.sh,references/release-notes-template.md}` | REGENERATED | mirror of source                            |
| `.opencode-plugin/skills/releaser/{SKILL.md,scripts/{draft-changelog,publish-release}.sh,references/release-notes-template.md}`  | REGENERATED | mirror of source                            |

## Deviations from Plan

1. **Range-aware `from-ref` parsing in `draft-changelog.sh`** — The plan's VALIDATE
   command for Task 1.1 passes `4dd8090..HEAD` as the `from-ref` positional. `git
rev-parse --verify` does not accept range expressions, so the implementor
   extended the validation to extract and verify only the left-side ref when a
   range is supplied. Not a deviation from intent — fills a gap the plan didn't
   address explicitly.

2. **`publish-release.sh` `--mode=edit` on missing tag** — The plan's VALIDATE
   command (step 5 of Task 1.3) expected `FAIL: cannot edit non-existent release`,
   but the script's first guard is the tag-existence check via `git rev-parse`,
   which fires earlier. Result: when both the tag is missing AND mode is `edit`, the
   tag-existence error wins. This is semantically correct (the gotcha #1 in the
   plan explicitly distinguishes the two conditions) and surfaces the more
   actionable diagnostic.

3. **Highlights section: redundant TODO** — Initial Batch-1 implementation kept the
   plan's "Preserve TODO comments for Highlights" rule literally, leaving both a
   hardcoded `<!-- TODO: Top 1–3 curated highlights... -->` and the `{{HIGHLIGHTS}}`
   placeholder (which the script substitutes with another TODO stub). Resulted in
   double TODO lines. Fixed post-Batch-3 by removing the static comment from the
   template; the placeholder substitution alone now provides the author prompt.
   Bundles re-synced. Cosmetic, not functional.

## Issues Encountered

- **None blocking.** Pre-existing markdownlint issues in the plan file itself
  surfaced during between-batch validation but were correctly identified as
  out-of-scope and the plan is being archived.
- **`gh` already authenticated** in the local environment — the smoke test step
  that exercises `publish-release.sh` against an existing tag (`v2.1.0`) found the
  associated release and printed `gh release edit ...`, confirming the auto-mode
  detection works against a real `gh` install.

## Tests Written

| Test                                              | Type             | Notes                                 |
| ------------------------------------------------- | ---------------- | ------------------------------------- |
| `draft-changelog.sh` smoke (default range)        | Functional smoke | Confirms layout + Maintenance routing |
| `draft-changelog.sh --exclude-internal`           | Functional smoke | Confirms section drop                 |
| `draft-changelog.sh --template <empty>`           | Functional smoke | Confirms placeholder substitution     |
| `publish-release.sh` non-existent tag             | Functional smoke | Confirms tag-existence guard          |
| `publish-release.sh` existing tag, no `--confirm` | Functional smoke | Confirms print-only default           |
| `publish-release.sh --mode=edit` on missing tag   | Functional smoke | Confirms refuse-overwrite             |
| `publish-release.sh` missing notes file           | Functional smoke | Confirms readability guard            |

No unit-test files added — the bundle has no shell unit-test infra (consistent with
plan's NOT Building list).

## Next Steps

- [ ] Code review via `/ycc:code-review`
- [ ] Create PR via `/ycc:prp-pr`
- [ ] Re-evaluate factoring a `_shared` template-fill helper if a third skill needs the same pattern (per plan Notes section)
