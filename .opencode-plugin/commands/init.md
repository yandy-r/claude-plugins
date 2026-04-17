---
description: 'Initialize workspace — profile project, emit AGENTS.md/AGENTS.md/.cursor/rules,
  optional GitHub templates, git conventions, and opencode config. Usage: [--dry-run]
  [--docs-only] [--templates] [--git] [--vendor-neutral] [--update] [--force] [--profile=rust|ts-node|python|go|mixed|empty]'
---

Initialize the current workspace with the optimal opencode configuration.

Invoke the **init** skill to:

- Detect or accept an explicit project profile (language, toolchain, conventions).
- Emit the doc trio: `AGENTS.md`, `AGENTS.md`, and `.cursor/rules`.
- Optionally seed GitHub issue/PR templates and git commit conventions.
- Optionally configure MCP servers and opencode agent stubs.
- Apply all selected artifacts to the workspace (or preview with `--dry-run`).

## Common invocations

| Command                                   | Effect                                                                              |
| ----------------------------------------- | ----------------------------------------------------------------------------------- |
| `/init`                               | Interactive full init — detect profile, emit all artifacts.                         |
| `/init --dry-run`                     | Preview every planned change without writing any files.                             |
| `/init --docs-only`                   | Emit the doc trio only; skip MCP/agent configuration.                               |
| `/init --docs-only --templates --git` | Doc trio + GitHub templates + git conventions; no MCP/agent touch.                  |
| `/init --templates --force`           | Re-seed GitHub artifacts, overwriting existing files.                               |
| `/init --update`                      | Structured refresh of existing docs/templates (merge + migrate, no clobber).        |
| `/init --update --docs-only`          | Refresh only the doc trio — append missing sections, migrate legacy `.cursorrules`. |
| `/init --profile=rust --docs-only`    | Use Rust profile explicitly; skip detection and MCP/agent steps.                    |

## Flags

| Flag               | Effect                                                                                                                                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `--dry-run`        | Print planned changes; write nothing.                                                                                                                                                                  |
| `--docs-only`      | Limit output to `AGENTS.md`, `AGENTS.md`, `.cursor/rules`.                                                                                                                                             |
| `--templates`      | Include GitHub issue/PR templates.                                                                                                                                                                     |
| `--git`            | Add git commit-convention config.                                                                                                                                                                      |
| `--vendor-neutral` | Omit Claude-specific sections; emit neutral doc content only.                                                                                                                                          |
| `--update`         | Structured refresh for existing artifacts — merge missing sections into `AGENTS.md`, migrate legacy `.cursorrules` to `.cursor/rules/project.mdc`, preserve custom content. Composes with other flags. |
| `--force`          | Overwrite existing files instead of skipping them.                                                                                                                                                     |
| `--profile=<name>` | Skip detection and use the named profile (`rust`, `ts-node`, `python`, `go`, `mixed`, `empty`).                                                                                                        |

See `ycc/skills/init/references/flag-reference.md` for the full matrix.

Pass `$ARGUMENTS` through to the skill.
