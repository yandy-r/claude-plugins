# Target Capability Matrix

As of 2026-04-16

This file is the authoritative source for which ycc bundle capabilities are supported on each
deployment target. Downstream scripts parse the table below; read the Parser Grammar section
before editing the table.

---

## Parser Grammar

The table below is parsed by `ycc/skills/compatibility-audit/scripts/audit-target-features.sh`.
Follow these rules exactly or the parser will misread cells:

- **Column order**: `capability, claude, cursor, codex` — do not reorder.
- **Cell vocabulary**: exactly one of `supported`, `partial`, or `unsupported` — no other tokens,
  no trailing punctuation, no parenthetical notes inside the cell.
- **Notes** belong in the Notes section below the table, keyed as `capability:target`.
- Do not change column order or cell vocabulary without updating the parser in
  `ycc/skills/compatibility-audit/scripts/audit-target-features.sh`.

---

## Capability Matrix

| capability        | claude    | cursor      | codex       |
| ----------------- | --------- | ----------- | ----------- |
| SKILLS            | supported | supported   | supported   |
| COMMANDS          | supported | partial     | unsupported |
| AGENTS            | supported | partial     | supported   |
| HOOKS.PreToolUse  | supported | partial     | unsupported |
| HOOKS.PostToolUse | supported | partial     | unsupported |
| HOOKS.Stop        | supported | partial     | unsupported |
| MCP               | supported | supported   | partial     |
| INSTALL_PATH      | supported | supported   | supported   |
| DANGEROUS_MODE    | supported | unsupported | unsupported |

---

## Notes

**COMMANDS:cursor**
Cursor does not natively execute Codex slash commands as installable artifacts. The
`ycc` command layer is surfaced to Cursor users only through rule-embedded guidance in
`.cursor-plugin/`. Interactive slash-command dispatch is not available.

**COMMANDS:codex**
The Codex customization platform does not support a slash-command layer. Skills are exposed
via the plugin bundle; the `ycc/commands/` source tree has no Codex analog.

**AGENTS:cursor**
Cursor supports background agents (`docs.cursor.com/ko/background-agents`) but does not
consume Codex agent `.md` definitions directly. Agents are adapted as Cursor rules or
referenced via the generated `.cursor-plugin/` bundle. Full parity is not guaranteed.

**HOOKS.PreToolUse:cursor**
Cursor does not expose a native PreToolUse hook execution surface equivalent to Codex's
`~/.codex/settings.json` hooks. Existing repo hook guidance (e.g., `ycc/rules/*/hooks.md`)
is embedded as rule-file notes, not executed by a hook runner.

**HOOKS.PostToolUse:cursor**
Same constraint as HOOKS.PreToolUse:cursor. PostToolUse hook guidance is rule-embedded only.

**HOOKS.Stop:cursor**
Same constraint as HOOKS.PreToolUse:cursor. Stop hook guidance is rule-embedded only.

**HOOKS.PreToolUse:codex**
The Codex config reference documents `features.codex_hooks` as still under development as of
the April 2026 research audit. No primary source confirms production availability. Marked
`unsupported` pending a verified Codex GA announcement.

**HOOKS.PostToolUse:codex**
Same constraint as HOOKS.PreToolUse:codex.

**HOOKS.Stop:codex**
Same constraint as HOOKS.PreToolUse:codex.

**MCP:codex**
MCP integration is referenced in the Codex customization docs
(`developers.openai.com/codex/concepts/customization`) but is less mature than the Codex
or Cursor MCP surfaces. Treat as partial until a verified stable API is documented.

**DANGEROUS_MODE:cursor**
The `--dangerously-skip-permissions` flag is a Codex CLI concept with no equivalent in
Cursor.

**DANGEROUS_MODE:codex**
No equivalent to Codex's dangerous mode exists in the Codex runtime.

**INSTALL_PATH:claude**
Installed at `~/.codex/plugins/ycc/` or the workspace `.codex-plugin/` directory.

**INSTALL_PATH:cursor**
Generated bundle lives at `.cursor-plugin/`; consumed by Cursor from the repo root.

**INSTALL_PATH:codex**
Generated bundle lives at `.codex-plugin/ycc/`; agents at `.codex-plugin/agents/`.

---

## How to Update This Document

Before changing any cell value, consult the three primary research artifacts that produced the
current verdicts:

1. `research/plugin-additions/report.md` — executive synthesis with platform source citations.
2. `research/plugin-additions/synthesis/innovation.md` — prioritized recommendations and
   rejected ideas, including the explicit warning against claiming cross-platform hook parity.
3. `research/plugin-additions/evidence/verification-log.md` — contradiction log and confidence
   ratings; specifically the Codex hook contradiction entry which drives the `unsupported`
   verdict for all HOOKS.\*:codex cells.

After updating a cell value, also update the corresponding note in the Notes section (or add
one if absent), and re-run the compatibility audit:

```
compatibility-audit
```

If the change affects generated bundles, follow the regeneration steps in `AGENTS.md` under
"Testing Changes".
