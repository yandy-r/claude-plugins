# Surface Map

Reference for every source-of-truth location a new skill, command, or agent occupies in
the `ycc/` tree. Use this when scaffolding to know exactly what to create and where.

---

## Surfaces

### Skill

| Field                | Value                                                                          |
| -------------------- | ------------------------------------------------------------------------------ |
| Path                 | `ycc/skills/<kebab-name>/SKILL.md`                                             |
| Required frontmatter | `name`, `description`                                                          |
| Optional frontmatter | `argument-hint`, `allowed-tools`, `disable-model-invocation`, `command: false` |
| Subdirs              | `references/` (static content), `scripts/` (bash helpers)                      |

Set `command: false` only when the skill should NOT have a matching slash
command under `ycc/commands/` — typically because it's a passive behavioral
ruleset that's never invoked directly. The pairing validator
(`scripts/validate-ycc-commands.sh`) enforces this as an explicit opt-out: a
skill without `command: false` MUST have a matching command.

The `description` field is the trigger surface for Claude Code — include plain-language
phrasing that describes when the skill should activate.

Script and reference paths inside the skill body use the plugin root variable:

```
${CLAUDE_PLUGIN_ROOT}/skills/<kebab-name>/scripts/<name>.sh
${CLAUDE_PLUGIN_ROOT}/skills/<kebab-name>/references/<name>.md
```

The skill body is freeform markdown organized into phases.

---

### Command

| Field                | Value                                             |
| -------------------- | ------------------------------------------------- |
| Path                 | `ycc/commands/<kebab-name>.md`                    |
| Required frontmatter | `description`                                     |
| Optional frontmatter | `argument-hint`, `allowed-tools`                  |
| Invocation           | Matching slash command (same kebab-case basename) |

Every command has a matching skill (same kebab-case name). The relationship is:

- **Skill** = workflow instructions + auto-trigger description (verbose,
  keyword-dense, scenario-based — tuned for the model to auto-match).
- **Command** = slash-menu surface + UI affordances that don't belong in the
  skill (flag documentation tables, usage examples, sibling-command
  cross-references, agent-type pinning, `$ARGUMENTS` injection, slash-scoped
  `allowed-tools`).

They are expected to differ. The command body dispatches to the skill and layers
on slash-specific UX; logic belongs in the skill.

Minimal body (scaffolded by `bundle-author`):

```
Invoke the **<kebab-name>** skill with `$ARGUMENTS` passed through.
```

Many commands grow beyond the minimal form — see `ycc/commands/plan.md` or
`ycc/commands/ask.md` for examples with flag tables, cross-refs, or agent pinning.

---

### Agent

| Field                | Value                                             |
| -------------------- | ------------------------------------------------- |
| Path                 | `ycc/agents/<kebab-name>.md`                      |
| Required frontmatter | `name`, `description`                             |
| Optional frontmatter | `tools`, `model`                                  |
| Invocation           | Invoked by skills and commands via the Agent tool |

The agent body is the system prompt. Agents are invoked by skills or commands, not
directly by users. Always ensure a skill or command will consume the agent before
adding it.

---

### Shared Helper Script

| Field       | Value                                                    |
| ----------- | -------------------------------------------------------- |
| Path        | `ycc/skills/_shared/scripts/<kebab-name>.sh`             |
| Sourced via | `${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/<name>.sh` |
| Threshold   | Only create when two or more distinct skills need it     |

All scripts must start with `#!/usr/bin/env bash` and use `set -euo pipefail`. Write
output to stdout and errors to stderr. Exit 0 on success, 1 on error.

---

## Post-Scaffold Required Commands

After scaffolding any surface, always run these in order:

```sh
# 1. Regenerate inventory + Cursor + Codex + opencode bundles from source
./scripts/sync.sh

# 2. Run the full validator sweep
./scripts/validate.sh

# 3. If scripts were scaffolded, make them executable
chmod +x ycc/skills/<name>/scripts/*.sh
```

Do not skip `./scripts/sync.sh`. The generated bundles under `.cursor-plugin/`,
`.codex-plugin/`, and `.opencode-plugin/` go stale immediately when `ycc/` changes.

---

## Never Edit — Generated Targets

The following paths are **regenerated** by `./scripts/sync.sh`. Do not hand-edit them:

- `.cursor-plugin/**`
- `.codex-plugin/**`
- `.opencode-plugin/**`
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
│       ├── SKILL.md         ← required (add `command: false` for skill-only)
│       ├── references/      ← static reference docs
│       └── scripts/         ← skill-scoped bash helpers
├── commands/
│   └── <kebab-name>.md      ← slash-command UX layer for the skill
└── agents/
    └── <kebab-name>.md      ← agent system prompt
```

Pairing policy: every skill under `skills/<kebab-name>/` has a matching
`commands/<kebab-name>.md` UNLESS the skill declares `command: false`.
Enforced by `scripts/validate-ycc-commands.sh`.

---

See also: `when-not-to-scaffold.md` (this directory), `CLAUDE.md` (repo root).
