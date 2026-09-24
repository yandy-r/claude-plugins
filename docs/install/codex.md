# Codex Install Guide

This guide covers Codex plugin installs, Codex custom agents, and Codex Desktop.

## Quick Start

From the repository root:

```bash
./install.sh install --target codex
```

The default `base` step generates and validates the Codex bundle, links the
plugin tree into `~/.codex/plugins/ycc/`, syncs custom agents into
`~/.codex/agents/`, and registers the bundle in
`~/.agents/plugins/marketplace.json`.
It also refreshes the enabled-plugin cache copy at
`~/.codex/plugins/cache/local-ycc-plugins/ycc`, which is required after clearing
the Codex plugin cache.

Restart Codex after the install. Open `/plugins` and install `ycc` from the
registered marketplace if it is not already installed.

## Add Settings And Rules

For the full local Codex setup:

```bash
./install.sh sync --target codex --intent base,settings,mcp,plugins,rules
```

The step-flag `install` form is equivalent:

```bash
./install.sh install --target codex --settings --rules
```

Step behavior:

| Step       | Effect                                                                                                                                                                                                                                                                                                                                       |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `base`     | Generates and validates the Codex bundle, links `~/.codex/plugins/ycc/` and `~/.agents/plugins/ycc` to `.codex-plugin/ycc/`, refreshes the `~/.codex/plugins/cache/local-ycc-plugins/ycc` plugin-root copy, syncs `.codex-plugin/agents/` to `~/.codex/agents/`, and registers the marketplace with the relative local path `./plugins/ycc`. |
| `settings` | Merges managed keys from `.codex-plugin/config/config.toml` into `~/.codex/config.toml`. Plugin enablement lives in the same file, so the `plugins` intent also maps here.                                                                                                                                                                   |
| `mcp`      | Merges `[mcp_servers.*]` from `.codex-plugin/config/config.toml` into `<project>/.codex/config.toml` (or `~/.codex/config.toml` with `--global`).                                                                                                                                                                                            |
| `rules`    | Symlinks `.codex-plugin/config/default.rules`, `CLAUDE.md`, and `AGENTS.md` into `~/.codex/`.                                                                                                                                                                                                                                                |

Settings merge without rewriting the rest of TOML: comments, local trusted
projects, account-specific connectors, tokens, and unknown tables stay intact.
Managed defaults are `gpt-6-astra` at Medium effort for the main agent and
`gpt-5.6-sol` at High effort for spawned agents (`[agents]` defaults). `--rules`
symlinks rules so rule edits stay shared across runtimes.

## Local Vs Repo Mode

Local mode is the default and is best for contributors:

```bash
./install.sh install --target codex --mode local
```

In local mode, the installer symlinks:

```text
~/.codex/plugins/ycc/ -> <repo>/.codex-plugin/ycc/
~/.agents/plugins/ycc -> <repo>/.codex-plugin/ycc/
```

It also refreshes `~/.codex/plugins/cache/local-ycc-plugins/ycc` as a real copy
of the generated bundle, because Codex treats that cache root as the installed
plugin record. The cache copy includes a compatibility manifest under
`skills/.codex-plugin/plugin.json` plus a `skills/_skills/` symlink index for
Codex versions that resolve the plugin root through the manifest's `skills`
path.

After editing source files under `ycc/`, regenerate the Codex bundle before
reloading Codex:

```bash
./scripts/sync.sh --only codex
```

Repo mode writes a GitHub marketplace entry and lets Codex pull the bundle from
`yandy-r/claude-plugins@main`:

```bash
./install.sh install --target codex --mode repo
```

Use repo mode for non-developer installs that should track the published
repository.

## Selective Steps

Use `--only` to run exactly the listed steps:

```bash
./install.sh install --target codex --only base
./install.sh install --target codex --only settings
./install.sh install --target codex --only rules
./install.sh install --target codex --only settings,rules
./install.sh install --target codex --only mcp                   # <project>/.codex/config.toml
./install.sh install --target codex --only mcp --global          # ~/.codex/config.toml
./install.sh remove --target codex --only mcp --global   # remove managed servers
```

Codex loads a project `.codex/config.toml` only when the project is trusted in
`~/.codex/config.toml`. MCP servers moved from the `settings` step to the `mcp`
step; pass `--global` to keep writing the user config. See
[Project Vs Global Scope](README.md#project-vs-global-scope) and
[Removing MCP Servers](README.md#removing-mcp-servers).

If `~/.codex/plugins/ycc/` already exists as a real directory from an older
install flow, remove it before rerunning the local-mode base step:

```bash
rm -rf ~/.codex/plugins/ycc
./install.sh install --target codex --only base
```

If you clear `~/.codex/plugins/cache/`, rerun the base step to refresh the
`local-ycc-plugins/ycc` cache root:

```bash
./install.sh install --target codex --only base
```

## Codex Desktop

Codex Desktop uses the same installed plugin and custom-agent locations when it
reads the standard Codex config directories:

| Surface            | Location                                       |
| ------------------ | ---------------------------------------------- |
| Plugin tree        | `~/.codex/plugins/ycc/`                        |
| Marketplace source | `~/.agents/plugins/ycc`                        |
| Enabled cache      | `~/.codex/plugins/cache/local-ycc-plugins/ycc` |
| Custom agents      | `~/.codex/agents/`                             |
| Config             | `~/.codex/config.toml`                         |
| Marketplace        | `~/.agents/plugins/marketplace.json`           |

Recommended desktop install:

```bash
./install.sh install --target codex --mode repo --settings --rules
```

Then restart Codex Desktop and install `ycc` through the desktop app's plugin UI
or `/plugins` surface.

For contributor/local desktop testing, use local mode instead:

```bash
./install.sh install --target codex --settings --rules
```

After local source edits, run `./scripts/sync.sh --only codex`, then restart or
reload Codex Desktop.

If Codex Desktop does not show `ycc`, confirm it is using the same `~/.codex/`
and `~/.agents/plugins/marketplace.json` locations as the Codex CLI/TUI.

## Codex Notes

- Codex support is native. Skills are packaged as a Codex plugin and agents are
  emitted as Codex custom-agent TOMLs.
- Codex does not install this repository's custom slash-command layer. Use the
  bundled skills directly and Codex built-ins such as `/plan` and `/review`.
- Generated Codex skill bodies assume the managed path
  `~/.codex/plugins/ycc/`. The installer creates that path as a symlink in local
  mode.
