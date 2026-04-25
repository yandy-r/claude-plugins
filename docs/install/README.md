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

Use `install.sh` from the repository root:

```bash
./install.sh --target <claude|cursor|codex|opencode|all> [flags]
```

The installer is organized by target and step. Without `--only`, the target's
`base` step runs by default, and additive flags run additional steps.

| Step       | Meaning                                                                                                                          |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `base`     | Install or register the target's native bundle surface.                                                                          |
| `settings` | Copy per-machine config files. Existing real files are protected unless `--force` is passed.                                     |
| `rules`    | Symlink shared rule files so rule edits flow across runtimes. Existing real rule files are protected unless `--force` is passed. |
| `mcp`      | Configure MCP where the target has a separate MCP step.                                                                          |
| `hooks`    | Claude-only hook setup, including the worktree redirect hook.                                                                    |

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
