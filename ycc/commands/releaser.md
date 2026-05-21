---
description: Prepare and cut a GitHub release for any project — detects toolchain, drafts changelog, plans platform/arch artifacts, optionally generates or audits release CI, optionally invokes the publish helper, and optionally drives the release CI to green via a bounded auto-fix loop (--ci). Emits commands; never auto-publishes without explicit --publish and --confirm. External-project counterpart to /ycc:bundle-release.
argument-hint: '[version] [--arch=list] [--os=list] [--ci-config[=generate|audit]] [--platform=name] [--skip-notes] [--dry-run] [--exclude-internal] [--publish[=create|edit|auto]] [--confirm] [--ci] [--ci-max-pushes=N] [--ci-max-same-failure=N] [--ci-timeout-min=N] [--ci-yes] [--ci-recut=destructive]'
---

Invoke the **releaser** skill with `$ARGUMENTS` passed through.

The skill:

1. Detects the project's language, build system, and version-bearing manifests.
2. Proposes a semver bump from conventional-commit history if no version is supplied.
3. Resolves the `{os × arch}` release matrix from language defaults or explicit flags.
4. Drafts a grouped changelog and a release-notes file (use `--exclude-internal` to
   drop the Maintenance section).
5. Bumps version in manifests (package.json / pyproject.toml / Cargo.toml) without
   editing anything else.
6. Optionally generates a release workflow (`--ci-config=generate`) or audits the
   existing one (`--ci-config=audit`) for supply-chain, caching, and permissions
   best practices.
7. Emits the exact `git tag`, `git push`, and `gh release create` commands to run.
8. When `--publish[=create|edit|auto]` is passed, runs `publish-release.sh` in
   print-only mode so the operator reviews the resolved `gh` command. Re-running with
   `--confirm` actually executes it. `--dry-run` always beats `--publish`.
9. When `--ci` is passed AND `--publish --confirm` actually publishes, enters the
   bounded **release-CI auto-fix loop** (Phase 8.5): polls the release-event
   workflow run, classifies failures, dispatches `ycc:release-fix-applier` on the
   implicated files, commits and pushes the fix, re-cuts the release via
   `gh workflow run` (preferred) or the destructive fallback (only with
   `--ci-recut=destructive`), and loops until green or a bail cap fires. Bounded by
   `--ci-max-pushes`, `--ci-max-same-failure`, `--ci-timeout-min`. Use `--ci-yes`
   to skip the one-time authorization prompt for non-interactive callers.

Never auto-commits, pushes, or publishes without an explicit `--publish` and
`--confirm` from the user. Use `/ycc:bundle-release` for this repo's internal ycc
bundle release — this command is the generic external-project variant.

> **Flag rename:** `--ci[=generate|audit]` was renamed to `--ci-config[=generate|audit]`
> to free up the bare `--ci`/`--ci-yes` namespace for the auto-fix loop, matching
> `/ycc:git-workflow`, `/ycc:prp-pr`, and `/ycc:pr-autofix`. Old invocations using
> `--ci=generate` or `--ci=audit` must be updated.
