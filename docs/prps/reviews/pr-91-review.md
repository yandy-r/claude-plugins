# PR Review #91 — fix(skills): wire prepare-feature-branch.sh into --no-worktree paths

**Reviewed**: 2026-05-06
**Mode**: PR (parallel, --no-worktree)
**Author**: yandy-r
**Branch**: `fix/no-worktree-branch-creation` → `main`
**Decision**: REQUEST CHANGES

## Summary

The PR closes the right gap — narrative-only branch instructions in `--no-worktree` paths really did let implementor agents commit to `main`, and a small idempotent helper script is the right shape for the fix. Validation is fully green (`./scripts/validate.sh`, `npm run lint`, `shellcheck -x`, JSON, executable bits). Two HIGH issues block merge: (a) the new dispatch site in `prp-implement/SKILL.md` quotes the helper path, and the bundle generator's tilde rewrite produces literal `"~/..."` that bash will not expand — Codex and opencode users running `/ycc:prp-implement` will hit "no such file or directory"; (b) inside the helper itself the dirty-tree guard runs _before_ the idempotent on-feature-branch check, so a developer re-invoking the helper while WIP is staged on `feat/<slug>` exits 1 instead of the documented no-op. Several MEDIUM findings are documentation/contract drift between the docblock, usage text, SKILL.md tables, and the actual code (the `develop` trunk branch and `docs/prps/prds/` plan-artifact path are accepted by the script but missing from the prose; `--allow-existing-feature-branch` accepts any non-trunk branch despite usage saying "starts with `feat/`"; `docs/orchestration/<slug>.md` plans break the dirty-tree guard).

## Findings

### CRITICAL

(none)

### HIGH

- **[F001]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:131-185` — Dirty-tree guard executes before the idempotent on-feature-branch check, so any invocation on `feat/<slug>` with non-plan-artifact WIP (e.g., `src/x.ts` modified) exits 1 instead of returning the no-op success path the docblock and SKILL.md tables advertise. The PR's manual test #3 covered the clean case only; the dirty re-invocation case (orchestrator re-running `/ycc:implement-plan` mid-batch after partial work) regresses the documented idempotent contract.
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: Move the `if [[ "$CURRENT_BRANCH" == "$FEATURE_BRANCH" ]]; then echo "$FEATURE_BRANCH"; exit 0; fi` early-exit to immediately after `FEATURE_BRANCH` is computed (line 112), before `collect_dirty` runs. The dirty-tree guard is only meaningful when the script is about to switch or create a branch.

- **[F002]** `ycc/skills/prp-implement/SKILL.md:206` — The new helper invocation is double-quoted: `bash "${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/prepare-feature-branch.sh"`. The Codex and opencode bundle generators rewrite `${CLAUDE_PLUGIN_ROOT}` to literal `~/.codex/plugins/ycc/shared` / `~/.config/opencode/shared` while preserving the surrounding double quotes. Bash does **not** tilde-expand inside double quotes (verified: `bash -c 'echo "~/foo"'` echoes literal `~/foo`), so `/ycc:prp-implement` will fail with "no such file or directory" in those bundles. The other 3 dispatch sites (`plan`, `implement-plan`, `orchestrate`) intentionally write the path **unquoted**, which keeps the tilde expansion intact post-rewrite.
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: Drop the surrounding double quotes in source: `FEATURE_BRANCH=$(bash ${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/prepare-feature-branch.sh "${WT_FEATURE_SLUG}")`. Then re-run `./scripts/sync.sh` to regenerate the cursor/codex/opencode mirrors. (Pre-existing identical bugs at lines 232, 243, 661 of the same file are out of scope for this PR but should be tracked separately — this PR adds _one_ new instance.)

### MEDIUM

- **[F003]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:8-13` — Header docblock lists allowed plan-artifact paths as `docs/plans/<slug>/*, docs/prps/plans/<slug>*, docs/prps/specs/<slug>*` and trunk as `(main/master)`, but `is_plan_artifact` (lines 123-128) also allows `docs/prps/prds/<slug>*` and `is_trunk_branch` (line 165) also accepts `trunk` and `develop`. Future maintainers reading the docblock will not match the code's actual behavior.
  - **Status**: Fixed
  - **Category**: Maintainability
  - **Suggested fix**: Update the Behavior bullets to: "Allow plan-artifact paths (`docs/plans/<slug>/*`, `docs/prps/{plans,specs,prds}/<slug>*`)" and "On trunk (`main`/`master`/`trunk`/`develop`)" so the contract matches the code in one read.

- **[F004]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:38-40` — `usage()` says `--allow-existing-feature-branch` "Reuse the current branch if it already starts with `feat/`", but line 189 returns `CURRENT_BRANCH` for any non-trunk branch — including `chore/x`, `hotfix/y`, `release/1.0`. The flag's actual semantics are broader than documented; a user reading `--help` will form the wrong mental model.
  - **Status**: Fixed
  - **Category**: Maintainability
  - **Suggested fix**: Decide which is canonical. If broader is intended, change usage to "Reuse the current non-trunk branch" and rename the flag accordingly (`--allow-existing-branch`?). If narrower is intended, add a `[[ "$CURRENT_BRANCH" == feat/* ]]` guard before line 189 and exit 2 otherwise.

- **[F005]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:69-71` — After the `--` separator's `break`, any positional argument that follows it (e.g., `prepare-feature-branch.sh -- my-slug`) is silently dropped: the loop exits, `FEATURE_SLUG` stays empty, and the script exits 1 with "feature-slug is required". The `--` convention typically implies "treat the rest as positional".
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: After `break`, process remaining `"$@"` as positional args (consume the first into `FEATURE_SLUG`, error on extras), or remove the `--` case arm entirely and document that `--` is not supported.

- **[F006]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:91` — A whitespace-only or otherwise malformed slug passes the `[[ -z "$FEATURE_SLUG" ]]` guard and is composed directly into `feat/${FEATURE_SLUG}` and `git checkout -b`. The user gets an opaque git error rather than a script-controlled message. Not a security issue in this developer-tool trust model (variables are double-quoted; git rejects invalid refs), but a poor failure mode.
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: Add a format guard immediately after the empty check: `[[ "$FEATURE_SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { _error "slug must be kebab-case [a-z0-9-]: '$FEATURE_SLUG'"; exit 1; }`.

- **[F007]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:120-128` — `is_plan_artifact` allows `docs/plans/`, `docs/prps/{plans,specs,prds}/`, but **not** `docs/orchestration/<slug>.md` — which is exactly where `orchestrate --plan-only --no-worktree` writes its plan (`orchestrate/SKILL.md` line 45 and 362 confirm the path). A subsequent `orchestrate --no-worktree` re-invocation against the same task would be blocked by the dirty-tree guard with no recovery beyond stashing the plan the user just generated.
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: Add `docs/orchestration/"${FEATURE_SLUG}"*) return 0 ;;` to the `case` in `is_plan_artifact`, mirroring the other plan-artifact entries. Update the docblock per F003 in the same edit.

- **[F008]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:159-185` — `branch_exists` only probes local refs (`refs/heads/$1`), not `refs/remotes/origin/$1`. If `feat/<slug>` exists on origin but was never fetched locally, the helper falls into the "create new branch from trunk" path and silently builds a divergent local history. Push later fails with non-fast-forward, so this is recoverable, but it surprises the user at push time and the agent has already done work on the wrong branch.
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: Extend `branch_exists` (or add a parallel `remote_branch_exists`) to also check `refs/remotes/origin/$1`. If only the remote ref exists, run `git checkout --track "origin/$1"` instead of `git checkout -b`. At minimum, emit a stderr warning when the remote ref exists and the local one does not. (No `git fetch` — keep network dependency out per the security reviewer's guidance.)

- **[F009]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:176-185` — When `feat/<slug>` exists locally and is behind the trunk merge-base, the helper switches to it without warning. Implementor agents then commit on a stale base. Same recoverable-but-surprising failure mode as F008.
  - **Status**: Fixed
  - **Category**: Correctness
  - **Suggested fix**: After `git checkout "$FEATURE_BRANCH"` succeeds, compare with trunk via `git merge-base --is-ancestor "$CURRENT_BRANCH" "$FEATURE_BRANCH"` and emit a stderr `_info` warning if behind, so the orchestrator can surface the staleness to the user before dispatching agents.

- **[F010]** `ycc/skills/implement-plan/SKILL.md:259-263` — `implement-plan` gates the `prepare-feature-branch.sh` call on `WORKTREE_ACTIVE=false`, while `prp-implement/SKILL.md:201-223` calls it unconditionally (and then runs `setup-worktree.sh parent` for the worktree-on path). Both work — `setup-worktree.sh` uses `git worktree add -B "$branch" ... HEAD` which creates the branch when missing — but the inconsistency is confusing for future maintainers reading both skills.
  - **Status**: Fixed
  - **Category**: Pattern Compliance
  - **Suggested fix**: Pick one convention and apply it to all four dispatch sites. Either (a) call `prepare-feature-branch.sh` unconditionally and let `setup-worktree.sh` adopt the existing branch (matches `prp-implement`), or (b) gate the helper on `WORKTREE_ACTIVE=false` and rely on `setup-worktree.sh -B` for the worktree path (matches `implement-plan`). Document the chosen convention in `_shared/scripts/prepare-feature-branch.sh` header.

- **[F011]** `ycc/skills/implement-plan/SKILL.md:265` — Inline cross-reference reads `(GitHub #TBD)`. The PR description has the same placeholder (`Closes #<!-- issue number, fill in after filing -->`). A `#TBD` reference inside a canonical skill prompt will ship to every Claude/Cursor/Codex/opencode user.
  - **Status**: Fixed
  - **Category**: Maintainability
  - **Suggested fix**: File the issue (the PR description implies one was planned) and replace `#TBD` with the real number, or remove the parenthetical entirely if the prose stands on its own without the cross-reference.

- **[F012]** `ycc/skills/implement-plan/SKILL.md:267-274`, `ycc/skills/prp-implement/SKILL.md:211-219`, `ycc/skills/orchestrate/SKILL.md` — The branch-decision matrix is duplicated (with minor wording variation) across three SKILL.md files. The project already uses `_shared/references/agent-team-dispatch.md` for exactly this single-source-of-truth pattern. If `prepare-feature-branch.sh`'s exit codes or accepted states change, three docs must be updated in lockstep.
  - **Status**: Fixed
  - **Category**: Maintainability
  - **Suggested fix**: Extract the matrix and the "exits 1 → stop / exits 2 → re-run with --allow-existing-feature-branch" guidance to `ycc/skills/_shared/references/branch-prep.md` (next to `agent-team-dispatch.md`). Replace the three inline copies with a single pointer: "See `${CLAUDE_PLUGIN_ROOT}/skills/_shared/references/branch-prep.md` for the helper's behavior and exit-code contract."

- **[F013]** `ycc/skills/implement-plan/SKILL.md:271`, `ycc/skills/prp-implement/SKILL.md:215`, `ycc/skills/orchestrate/SKILL.md` — All four SKILL.md branch-decision tables enumerate trunk as `main/master/trunk` but the helper's `is_trunk_branch` also accepts `develop`. Orchestrators reading the tables won't know `develop` is a valid starting point.
  - **Status**: Fixed
  - **Category**: Maintainability
  - **Suggested fix**: Add `develop` to the trunk row label in all SKILL.md tables (or, if F012 is taken, do this in the new `_shared/references/branch-prep.md` only). Pair with the F003 docblock fix.

### LOW

- **[F014]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:1-25` — Header comment scopes the script to `--no-worktree` mode ("ensure the current checkout is on the feature branch before dispatching implementor agents in --no-worktree mode"), but `prp-implement/SKILL.md:223` now invokes it in the worktree-on path too. The scope claim is stale.
  - **Status**: Open
  - **Category**: Maintainability
  - **Suggested fix**: Update header to "ensure the current checkout is on the feature branch before dispatching implementor agents (both worktree and `--no-worktree` modes)".

- **[F015]** `ycc/skills/plan/SKILL.md:572-580` — Slug-derivation rules ("lowercase, non-`[a-z0-9-]` → `-`, collapse runs, truncate to 20 chars, fallback `untitled`") are embedded in prose, requiring the LLM orchestrator to apply them in its head. Risk of inconsistent slugs across `plan` vs `parallel-plan` vs `implement-plan`.
  - **Status**: Open
  - **Category**: Maintainability
  - **Suggested fix**: Add a deterministic `--slug-from "<raw text>"` mode to `prepare-feature-branch.sh` (or a sibling `derive-feature-slug.sh`) so all skills produce identical slugs via tool call instead of prose rule interpretation. Follow-up, not a blocker.

- **[F016]** `ycc/skills/_shared/scripts/prepare-feature-branch.sh:48-50` — Defines `_info()` (writes to stderr without prefix) while sibling `_shared/scripts/move-plan-to-worktree.sh:65` uses `_debug()` for the same role. Setup-worktree.sh and list-worktrees.sh use neither helper. No project-wide convention exists yet, so this is a small drift.
  - **Status**: Open
  - **Category**: Pattern Compliance
  - **Suggested fix**: Pick one name (`_info` reads more like a release-time message, `_debug` like noise; `_info` is probably the better choice since these messages are user-facing) and apply it across the helper family in a follow-up.

- **[F017]** PR description test scenario #3 ("Already on `feat/foo` → idempotent no-op, exit 0") is documented as PASS, but the test was run against a clean tree only. The dirty variant (F001) was not exercised. The reviewer notes section claims test coverage that does not exist for the most common re-invocation case.
  - **Status**: Open
  - **Category**: Completeness
  - **Suggested fix**: After applying F001's fix, add a test scenario "On `feat/foo` with WIP non-plan-artifact dirty file → exit 0 (idempotent no-op)". The PR description's test table can be updated in the same commit.

## Validation Results

| Check                                    | Result                                                          |
| ---------------------------------------- | --------------------------------------------------------------- |
| JSON (`marketplace.json`, `plugin.json`) | Pass                                                            |
| Shell scripts executable                 | Pass (only 2 pre-existing library files are non-executable)     |
| `./scripts/validate.sh`                  | Pass (cursor + codex + opencode sync, content policy, manifest) |
| `npm run lint`                           | Pass (markdownlint, prettier, ruff, black, shellcheck)          |
| `shellcheck -x` on new helper            | Pass (clean)                                                    |

## Files Reviewed

Source (5 files, the reviewable surface):

- `ycc/skills/_shared/scripts/prepare-feature-branch.sh` (Added, 197 lines)
- `ycc/skills/plan/SKILL.md` (Modified — Option 1 in-conversation parallel execution + frontmatter)
- `ycc/skills/implement-plan/SKILL.md` (Modified — Step 6.6 branch prep)
- `ycc/skills/orchestrate/SKILL.md` (Modified — Phase 2.5 worktree-mode-false branch + frontmatter)
- `ycc/skills/prp-implement/SKILL.md` (Modified — Phase 2 Branch Decision rewrite + frontmatter)

Generated bundle mirrors (15 files, spot-checked for parity):

- `.codex-plugin/ycc/shared/scripts/prepare-feature-branch.sh` (Added — identical to source)
- `.codex-plugin/ycc/skills/{plan,implement-plan,orchestrate,prp-implement}/SKILL.md` (Modified)
- `.cursor-plugin/skills/_shared/scripts/prepare-feature-branch.sh` (Added — identical to source)
- `.cursor-plugin/skills/{plan,implement-plan,orchestrate,prp-implement}/SKILL.md` (Modified)
- `.opencode-plugin/shared/scripts/prepare-feature-branch.sh` (Added — identical to source)
- `.opencode-plugin/skills/{plan,implement-plan,orchestrate,prp-implement}/SKILL.md` (Modified)
