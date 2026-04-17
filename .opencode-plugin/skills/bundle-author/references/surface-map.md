# Surface Map

Reference for every source-of-truth location a new skill, command, or agent occupies in
the `ycc/` tree. Use this when scaffolding to know exactly what to create and where.

---

## Surfaces

### Skill

| Field                | Value                                                        |
| -------------------- | ------------------------------------------------------------ |
| Path                 | `ycc/skills/<kebab-name>/SKILL.md`                           |
| Required frontmatter | `name`, `description`                                        |
| Optional frontmatter | `argument-hint`, `allowed-tools`, `disable-model-invocation` |
| Subdirs              | `references/` (static content), `scripts/` (bash helpers)    |

The `description` field is the trigger surface for opencode — include plain-language
phrasing that describes when the skill should activate.

Script and reference paths inside the skill body use the plugin root variable:

```
~/.config/opencode/skills/<kebab-name>/scripts/<name>.sh
~/.config/opencode/skills/<kebab-name>/references/<name>.md
```

The skill body is freeform markdown organized into phases.

---

### Command

| Field                | Value                                             |
| -------------------- | ------------------------------------------------- |
| Path                 | `ycc/commands/<kebab-name>.md`                    |
| Required frontmatter | `description`                                     |
| Optional frontmatter | `argument-hint`                                   |
| Invocation           | Matching slash command (same kebab-case basename) |

The command body invokes its matching skill and passes `$ARGUMENTS`. One command maps to
one skill. Do not embed logic in commands — put it in the skill.

Example body:

```
Invoke the matching skill with `$ARGUMENTS` passed through.
```

---

### Agent

| Field                | Value                                             |
| -------------------- | ------------------------------------------------- |
| Path                 | `ycc/agents/<kebab-name>.md`                      |
| Required frontmatter | `name`, `description`                             |
| Optional frontmatter | `tools`, `model`                                  |
| Invocation           | Invoked by skills and commands via the opencode `task` tool |

The agent body is the system prompt. Agents are invoked by skills or commands, not
directly by users. Always ensure a skill or command will consume the agent before
adding it.

---

### Shared Helper Script

| Field       | Value                                                    |
| ----------- | -------------------------------------------------------- |
| Path        | `ycc/skills/_shared/scripts/<kebab-name>.sh`             |
| Sourced via | `~/.config/opencode/shared/scripts/<name>.sh` |
| Threshold   | Only create when two or more distinct skills need it     |

All scripts must start with `#!/usr/bin/env bash` and use `set -euo pipefail`. Write
output to stdout and errors to stderr. Exit 0 on success, 1 on error.

---

## Post-Scaffold Required Commands

After scaffolding any surface, always run these in order:

```sh
# 1. Regenerate Cursor + Codex bundles from source
./scripts/sync.sh

# 2. Run the full validator sweep
./scripts/validate.sh

# 3. If scripts were scaffolded, make them executable
chmod +x ycc/skills/<name>/scripts/*.sh
```

Do not skip `./scripts/sync.sh`. The generated bundles under `.cursor-plugin/` and
`.codex-plugin/` go stale immediately when `ycc/` changes.

---

## Never Edit — Generated Targets

The following paths are **regenerated** by `./scripts/sync.sh`. Do not hand-edit them:

- `.cursor-plugin/**`
- `.codex-plugin/**`
- `docs/inventory.json`

Make all source changes under `ycc/` and let the generators produce the bundles.

---

## Quick Reference

```
ycc/
├── skills/
│   ├── _shared/
│   │   └── scripts/        ← shared bash helpers
│   └── <kebab-name>/
│       ├── SKILL.md         ← required
│       ├── references/      ← static reference docs
│       └── scripts/         ← skill-scoped bash helpers
├── commands/
│   └── <kebab-name>.md      ← slash command wrapper
└── agents/
    └── <kebab-name>.md      ← agent system prompt
```

---

See also: `when-not-to-scaffold.md` (this directory), `AGENTS.md` (repo root).
