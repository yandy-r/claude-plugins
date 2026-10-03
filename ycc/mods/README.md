# Mods

Claude Code mods: plugins with a hooks module (`hooks/hooks.json` `modules`)
that hooks into Claude Code itself, drawing UI, adding commands, or holding
and rewriting tool calls. One folder per mod; each folder is a complete plugin.
They need Claude Code 2.1.287 or later, in the CLI or the desktop app.

| Mod                          | What it does                                                                                                                                                            |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`status-bar/`](status-bar/) | Draws the context window above the prompt as a stacked bar, one color per `/context` category, with cost, rate limits and recent tool calls. Toggle with `/status-bar`. |

## Install

```bash
ycc sync --target claude --intent mods
```

This registers this folder as the local `ycc-mods` marketplace
(`.claude-plugin/marketplace.json`) and installs every mod it lists at user
scope. The marketplace is a directory source, so Claude Code loads each mod in
place from this checkout: edit a mod, then run `/reload-plugins`.

Disable or remove one mod like any plugin: `/plugin`, or
`claude plugin uninstall <mod>@ycc-mods`.

If you developed a mod under `CLAUDE_CODE_PLUGIN_DIRS` (a per-machine sideload),
drop that entry from `~/.claude/settings.json` once the marketplace copy is
installed, or the mod loads twice. The sync step warns when it sees one.

## Add a mod

1. Create `ycc/mods/<name>/` with `.claude-plugin/plugin.json`,
   `hooks/hooks.json` (`{ "modules": ["./register.tsx"] }`) and the module.
2. Add a `plugins` entry to `.claude-plugin/marketplace.json` with
   `"source": "./<name>"` and the same `version` as its `plugin.json`.
3. Run `./scripts/validate.sh --only mods`, then `claude plugin test ycc/mods/<name>`
   (needs a signed-in CLI).

Claude Code writes `.claude-plugin/types/` and `tsconfig.json` into a mod on each
load; both are git-ignored by the mod's own `.gitignore`.

## Other targets

Mods are Claude Code only. `ycc sync --intent mods` on `cursor`, `codex` or
`opencode` reports the intent as unsupported and skips it. To add a target,
map `<target>:mods` in `intent_steps_for_target` (`install.sh`) to a step that
translates `ycc/mods/<name>` into that tool's extension format, and flip its
`MODS` cell in
[`target-capability-matrix.md`](../skills/_shared/references/target-capability-matrix.md).
