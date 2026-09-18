# Claude Install Guide

This guide covers Claude Code and Claude Desktop. Claude Code can install the
`ycc` plugin. Claude Desktop does not load Claude Code plugins or slash
commands, but it can use the shared MCP server configuration.

## Claude Code Quick Start

From the repository root:

```bash
./install.sh --target claude
```

The default `base` step registers this checkout as a Claude plugin marketplace
source and installs `ycc@ycc` through the Claude CLI.

After the command completes, run `/reload-plugins` in Claude Code or start a new
Claude Code session.

## Add Settings, Rules, MCP, Hooks, And Plugins

For a full local Claude Code sync without implicitly running plugin registration:

```bash
./install.sh sync --target claude --intent hooks,settings,mcp,plugins,rules
```

Add `base` to the intent list when you also want the Claude CLI to register and
install the plugin marketplace. The legacy equivalent remains supported:

```bash
./install.sh --target claude --settings --rules --mcp --hooks
```

Step behavior:

| Step       | Effect                                                                                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `base`     | Runs `claude plugin marketplace add <repo> --scope user` and `claude plugin install ycc@ycc --scope user`.                                              |
| `settings` | Merges managed keys from `ycc/settings/settings.json` into `~/.claude/settings.json` and copies `ycc/settings/statusline-command.sh` into `~/.claude/`. |
| `rules`    | Symlinks `ycc/settings/rules/CLAUDE.md` and `AGENTS.md` into `~/.claude/`.                                                                              |
| `mcp`      | Merges `mcp-configs/mcp.json` into `~/.claude.json`.                                                                                                    |
| `hooks`    | Symlinks `ycc/settings/hooks/` into `~/.claude/hooks/`.                                                                                                 |

Settings are merge-safe: unmanaged local keys are preserved, and managed keys
you changed locally are kept unless `--force` is passed. Model defaults are
`claude-fable-5-1` at Medium effort for the main session and `opus[1m]` at High
effort for subagents. `--rules` symlinks rules so rule edits stay shared across
runtimes.

## Local Vs Repo Mode

Local mode is the default and points Claude Code at this checkout:

```bash
./install.sh --target claude --mode local
```

Repo mode registers the upstream GitHub repository instead:

```bash
./install.sh --target claude --mode repo
```

Use repo mode for a non-developer install that should track the published
repository instead of a local checkout.

## Selective Steps

Use `--only` when you want exactly one step or a small set of steps:

```bash
./install.sh --target claude --only base
./install.sh --target claude --only settings
./install.sh --target claude --only rules
./install.sh --target claude --only mcp
./install.sh --target claude --only hooks
```

Rules symlinks stop rather than overwrite an existing real rules file; pass
`--force` when you intentionally want to replace it. Structured config files
merge instead, so `--force` there only resolves conflicts on managed keys you
edited locally.

## Live Iteration

In local mode, edits under `ycc/` are picked up by Claude Code after
`/reload-plugins`. No rsync or cache clear is needed.

If you move or rename this checkout, refresh the registered marketplace path:

```bash
./install.sh --target claude --only base
```

## Claude Desktop

Claude Desktop does not currently consume Claude Code plugin marketplaces, `ycc`
skills, or `ycc` slash commands. Use Claude Code for the plugin workflow.

Claude Desktop can use the shared MCP server definitions from
[`../../mcp-configs/mcp.json`](../../mcp-configs/mcp.json). Add the `mcpServers`
object from that file to your Claude Desktop config, preserving any existing
servers.

Common Claude Desktop config locations:

| Platform | Config path                                                       |
| -------- | ----------------------------------------------------------------- |
| macOS    | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Windows  | `%APPDATA%\\Claude\\claude_desktop_config.json`                   |

The resulting file should contain a top-level `mcpServers` object:

```json
{
  "mcpServers": {
    "example-server": {
      "command": "example",
      "args": []
    }
  }
}
```

Restart Claude Desktop after editing the config.

Note: `./install.sh --target claude --mcp` updates `~/.claude.json`, which is the
Claude Code MCP file. It does not edit the Claude Desktop config path.
