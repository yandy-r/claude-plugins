# Claude Plugins - Project Instructions

## Overview

This repository contains Claude Code plugins distributed as a marketplace. Each subdirectory is a self-contained plugin.

## Plugin Development Conventions

### Directory Structure

Every plugin must have:

- `.claude-plugin/plugin.json` - Plugin manifest with name, description, version
- At least one of: `commands/`, `skills/`, `agents/`

### Naming

- Plugin directories: `kebab-case` (e.g., `plan-workflow`, `git-workflow`)
- Skills: `kebab-case` matching the command they expose
- Agents: `kebab-case.md` files describing the agent persona
- Scripts: `kebab-case.sh` with bash shebang

### Scripts

All scripts must:

- Start with `#!/usr/bin/env bash`
- Use `set -euo pipefail` for safety
- Include validation guards (check required inputs exist)
- Exit with meaningful codes (0 = success, 1 = error)
- Write output to stdout, errors to stderr

### Skills

Each skill directory contains:

- `SKILL.md` - The skill prompt (required)
- `references/` - Templates, examples, and reference docs
- `scripts/` - Validation and helper scripts

### Registration

All plugins must be registered in `.claude-plugin/marketplace.json` with:

- `name` matching the directory name
- `description` summarizing what the plugin does
- `version` following semver
- `source` as a relative path (`./plugin-name`)

## Testing Changes

After modifying a plugin:

1. Verify the plugin.json is valid JSON
2. Verify marketplace.json includes the plugin
3. Test the skill/command in a Claude Code session
4. Check that all referenced scripts exist and are executable
