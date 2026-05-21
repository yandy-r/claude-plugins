---
name: releaser
description: This skill should be used when the user asks to "prepare a release",
  "cut a release", "tag a release", "create a GitHub release", "draft release notes",
  "set up release CI", "add a release workflow", "audit release pipeline", "publish
  a GitHub release", or "publish release notes" for any project. Detects language/toolchain,
  drafts a changelog, plans platform/arch artifacts, optionally generates or audits
  GitHub Actions release CI, and emits the exact commands the user runs to tag and
  publish. Never auto-commits, pushes, or publishes without an explicit `--publish`
  and `--confirm` from the user. Generic external-project counterpart to `bundle-release`
  (which is scoped to this repo's ycc bundle).
---

# Generic Release Orchestrator

This skill prepares a release for **any** project: detects the toolchain, drafts a
changelog from conventional commits, plans platform/architecture artifacts, and — on
request — either generates a GitHub Actions release workflow or audits an existing one
against best practices. It emits the exact `git tag`, `git push`, and `gh release
create` commands the user runs; **it never commits, pushes, or publishes without an explicit `--publish` and `--confirm` from the user**.

> **Not for this bundle.** For `ycc` bundle releases use `bundle-release`, which is
> scoped to this repo's `plugin.json` + `marketplace.json` version-parity contract and
> the Cursor/Codex sync flow.

## Arguments

Parse `$ARGUMENTS`:

- **version** (optional first positional) — target semver (`1.4.0`, `v1.4.0`, or a
  pre-release like `1.4.0-rc.1`). If omitted, the skill proposes one from commit history
  (conventional-commit bump) and asks for confirmation before continuing.
- **--arch=\<list\>** — comma-separated target architectures (e.g. `amd64,arm64`).
  Overrides language defaults.
- **--os=\<list\>** — comma-separated target operating systems (e.g. `linux,darwin,windows`).
  Overrides language defaults.
- **--ci-config** / **--ci-config=generate** — scaffold a GitHub Actions release
  workflow under `.github/workflows/release.yml`. Fails if one already exists unless
  `--ci-config=audit` is also requested. (Renamed from `--ci` so the bare `--ci` flag
  matches the auto-fix-loop family used by `git-workflow`, `prp-pr`, and
  `pr-autofix`.)
- **--ci-config=audit** — invoke the `releaser` agent to read the existing
  release workflow(s) and emit an optimization report. Read-only.
- **--platform=\<name\>** — explicit toolchain override (`node`, `python`, `go`, `rust`,
  `docker`, `generic`). Skips auto-detection. Useful for monorepos.
- **--skip-notes** — skip drafting `CHANGELOG` updates and release notes.
- **--dry-run** — run detection and print the full release plan. Writes nothing,
  executes no state-changing commands.
- **--exclude-internal** — omit the Maintenance section from the drafted release notes
  entirely. Use only when the release truly has zero internal-only churn worth surfacing.
- **--publish[=create|edit|auto]** — after the user reviews the rendered notes, invoke
  `publish-release.sh` to preview or apply the `gh release` command. Default mode is
  `auto` (creates if no release exists, otherwise proposes `edit`). Use `edit` only to
  intentionally replace an existing release body — this is destructive.
- **--confirm** — when combined with `--publish`, re-runs the helper with `--confirm` to
  actually execute the `gh` command. The skill NEVER passes `--confirm` automatically.
- **--ci** — after a successful `--publish --confirm`, enter the bounded **Release CI
  auto-fix loop** (Phase 8.5): poll the release-event workflow run, classify failures,
  dispatch a fix agent on implicated files, commit + push, re-cut the release, and
  loop until green or a bail cap fires. No-op (with warning) if `--publish --confirm`
  did not succeed in this run. Shares contract with `ci-monitor.sh` / sibling skills.
- **--ci-max-pushes=N** — hard cap on autonomous fix-and-recut iterations per
  invocation. Default `5`. Forwarded to `release-ci-monitor.sh`.
- **--ci-max-same-failure=N** — bail after the same failure signature recurs N
  times. Default `3`. Forwarded to `release-ci-monitor.sh`.
- **--ci-timeout-min=N** — wall-clock cap in minutes from the first iteration.
  Default `30`. Forwarded to `release-ci-monitor.sh`.
- **--ci-yes** — skip the one-time Phase 8.5 authorization prompt. Use only for
  non-interactive callers; safety caps remain enforced.
- **--ci-recut=destructive** — opt in to the destructive re-cut fallback when the
  detected release workflow has no `workflow_dispatch` trigger. Without this flag,
  the loop refuses to enter when the only available re-cut path is
  `gh release delete --cleanup-tag` followed by re-publish.

## Phase 0: Preflight

Before anything else, verify:

1. Working directory is a git repo: `git rev-parse --show-toplevel` succeeds.
2. Working tree is clean: `git status --porcelain` is empty. If dirty, STOP and ask
   whether to stash or abort — never silently move forward with uncommitted changes.
3. `gh` is installed and authenticated when `--ci-config` is absent but the user
   asked for a GitHub release. Also required when `--ci` is set, since the
   auto-fix loop calls `gh run list`, `gh workflow run`, and `gh release` under
   the hood. Surface install/login hints if missing.
4. If `version` was provided, it matches the regex
   `^v?[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?(\+[A-Za-z0-9.-]+)?$`. Reject malformed
   input with a clear error.

If any check fails, STOP and surface a specific remediation — do not continue past
Phase 0 with known-bad preconditions.

## Phase 1: Detect project

Run:

```
~/.config/opencode/skills/releaser/scripts/detect-project.sh
```

The helper emits a single JSON document to stdout describing:

- `language` — primary language (`node`, `python`, `go`, `rust`, `docker`, `mixed`,
  `generic`).
- `build_system` — `npm` / `pnpm` / `yarn` / `poetry` / `uv` / `hatch` / `setuptools` /
  `cargo` / `go-modules` / `docker` / `none`.
- `manifest_files` — list of version-bearing files.
- `default_os` and `default_arch` — sensible defaults for that language.
- `existing_ci` — list of `.github/workflows/*.yml` files already present.
- `current_version` — extracted from the manifest, or `null` if not found.
- `latest_tag` — output of `git describe --tags --abbrev=0 2>/dev/null` or `null`.

If `--platform` was passed, override the detected `language` field before continuing.

See `references/project-type-matrix.md` for the full language → toolchain → default
matrix.

## Phase 2: Propose version and compute bump

If the user did NOT supply a version:

1. Collect commits since `latest_tag` (or the last 50 if no tag exists):
   `git log <latest_tag>..HEAD --format="%s"`.
2. Classify each commit against conventional-commit types. Determine the bump:
   - Any `!` marker, `BREAKING CHANGE` footer, or `major:` → major.
   - Any `feat:` → minor.
   - Otherwise → patch.
3. Propose the next semver and ASK for confirmation before writing anything.

If the user DID supply a version, sanity-check the bump magnitude against commit
history. Surface a concern if they are mismatched (e.g. `feat:` commits but a patch
bump) and require explicit confirmation before continuing.

## Phase 3: Resolve release target matrix

Build the final `{os × arch}` matrix:

1. Start with `default_os` / `default_arch` from Phase 1.
2. If `--os` or `--arch` was passed, replace the corresponding axis entirely.
3. Reject combinations with no known build recipe (e.g. `windows × arm` for languages
   where cross-compilation is unsupported) — list the invalid combos and ask whether to
   drop or abort.

Store the matrix for Phases 5, 6, and 7.

## Phase 4: Draft changelog and release notes

Unless `--skip-notes` was passed:

1. Invoke the changelog helper and capture its stdout:

   ```
   ~/.config/opencode/skills/releaser/scripts/draft-changelog.sh [--exclude-internal] [--template <path>] <new-version> [<from-ref>]
   ```

   Pass `--exclude-internal` if the user requested it. Pass `--template <path>` if the
   user supplied a custom template path. The helper fills the template placeholders
   (`{{VERSION}}`, `{{DATE}}`, `{{HIGHLIGHTS}}`, `{{BREAKING}}`, `{{FEATURES}}`,
   `{{FIXES}}`, `{{INTERNAL}}`, `{{COMMITS}}`, `{{COMPARE_URL}}`, `{{PREVIOUS_TAG}}`)
   from git history and writes the complete rendered document to stdout.

2. Write the captured stdout to `docs/releases/<new-version>.md` (or
   `.github/releases/<version>.md` if the repo already uses that path). This is the
   notes file that the `gh release create` command consumes.

3. Update `CHANGELOG.md` by prepending a slim version of the same content — Summary and
   per-category sections only, no `<details>` blocks — above any `## [Unreleased]`
   marker. If no `CHANGELOG.md` exists, create one using the template seeded from
   `~/.config/opencode/skills/releaser/references/release-notes-template.md`.

Ask the user to review the drafted Summary and Upgrade Notes sections before moving on.

### Internal vs. user-facing commits

Commits typed `docs`, `chore`, `test`, `build`, `ci`, `style`, and `refactor` are
classified as Maintenance. The helper surfaces them in a collapsible `<details>` block
so they are visible but not dominant. Pass `--exclude-internal` to drop the Maintenance
section entirely — use this only when the release genuinely contains no internal-only
churn worth surfacing; otherwise keep the section so reviewers have full context.

## Phase 5: Bump version in manifests

Edit only the files named in `manifest_files` from Phase 1. Common targets:

- `package.json` → `version` field.
- `pyproject.toml` → `[project].version` or `[tool.poetry].version`.
- `Cargo.toml` → `[package].version`.
- `go.mod` does not carry a version; the tag IS the version. Skip the bump step.
- `Dockerfile` or `docker-compose.yml` labels → update if the repo uses
  `org.opencontainers.image.version`.

NEVER edit files outside that list. After edits, emit a diff summary and STOP for user
review before continuing.

## Phase 6: CI workflow file (optional)

This phase generates or audits the **release.yml** file itself. It is separate from
the **Phase 8.5 release-CI auto-fix loop** (which watches a live workflow run after
publish). Three modes:

### --ci-config=generate

Fails if any file in `existing_ci` looks release-related (matches
`release|publish|deploy`). Otherwise, write a new `.github/workflows/release.yml` by
copying the matching template:

- Node → `references/ci-templates/node-release.yml`
- Python → `references/ci-templates/python-release.yml`
- Go → `references/ci-templates/go-release.yml` (uses goreleaser)
- Rust → `references/ci-templates/rust-release.yml` (uses cargo-dist if configured,
  else actions-rs matrix)
- Docker → `references/ci-templates/docker-release.yml`
- Generic → `references/ci-templates/generic-release.yml` (tag-triggered, uploads
  artifacts via `softprops/action-gh-release`)

Substitute the Phase 3 matrix and project name into the template. Also emit a short
`.github/workflows/README.md` entry documenting the new workflow — required (see
`references/ci-optimization-checklist.md`, "Documentation" section).

### --ci-config=audit

Delegate to the `releaser` agent. Pass it the list of existing workflow files. The
agent returns a structured report (Findings → Severity → Fix). The skill summarizes the
top items and writes the full report to `docs/prps/reviews/ci-release-audit.md` for
later consumption by `review-fix`.

### No --ci-config flag

Skip Phase 6 entirely. Print a one-line reminder: "Skipped CI workflow generation.
Run with `--ci-config=generate` or `--ci-config=audit` to include it. (This is
separate from `--ci`, which monitors a live release workflow after publish.)"

## Phase 7: Dry-run check

If `--dry-run` was passed:

1. Print the full release plan: detected project, proposed version, target matrix,
   files that would change, commands that would run.
2. STOP. Write nothing, execute nothing side-effecting.
3. If both `--dry-run` and `--publish` were passed, `--dry-run` wins: the publish helper
   does NOT run.

## Phase 8: Emit next-step commands

Always emit the following block. Substitute `<new-version>`, `<changed-files>`, and
`<notes-path>` with real values. NEVER run these commands automatically.

```
Release prepared. No commits or tags have been created — review the diff, then run:

git add <changed-files>
git commit -m "chore(release): v<new-version>"
git tag -a v<new-version> -m "v<new-version>"
git push origin HEAD --follow-tags

# Create the GitHub release from the drafted notes:
gh release create v<new-version> \
  --notes-file <notes-path> \
  --title "v<new-version>"

# If artifacts were produced locally and need uploading:
gh release upload v<new-version> <path-to-artifact> [...]
```

If `--ci-config=generate` ran, append:

```
# Verify the new workflow in CI by pushing the tag — the release workflow will
# build the matrix and attach artifacts to the GitHub release.
```

When the user passed `--publish[=create|edit|auto]`, after they review the rendered
notes, run:

```
~/.config/opencode/skills/releaser/scripts/publish-release.sh v<new-version> <notes-path> --mode=<mode>
```

**Examples:**

```
# Preview only — prints the resolved gh command without executing it:
~/.config/opencode/skills/releaser/scripts/publish-release.sh v1.4.0 docs/releases/v1.4.0.md --mode=auto

# Apply — executes the resolved gh command:
~/.config/opencode/skills/releaser/scripts/publish-release.sh v1.4.0 docs/releases/v1.4.0.md --mode=auto --confirm
```

This prints the resolved `gh` command without executing it. Re-run with `--confirm` to
apply. Use `--mode=edit` only when intentionally replacing an existing release body —
this is destructive.

## Phase 8.5: Release CI auto-fix loop (--ci)

Runs **only** when ALL of the following hold:

- `--ci` was passed.
- `--publish` was passed.
- `--confirm` was passed AND `publish-release.sh --confirm` exited 0 (the release
  exists on GitHub and the release-event workflow has been triggered).

Otherwise, print a one-line warning — `--ci ignored: no successful publish in this
run` — and skip to Phase 9. Never enter the loop without a live release to watch.

The contract (exit codes, `RESULT=` signaling, JSONL audit log, failure classification,
signature dedup, default-branch refusal) mirrors `ci-monitor.sh` verbatim. See
[`_shared/references/ci-monitoring.md`](../_shared/references/ci-monitoring.md),
section "Release mode", for the single source of truth.

### 8.5.0 Detect re-cut strategy

Read `.github/workflows/<resolved-release-workflow>.yml` and inspect the `on:`
triggers:

- If `workflow_dispatch` is present → **preferred path**: re-trigger via
  `gh workflow run <name> --ref <tag>`. Non-destructive.
- Else if `--ci-recut=destructive` was passed → **fallback path**:
  `gh release delete <tag> --cleanup-tag --yes` then re-run
  `publish-release.sh ... --confirm` to recreate the tag and release.
- Else → REFUSE to enter the loop. Print: "Release workflow has no
  `workflow_dispatch` trigger; re-running it requires destroying and recreating the
  release. Add a `workflow_dispatch:` trigger to your release workflow, or re-run
  this command with `--ci-recut=destructive` to opt in." Exit Phase 8.5.

### 8.5.1 Authorization gate (skipped if --ci-yes)

Render a one-time block showing:

- Resource: tag `v<new-version>`, workflow `<file>`, repo `<owner/name>`.
- Resolved caps: `--ci-max-pushes` (default 5), `--ci-max-same-failure` (default 3),
  `--ci-timeout-min` (default 30).
- Re-cut strategy detected in 8.5.0: `workflow_dispatch` (preferred) or
  `delete-release-and-retag` (destructive — only if `--ci-recut=destructive`).
- Non-toggleable safety constraints:
  - Never `git push --force` to any branch.
  - Never `git push --no-verify`.
  - Never edits files outside the failed workflow step's implicated paths.
  - Never amends published release notes without an explicit user opt-in.

Wait for `yes`/`no`. Any other input aborts the loop and proceeds to Phase 9 with
"loop declined" status.

### 8.5.2 Loop protocol

1. Initialize audit log:

   ```
   mkdir -p ~/.config/opencode/session-data/release-ci-watch/
   AUDIT_LOG=~/.config/opencode/session-data/release-ci-watch/<tag>-<utc-iso>.log
   ```

2. Invoke the monitor:

   ```
   ~/.config/opencode/shared/scripts/release-ci-monitor.sh \
     --tag v<new-version> \
     --workflow <detected-or-passed> \
     --repo <owner/name> \
     --max-pushes <N> \
     --max-same-failure <N> \
     --timeout-min <N> \
     --log-file "$AUDIT_LOG"
   ```

3. Branch on the exit code (identical contract to `ci-monitor.sh`):

   | Exit | `RESULT=`         | Action                                                |
   | ---- | ----------------- | ----------------------------------------------------- |
   | 0    | `green`           | Success. Exit Phase 8.5, continue to Phase 9.         |
   | 20   | `handoff`         | Step **8.5.3** (fix and re-cut), then loop to step 2. |
   | 21   | `rerun-pending`   | `sleep 30`, then loop to step 2 (no fix applied).     |
   | 10   | `bail-recurrence` | Step **8.5.4** (diagnosis), exit Phase 8.5.           |
   | 11   | `bail-nonfixable` | Step **8.5.4**, exit Phase 8.5.                       |
   | 12   | `bail-pushes`     | Step **8.5.4**, exit Phase 8.5.                       |
   | 13   | `bail-timeout`    | Step **8.5.4**, exit Phase 8.5.                       |
   | 2    | `not-found`       | Step **8.5.4**, exit Phase 8.5.                       |

### 8.5.3 Fix and re-cut on handoff

The monitor wrote one JSONL line to the audit log with the failed run's metadata:
`run_id`, `workflow_name`, `job_name`, `step_name`, `category`, `signature`,
`log_excerpt_path`, `implicated_files`.

1. **Dispatch the fix agent** via the opencode `task` tool with
   `@release-fix-applier`. Pass the JSONL line verbatim. The
   agent edits ONLY the implicated files, returns the proposed commit message
   (conventional-commit prefix matching the category — `fix`, `ci`, `build`, etc.)
   and the diff summary.

2. **Validate the commit message**:

   ```
   ~/.config/opencode/skills/git-workflow/scripts/validate-commit.sh "<message>"
   ```

3. **Pre-push branch-protection check**:

   ```
   gh api repos/<owner>/<name>/branches/main/protection 2>/dev/null
   ```

   If `main` has `required_pull_request_reviews`, the loop cannot push directly.
   Surface: "Direct push to `main` blocked by branch protection — open a PR with
   the fix, merge it, and re-run with `--ci`." Exit Phase 8.5 with `loop-blocked`
   status (renders an 8.5.4-style block without retrying).

4. **Commit and push**:

   ```
   git add <implicated-files>
   git commit -m "<validated-message>"
   git push origin HEAD
   ```

   NEVER `--force`. NEVER `--no-verify`.

5. **Re-trigger the release workflow** per the strategy detected in 8.5.0.
   - **Preferred** (`workflow_dispatch` available):

     ```
     gh workflow run <name> --ref v<new-version>
     ```

   - **Fallback** (only if `--ci-recut=destructive` was set):

     ```
     gh release delete v<new-version> --cleanup-tag --yes
     ~/.config/opencode/skills/releaser/scripts/publish-release.sh \
       v<new-version> <notes-path> --mode=create --confirm
     ```

6. `push_count++`. Loop back to 8.5.2 step 2.

### 8.5.4 Bail diagnosis block

Render to the user:

- **Reason** — one of `recurrence` / `nonfixable` / `pushes` / `timeout` /
  `not-found` / `loop-blocked`.
- **Cap that fired** and its resolved value.
- **Last failure** — `run_id`, `workflow_name`, `job_name`, `step_name`,
  `category`, `signature`.
- **Log excerpt path** (from the monitor's `--log-file`).
- **Audit log path**.
- **Next steps** — concrete guidance keyed off the bail reason (e.g., for
  `recurrence`: "The same failure (`<signature>`) recurred. Inspect
  `<log-excerpt-path>` and apply a manual fix before retrying.").

Always print this block — even on `not-found` — so the user has a single
post-mortem surface.

## Phase 9: Final summary

Report to the user:

- Detected language / build system / manifest files.
- Proposed vs. requested version.
- Target `{os × arch}` matrix.
- Files modified (changelog, notes, manifests, workflow).
- CI workflow-file outcome (generate / audit / skipped) and report path if audit ran.
- Publish mode outcome: whether the release was published (applied with `--confirm`),
  previewed only (print-only via `--publish` without `--confirm`), or emit-only
  (no `--publish` flag).
- Release CI loop outcome (if `--ci` was set): `green` (final status), `bail-*`
  (with reason and cap that fired), `loop-blocked`, `declined`, or `skipped` (no
  successful publish). Include the audit log path so the user can inspect it.
- The exact command block from Phase 8.

## Important Notes

- **Never auto-commits, pushes, or publishes.** The user reviews every change and runs
  the emitted commands manually. This is the same discipline as `bundle-release`.
- **Publish helper = operator workflow, not a guardrail.** `publish-release.sh` runs in
  print-only mode by default: it prints the resolved `gh` command (including
  `--verify-tag` for creates) and exits successfully. The operator reviews that line,
  then re-runs the same invocation with `--confirm` when they intend to publish.
  The script sets an internal confirm flag only when `--confirm` is passed; without
  it, no mutating `gh` call runs.
- **`--dry-run` beats `--publish`.** If both flags are present, the publish helper does
  not run. Dry-run always exits before any side-effecting step.
- **Never edits files outside the detected `manifest_files` list.** If the repo has
  unusual version ownership (e.g. a `VERSION` file, a `_version.py`, multi-package
  workspaces), add it to the list via `--platform=generic` and the user confirms
  before edit.
- **Never regenerates third-party lockfiles as a side effect.** If `package.json` bumps
  require `package-lock.json`, the skill instructs the user to run the lockfile command
  themselves and surfaces any drift.
- **CI generation is opinionated, not magic.** The templates are starting points; the
  skill calls out which inputs require human configuration (secrets, environments,
  signing keys, provenance) before the workflow will run green.
- For existing CI workflow files, always prefer `--ci-config=audit` first. Do not
  overwrite a working workflow without the user's explicit confirmation.
- **`--ci` (Phase 8.5) is opt-in and post-publish.** It enters only after
  `--publish --confirm` has actually created/edited the release on GitHub. The
  authorization gate (8.5.1) cannot be bypassed except with `--ci-yes`, and the
  destructive re-cut fallback cannot be reached except with `--ci-recut=destructive`.
- **The release-CI loop never edits release notes or manifest files.** It only
  touches files implicated by the failed workflow step. Notes and manifests are
  considered immutable for the lifetime of the loop.
- See `references/project-type-matrix.md` for the full language → toolchain map.
- See `references/ci-optimization-checklist.md` for the audit criteria used by the
  agent and the default quality gate for generated workflows.
- See `references/release-notes-template.md` for the drafted notes format.
- See [`../_shared/references/ci-monitoring.md`](../_shared/references/ci-monitoring.md)
  ("Release mode" section) for the loop contract, exit-code table, and audit-log
  schema.
