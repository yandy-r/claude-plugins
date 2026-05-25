# Implementation Report: /goal integration for ycc:prp-implement

## Summary

Made `ycc:prp-implement` loop-to-completion friendly with Claude Code's and Codex CLI's `/goal` directive by printing a verbatim machine-readable Goal Signals block in Phase 6 OUTPUT, adding a `## /goal pairing` section to the skill, and surfacing the recommended `/goal` invocation in the command help. Regenerated and validated Cursor/Codex/opencode bundles.

## Assessment vs Reality

| Metric        | Predicted (Plan)   | Actual                                   |
| ------------- | ------------------ | ---------------------------------------- |
| Complexity    | Small–Medium       | Small–Medium                             |
| Confidence    | High               | High                                     |
| Files Changed | 2 source + bundles | 6 files (+38 lines each in skill copies) |

## Tasks Completed

| #   | Task                                                                      | Status          | Notes                                                         |
| --- | ------------------------------------------------------------------------- | --------------- | ------------------------------------------------------------- |
| 1.1 | Make prp-implement signals transcript-observable + document /goal pairing | [done] Complete | Source prose revised once after Task 3.1 cross-target review  |
| 1.2 | Surface recommended /goal invocation in command help                      | [done] Complete |                                                               |
| 2.1 | Regenerate and validate all compatibility bundles                         | [done] Complete | sync.sh + validate.sh exit 0                                  |
| 3.1 | Cross-target prose verification                                           | [done] Complete | Fixed misleading opencode/Codex rewrites in source; re-synced |

## Validation Results

| Level           | Status      | Notes                                                   |
| --------------- | ----------- | ------------------------------------------------------- |
| Static Analysis | [done] Pass | npm run lint:modified                                   |
| Unit Tests      | N/A         | No unit-test harness for skill prose                    |
| Build           | N/A         | Documentation-only change                               |
| Integration     | [done] Pass | ./scripts/sync.sh + ./scripts/validate.sh               |
| Edge Cases      | [done] Pass | Cross-target prose verified; version unchanged at 3.1.2 |

## Files Changed

| File                                              | Action      | Lines |
| ------------------------------------------------- | ----------- | ----- |
| `ycc/skills/prp-implement/SKILL.md`               | UPDATED     | +38   |
| `ycc/commands/prp-implement.md`                   | UPDATED     | +6    |
| `.cursor-plugin/skills/prp-implement/SKILL.md`    | REGENERATED | +38   |
| `.codex-plugin/ycc/skills/prp-implement/SKILL.md` | REGENERATED | +38   |
| `.opencode-plugin/skills/prp-implement/SKILL.md`  | REGENERATED | +38   |
| `.opencode-plugin/commands/prp-implement.md`      | REGENERATED | +6    |

## Deviations from Plan

Revised source wording in Task 3.1 after cross-target generator review:

- **WHAT**: Intro and platform caveat no longer use "Claude Code and Codex CLI" phrasing; command example comment uses "Anthropic terminal / Codex CLI only".
- **WHY**: opencode generator rewrites "Claude Code" → "opencode", producing misleading claims that opencode ships `/goal`. Using "Anthropic terminal" and leading with "not available in Cursor or opencode" survives all three generators correctly.

## Issues Encountered

Initial `/goal pairing` section phrasing ("Claude Code and Codex CLI") was rewritten by opencode/Codex generators to falsely claim `/goal` exists in opencode. Fixed in source and re-synced; validate.sh green on second pass.

## Tests Written

| Test File | Tests | Coverage                                  |
| --------- | ----- | ----------------------------------------- |
| N/A       | —     | Grep + validate.sh pipeline per CLAUDE.md |

## Next Steps

- [ ] Code review via `/code-review`
- [ ] Create PR via `/prp-pr`
