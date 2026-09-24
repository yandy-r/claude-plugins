# install.sh: `remove` command + `--project` / `--global` scope

Scope: framework + the `mcp` step only, all four targets. Every other step
rejects `remove` / `--project` in preflight, before any target runs, so
support can be widened step by step (`step_supports_project`,
`step_supports_remove` in `install.sh`).

## CLI

```bash
./install.sh        --target <t> --only mcp    [--project|--global]
./install.sh sync   --target <t> --intent mcp  [--project|--global]
./install.sh remove --target <t> --only mcp    [--project|--global] [--force]
./install.sh remove --target <t> --intent mcp  [--project|--global] [--force]
```

- `--project` / `--global` are mutually exclusive. No flag: project-capable
  steps use project scope, all others stay global. Explicit `--project` on a
  step without project support is an error.
- Project root: `git rev-parse --show-toplevel` from `$PWD`, else `$PWD`.
- `remove` requires `--only` or `--intent`, rejects additive flags, never runs
  `base`.

## Destinations

| target   | project                        | global                             |
| -------- | ------------------------------ | ---------------------------------- |
| claude   | `<project>/.mcp.json`          | `~/.claude.json`                   |
| cursor   | `<project>/.cursor/mcp.json`   | `~/.cursor/mcp.json`               |
| codex    | `<project>/.codex/config.toml` | `~/.codex/config.toml`             |
| opencode | `<project>/opencode.json`      | `~/.config/opencode/opencode.json` |

All go through `scripts/merge_managed_config.py` (profiles `claude-mcp`,
`cursor-mcp`, `codex-config`, `opencode-config`, group `mcp`); ownership state
is keyed per destination so scopes never interfere.

Behavior changes: cursor MCP merges instead of symlinking; codex/opencode MCP
moved out of the `settings` step into a dedicated scope-aware `mcp` step.

## Removal (`merge_managed_config.py --remove`)

Candidates: managed entries from the repo source plus entries recorded in
ownership state (installed earlier, since dropped from the repo).

- entry equals repo value, or every leaf matches its last-applied hash:
  removed, state dropped.
- user-edited entry: kept with warning; `--force` removes.
- unmanaged entries and unrelated keys: never touched.
- file left empty: deleted. TOML removal patches text (comments and unrelated
  tables survive) and re-parses before writing.

## Verification

- `python3 scripts/test_merge_managed_config.py`: helper remove tests
- `scripts/test-install-sync.sh`: scope + remove across all targets,
  sandboxed HOME and project dir
- `./scripts/validate.sh`, `shellcheck install.sh`
