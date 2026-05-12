# Target Capability Matrix

As of 2026-04-16

This file is the authoritative source for which ycc bundle capabilities are supported on each
deployment target. Downstream scripts parse the table below; read the Parser Grammar section
before editing the table.

---

## Parser Grammar

The table below is parsed by `ycc/skills/compatibility-audit/scripts/audit-target-features.sh`.
Follow these rules exactly or the parser will misread cells:

- **Column order**: `capability, claude, cursor, codex, opencode` — do not reorder.
- **Cell vocabulary**: exactly one of `supported`, `partial`, or `unsupported` — no other tokens,
  no trailing punctuation, no parenthetical notes inside the cell.
- **Notes** belong in the Notes section below the table, keyed as `capability:target`.
- Do not change column order or cell vocabulary without updating the parser in
  `ycc/skills/compatibility-audit/scripts/audit-target-features.sh`.

---

## Capability Matrix

| capability        | claude    | cursor      | codex       | opencode    |
| ----------------- | --------- | ----------- | ----------- | ----------- |
| SKILLS            | supported | supported   | supported   | supported   |
| COMMANDS          | supported | partial     | unsupported | supported   |
| AGENTS            | supported | partial     | supported   | supported   |
| HOOKS.PreToolUse  | supported | partial     | unsupported | partial     |
| HOOKS.PostToolUse | supported | partial     | unsupported | partial     |
| HOOKS.Stop        | supported | partial     | unsupported | partial     |
| MCP               | supported | supported   | partial     | supported   |
| INSTALL_PATH      | supported | supported   | supported   | supported   |
| DANGEROUS_MODE    | supported | unsupported | unsupported | unsupported |
| WORKTREE          | supported | partial     | partial     | partial     |

---

## Notes

**COMMANDS:cursor**
Cursor does not natively execute Claude Code slash commands as installable artifacts. The
`ycc` command layer is surfaced to Cursor users only through rule-embedded guidance in
`.cursor-plugin/`. Interactive slash-command dispatch is not available.

**COMMANDS:codex**
The Codex customization platform does not support a slash-command layer. Skills are exposed
via the plugin bundle; the `ycc/commands/` source tree has no Codex analog.

**AGENTS:cursor**
Cursor supports background agents (`docs.cursor.com/ko/background-agents`) but does not
consume Claude Code agent `.md` definitions directly. Agents are adapted as Cursor rules or
referenced via the generated `.cursor-plugin/` bundle. Full parity is not guaranteed.

**HOOKS.PreToolUse:cursor**
Cursor does not expose a native PreToolUse hook execution surface equivalent to Claude Code's
`~/.claude/settings.json` hooks. Existing repo hook guidance (e.g., `ycc/rules/*/hooks.md`)
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
(`developers.openai.com/codex/concepts/customization`) but is less mature than the Claude Code
or Cursor MCP surfaces. Treat as partial until a verified stable API is documented.

**DANGEROUS_MODE:cursor**
The `--dangerously-skip-permissions` flag is a Claude Code CLI concept with no equivalent in
Cursor.

**DANGEROUS_MODE:codex**
No equivalent to Claude Code's dangerous mode exists in the Codex runtime.

**INSTALL_PATH:claude**
Two supported install paths. (1) GitHub marketplace install managed by Claude Code
at `~/.claude/plugins/ycc/`, or the workspace `.claude-plugin/` directory. (2)
`install.sh --target claude` additionally registers the repo's
`.claude-plugin/marketplace.json` absolute path as a local marketplace
(`local-ycc-plugins`, `source: "file"`) in `~/.claude/settings.local.json`
(user-private, auto-gitignored) — edits in `ycc/` are live on the next plugin
reload with no rsync. The two marketplaces coexist; enable either `ycc@ycc` or
`ycc@local-ycc-plugins` to pick which copy is active.

**INSTALL_PATH:cursor**
Generated bundle lives at `.cursor-plugin/`; consumed by Cursor from the repo root.

**INSTALL_PATH:codex**
`install.sh --target codex` symlinks `~/.codex/plugins/ycc/` to the repo's
`.codex-plugin/ycc/`, also symlinks `~/.agents/plugins/ycc` to the same bundle,
refreshes the `~/.codex/plugins/cache/local-ycc-plugins/ycc` plugin-root copy,
adds a cache-only compatibility manifest at `skills/.codex-plugin/plugin.json`
with a `skills/_skills/` symlink index, rsyncs custom agents to
`~/.codex/agents/`, and registers `./plugins/ycc` as the local marketplace
source in
`~/.agents/plugins/marketplace.json`. Edits are live after regenerating the
bundle via `./scripts/sync.sh --only codex`; rerun the base install step after
clearing `~/.codex/plugins/cache/`.

**INSTALL_PATH:opencode**
Generated bundle lives at `.opencode-plugin/` (skills, agents, commands, AGENTS.md,
opencode.json). Consumed by opencode from `~/.config/opencode/` (global) or `.opencode/`
(project-local) after `install.sh --target opencode` rsyncs the files.

**SKILLS:opencode**
Native support at `.opencode/skills/<name>/SKILL.md` with strict YAML frontmatter
(`name`, `description` required; `license`, `compatibility`, `metadata` optional). Descriptions
are limited to 1024 chars. opencode also reads `.claude/skills/*/SKILL.md` and
`.agents/skills/*/SKILL.md` as compatibility fallbacks. Source: opencode.ai/docs/skills/.

**COMMANDS:opencode**
Native slash-command support at `.opencode/commands/<name>.md`. Frontmatter fields:
`description`, `agent`, `model`, `subtask`. Body supports the same `$ARGUMENTS` / `$1` /
``!`shell` `` / `@file` placeholders as Claude Code commands. opencode is the only non-Claude
target with first-class command support. Source: opencode.ai/docs/commands/.

**AGENTS:opencode**
Native agent support at `.opencode/agents/<name>.md`. Frontmatter: `description` (required),
`mode` (`primary` | `subagent` | `all`), `model` (`provider/model-id`), `prompt`, `tools`
(deprecated — prefer `permission`), `permission`, `temperature`, `top_p`, `steps`, `disable`,
`hidden`, `color`. Two invocation styles: Tab/`switch_agent` for primaries; `@mention` or
built-in `task` tool for subagents. Source: opencode.ai/docs/agents/.

**HOOKS.PreToolUse:opencode**
opencode has a TypeScript plugin system with a `tool.execute.before` event that covers the
same surface area as Claude Code's PreToolUse hook. Marked `partial` because the `ycc` bundle
does not ship a TypeScript plugin in v1 — hook guidance is emitted as rule-embedded notes
only. Upgrading to `supported` requires publishing an `@yandy/opencode-ycc-hooks` npm package.

**HOOKS.PostToolUse:opencode**
Same constraint as HOOKS.PreToolUse:opencode. The underlying opencode event is
`tool.execute.after`.

**HOOKS.Stop:opencode**
Same constraint as HOOKS.PreToolUse:opencode. Closest opencode event is `session.idle`
(fires when a session's agentic loop halts).

**MCP:opencode**
Native MCP support in the top-level `"mcp"` key of `opencode.json`. Server values are either
`{type: "local", command: [argv0, …args], environment, timeout}` or
`{type: "remote", url, headers, oauth, timeout}`. Note the critical shape difference from
Claude Code: opencode's `command` is a single array containing both argv0 and args (no
separate `args` key), and `env` is spelled `environment`. OAuth uses RFC 7591 Dynamic Client
Registration when `clientId` is omitted. Source: opencode.ai/docs/mcp-servers/.

**DANGEROUS_MODE:opencode**
No equivalent to Claude Code's `--dangerously-skip-permissions` flag exists in opencode. The
opencode permission model uses per-agent `permission.{edit,bash,webfetch}` fields with
`allow` / `deny` / `ask` values; there is no global override.

**WORKTREE:claude**
Full support. Worktree isolation is **on by default** for the 9 worktree-aware skills; pass
`--no-worktree` to opt out. The legacy `--worktree` flag is accepted as a silent no-op.
Harness-managed worktrees exist (`Agent(isolation: "worktree")`, `EnterWorktree`, plus the
`WorktreeCreate` hook registered in `ycc/settings/settings.json`), but the current ycc
single-worktree contract should not use per-agent tool-side isolation for parallel task fan-out.
Instead, pre-create one feature worktree and point every agent at it via `Working directory:`.
A Bash fallback (`git worktree add`) is always available. See
`ycc/skills/_shared/references/worktree-strategy.md` for the single-worktree naming scheme.

**WORKTREE:cursor**
Partial. Worktree mode is on by default for the 9 worktree-aware skills; pass `--no-worktree`
to opt out. The legacy `--worktree` flag is a silent no-op. Skills emit `git worktree add`
instructions for the user; no auto-creation from the skill layer. Worktree support is
editor-side in Cursor and is not skill-programmable. See
`ycc/skills/_shared/references/worktree-strategy.md` for Cursor-specific guidance.

**WORKTREE:codex**
Partial. Worktree mode is on by default for the 9 worktree-aware skills; pass `--no-worktree`
to opt out. The legacy `--worktree` flag is a silent no-op. No tool-side isolation equivalent.
Skills instruct the agent to run `git worktree add` via Bash; auto-creation happens when the
instruction is embedded in the agent prompt. See
`ycc/skills/_shared/references/worktree-strategy.md` for the Bash-fallback protocol.

**WORKTREE:opencode**
Partial. Worktree mode is on by default for the 9 worktree-aware skills; pass `--no-worktree`
to opt out. The legacy `--worktree` flag is a silent no-op. Same as Codex — Bash via prompt,
no tool-side isolation. Skills embed `git worktree add` commands in agent prompts. See
`ycc/skills/_shared/references/worktree-strategy.md` for the Bash-fallback protocol.

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
ycc:compatibility-audit
```

If the change affects generated bundles, follow the regeneration steps in `CLAUDE.md` under
"Testing Changes".
