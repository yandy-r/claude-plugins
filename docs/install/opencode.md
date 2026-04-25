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
./install.sh --target opencode --settings --rules
```

Step behavior:

| Step       | Effect                                                                                                             |
| ---------- | ------------------------------------------------------------------------------------------------------------------ |
| `base`     | Generates and validates `.opencode-plugin/{skills,agents,commands}/`, then rsyncs them into `~/.config/opencode/`. |
| `settings` | Copies `.opencode-plugin/opencode.json` into `~/.config/opencode/opencode.json`.                                   |
| `rules`    | Symlinks `.opencode-plugin/AGENTS.md` into `~/.config/opencode/AGENTS.md`.                                         |

opencode reads MCP configuration from `opencode.json`; there is no separate
`mcp` step for this target.

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

The generated `opencode.json` sets the default model and provider options for
this bundle. Users can keep local changes in the copied config file without
back-propagating edits into the repository.

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
