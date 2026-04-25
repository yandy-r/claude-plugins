# Cursor Install Guide

Cursor support is generated from the `ycc/` source tree and synced into
Cursor-native config directories.

## Quick Start

From the repository root:

```bash
./install.sh --target cursor
```

The default `base` step generates, validates, formats, and rsyncs the Cursor
bundle into `~/.cursor/`.

## Add Rules And MCP

For the full Cursor setup:

```bash
./install.sh --target cursor --rules --mcp
```

Step behavior:

| Step    | Effect                                                                                               |
| ------- | ---------------------------------------------------------------------------------------------------- |
| `base`  | Generates and validates `.cursor-plugin/{skills,agents,rules}/`, then rsyncs them into `~/.cursor/`. |
| `rules` | Symlinks `ycc/settings/rules/CLAUDE.md` and `AGENTS.md` into `~/.cursor/`.                           |
| `mcp`   | Symlinks `mcp-configs/mcp.json` to `~/.cursor/mcp.json`.                                             |

Cursor has no `settings` step because this repository does not manage a
per-machine Cursor config file.

## Selective Steps

Use `--only` to run exactly the listed steps:

```bash
./install.sh --target cursor --only base
./install.sh --target cursor --only rules
./install.sh --target cursor --only mcp
```

`--mode repo` is not supported for Cursor. Cursor reads files from local config
directories, so use the default local mode.

## Installed Surfaces

| Surface                | Location                                     |
| ---------------------- | -------------------------------------------- |
| Skills                 | `~/.cursor/skills/`                          |
| Agents                 | `~/.cursor/agents/`                          |
| Cursor rules           | `~/.cursor/rules/`                           |
| Shared top-level rules | `~/.cursor/CLAUDE.md`, `~/.cursor/AGENTS.md` |
| MCP config             | `~/.cursor/mcp.json`                         |

The top-level rule links intentionally live outside `~/.cursor/rules/` because
the `base` step rsyncs `~/.cursor/rules/` with `--delete`.

## Regenerate Only Cursor Artifacts

After editing source files under `ycc/`, regenerate Cursor artifacts directly or
through the unified sync script:

```bash
./scripts/sync.sh --only cursor
./scripts/validate.sh --only cursor
```
