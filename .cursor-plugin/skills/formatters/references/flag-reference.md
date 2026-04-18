# Flag Reference

Detailed reference for every flag accepted by `formatters`. See `SKILL.md` for live phase logic.

---

## Flag Matrix

| Flag               | Default     | Affects phases   | Writes to                                                       | Example                                  |
| ------------------ | ----------- | ---------------- | --------------------------------------------------------------- | ---------------------------------------- |
| `--dry-run`        | off         | 3 (halt)         | nothing                                                         | `formatters --dry-run`               |
| `--force`          | off         | 4, 5 (overwrite) | all target files                                                | `formatters --force`                 |
| `--yes`            | off         | 3 (skip prompt)  | existing files preserved                                        | `formatters --yes`                   |
| `--sync`           | auto        | 4 (prune)        | `scripts/` bundle + removes stale managed files                 | `formatters --sync`                  |
| `--copy`           | on          | 4 (install)      | `scripts/` bundle                                               | `formatters --copy`                  |
| `--ci`             | off         | 5 (extend)       | `.github/workflows/lint.yml`                                    | `formatters --ci`                    |
| `--hooks`          | off         | 5 (extend)       | `lefthook.yml` or `.husky/pre-commit`                           | `formatters --hooks`                 |
| `--no-aliases`     | off         | 5 (skip)         | (suppresses package.json / Makefile / justfile alias injection) | `formatters --no-aliases`            |
| `--no-docs`        | off         | 5 (skip)         | (suppresses README section append)                              | `formatters --no-docs`               |
| `--target=<dir>`   | `$PWD`      | 1 (override)     | configs + scripts land in `<dir>`                               | `formatters --target=~/projects/app` |
| `--profile=<lang>` | auto-detect | 1 (override)     | (forces stack flags)                                            | `formatters --profile=rust`          |
| `--rust`           | auto        | 4 (enable)       | `rustfmt.toml`, `clippy.toml`                                   | `formatters --rust`                  |
| `--ts`             | auto        | 4 (enable)       | `biome.json`, `tsconfig.json`, `package.json` (scaffold only)   | `formatters --ts`                    |
| `--python`         | auto        | 4 (enable)       | `pyproject.toml` (scaffold only; refuses to overwrite)          | `formatters --python`                |
| `--go`             | auto        | 4 (enable)       | `.golangci.yml`                                                 | `formatters --go`                    |
| `--docs`           | auto        | 4 (enable)       | `.markdownlint.json`, `.prettierrc`, `.prettierignore`          | `formatters --docs`                  |
| `--shell`          | auto        | 4 (enable)       | (bundled scripts; no separate config emitted)                   | `formatters --shell`                 |
| `--all`            | off         | 4 (enable all)   | every stack regardless of detection                             | `formatters --all`                   |

### Flag precedence

1. `--profile=<lang>` **and** explicit stack flags (`--rust`, `--ts`, …) override auto-detection entirely.
2. `--all` is shorthand for every per-stack flag; it does not override `--no-aliases` or `--no-docs`.
3. `--force` implies `--yes`; `--yes --force` are both accepted for clarity.
4. `--sync` and `--copy` are mutually exclusive. If neither is passed, `--sync` is chosen when `has_style_bundle=true`, otherwise `--copy`.
5. `--dry-run` wins over everything: the phase runs for reporting only, no writes.

### `--profile` accepted values

| Value     | Skips detection? | Effect                                                          |
| --------- | ---------------- | --------------------------------------------------------------- |
| `rust`    | yes              | Forces `--rust`                                                 |
| `ts-node` | yes              | Forces `--ts` and `--docs`                                      |
| `python`  | yes              | Forces `--python`                                               |
| `go`      | yes              | Forces `--go`                                                   |
| `docs`    | yes              | Forces `--docs` only (useful for pure-docs repos)               |
| `mixed`   | yes              | Forces every stack whose matching manifest exists in the target |

---

## Per-Flag Examples

### `--dry-run`

Preview everything without writing. Combines with any other flag.

```
formatters --dry-run
formatters --dry-run --ci --hooks
```

### `--force`

Non-interactive overwrite. Required when running in CI or over existing user-authored configs.

```
formatters --force --yes
```

### `--sync`

Re-run after a prior install. Prunes managed files that were removed from the upstream bundle. Safe to run periodically.

```
formatters --sync
```

### `--ci`

Emit `.github/workflows/lint.yml`. Skipped when the file already exists unless `--force` is also passed.

```
formatters --ci
formatters --ci --force
```

### `--hooks`

Wire a pre-commit hook via lefthook (default) or husky (if `.husky/` is detected). Always prints a `git commit --no-verify` escape reminder.

```
formatters --hooks
```

### `--no-aliases` / `--no-docs`

Opt out of the post-install sugar. Useful when the target project already has a custom Makefile or docs pipeline.

```
formatters --no-aliases
formatters --no-aliases --no-docs
```

### `--target=<dir>`

Install into a directory other than `$PWD`. The directory must exist and should be a git repo (hooks refuse otherwise).

```
formatters --target=~/projects/new-app
```

### `--profile=<lang>`

Skip detection entirely and force a stack set. Useful when auto-detection picks up vendored files.

```
formatters --profile=rust
formatters --profile=mixed --target=./monorepo
```

### Per-stack flags (`--rust`, `--ts`, `--python`, `--go`, `--docs`, `--shell`)

Enable one or more specific stacks explicitly. When any per-stack flag is passed, auto-detection is suppressed and only the named stacks run.

```
formatters --rust --go
formatters --ts --docs
```

### `--all`

Install configs for every supported stack regardless of detection. Useful for template repos or scaffolding an empty project ahead of code.

```
formatters --all
```
