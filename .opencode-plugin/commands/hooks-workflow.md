---
description: 'Generate target-aware hook configuration from ycc rule guidance with
  graceful fallbacks. Usage: <language> [--target=claude|cursor|codex] [--event=PreToolUse|PostToolUse|Stop|all]
  [--out=<path>] [--dry-run] [--verify] [--force]'
---

Generate hook configuration for a given programming language, respecting each target platform's support level. Claude produces a native JSON hooks block; Cursor produces a rule-embedded `.mdc` fragment where the capability matrix allows it, and falls back to an advisory marker otherwise; Codex emits an advisory-only `config.toml` fragment because its hook surface is under active development. All output is previewed first unless `--force` is passed alongside `--out`.

Invoke the **hooks-workflow** skill to:

1. Validate the language argument and resolve the effective target (defaults to `claude` when omitted)
2. Consult the target-capability matrix to determine what hook output is possible for that target
3. Generate the appropriate configuration fragment or advisory notice
4. Optionally write the result to `--out`, verify it with `--verify`, or preview it with `--dry-run`

Pass `$ARGUMENTS` through to the skill. Supported flags:

- `--target=claude|cursor|codex`: Destination platform (default: `claude`)
- `--event=PreToolUse|PostToolUse|Stop|all`: Hook event scope (default: `all`)
- `--out=<path>`: Write output to this path instead of printing to stdout
- `--dry-run`: Print what would be generated without writing any files
- `--verify`: After generation, validate the output against the target schema
- `--force`: Write to `--out` without prompting even if the file already exists

## What it produces

- **Claude**: a JSON `hooks` block compatible with `~/.config/opencode/settings.json`, scoped to the requested event(s).
- **Cursor**: a rule-embedded `.mdc` fragment where the capability matrix allows it; otherwise an advisory-only marker is emitted explaining the limitation.
- **Codex**: an advisory-only `config.toml` fragment prefixed with "Advisory only — Codex hooks under development as of 2026-04-16." No runnable configuration is generated for this target.

## Examples

```
/hooks-workflow python
/hooks-workflow python --target=claude --event=PreToolUse --out=hooks.json
/hooks-workflow typescript --target=claude --dry-run --verify
/hooks-workflow python --target=cursor --dry-run
/hooks-workflow python --target=codex --dry-run
```

The `--target=codex --dry-run` case emits the "advisory only / under development" notice instead of fabricating runnable config. This is intentional — no Codex hook output is generated until the platform surface stabilizes.

## See also

- `.opencode-plugin/skills/_shared/references/target-capability-matrix.md` — defines which features each target supports and drives the graceful-fallback logic
- `.opencode-plugin/skills/hooks-workflow/references/support-notes.md` — per-target hook support details and known limitations
- `.opencode-plugin/skills/hooks-workflow/references/templates/` — generation templates used internally by the skill
