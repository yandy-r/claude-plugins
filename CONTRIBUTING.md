# Contributing

## Repository Model

This repo no longer accepts new top-level Claude plugins. All new functionality goes into the
existing `ycc` source plugin under `ycc/`, then flows through the generated Cursor and Codex
compatibility bundles.

## Structure Requirements

- Claude source plugin manifest: `ycc/.claude-plugin/plugin.json`
- Claude marketplace: `.claude-plugin/marketplace.json`
- Codex generated plugin root: `.codex-plugin/ycc/`
- Codex generated custom agents: `.codex-plugin/agents/`
- Cursor generated bundle: `.cursor-plugin/`
- Skills go in `ycc/skills/<skill-name>/SKILL.md`
- Scripts must be executable (`chmod +x`) and use `set -euo pipefail`
- Reference templates go in `ycc/skills/<skill-name>/references/`

## Naming Conventions

- Directories and files: `kebab-case`
- Skills match their slash command name (e.g., skill `git-workflow` -> `/git-workflow`)

## Regeneration

After changing `ycc/skills/` or `ycc/agents/`, regenerate and validate compatibility artifacts:

```bash
./scripts/generate-codex-skills.sh
./scripts/generate-codex-agents.sh
./scripts/generate-codex-plugin.sh
./scripts/validate-codex-skills.sh
./scripts/validate-codex-agents.sh
./scripts/validate-codex-plugin.sh
./scripts/generate-cursor-skills.sh
./scripts/generate-cursor-agents.sh
./scripts/generate-cursor-rules.sh
./scripts/validate-cursor-skills.sh
./scripts/validate-cursor-agents.sh
./scripts/validate-cursor-rules.sh
```

## Pull Requests

- Include a description of the source change and any regenerated compatibility artifacts
- Ensure relevant marketplace/manifests are updated when generators change them
