# Contributing

## Adding a New Plugin

1. Create a directory at the repo root with your plugin name in `kebab-case`
2. Add `.claude-plugin/plugin.json`:
   ```json
   {
     "name": "your-plugin",
     "description": "What the plugin does",
     "version": "1.0.0"
   }
   ```
3. Add skills, commands, or agents following the structure in [CLAUDE.md](CLAUDE.md)
4. Register in `.claude-plugin/marketplace.json` by adding an entry to the `plugins` array:
   ```json
   {
     "name": "your-plugin",
     "description": "What the plugin does",
     "version": "1.0.0",
     "author": { "name": "your-github-username" },
     "source": "./your-plugin"
   }
   ```
5. Test by enabling the plugin and running its commands

## Plugin Structure Requirements

- Every plugin needs `.claude-plugin/plugin.json`
- Skills go in `skills/<skill-name>/SKILL.md`
- Scripts must be executable (`chmod +x`) and use `set -euo pipefail`
- Reference templates go in `skills/<skill-name>/references/`

## Naming Conventions

- Directories and files: `kebab-case`
- Skills match their slash command name (e.g., skill `git-workflow` -> `/git-workflow`)

## Pull Requests

- One plugin per PR when adding new plugins
- Include a description of what the plugin does and example usage
- Ensure marketplace.json is updated
