# Claude Plugins - Project Instructions

## Overview

This repository ships a single Claude Code plugin called `ycc`, distributed via the
marketplace at `.claude-plugin/marketplace.json`. All skills, commands, and agents live
under `ycc/` and are accessed at runtime as `ycc:{skill}`, `/ycc:{command}`, or
`subagent_type: "ycc:{agent}"`.

The same source trees also generate native compatibility bundles for Cursor and Codex:

- Cursor bundle: `.cursor-plugin/`
- Codex bundle: `.codex-plugin/ycc/`
- Codex custom agents: `.codex-plugin/agents/`

> Pre-2.0 versions shipped 9 separate plugins. 2.0.0 collapsed them into one bundle so
> every skill is reachable via the same `ycc:` namespace prefix. See `docs/plans/` for
> the consolidation plan.

## Repository Layout

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json     # single ycc entry
├── .codex-plugin/
│   ├── agents/              # generated Codex custom agents
│   └── ycc/                 # generated Codex plugin root
├── .cursor-plugin/          # generated Cursor bundle
├── ycc/
│   ├── .claude-plugin/
│   │   └── plugin.json      # name: "ycc", version: 2.0.0
│   ├── commands/            # slash commands (one .md per command)
│   ├── agents/              # agents (one .md per agent)
│   └── skills/
│       ├── _shared/         # cross-skill helper scripts
│       └── {skill-name}/
│           ├── SKILL.md     # skill prompt (required)
│           ├── references/  # templates, examples, reference docs
│           └── scripts/     # validation and helper scripts
└── docs/
    └── plans/               # implementation plans
```

## Plugin Development Conventions

### Naming

- The plugin name is `ycc` and must NOT change. The marketplace prefix is always `ycc:`.
- Skills: `kebab-case` directory under `ycc/skills/`. The directory name becomes the
  skill identifier (e.g., `ycc/skills/git-workflow/` → `ycc:git-workflow`).
- Commands: `kebab-case.md` under `ycc/commands/`. The basename becomes the slash
  command (e.g., `ycc/commands/clean.md` → `/ycc:clean`).
- Agents: `kebab-case.md` under `ycc/agents/`. The basename becomes the agent identifier
  (e.g., `ycc/agents/codebase-advisor.md` → `subagent_type: "ycc:codebase-advisor"`).
- Scripts: `kebab-case.sh` with bash shebang.

### Scripts

All scripts must:

- Start with `#!/usr/bin/env bash`
- Use `set -euo pipefail` for safety
- Include validation guards (check required inputs exist)
- Exit with meaningful codes (0 = success, 1 = error)
- Write output to stdout, errors to stderr

When a script needs to reference its own plugin path, use `${CLAUDE_PLUGIN_ROOT}` —
this resolves to the `ycc/` directory at runtime. Paths inside skills follow the form
`${CLAUDE_PLUGIN_ROOT}/skills/{skill-name}/...`.

Codex-generated skills are not source-edited directly. The Codex generator rewrites
those paths to the managed install location `~/.codex/plugins/ycc/...`.

### Skills

Each skill directory contains:

- `SKILL.md` — the skill prompt (required)
- `references/` — templates, examples, and reference docs
- `scripts/` — validation and helper scripts

### Cross-skill helpers

Shared helpers (used by more than one skill) live under `ycc/skills/_shared/scripts/`.
Skills source them via `${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/{name}.sh`.

### Registration

The marketplace registry at `.claude-plugin/marketplace.json` contains a single entry:

```json
{
  "name": "ycc",
  "version": "2.0.0",
  "source": "./ycc"
}
```

Do not add additional plugin entries. New functionality goes into the existing `ycc`
plugin as a new skill, command, or agent. See `CONTRIBUTING.md` → Scope & Guardrails for
the full policy on what belongs in `ycc` and what to reject.

## Generated Compatibility Targets

- `ycc/skills/` is the source of truth for Cursor and Codex skill generation.
- `ycc/agents/` is the source of truth for Cursor and Codex agent generation.
- Do not hand-edit generated files under `.cursor-plugin/` or `.codex-plugin/` unless
  you are first changing the generator.
- Codex does not support this repo's custom slash-command layer as installable artifacts.
  The native Codex target exposes skills via the plugin bundle and agents via TOML files.

## Testing Changes

After modifying anything under `ycc/`:

1. Validate JSON with `python3 -m json.tool`:
   - `python3 -m json.tool .claude-plugin/marketplace.json`
   - `python3 -m json.tool ycc/.claude-plugin/plugin.json`
2. Verify all `${CLAUDE_PLUGIN_ROOT}` paths resolve (no broken references).
3. Confirm shell scripts remain executable:
   `find ycc/skills -name "*.sh" -not -executable` (should output nothing).
4. Test the skill or command in a live Claude Code session via its `ycc:` prefix.

If you changed `ycc/skills/` or `ycc/agents/`, also regenerate and validate the
compatibility bundles:

1. Codex:
   - `./scripts/generate-codex-skills.sh`
   - `./scripts/generate-codex-agents.sh`
   - `./scripts/generate-codex-plugin.sh`
   - `./scripts/validate-codex-skills.sh`
   - `./scripts/validate-codex-agents.sh`
   - `./scripts/validate-codex-plugin.sh`
2. Cursor:
   - `./scripts/generate-cursor-skills.sh`
   - `./scripts/generate-cursor-agents.sh`
   - `./scripts/generate-cursor-rules.sh`
   - `./scripts/validate-cursor-skills.sh`
   - `./scripts/validate-cursor-agents.sh`
   - `./scripts/validate-cursor-rules.sh`
