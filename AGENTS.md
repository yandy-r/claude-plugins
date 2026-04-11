# Repository Instructions

This repository's source of truth is the Claude-facing `ycc/` tree.

- Add new workflow logic under `ycc/`, not under `.cursor-plugin/` or `.codex-plugin/`.
- Treat `.cursor-plugin/` and `.codex-plugin/` as generated outputs unless you are changing the generators themselves.
- After changing `ycc/skills/` or `ycc/agents/`, run the Codex and Cursor generators plus their validators before considering the work done.
- Keep the plugin name `ycc` stable across all targets.
- For Codex, the native install surface is:
  - plugin source under `.codex-plugin/ycc/`
  - custom agents under `.codex-plugin/agents/`
  - user install target `~/.codex/plugins/ycc`
  - user marketplace `~/.agents/plugins/marketplace.json`
- Do not introduce new top-level plugins; extend the existing `ycc` bundle.
