# Flag Reference

Detailed reference for every flag accepted by `init`. See also `SKILL.md` for the live phase logic.

---

## Flag Matrix

| Flag               | Default     | Affects phases | Writes to                                                                                                                                               | Example                     |
| ------------------ | ----------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------- |
| `--dry-run`        | off         | 5 (halt)       | nothing                                                                                                                                                 | `init --dry-run`        |
| `--docs-only`      | off         | 2, 4 (skip)    | `AGENTS.md`, `AGENTS.md`, `.cursor/rules/project.mdc`                                                                                                   | `init --docs-only`      |
| `--templates`      | off         | 3 (extend)     | `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md`, `.github/labels.md`, `.github/copilot-instructions.md`, `.github/workflows/pr-title.yml`, `.github/workflows/pr-title-autofix.yml` | `init --templates`      |
| `--git`            | off         | 3 (extend)     | `.gitmessage`, `commitlint.config.cjs` (JS/TS only), `lefthook.yml`, `scripts/install-lefthook.sh`, `docs/lefthook-usage.md`                            | `init --git`            |
| `--vendor-neutral` | off         | 3 (extend)     | `.ai/rules/project.md`                                                                                                                                  | `init --vendor-neutral` |
| `--formatters`     | off         | 6.5 (delegate) | (delegates to `formatters` — see its flag matrix)                                                                                                   | `init --formatters`     |
| `--update`         | off         | 6 (merge)      | existing targets only                                                                                                                                   | `init --update`         |
| `--force`          | off         | 6 (overwrite)  | all target files                                                                                                                                        | `init --force`          |
| `--profile=<name>` | auto-detect | 1 (skip)       | (drives template variables)                                                                                                                             | `init --profile=rust`   |

### `--profile` accepted values

| Value     | Skips detection? | Effect                                                              |
| --------- | ---------------- | ------------------------------------------------------------------- |
| `rust`    | yes              | Sets `PRIMARY_LANG=rust`, `BUILD_CMD=cargo build`                   |
| `ts-node` | yes              | Sets `PRIMARY_LANG=typescript`, `PACKAGE_MANAGER=npm/pnpm/yarn/bun` |
| `python`  | yes              | Sets `PRIMARY_LANG=python`                                          |
| `go`      | yes              | Sets `PRIMARY_LANG=go`, `BUILD_CMD=go build ./...`                  |
| `mixed`   | yes              | Sets primary + secondary from manifest count                        |
| `empty`   | yes              | Triggers name/purpose/language prompts                              |

---

## Per-Flag Examples

### `--dry-run`

Preview everything without writing a single file. Combines with any other flag.

```
/init --dry-run
/init --dry-run --templates --git
```

Output: a table of planned files with their rendered content previewed inline.

### `--docs-only`

Emit only the doc trio; skip MCP/agent selection (phase 4) and profiler agent dispatch (phase 2).

```
/init --docs-only
/init --docs-only --profile=go
```

### `--templates`

Adds the full GitHub templates bundle. Extends the default run or combines with `--docs-only`:

- `.github/ISSUE_TEMPLATE/bug_report.yml`, `feature_request.yml`,
  `docs_request.yml`, `config.yml` — YAML issue forms
- `.github/pull_request_template.md` — PR template with a required-check
  preamble pointing at the PR-title workflow and copilot instructions
- `.github/labels.md` — reference list of the project's label taxonomy
  (`gh label create` commands included)
- `.github/copilot-instructions.md` — PR-workflow essentials restated for
  GitHub Copilot's coding agent (points at `AGENTS.md` / `AGENTS.md` for
  canonical rules)
- `.github/workflows/pr-title.yml` — required GitHub Actions check that
  validates PR titles as Conventional Commits and rejects placeholder
  prefixes (`[WIP]`, `Draft:`, `Initial plan`) that agents often open PRs
  with. Enable as a required status check in branch protection — see the
  `--templates` next-step emitted at end of `init`.
- `.github/workflows/pr-title-autofix.yml` — runs alongside the validator
  and strips placeholder prefixes server-side using the repo's
  `GITHUB_TOKEN`, then toggles the PR to draft. Exists because GitHub
  Copilot's coding-agent token typically lacks `pull_requests:write` and
  cannot fix its own title after the instructions file has been ignored.
  Not a required check — it is an auto-correcting side effect.

```
/init --templates
/init --docs-only --templates
```

### `--git`

Adds the full git-conventions bundle:

- `.gitmessage` (always) — Conventional Commits template. Wire with
  `git config commit.template .gitmessage`.
- `commitlint.config.cjs` (JS/TS ecosystems only) — enforced via the
  lefthook `commit-msg` hook below.
- `lefthook.yml` (always) — git hook manager config with stack-specific
  pre-commit lint/format commands (staged scope), a `pre-push` test stage,
  and a commitlint `commit-msg` stage on JS/TS projects.
- `scripts/install-lefthook.sh` (always) — idempotent, cross-platform
  bootstrap. Installs the `lefthook` binary and runs `lefthook install`.
- `docs/lefthook-usage.md` (always) — reference doc explaining what the
  hooks do, how to extend them, how to bypass, and how they skip in CI.

```
/init --git
/init --git --profile=ts-node
```

### `--vendor-neutral`

Add `.ai/rules/project.md` — a plain-markdown mirror of the Cursor `.mdc` rule body with no frontmatter.

```
/init --vendor-neutral
```

### `--update`

Structured refresh of existing artifacts. Never clobbers user content — merges instead.

- `AGENTS.md`: append template sections that are missing; preserve everything else verbatim.
- `AGENTS.md`: refresh pointer text, preserve custom `## Agent-runtime notes`. If the existing file is custom (long, no AGENTS.md reference), asks to migrate.
- `.cursorrules` (legacy): migrate to `.cursor/rules/project.mdc`; leaves the old file for you to delete.
- `.github/ISSUE_TEMPLATE/*.yml`: create missing templates; skip existing ones with a diff (pair with `--force` to overwrite).
- `.github/labels.md`, `docs/lefthook-usage.md`, `scripts/install-lefthook.sh`: always overwritten (managed reference docs / tooling).
- `commitlint.config.cjs`: diff + skip by default (often customized). Pair with `--force` to overwrite.
- `lefthook.yml`: diff + skip by default (users often extend the config). Pair with `--force` to overwrite.

```
/init --update
/init --update --docs-only
/init --update --force --templates
```

### `--force`

Overwrite existing files without prompting. Default behavior diffs and asks; never silently clobbers. Compose with `--update` to bias merges toward overwrite on conflict.

```
/init --force --docs-only
/init --update --force
```

### `--profile=<name>`

Pre-set the project profile, bypassing `profile-project.sh` detection entirely.

```
/init --profile=python --templates --git
```

---

## Composition Rules

Flags are independent and composable. Any combination is valid:

- `--dry-run` is always safe — it suppresses all writes regardless of other flags.
- `--docs-only` narrows scope; adding `--templates` or `--git` extends it back out.
- `--force` applies to every output flag in the same invocation.
- `--profile=` and detection are mutually exclusive; `--profile=` wins.
- Unrecognised flags are reported as errors before any phase runs.

### Common combinations

| Combination                            | Result                                                                    |
| -------------------------------------- | ------------------------------------------------------------------------- |
| `--docs-only --templates --git`        | Full doc/workflow bundle, no MCP/agent touch                              |
| `--dry-run --templates`                | Preview only the template output                                          |
| `--force --profile=python --templates` | Apply Python doc set + GitHub forms, overwrite freely                     |
| `--docs-only --vendor-neutral`         | Doc trio + `.ai/rules/project.md`, skip MCP                               |
| `--update`                             | Refresh existing doc trio in place; skip untouched files                  |
| `--update --force --templates`         | Refresh everything aggressively — merge semantics + overwrite on conflict |

---

See also: [`project-profile-heuristics.md`](project-profile-heuristics.md), [`template-library.md`](template-library.md).
