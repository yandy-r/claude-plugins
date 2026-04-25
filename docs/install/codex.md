# Codex Install Guide

This guide covers Codex plugin installs, Codex custom agents, and Codex Desktop.

## Quick Start

From the repository root:

```bash
./install.sh --target codex
```

The default `base` step generates and validates the Codex bundle, links the
plugin tree into `~/.codex/plugins/ycc/`, syncs custom agents into
`~/.codex/agents/`, and registers the bundle in
`~/.agents/plugins/marketplace.json`.

Restart Codex after the install. Open `/plugins` and install `ycc` from the
registered marketplace if it is not already installed.

## Add Settings And Rules

For the full local Codex setup:

```bash
./install.sh --target codex --settings --rules
```

Step behavior:

| Step       | Effect                                                                                                                                                                               |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `base`     | Generates and validates the Codex bundle, links `~/.codex/plugins/ycc/` to `.codex-plugin/ycc/`, syncs `.codex-plugin/agents/` to `~/.codex/agents/`, and registers the marketplace. |
| `settings` | Copies `.codex-plugin/config/config.toml` into `~/.codex/config.toml`.                                                                                                               |
| `rules`    | Symlinks `.codex-plugin/config/default.rules`, `CLAUDE.md`, and `AGENTS.md` into `~/.codex/`.                                                                                        |

`--settings` copies config so model, trusted-project, and token edits remain
local. `--rules` symlinks rules so rule edits stay shared across runtimes.

## Local Vs Repo Mode

Local mode is the default and is best for contributors:

```bash
./install.sh --target codex --mode local
```

In local mode, the installer symlinks:

```text
~/.codex/plugins/ycc/ -> <repo>/.codex-plugin/ycc/
```

After editing source files under `ycc/`, regenerate the Codex bundle before
reloading Codex:

```bash
./scripts/sync.sh --only codex
```

Repo mode writes a GitHub marketplace entry and lets Codex pull the bundle from
`yandy-r/claude-plugins@main`:

```bash
./install.sh --target codex --mode repo
```

Use repo mode for non-developer installs that should track the published
repository.

## Selective Steps

Use `--only` to run exactly the listed steps:

```bash
./install.sh --target codex --only base
./install.sh --target codex --only settings
./install.sh --target codex --only rules
./install.sh --target codex --only settings,rules
```

If `~/.codex/plugins/ycc/` already exists as a real directory from an older
install flow, remove it before rerunning the local-mode base step:

```bash
rm -rf ~/.codex/plugins/ycc
./install.sh --target codex --only base
```

## Codex Desktop

Codex Desktop uses the same installed plugin and custom-agent locations when it
reads the standard Codex config directories:

| Surface       | Location                             |
| ------------- | ------------------------------------ |
| Plugin tree   | `~/.codex/plugins/ycc/`              |
| Custom agents | `~/.codex/agents/`                   |
| Config        | `~/.codex/config.toml`               |
| Marketplace   | `~/.agents/plugins/marketplace.json` |

Recommended desktop install:

```bash
./install.sh --target codex --mode repo --settings --rules
```

Then restart Codex Desktop and install `ycc` through the desktop app's plugin UI
or `/plugins` surface.

For contributor/local desktop testing, use local mode instead:

```bash
./install.sh --target codex --settings --rules
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
