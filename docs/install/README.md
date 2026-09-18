# Install Guides

This directory contains the runtime-specific install guides for `ycc`. The root
[`README.md`](../../README.md) stays short and links here instead of duplicating
every target's installer behavior.

## Runtime Guides

| Runtime  | Guide                        | Best for                                                                   |
| -------- | ---------------------------- | -------------------------------------------------------------------------- |
| Claude   | [`claude.md`](claude.md)     | Claude Code plugin installs, Claude rules/config, Claude Desktop MCP setup |
| Cursor   | [`cursor.md`](cursor.md)     | Cursor-native skills, agents, rules, and MCP sync                          |
| Codex    | [`codex.md`](codex.md)       | Codex plugin installs, custom agents, Codex Desktop setup                  |
| opencode | [`opencode.md`](opencode.md) | opencode-native skills, agents, commands, config, and rules                |

## Installer Model

Use `install.sh` from the repository root. The `sync` subcommand is the
recommended entry point:

```bash
./install.sh sync --target <claude|cursor|codex|opencode|all> --intent <intents>
```

You say **what** you want synced; each target maps the intent onto the steps it
actually supports, and reports (rather than silently substitutes) anything it
cannot do.

```bash
./install.sh sync --target claude --intent hooks,settings,mcp,plugins
./install.sh sync --target all --intent settings,rules
./install.sh sync --target codex --intent settings,mcp
```

| Intent     | Meaning                                                                                    |
| ---------- | ------------------------------------------------------------------------------------------ |
| `base`     | Install or register the target's native bundle surface.                                    |
| `settings` | Merge repo-managed config keys (models, effort levels, statusline, ...).                   |
| `rules`    | Symlink shared rule files so rule edits flow across runtimes.                              |
| `mcp`      | Merge MCP server definitions into the target's MCP surface.                                |
| `hooks`    | Merge hook configuration; Claude also links the hook scripts directory.                    |
| `plugins`  | Merge plugin enablement and marketplace entries. Add `base` for CLI-side registration too. |

Per-target mapping (intents a target cannot execute are skipped with a notice):

| Intent     | claude             | cursor     | codex      | opencode   |
| ---------- | ------------------ | ---------- | ---------- | ---------- |
| `base`     | `base`             | `base`     | `base`     | `base`     |
| `settings` | `settings`         | `settings` | `settings` | `settings` |
| `rules`    | `rules`            | `rules`    | `rules`    | `rules`    |
| `mcp`      | `mcp`              | `mcp`      | `settings` | `settings` |
| `hooks`    | `settings`+`hooks` | no-op      | no-op      | no-op      |
| `plugins`  | `settings`         | no-op      | `settings` | `settings` |

`sync` is exclusive: it never implicitly runs `base`.

### Merge Semantics

Structured config files (`~/.claude/settings.json`, `~/.claude.json`,
`~/.codex/config.toml`, `~/.config/opencode/opencode.json`,
`~/.cursor/cli-config.json`) are **merged**, not copied:

- Only keys this repository declares as managed are written; every other key
  in your file is preserved.
- A managed value the installer previously wrote is updated automatically on
  later runs.
- A managed value **you** changed is preserved with a warning; `--force` takes
  the repo value instead.
- Ownership is tracked by hash in `~/.config/ycc/managed-config-state.json`
  (hashes only, never values, so tokens never leak into state).

This is what makes new-machine setup reliable: run the same `sync` command on
any machine and repo-managed settings land without clobbering machine-local
trusted projects, provider credentials, or CLI-written marketplace entries.

### Legacy Flag Form

The original flag CLI keeps working unchanged:

```bash
./install.sh --target <claude|cursor|codex|opencode|all> [flags]
```

Without `--only`, the target's `base` step runs by default, and additive flags
run additional steps.

Common flags:

```bash
./install.sh --target claude --settings --rules --mcp --hooks
./install.sh --target cursor --rules --mcp
./install.sh --target codex --settings --rules
./install.sh --target opencode --settings --rules
./install.sh --target all --settings --rules --mcp
```

Use `--only <steps>` to run exactly the listed steps and skip the default `base`
step:

```bash
./install.sh --target claude --only rules
./install.sh --target codex --only settings,rules
```

## Source Modes

`--mode local` is the default. It registers or syncs the current checkout so
contributors can iterate locally.

`--mode repo` registers the upstream GitHub repository instead of the local
checkout. It is supported by the `claude` and `codex` targets only:

```bash
./install.sh --target claude --mode repo
./install.sh --target codex --mode repo
./install.sh --target all --mode repo
```

With `--target all --mode repo`, Cursor and opencode are skipped because they do
not have a remote-source install surface.

## Regenerate And Validate

When editing source-of-truth files under `ycc/`, regenerate derived bundles and
validate them before committing:

```bash
./scripts/sync.sh
./scripts/validate.sh
```

Both scripts accept `--only <targets>` for narrower runs, such as
`./scripts/sync.sh --only codex`.
