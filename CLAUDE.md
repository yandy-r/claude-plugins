# Claude Plugins - Project Instructions

## Overview

This repository ships a single Claude Code plugin called `ycc`, distributed via the
marketplace at `.claude-plugin/marketplace.json`. All skills, commands, and agents live
under `ycc/` and are accessed at runtime as `ycc:{skill}`, `/ycc:{command}`, or
`subagent_type: "ycc:{agent}"`.

> Pre-2.0 versions shipped 9 separate plugins. 2.0.0 collapsed them into one bundle so
> every skill is reachable via the same `ycc:` namespace prefix. See `docs/plans/` for
> the consolidation plan.

## Repository Layout

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json     # single ycc entry
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
plugin as a new skill, command, or agent.

## Testing Changes

After modifying anything under `ycc/`:

1. Validate JSON with `python3 -m json.tool`:
   - `python3 -m json.tool .claude-plugin/marketplace.json`
   - `python3 -m json.tool ycc/.claude-plugin/plugin.json`
2. Verify all `${CLAUDE_PLUGIN_ROOT}` paths resolve (no broken references).
3. Confirm shell scripts remain executable:
   `find ycc/skills -name "*.sh" -not -executable` (should output nothing).
4. Test the skill or command in a live Claude Code session via its `ycc:` prefix.
