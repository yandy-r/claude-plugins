# Implementation Report: Visual Planning Skills

## Summary

Ported the BuilderIO `visual-plan` and `visual-recap` skills (pinned upstream commit
`a0726717ab0402e85eadca46183d8be50bc3a102`) into the `ycc` bundle as `ycc:visual-plan` and
`ycc:visual-recap`, and added an orthogonal `--visual` decorator flag to the four planning
skills (`prp-plan`, `plan`, `plan-workflow`, `parallel-plan`). `ycc:visual-plan` keeps the
faithful Agent-Native integration (MDX, hosted shareable links, `npx @agent-native/*` tooling,
localhost bridge) but gates hosted egress behind explicit `--share` consent and routes it
through a shared egress guard; `ycc:visual-recap` is rewritten local-only and remote-agnostic.
The `plan` Agent-Native MCP connector (legacy alias `agent-native-plans`) was registered, and
all Cursor / Codex / opencode bundles plus `docs/inventory.json` were regenerated and validated.

## Assessment vs Reality

| Metric        | Predicted (Plan)           | Actual                                       |
| ------------- | -------------------------- | -------------------------------------------- |
| Complexity    | Large (10+ files)          | Large — confirmed                            |
| Confidence    | 7/10                       | High — implemented as planned                |
| Files Changed | ~22 source (excl. bundles) | 22 source files; 38 regenerated bundle files |

## Execution Mode

- **Mode**: Parallel sub-agents (`--parallel --no-worktree`)
- **Batches**: 5 (B1 width 4, B2 width 2, B3 width 4, B4 width 1, B5 width 1)
- **Branch**: `feat/visual-planning-skills` (from `main`)

## Tasks Completed

| #   | Task                                                 | Status   | Notes                                             |
| --- | ---------------------------------------------------- | -------- | ------------------------------------------------- |
| 1.1 | Shared `agent-native-setup.md` reference             | Complete | Pinned `@agent-native/core@0.59.1` (no `@latest`) |
| 1.2 | Shared `visual-mode.md` contract reference           | Complete |                                                   |
| 1.3 | `visual-recap-collect.sh` + `visual-egress-guard.sh` | Complete | Distinct exit codes; remote-agnostic              |
| 1.4 | `docs/prps/reviews/visual/.gitkeep` + `.gitignore`   | Complete | `.gitkeep` recreated after a B1 cleanup race      |
| 2.1 | Port `ycc:visual-plan` (skill + 4 refs + command)    | Complete | + thin `derive-visual-dir.sh`; no GitHub Action   |
| 2.2 | Port `ycc:visual-recap` (local-only)                 | Complete | Inverts hosted mandate; `local-files` enforced    |
| 3.1 | `--visual` on `prp-plan`                             | Complete | + `Visual Artifact`/`Visual Link` report fields   |
| 3.2 | `--visual` on `plan` (force-write artifact)          | Complete | Force-writes plan file first                      |
| 3.3 | `--visual` on `plan-workflow`                        | Complete | Hands off actual feature-dir plan path            |
| 3.4 | `--visual` on `parallel-plan`                        | Complete | `--dry-run` short-circuit honored                 |
| 4.1 | Register `plan` MCP connector + `./scripts/sync.sh`  | Complete | Regenerated all bundles + inventory               |
| 5.1 | `./scripts/validate.sh` CI loop                      | Complete | Green after one fix (see Deviations)              |

## Validation Results

| Level                      | Status | Notes                                                        |
| -------------------------- | ------ | ------------------------------------------------------------ |
| Structural (`validate.sh`) | Pass   | inventory + cursor/codex/opencode `--check` + JSON manifests |
| JSON manifests             | Pass   | marketplace.json, plugin.json, mcp.json all parse            |
| Script hygiene             | Pass   | new `*.sh` executable, `bash -n` clean, `shellcheck` clean   |
| Lint (markdown/prettier)   | Pass   | `npm run lint:modified` clean after auto-fix                 |
| Flag presence              | Pass   | `--visual`/`VISUAL_MODE`/`visual-mode.md` on all 4 skills    |

> Note: this repo has no unit-test runner; "tests" are the validator pipeline + targeted greps,
> per the plan's Testing Strategy.

## Files Changed

### Created (source)

| File                                                                                | Action  |
| ----------------------------------------------------------------------------------- | ------- |
| `ycc/skills/_shared/references/agent-native-setup.md`                               | CREATED |
| `ycc/skills/_shared/references/visual-mode.md`                                      | CREATED |
| `ycc/skills/_shared/scripts/visual-recap-collect.sh`                                | CREATED |
| `ycc/skills/_shared/scripts/visual-egress-guard.sh`                                 | CREATED |
| `ycc/skills/visual-plan/SKILL.md`                                                   | CREATED |
| `ycc/skills/visual-plan/references/{canvas,wireframe,document-quality,exemplar}.md` | CREATED |
| `ycc/skills/visual-plan/scripts/derive-visual-dir.sh`                               | CREATED |
| `ycc/commands/visual-plan.md`                                                       | CREATED |
| `ycc/skills/visual-recap/SKILL.md`                                                  | CREATED |
| `ycc/skills/visual-recap/references/wireframe.md`                                   | CREATED |
| `ycc/commands/visual-recap.md`                                                      | CREATED |
| `docs/prps/reviews/visual/.gitkeep`                                                 | CREATED |

### Updated (source)

| File                                | Action  |
| ----------------------------------- | ------- |
| `.gitignore`                        | UPDATED |
| `mcp-configs/mcp.json`              | UPDATED |
| `ycc/skills/prp-plan/SKILL.md`      | UPDATED |
| `ycc/commands/prp-plan.md`          | UPDATED |
| `ycc/skills/plan/SKILL.md`          | UPDATED |
| `ycc/commands/plan.md`              | UPDATED |
| `ycc/skills/plan-workflow/SKILL.md` | UPDATED |
| `ycc/commands/plan-workflow.md`     | UPDATED |
| `ycc/skills/parallel-plan/SKILL.md` | UPDATED |
| `ycc/commands/parallel-plan.md`     | UPDATED |

### Regenerated (never hand-edited)

`.cursor-plugin/**`, `.codex-plugin/**`, `.opencode-plugin/**`, `docs/inventory.json`,
`README.md` — 38 generated files, produced by `./scripts/sync.sh`.

## Deviations from Plan

- **opencode install-coverage failure (fixed)**: The first `validate.sh` run failed because
  `agent-native-setup.md`'s intro cited `${CLAUDE_PLUGIN_ROOT}/skills/visual-plan/...` with a
  literal `...` ellipsis, which the install-coverage validator tried to resolve as a real file.
  Repointed the two references to the concrete `SKILL.md` files, regenerated, and re-validated
  green.
- **B1 race condition (recovered)**: Task 1.3's functional smoke tests transiently removed the
  `docs/prps/reviews/visual/.gitkeep` created by Task 1.4 (shared checkout, no worktree). The
  parent recreated it during B1 validation.

## Issues Encountered

- Two pre-existing non-executable scripts (`ycc/skills/formatters/scripts/bundle/lib/shellcheck-resolve.sh`,
  `shellcheck-version.sh`) are tracked mode `100644` (sourced `lib/` files, not executables).
  They predate this work and are not flagged by `validate.sh`; left untouched.

## Security Posture (plan S1–S9)

- **S1** `npx @agent-native/*` pinned to exact `0.59.1`; pin + egress documented in setup ref.
- **S2** Hosted upload OFF by default; `--share` required, naming `plan.agent-native.com`.
- **S3** `visual-recap` performs no remote fetch/upload by default (`local-files`).
- **S4** Remote sourcing explicit via `git remote get-url`; upload refused on private Forgejo `origin`.
- **S5** Pre-upload `.env*`/key denylist scan aborts on hit (`visual-egress-guard.sh`).
- **S6** Localhost bridge binds `127.0.0.1`, ephemeral port (documented in setup ref).
- **S7** New scripts: strict mode, input guards, `case` parsing, stdout/stderr discipline, distinct exit codes.
- **S8** Shared egress/guard logic in one `_shared/scripts` helper.
- **S9** `find ycc/skills -name "*.sh" -not -executable` lists only pre-existing libs; `shellcheck` clean.

## /goal Pairing Decision

Deferred (per plan "NOT Building"). `/goal` pairing was NOT added to the new visual skills in
this pass. Revisit as a follow-up if autonomous visual generation is desired.

## Next Steps

- [ ] Code review via `/code-review`
- [ ] Create PR via `/prp-pr`
- [ ] (Optional) Decide on `/goal` pairing for the new visual skills
