# Generic User-Global Rules

This directory is the authoritative source for user-global agent rules installed by
`install.sh --settings` into each supported runtime's config directory.

## Files

- `CLAUDE.md` — Full merged generic ruleset (workflow, principles, MUST/MUST NOT,
  Conventional Commits, GitHub workflow, security). **Source of truth.**
- `AGENTS.md` — Short pointer that redirects to `CLAUDE.md`; used by runtimes that
  default to `AGENTS.md` (Cursor, Codex, opencode, Windsurf).
- `README.md` — this file.

## Scope vs. other rules files in this repo

| File                                       | Scope                                         |
| ------------------------------------------ | --------------------------------------------- |
| `ycc/settings/rules/CLAUDE.md` (this dir)  | User-global — installed everywhere.           |
| `CLAUDE.md` (repo root)                    | Repo-specific — only applies to this repo.    |
| `ycc/skills/init/templates/CLAUDE.md.tmpl` | Project template emitted by `/ycc:init`.      |
| `.opencode-plugin/AGENTS.md`               | Generated from repo `CLAUDE.md` (ycc bundle). |

These are deliberately separate. The generic file here is never ycc-specific; the
repo `CLAUDE.md` is never shipped outside this repo; the init template is what
`/ycc:init` writes into a **new** project.

## Installation

Installed by `install.sh --settings` for each target:

| Target     | Destinations                                                        |
| ---------- | ------------------------------------------------------------------- |
| `claude`   | `~/.claude/CLAUDE.md`, `~/.claude/AGENTS.md`                        |
| `cursor`   | `~/.cursor/CLAUDE.md`, `~/.cursor/AGENTS.md`                        |
| `codex`    | `~/.codex/CLAUDE.md`, `~/.codex/AGENTS.md`                          |
| `opencode` | uses `.opencode-plugin/AGENTS.md` (generator output — not this dir) |

`install.sh` uses a `link_rules_file` helper that refuses to overwrite a real
(non-symlink) file at the destination unless `--force` is passed. This protects
user-customized rules files.

## Editing guidelines

- **Edit `CLAUDE.md`.** `AGENTS.md` is a pointer only — never duplicate prose.
- Keep the content **generic**. No repo names, package managers, or project paths.
- After edits, run `shellcheck install.sh` and re-run
  `./install.sh --target all --settings` to confirm the symlinks resolve.
- Drift between this file and the repo's own `CLAUDE.md` is expected and fine —
  the two have different scopes.
