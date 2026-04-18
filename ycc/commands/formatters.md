---
description: Bootstrap a best-practices lint/format environment — installs a self-contained scripts/style.sh bundle, per-language tool configs, runnable aliases (package.json/Makefile/justfile), README docs, and optionally CI + pre-commit hooks.
argument-hint: '[--dry-run] [--force] [--yes] [--sync] [--copy] [--ci] [--hooks] [--no-aliases] [--no-docs] [--target=<dir>] [--profile=<lang>] [--rust] [--ts] [--python] [--go] [--docs] [--shell] [--all]'
---

Bootstrap a best-practices lint/format environment into a target project. Detects the language stack, installs a self-contained `scripts/style.sh` bundle, drops tool configs, injects runnable aliases, updates docs, and optionally wires CI and pre-commit hooks.

Invoke the **formatters** skill to:

- Profile the target — detect Rust / Go / TS / Python / Docs / Shell stacks and existing configs.
- Install the bundle — copy `scripts/style.sh`, `format.sh`, `lint.sh`, `init-formatters.sh`, `go-tools.sh`, `lib/modified-files.sh`, and `templates/*` into the target's `scripts/` directory.
- Drop per-language configs — `rustfmt.toml`, `clippy.toml`, `.golangci.yml`, `biome.json`, `tsconfig.json`, `pyproject.toml` (Ruff + Black), `.markdownlint.json`, `.prettierrc`, etc. Refuses to overwrite user-authored configs unless `--force`.
- Inject runnable aliases — `package.json` scripts when Node is present; otherwise Makefile or justfile (Node never forced).
- Update docs — append a `## Linting & Formatting` section to `README.md` (or `CONTRIBUTING.md` / `AGENTS.md` / `CLAUDE.md` in that precedence).
- (Optional) Emit `.github/workflows/lint.yml` with `--ci`.
- (Optional) Wire a pre-commit hook (lefthook preferred, husky if detected) with `--hooks`.

Idempotent via a managed `.style-bundle-manifest`: re-running with `--sync` prunes stale managed files and refreshes the bundle.

## Common invocations

| Command                                                  | Effect                                                                         |
| -------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `/ycc:formatters`                                        | Auto-detect stacks and bootstrap the current project.                          |
| `/ycc:formatters --dry-run`                              | Preview every planned change without writing any files.                        |
| `/ycc:formatters --sync`                                 | Re-run after a prior install; prune stale managed files.                       |
| `/ycc:formatters --ci --hooks`                           | Also emit `.github/workflows/lint.yml` and wire a pre-commit hook.             |
| `/ycc:formatters --no-aliases --no-docs`                 | Install scripts and configs only; skip package.json/Makefile and README edits. |
| `/ycc:formatters --target=~/projects/app --profile=rust` | Bootstrap a different directory with a forced Rust profile.                    |
| `/ycc:formatters --all --force --yes`                    | Non-interactive full install regardless of detection (CI-friendly).            |

## Flags

| Flag                                                           | Effect                                                                  |
| -------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `--dry-run`                                                    | Print planned changes; write nothing.                                   |
| `--force`                                                      | Overwrite existing tool configs / aliases / docs without prompting.     |
| `--yes`                                                        | Non-interactive; keep existing files on conflict.                       |
| `--sync`                                                       | Install bundle + prune stale managed files (preferred on re-run).       |
| `--copy`                                                       | Install bundle without pruning (default when no manifest exists).       |
| `--ci`                                                         | Also emit `.github/workflows/lint.yml`.                                 |
| `--hooks`                                                      | Also wire a pre-commit hook (lefthook preferred, husky if detected).    |
| `--no-aliases`                                                 | Skip package.json / Makefile / justfile alias injection.                |
| `--no-docs`                                                    | Skip README section append.                                             |
| `--target=<dir>`                                               | Target directory (default: `$PWD`).                                     |
| `--profile=<lang>`                                             | Override detection: `rust`, `ts-node`, `python`, `go`, `docs`, `mixed`. |
| `--rust` / `--ts` / `--python` / `--go` / `--docs` / `--shell` | Enable specific stack(s); suppresses auto-detection.                    |
| `--all`                                                        | Install every supported stack's configs regardless of detection.        |

See `${CLAUDE_PLUGIN_ROOT}/skills/formatters/references/flag-reference.md` for the full matrix and precedence rules, and `best-practices.md` for per-language tool rationale.

Pass `$ARGUMENTS` through to the skill.
