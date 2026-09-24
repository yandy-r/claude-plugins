# install.sh: `cli` + `completion` subcommands (`ycc` command)

Problem: `install.sh` only exists in this checkout, so project-scoped runs
(`--project`, the default for `mcp`) need `cd`-ing elsewhere and calling the
script by absolute path. A hand-made symlink (`~/.local/bin/install-cc-plugins`)
also broke: `SCRIPT_DIR` did not resolve symlinks, so helpers were looked up
next to the link (`~/.local/bin/scripts/merge_managed_config.py`).

## CLI

```bash
./install.sh cli [--dir <dir>] [--force]         # link install.sh as `ycc` on PATH
ycc completion [--shell bash|zsh|fish]           # print completion script
ycc completion [--shell <s>] --install [--force] # link it where the shell autoloads
ycc sync --target opencode --intent mcp          # works from any directory
```

- Name `ycc`: matches the plugin/bundle name; no clash on common hosts.
- `SCRIPT_DIR` resolves through symlinks (`readlink -f`), so the linked command
  finds the repo; `--project` keeps targeting the caller's `$PWD` git toplevel.
- `cli` and `completion` are dispatched before target parsing and exit.

## `cli` destination

`--dir` wins. Else the first of `$XDG_BIN_HOME`, `~/.local/bin`, `~/bin` that is
on `$PATH`; else `$XDG_BIN_HOME` or `~/.local/bin` with a PATH warning.
Existing `ycc` symlink to this `install.sh`: no-op. Anything else there
(foreign symlink or real file): refuse unless `--force`.

## `completion`

`--shell` defaults to `basename $SHELL`. Scripts live in
`scripts/completions/{ycc.bash,_ycc,ycc.fish}`; without `--install` the script is
printed (for `eval`/`source`). `--install` symlinks it (so repo updates flow):

| shell | destination                                                                                     |
| ----- | ----------------------------------------------------------------------------------------------- |
| bash  | `${BASH_COMPLETION_USER_DIR:-${XDG_DATA_HOME:-~/.local/share}/bash-completion}/completions/ycc` |
| zsh   | `${XDG_DATA_HOME:-~/.local/share}/zsh/site-functions/_ycc` (must be in `fpath`)                 |
| fish  | `${XDG_CONFIG_HOME:-~/.config}/fish/completions/ycc.fish`                                       |

Same overwrite rule as `cli`: real file or foreign symlink needs `--force`.

Completions cover subcommands (`sync`, `remove`, `cli`, `completion`), every
flag, and values for `--target`, `--intent`, `--only` (comma lists), `--mode`,
`--shell`, `--dir`.

## Tests (`scripts/test-install-sync.sh`)

- `cli` links into a sandbox `~/.local/bin`; rerun is a no-op; foreign file
  refused without `--force`; `--dir` honored.
- Linked `ycc` run from a non-repo dir merges project MCP (the regression).
- `completion` prints each shell's script; `--install` links to the table
  paths; differing real file refused without `--force`; unknown shell rejected.
- `bash -n` / `zsh -n` / `fish -n` syntax checks on the scripts (when present).
