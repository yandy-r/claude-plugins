---
name: releaser
description: This skill should be used when the user asks to "prepare a release",
  "cut a release", "tag a release", "create a GitHub release", "draft release notes",
  "set up release CI", "add a release workflow", or "audit release pipeline" for any
  project. Detects language/toolchain, drafts a changelog, plans platform/arch artifacts,
  optionally generates or audits GitHub Actions release CI, and emits the exact commands
  the user runs to tag and publish. Never auto-commits, pushes, or publishes. Generic
  external-project counterpart to `bundle-release` (which is scoped to this repo's
  ycc bundle).
---

# Generic Release Orchestrator

This skill prepares a release for **any** project: detects the toolchain, drafts a
changelog from conventional commits, plans platform/architecture artifacts, and — on
request — either generates a GitHub Actions release workflow or audits an existing one
against best practices. It emits the exact `git tag`, `git push`, and `gh release
create` commands the user runs; it never commits, pushes, or publishes on its own.

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
- **--ci** / **--ci=generate** — scaffold a GitHub Actions release workflow under
  `.github/workflows/release.yml`. Fails if one already exists unless `--ci=audit` is
  also requested.
- **--ci=audit** — invoke the `releaser` agent to read the existing release
  workflow(s) and emit an optimization report. Read-only.
- **--platform=\<name\>** — explicit toolchain override (`node`, `python`, `go`, `rust`,
  `docker`, `generic`). Skips auto-detection. Useful for monorepos.
- **--skip-notes** — skip drafting `CHANGELOG` updates and release notes.
- **--dry-run** — run detection and print the full release plan. Writes nothing,
  executes no state-changing commands.

## Phase 0: Preflight

Before anything else, verify:

1. Working directory is a git repo: `git rev-parse --show-toplevel` succeeds.
2. Working tree is clean: `git status --porcelain` is empty. If dirty, STOP and ask
   whether to stash or abort — never silently move forward with uncommitted changes.
3. `gh` is installed and authenticated when `--ci` is absent but the user asked for a
   GitHub release. Surface install/login hints if missing.
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

1. Invoke:

   ```
   ~/.config/opencode/skills/releaser/scripts/draft-changelog.sh <new-version>
   ```

   The helper writes grouped, conventional-commit-based Markdown to stdout
   (sections: **Features**, **Fixes**, **Breaking Changes**, **Docs**, **Chore**).

2. Update the project's changelog file in place. Supported layouts:
   - `CHANGELOG.md` with `## [Unreleased]` section → insert a new dated entry above it.
   - `CHANGELOG.md` with no `Unreleased` marker → prepend a new entry under the title.
   - No `CHANGELOG.md` → create one seeded from
     `~/.config/opencode/skills/releaser/references/release-notes-template.md`.
3. Write `docs/releases/<new-version>.md` (or `.github/releases/<version>.md` if the
   repo already uses that path) using the same template. This is the body that the
   emitted `gh release create` command consumes.

Ask the user to review the drafted Summary and Upgrade Notes sections before moving on.

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

## Phase 6: CI pipeline (optional)

Three modes:

### --ci=generate

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

### --ci=audit

Delegate to the `releaser` agent. Pass it the list of existing workflow files. The
agent returns a structured report (Findings → Severity → Fix). The skill summarizes the
top items and writes the full report to `docs/prps/reviews/ci-release-audit.md` for
later consumption by `review-fix`.

### No --ci flag

Skip Phase 6 entirely. Print a one-line reminder: "Skipped CI. Run with `--ci=generate`
or `--ci=audit` to include it."

## Phase 7: Dry-run check

If `--dry-run` was passed:

1. Print the full release plan: detected project, proposed version, target matrix,
   files that would change, commands that would run.
2. STOP. Write nothing, execute nothing side-effecting.

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

If `--ci=generate` ran, append:

```
# Verify the new workflow in CI by pushing the tag — the release workflow will
# build the matrix and attach artifacts to the GitHub release.
```

## Phase 9: Final summary

Report to the user:

- Detected language / build system / manifest files.
- Proposed vs. requested version.
- Target `{os × arch}` matrix.
- Files modified (changelog, notes, manifests, workflow).
- CI mode outcome (generate / audit / skipped) and report path if audit ran.
- The exact command block from Phase 8.

## Important Notes

- **Never auto-commits, pushes, or publishes.** The user reviews every change and runs
  the emitted commands manually. This is the same discipline as `bundle-release`.
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
- For existing CI, always prefer `--ci=audit` first. Do not overwrite a working
  workflow without the user's explicit confirmation.
- See `references/project-type-matrix.md` for the full language → toolchain map.
- See `references/ci-optimization-checklist.md` for the audit criteria used by the
  agent and the default quality gate for generated workflows.
- See `references/release-notes-template.md` for the drafted notes format.
