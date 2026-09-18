# opencode Install Guide

opencode support is native. The generated bundle installs skills, agents,
commands, config, and rules into `~/.config/opencode/`.

## Quick Start

From the repository root:

```bash
./install.sh --target opencode
```

The default `base` step generates, validates, formats, and rsyncs the opencode
bundle into `~/.config/opencode/`.

Restart opencode after installing or updating the bundle.

## Add Settings And Rules

For the full opencode setup:

```bash
./install.sh sync --target opencode --intent base,settings,mcp,plugins,rules
```

The legacy equivalent remains supported:

```bash
./install.sh --target opencode --settings --rules
```

Step behavior:

| Step       | Effect                                                                                                                                     |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `base`     | Generates and validates `.opencode-plugin/{skills,agents,commands}/`, then rsyncs them into `~/.config/opencode/`.                         |
| `settings` | Merges managed keys from `.opencode-plugin/opencode.json` into `~/.config/opencode/opencode.json`. MCP and plugins live in this same file. |
| `rules`    | Symlinks `.opencode-plugin/AGENTS.md` into `~/.config/opencode/AGENTS.md`.                                                                 |

opencode reads MCP configuration from `opencode.json`; there is no separate
`mcp` step for this target.

## Plugins

The generated `opencode.json` declares the bundle's shared OpenCode V2 plugins in
`plugins`:

| Plugin                                | Purpose                                                                      |
| ------------------------------------- | ---------------------------------------------------------------------------- |
| `@prevalentware/opencode-goal-plugin` | Goal mode — `/goal` commands, persistent goal state, and the goal tool suite |

`--settings` installs the server-side half. The TUI half (sidebar goal indicator
and command-palette entry) is read from the global `~/.config/opencode/cli.json`,
which this repository does not manage. Install both halves on a new machine with:

```bash
./install.sh --target opencode --settings --rules
opencode2 plugin add @prevalentware/opencode-goal-plugin
```

`opencode2 plugin add` writes the package into `~/.config/opencode/opencode.json`
and `~/.config/opencode/cli.json`, and is idempotent. Verify with
`opencode2 plugin list`. Use `opencode` instead of `opencode2` when the V2 binary
is installed under that name.

## Selective Steps

Use `--only` to run exactly the listed steps:

```bash
./install.sh --target opencode --only base
./install.sh --target opencode --only settings
./install.sh --target opencode --only rules
./install.sh --target opencode --only settings,rules
```

`--mode repo` is not supported for opencode. opencode reads files from local
config directories, so use the default local mode.

## Installed Surfaces

| Surface        | Location                           |
| -------------- | ---------------------------------- |
| Skills         | `~/.config/opencode/skills/`       |
| Agents         | `~/.config/opencode/agents/`       |
| Commands       | `~/.config/opencode/commands/`     |
| Config and MCP | `~/.config/opencode/opencode.json` |
| Rules          | `~/.config/opencode/AGENTS.md`     |

Invoke skills with the built-in `skill` tool, agents with `@agent-name` mentions
or the built-in `task` tool, and commands as `/<name>` in the TUI.

## Model Configuration

The generated `opencode.json` sets the bundle's main model, its reasoning
effort, and a `#subagent` variant carrying the sub-agent reasoning effort. The
built-in `general` and `explore` subagents are pinned to that variant so
delegated work runs at sub-agent effort.

**These values are placeholders.** Unlike Claude and Codex, opencode's usable
catalog depends on which provider subscriptions and models you have configured,
so the bundle ships a portable default rather than a fixed model. Change the
preferred models in [`ycc/settings/models.json`](../../ycc/settings/models.json)
(`targets.opencode`), or simply edit your own
`~/.config/opencode/opencode.json` — the merge keeps local model choices and
provider credentials instead of overwriting them.

## Hooks

opencode hook guidance is advisory in this bundle. opencode lifecycle hooks
require a TypeScript plugin module, which `ycc` does not ship currently.

## Regenerate Only opencode Artifacts

After editing source files under `ycc/`, regenerate opencode artifacts directly
or through the unified sync script:

```bash
./scripts/sync.sh --only opencode
./scripts/validate.sh --only opencode
```
