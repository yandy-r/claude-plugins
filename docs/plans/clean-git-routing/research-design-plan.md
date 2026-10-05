# YAN-711 — clean/git-cleanup routing (research → design → plan → evidence)

## Findings

- `--include-git` was advertised in `ycc/skills/clean/SKILL.md` (argument-hint + Arguments bullet) and `ycc/commands/clean.md` (argument-hint, Supported flags, `--safe-mode --include-git` example) but nothing in the clean pipeline consumed it — declared, unused.
- Real overlap lived in the `project-file-cleaner` agent, section 7 "Legacy Git Files": merged branches, history objects, old tags, submodules, plus `.gitignore`/`.gitattributes` contradicted by the safety config's protected list (`ycc/skills/clean/references/safety-config.md` protects `.git/`, `.gitignore`, `.gitattributes`, `.gitmodules`).
- `git-cleanup` skill owns branches, worktrees, remotes, stashes, tags, PRs/issues; dry-run default, destructive actions need `--apply` + interactive confirmation. History rewriting and submodule cleanup are not covered by either skill.
- No skill deletions required.

## Design

- Stop advertising `--include-git` (hints, flags list, examples). Keep one explicit deprecated-compat parse in the skill: ignore the flag, preserve all other args, show exactly ONE notice before Phase 0 (also before any `--dry-run` stop): deprecated/ignored, files-only scope, run `/ycc:git-cleanup` separately, no Git audit/cleanup, never auto-chained.
- Command passes `$ARGUMENTS` through untouched; skill emits the notice. Command carries a note outside the "Supported flags" list.
- Clean scope: project-directory files only. Large present files still evaluated under existing category rules — size alone is not evidence. Git metadata (`.git` directory or pointer file, `.gitignore`/`.gitattributes`/`.gitmodules`) never removal candidates. History rewriting and submodule cleanup out of scope everywhere. Git-only requests get routing guidance, not a file-cleanup deployment.
- Agent: section 7 replaced by "Scope Boundaries"; findings only — orchestrator controls approved deletion. All other phases and approval gates untouched. No edits to `git-cleanup`, scripts, generators, or model map.

## Plan (executed)

1. Edit `ycc/skills/clean/SKILL.md` — hint + deprecated-compat notice before Phase 0.
2. Edit `ycc/commands/clean.md` — hint, Supported flags, note, example fix.
3. Edit `ycc/agents/project-file-cleaner.md` — replace section 7 with Scope Boundaries.
4. `./scripts/sync.sh` → regenerate `.cursor-plugin/`, `.codex-plugin/`, `.opencode-plugin/`.
5. `./scripts/validate.sh` (full bundle checks).
6. Temporary assert-based contract check (removed after run) + `git diff --check`.

## Evidence

- `./scripts/validate.sh` — all bundle checks OK (one pre-existing warning: worktree hooks symlink not installed; unrelated, documented in CONTRIBUTING.md).
- Second `./scripts/sync.sh` run — no further changes (idempotent).
- Contract check (39 asserts, all pass): no advertised `--include-git` / "Analyze git artifacts" / "Legacy Git Files" in source or generated copies; notice ordering, single-occurrence, routing language, no-auto-chain verified; agent scope-boundary lines present; dry-run/report-only STOP and final AskUserQuestion gates unchanged; `git-cleanup` dry-run default + `--apply` gate untouched; repo-wide `--include-git` only in compat parsing, routing notes, and the historical 2026-04-07 consolidation plan.
- `git diff --check` — clean.

## Final verification record

- The 39-assert check above is the initial historical record. After final review (clean), a read-only 77-assert check passed: approval gates identical to `origin/main` across all four clean skill copies, Git-only guard present and ordered (deprecation notice < guard < Phase 0), agent routing splits supported Git resources (`git-cleanup`) from history/submodules (out of scope for both), findings-only wording, Codex TOML parses, `git-cleanup` untouched, deprecation notice exactly once.
- Final `./scripts/sync.sh` and `./scripts/validate.sh` both exit 0.

## Limitations

Prompt-only change: static checks prove contract text, generated parity, and idempotency; live runtime behavior (notice actually rendered, flag actually ignored end-to-end) not exercised by an automated runtime test.
