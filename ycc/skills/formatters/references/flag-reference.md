# Flag Reference

Detailed reference for every flag accepted by `ycc:formatters`. See `SKILL.md` for live phase logic.

---

## Flag Matrix

| Flag               | Default     | Affects phases   | Writes to                                                       | Example                                  |
| ------------------ | ----------- | ---------------- | --------------------------------------------------------------- | ---------------------------------------- |
| `--dry-run`        | off         | 3 (halt)         | nothing                                                         | `ycc:formatters --dry-run`               |
| `--force`          | off         | 4, 5 (overwrite) | all target files                                                | `ycc:formatters --force`                 |
| `--yes`            | off         | 3 (skip prompt)  | existing files preserved                                        | `ycc:formatters --yes`                   |
| `--sync`           | auto        | 4 (prune)        | `scripts/` bundle + removes stale managed files                 | `ycc:formatters --sync`                  |
| `--copy`           | on          | 4 (install)      | `scripts/` bundle                                               | `ycc:formatters --copy`                  |
| `--ci`             | off         | 5 (extend)       | `.github/workflows/lint.yml`                                    | `ycc:formatters --ci`                    |
| `--hooks`          | off         | 5 (extend)       | `lefthook.yml` or `.husky/pre-commit`                           | `ycc:formatters --hooks`                 |
| `--no-aliases`     | off         | 5 (skip)         | (suppresses package.json / Makefile / justfile alias injection) | `ycc:formatters --no-aliases`            |
| `--no-docs`        | off         | 5 (skip)         | (suppresses README section append)                              | `ycc:formatters --no-docs`               |
| `--target=<dir>`   | `$PWD`      | 1 (override)     | configs + scripts land in `<dir>`                               | `ycc:formatters --target=~/projects/app` |
| `--profile=<lang>` | auto-detect | 1 (override)     | (forces stack flags)                                            | `ycc:formatters --profile=rust`          |
| `--rust`           | auto        | 4 (enable)       | `rustfmt.toml`, `clippy.toml`                                   | `ycc:formatters --rust`                  |
| `--ts`             | auto        | 4 (enable)       | `biome.json`, `tsconfig.json`, `package.json` (scaffold only)   | `ycc:formatters --ts`                    |
| `--python`         | auto        | 4 (enable)       | `pyproject.toml` (scaffold only; refuses to overwrite)          | `ycc:formatters --python`                |
| `--go`             | auto        | 4 (enable)       | `.golangci.yml`                                                 | `ycc:formatters --go`                    |
| `--docs`           | auto        | 4 (enable)       | `.markdownlint.json`, `.prettierrc`, `.prettierignore`          | `ycc:formatters --docs`                  |
| `--shell`          | auto        | 4 (enable)       | (bundled scripts; no separate config emitted)                   | `ycc:formatters --shell`                 |
| `--all`            | off         | 4 (enable all)   | every stack regardless of detection                             | `ycc:formatters --all`                   |

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
ycc:formatters --dry-run
ycc:formatters --dry-run --ci --hooks
```

### `--force`

Non-interactive overwrite. Required when running in CI or over existing user-authored configs.

```
ycc:formatters --force --yes
```

### `--sync`

Re-run after a prior install. Prunes managed files that were removed from the upstream bundle. Safe to run periodically.

```
ycc:formatters --sync
```

### `--ci`

Emit `.github/workflows/lint.yml`. Skipped when the file already exists unless `--force` is also passed.

```
ycc:formatters --ci
ycc:formatters --ci --force
```

### `--hooks`

Wire a pre-commit hook via lefthook (default) or husky (if `.husky/` is detected). Always prints a `git commit --no-verify` escape reminder.

```
ycc:formatters --hooks
```

### `--no-aliases` / `--no-docs`

Opt out of the post-install sugar. Useful when the target project already has a custom Makefile or docs pipeline.

```
ycc:formatters --no-aliases
ycc:formatters --no-aliases --no-docs
```

### `--target=<dir>`

Install into a directory other than `$PWD`. The directory must exist and should be a git repo (hooks refuse otherwise).

```
ycc:formatters --target=~/projects/new-app
```

### `--profile=<lang>`

Skip detection entirely and force a stack set. Useful when auto-detection picks up vendored files.

```
ycc:formatters --profile=rust
ycc:formatters --profile=mixed --target=./monorepo
```

### Per-stack flags (`--rust`, `--ts`, `--python`, `--go`, `--docs`, `--shell`)

Enable one or more specific stacks explicitly. When any per-stack flag is passed, auto-detection is suppressed and only the named stacks run.

```
ycc:formatters --rust --go
ycc:formatters --ts --docs
```

### `--all`

Install configs for every supported stack regardless of detection. Useful for template repos or scaffolding an empty project ahead of code.

```
ycc:formatters --all
```
