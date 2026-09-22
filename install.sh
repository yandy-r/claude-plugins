#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# install.sh — sync plugin assets to target IDE config directories
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_PLUGIN_DIR="${SCRIPT_DIR}/.cursor-plugin"
CODEX_PLUGIN_DIR="${SCRIPT_DIR}/.codex-plugin/ycc"
CODEX_AGENTS_DIR="${SCRIPT_DIR}/.codex-plugin/agents"
OPENCODE_PLUGIN_DIR="${SCRIPT_DIR}/.opencode-plugin"
MCP_CONFIG_SRC="${SCRIPT_DIR}/mcp-configs/mcp.json"
CURSOR_CLI_CONFIG_SRC="${SCRIPT_DIR}/.cursor-plugin/config/cli-config.json"
CONFIG_MERGE_HELPER="${SCRIPT_DIR}/scripts/merge_managed_config.py"

# Colors ($'...' so escapes are real bytes, not literal \\033)
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BOLD=$'\033[1m'
NC=$'\033[0m'

info()  { printf "${GREEN}[ok]${NC}  %s\n" "$1"; }
warn()  { printf "${YELLOW}[!!]${NC}  %s\n" "$1"; }
err()   { printf "${RED}[err]${NC} %s\n" "$1" >&2; }

# link_file <src> <dest>
# - Ensures parent of <dest> exists.
# - If <dest> is already a symlink pointing at <src>, does nothing.
# - Otherwise, removes any existing file/symlink at <dest> and creates a symlink.
# - Errors if <src> is missing. Refuses to operate on a directory at <dest>.
link_file() {
    local src="$1"
    local dest="$2"
    [[ -e "$src" ]] || { err "source not found: $src"; exit 1; }
    if [[ -d "$dest" && ! -L "$dest" ]]; then
        err "refusing to replace directory with symlink: $dest"
        exit 1
    fi
    mkdir -p "$(dirname "$dest")"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        info "link up-to-date: $dest -> $src"
        return 0
    fi
    ln -sfn "$src" "$dest"
    info "linked $dest -> $src"
}

# link_rules_file <src> <dest>
# Stricter variant of link_file for user-customizable agent rules files
# (CLAUDE.md, AGENTS.md). Behaves like link_file EXCEPT that a real
# (non-symlink) regular file at <dest> is treated as user content and the
# link is refused unless FORCE=1. Symlinks are replaced as usual.
link_rules_file() {
    local src="$1"
    local dest="$2"
    [[ -e "$src" ]] || { err "rules source not found: $src"; exit 1; }
    if [[ -d "$dest" && ! -L "$dest" ]]; then
        err "refusing to replace directory with symlink: $dest"
        exit 1
    fi
    if [[ -e "$dest" && ! -L "$dest" && "${FORCE:-0}" != "1" ]]; then
        err "refusing to replace user-authored rules file: $dest"
        err "  move it aside or re-run with --force to overwrite."
        exit 1
    fi
    link_file "$src" "$dest"
}

# copy_settings_file <src> <dest>
# Copy <src> to <dest> so per-machine edits don't propagate back into the repo.
# - Errors if <src> is missing.
# - Refuses to replace a directory at <dest>.
# - If <dest> is a symlink, warns and replaces it with a real copy (no --force
#   needed — symlinks are considered agent-owned upgrade artifacts).
# - If <dest> is a regular file whose content is byte-identical to <src>, the
#   copy is a no-op (idempotent re-run; no --force needed).
# - If <dest> is a regular file whose content differs from <src>, refuses
#   unless FORCE=1 (protects user edits).
# - Uses 'cp -p' to preserve the source's exec bit (matters for
#   statusline-command.sh and friends).
copy_settings_file() {
    local src="$1"
    local dest="$2"
    [[ -e "$src" ]] || { err "settings source not found: $src"; exit 1; }
    if [[ -d "$dest" && ! -L "$dest" ]]; then
        err "refusing to replace directory with file: $dest"
        exit 1
    fi
    mkdir -p "$(dirname "$dest")"
    if [[ -L "$dest" ]]; then
        local link_target
        link_target="$(readlink "$dest")"
        warn "replacing symlink with copy: $dest -> $link_target"
        rm "$dest"
    elif [[ -f "$dest" ]]; then
        if cmp -s "$src" "$dest"; then
            info "copy up-to-date: $dest"
            return 0
        fi
        if [[ "${FORCE:-0}" != "1" ]]; then
            err "refusing to overwrite real file with differing content: $dest"
            err "  local edits differ from repo; re-run with --force to overwrite."
            exit 1
        fi
    fi
    cp -p "$src" "$dest"
    info "copied $src -> $dest"
}

# merge_settings_config <profile> <src> <dest> <groups>
# Merge only repo-managed keys while preserving unknown/local settings. Managed
# values previously written by this helper update automatically; locally edited
# managed values are preserved unless --force is passed.
merge_settings_config() {
    local profile="$1"
    local src="$2"
    local dest="$3"
    local groups="$4"

    [[ -f "${CONFIG_MERGE_HELPER}" ]] || { err "config merge helper not found: ${CONFIG_MERGE_HELPER}"; exit 1; }
    [[ -r "${CONFIG_MERGE_HELPER}" ]] || { err "config merge helper not readable: ${CONFIG_MERGE_HELPER}"; exit 1; }
    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }

    local -a command=(
        python3 "${CONFIG_MERGE_HELPER}"
        --profile "${profile}"
        --source "${src}"
        --destination "${dest}"
        --groups "${groups}"
    )
    [[ "${FORCE:-0}" == "1" ]] && command+=(--force)
    "${command[@]}"
}

usage() {
    cat <<EOF
Usage: $(basename "$0") sync --target <targets> --intent <intents> [--mode <mode>] [--force]
       $(basename "$0") --target <targets> [--mode <mode>] [--settings] [--rules] [--mcp] [--hooks] [--force] [--only <steps>]

Sync plugin assets to an IDE configuration directory.

The 'sync' subcommand is the recommended entry point: say WHAT you want synced
and each target maps it onto the steps it actually supports. Structured config
files are MERGED (repo-managed keys only), so local edits, tokens, trusted
projects and CLI-written marketplace entries survive. The legacy flag form
below keeps working unchanged.

  $(basename "$0") sync --target claude --intent hooks,settings,mcp,plugins
  $(basename "$0") sync --target codex,claude,opencode --intent mcp

Intents (valid: base, settings, rules, mcp, hooks, plugins):
  base      Install/register the target's bundle.
  settings  Merge repo-managed config keys (models, effort levels, ...).
  rules     Symlink the shared CLAUDE.md / AGENTS.md ruleset.
  mcp       Merge MCP server definitions.
  hooks     Merge hook config; claude also links the hook scripts directory.
  plugins   Merge plugin enablement and marketplace entries. Add 'base' too
            when you also want the target's CLI to perform registration.

  Intents a target cannot execute are reported and skipped. 'sync' is exclusive:
  it never implicitly runs 'base'.

  Intent → step mapping per target:
    claude    base→base  settings→settings  rules→rules  mcp→mcp
              hooks→settings+hooks  plugins→settings
    cursor    base→base  settings→settings  rules→rules  mcp→mcp
              hooks, plugins → no-op
    codex     base→base  settings→settings  rules→rules
              mcp, plugins → settings (config.toml holds both)
    opencode  base→base  settings→settings  rules→rules
              mcp, plugins → settings (opencode.json holds both)

Merge semantics (all structured config files):
  - Keys this repo declares as managed are written; every other key is kept.
  - A managed value the installer previously wrote is updated automatically.
  - A managed value YOU changed is preserved, with a warning; --force takes
    the repo value instead.
  - Ownership is tracked by hash in ~/.config/ycc/managed-config-state.json
    (hashes only — never values).

Options:
  --target <targets>  Comma-separated targets: claude, cursor, codex, opencode,
                      or all (which must stand alone). Every target is
                      validated before any of them runs.
  --mode <mode>       Marketplace source mode (default: local). Supported:
                        local — register the local repo checkout as the
                                marketplace source. claude target adds the
                                local path as a directory marketplace; codex
                                target symlinks .codex-plugin/ycc/ into
                                ~/.codex/plugins/ycc/ and
                                ~/.agents/plugins/ycc, refreshes the
                                enabled-plugin cache path, then writes a
                                {source: local, path: ./plugins/ycc} marketplace
                                entry. cursor/opencode rsync the bundles.
                        repo  — register the upstream github repo
                                yandy-r/claude-plugins as the marketplace
                                source. claude target adds the github slug
                                via the CLI; codex target writes a
                                {source: github, repo: yandy-r/claude-plugins,
                                ref: main} marketplace entry and skips
                                local generation/symlink/agents-sync.
                                cursor and opencode REJECT --mode repo
                                (they have no remote-source concept).
                                With --target all + --mode repo, cursor and
                                opencode are skipped with a warning.
  --settings          Additive: MERGE repo-managed keys into per-machine config
                      files while preserving local model choices, tokens,
                      marketplace entries written by the CLI, trusted-project
                      lists, and unknown keys. Managed values changed locally
                      are preserved unless --force is passed. Non-structured
                      companion files (for example the Claude statusline script)
                      still use copy semantics.
                      Mode-agnostic. Scope per target:
                        claude   — settings.json, statusline-command.sh
                        codex    — config.toml
                        opencode — opencode.json
                        cursor   — cli-config.json (CLI model preference)
  --rules             Additive: SYMLINK rules files so edits flow across
                      systems (this is the old --settings behavior for rules).
                      Refuses to replace a real rules file without --force;
                      replaces existing symlinks idempotently. Mode-agnostic.
                      Scope per target:
                        claude   — CLAUDE.md, AGENTS.md at ~/.claude/
                        cursor   — CLAUDE.md, AGENTS.md at ~/.cursor/
                        codex    — default.rules, CLAUDE.md, AGENTS.md at ~/.codex/
                        opencode — AGENTS.md at ~/.config/opencode/
  --mcp               Additive: also run the target's 'mcp' step. Mode-agnostic.
  --hooks             Additive: also run the target's 'hooks' step.
                      Currently supported by the claude target only; silently
                      ignored by targets without hook support. Mode-agnostic.
  --force             Let repo-managed config values win over local edits, and
                      replace real rules files with repo symlinks when needed.
                      Unknown/unmanaged config keys are never removed.
  --only <steps>      Exclusive: run only the comma-separated steps
                      (e.g. --only settings, --only rules,settings).
                      Overrides defaults and --settings/--rules/--mcp/--hooks.
  --intent <intents>  'sync' subcommand only. Comma-separated intents (see
                      above). Cannot be combined with --only or the additive
                      --settings/--rules/--mcp/--hooks flags.
  --help              Show this help message

Semantics:
  Default (no --only):
    - Run the target's 'base' step (if any).
    - Additionally run 'settings' / 'rules' / 'mcp' / 'hooks' if their flag is
      passed.
  With --only <steps>:
    - Run exactly the listed steps. Nothing else.

  Transport semantics:
    - --settings (copy)   dest absent: cp; dest is a symlink: warn + rm + cp;
                          dest is a real file: error unless --force.
    - --rules    (symlink) idempotent link; refuses to replace a real file
                          without --force.

Target steps:
  claude    base | settings | rules | mcp | hooks
            base:     invoke 'claude plugin marketplace add <repo> --scope user'
                      + 'claude plugin install ycc@ycc --scope user'. Breaks
                      ~/.claude/settings.json symlink (if any) first so the CLI
                      write doesn't pollute the committed source file. Edits
                      in ycc/ apply on /reload-plugins.
            settings: MERGE managed keys from ycc/settings/settings.json into
                      ~/.claude/settings.json and COPY statusline-command.sh.
                      Local edits and CLI-written marketplace entries are
                      preserved unless --force resolves a managed conflict.
            rules:    symlink ycc/settings/rules/{CLAUDE.md,AGENTS.md} into
                      ~/.claude/.
            mcp:      merge mcp-configs/mcp.json mcpServers into ~/.claude.json.
            hooks:    symlink ycc/settings/hooks/ into ~/.claude/hooks/, enabling
                      the WorktreeCreate hook (redirects harness-managed
                      worktrees to ~/.claude-worktrees/).
  cursor    base | settings | mcp | rules
            base:     generate + validate + format + rsync bundle to ~/.cursor/.
            settings: merge .cursor-plugin/config/cli-config.json into
                      ~/.cursor/cli-config.json (main CLI model preference).
            mcp:      symlink mcp-configs/mcp.json → ~/.cursor/mcp.json.
            rules:    symlink ycc/settings/rules/{CLAUDE.md,AGENTS.md} into
                      ~/.cursor/ (top level — NOT inside ~/.cursor/rules/, which
                      is rsynced with --delete during 'base').
                      Cursor sub-agent models are set per generated agent file
                      in .cursor-plugin/agents/, not in cli-config.json.
  codex     base | settings | rules
            base:     generate + validate + format + sync custom agents, then
                      register the repo's .codex-plugin/ycc/ as a local
                      marketplace source in ~/.agents/plugins/marketplace.json
                      via ~/.agents/plugins/ycc -> .codex-plugin/ycc/.
                      Also refreshes the Codex enabled-plugin cache copy at
                      ~/.codex/plugins/cache/local-ycc-plugins/ycc. Rerun
                      ./scripts/sync.sh --only codex to refresh the generated
                      bundle, and rerun this step after clearing the Codex
                      plugin cache.
            settings: MERGE managed keys from .codex-plugin/config/config.toml
                      into ~/.codex/config.toml. Comments, trusted projects,
                      MCP bearer tokens, connector entries and unknown tables
                      are preserved; Codex reads MCP and plugin state from the
                      same file, so those intents map here too.
            rules:    symlink .codex-plugin/config/default.rules AND
                      ycc/settings/rules/{CLAUDE.md,AGENTS.md} into ~/.codex/.
  opencode  base | settings | rules
            base:     generate + validate + format + rsync skills/agents/commands
                      into ~/.config/opencode/.
            settings: MERGE managed keys from .opencode-plugin/opencode.json
                      into ~/.config/opencode/opencode.json. Local model
                      choices, provider credentials and unknown keys are
                      preserved. opencode reads MCP and plugins from the same
                      file, so those intents map here — no separate mcp step.
            rules:    symlink .opencode-plugin/AGENTS.md into
                      ~/.config/opencode/ (generator-produced from
                      ycc/settings/rules/CLAUDE.md — the same user-global
                      ruleset as every other target).
  all       Run claude then cursor then codex then opencode; step flags propagate.

Examples:
  $(basename "$0") --target claude                         # base only (register local marketplace)
  $(basename "$0") --target claude --only base             # same, exclusive
  $(basename "$0") --target claude --settings --rules      # base + merge settings + link rules
  $(basename "$0") --target claude --settings --rules --mcp
  $(basename "$0") --target claude --only settings         # copy settings only
  $(basename "$0") --target claude --only rules            # link rules only
  $(basename "$0") --target claude --only mcp
  $(basename "$0") --target claude --settings --force      # repo values win for managed-key conflicts
  $(basename "$0") --target claude --hooks                 # base + WorktreeCreate hook
  $(basename "$0") --target claude --only hooks            # hooks only
  $(basename "$0") --target cursor                         # base only
  $(basename "$0") --target cursor --mcp                   # base + mcp
  $(basename "$0") --target cursor --rules                 # base + rules symlinks
  $(basename "$0") --target cursor --only rules            # rules only
  $(basename "$0") --target codex --settings --rules       # base + merge config + link rules
  $(basename "$0") --target codex --only settings          # merge config.toml only
  $(basename "$0") --target codex --only rules             # link default.rules + CLAUDE.md + AGENTS.md
  $(basename "$0") --target opencode                       # base only
  $(basename "$0") --target opencode --settings --rules    # base + merge opencode.json + link AGENTS.md
  $(basename "$0") --target all --settings --rules --mcp
  $(basename "$0") --target claude,codex --only rules      # rules for two targets
  $(basename "$0") --target all --rules --force            # force-replace user-authored rules files

  # Upgrading from the symlink-based --settings (<= pre-split): the first run of
  # --settings detects the existing symlink at each destination and replaces it
  # with a copy (emits an info/warn line per file). No --force needed.

  # Repo mode (track the upstream github repo instead of the local checkout):
  $(basename "$0") --target claude --mode repo             # register yandy-r/claude-plugins
                                                           # as a github marketplace source
  $(basename "$0") --target codex  --mode repo             # write the codex marketplace.json
                                                           # with {source: github, repo: ...,
                                                           # ref: main}; skip symlink/rsync
  $(basename "$0") --target all    --mode repo             # claude + codex in repo mode;
                                                           # cursor/opencode are skipped
  $(basename "$0") --target claude --mode repo --settings --rules
EOF
}

# ---------------------------------------------------------------------------
# Repo formatting (modified files via scripts/style.sh)
# Only stacks present in this repo: Markdown/JSON (prettier) and Python (black).
# style.sh format has no shell formatter; Rust/TS/Go are omitted to avoid requiring
# those toolchains or failing on unrelated stacks.
# ---------------------------------------------------------------------------
run_repo_style_format_modified() {
    local style_sh="${SCRIPT_DIR}/scripts/style.sh"

    if [[ ! -f "${style_sh}" ]]; then
        err "style script not found: ${style_sh}"
        exit 1
    fi
    if [[ ! -r "${style_sh}" ]]; then
        err "style script not readable: ${style_sh}"
        exit 1
    fi
    if [[ ! -x "${style_sh}" ]]; then
        err "style script not executable: ${style_sh}"
        exit 1
    fi

    info "Running scripts/style.sh format --modified --docs --python"
    PROJECT_ROOT="${SCRIPT_DIR}" bash "${style_sh}" format --modified --docs --python

    info "Running scripts/style.sh lint --modified --fix --python --shell"
    PROJECT_ROOT="${SCRIPT_DIR}" bash "${style_sh}" lint --modified --fix --python --shell
}

# ---------------------------------------------------------------------------
# MCP: Claude Code (~/.claude.json root mcpServers)
# ---------------------------------------------------------------------------
# Claude Code reads MCP servers from ~/.claude.json. The shared merge helper
# gives this the same ownership tracking, local-edit protection and atomic
# write behavior as every other structured config file.
merge_claude_mcp_json() {
    merge_settings_config \
        "claude-mcp" \
        "${MCP_CONFIG_SRC}" \
        "${HOME}/.claude.json" \
        "mcp"
}

# ---------------------------------------------------------------------------
# Claude marketplace — registers ycc as a marketplace via the canonical CLI:
#
#   local mode:  claude plugin marketplace add <repo-path>            --scope user
#   repo  mode:  claude plugin marketplace add yandy-r/claude-plugins --scope user
#                followed by:
#                claude plugin install ycc@ycc --scope user
#
# The CLI writes to ~/.claude/settings.json regardless of source type. That
# path is typically a symlink to ycc/settings/settings.json (via the
# 'settings' step), so we break the symlink first in BOTH modes — otherwise
# the CLI would follow the link and pollute the committed source-of-truth
# file with the marketplace registration.
#
# After this step, ~/.claude/settings.json is a REAL file. Re-running
# `install.sh --target claude --only settings` would symlink over it and wipe
# the marketplace entry; the 'settings' step detects this and refuses
# without --force.
#
# CLI source form (verified via `claude plugin marketplace add --help`):
#   "Add a marketplace from a URL, path, or GitHub repo" — the
#   <owner>/<repo> slug is accepted directly for repo mode.
# ---------------------------------------------------------------------------
register_claude_marketplace() {
    local mode="${1:-local}"
    if [[ ! "$mode" =~ ^(local|repo)$ ]]; then
        err "register_claude_marketplace: invalid mode '${mode}' (expected local|repo)"
        exit 1
    fi

    command -v claude >/dev/null 2>&1 || {
        err "'claude' CLI is required but not found in PATH"
        exit 1
    }
    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    command -v realpath >/dev/null 2>&1 || { err "realpath is required but not found"; exit 1; }

    local source_arg
    if [[ "$mode" == "local" ]]; then
        source_arg="$(realpath "${SCRIPT_DIR}")"
    else
        source_arg="yandy-r/claude-plugins"
    fi

    local settings="${HOME}/.claude/settings.json"

    # Break the symlink safely if it points into this repo (or anywhere).
    # We materialize the current content before the CLI writes to it.
    if [[ -L "${settings}" ]]; then
        local link_target
        link_target="$(readlink -f "${settings}")"
        info "${settings} is a symlink to ${link_target}"
        info "Breaking the symlink before CLI write (protects the committed source file from pollution)"
        local tmp
        tmp="$(mktemp)"
        cat "${settings}" > "${tmp}"
        rm "${settings}"
        mv "${tmp}" "${settings}"
    fi

    # Ensure parent dir exists (fresh $HOME case)
    mkdir -p "$(dirname "${settings}")"

    info "Running: claude plugin marketplace add ${source_arg} --scope user  (mode=${mode})"
    claude plugin marketplace add "${source_arg}" --scope user
    info "Running: claude plugin install ycc@ycc --scope user"
    claude plugin install ycc@ycc --scope user || warn "plugin install returned non-zero — check 'claude plugin list'"

    # Cleanup orphans from earlier broken attempts of this installer
    cleanup_claude_local_orphans
}

# Remove 'local-ycc-plugins' detritus from earlier (broken) versions of the
# installer that wrote to the wrong files with the wrong schema.
cleanup_claude_local_orphans() {
    local files=("${HOME}/.claude.json" "${HOME}/.claude/settings.local.json")
    local f
    for f in "${files[@]}"; do
        [[ -f "$f" ]] || continue
        python3 - "$f" <<'PY' || true
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
try:
    data = json.loads(p.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError):
    sys.exit(0)
if not isinstance(data, dict):
    sys.exit(0)

changed = False
extras = data.get("extraKnownMarketplaces")
if isinstance(extras, dict) and "local-ycc-plugins" in extras:
    del extras["local-ycc-plugins"]
    if not extras:
        del data["extraKnownMarketplaces"]
    changed = True

enabled = data.get("enabledPlugins")
if isinstance(enabled, dict) and "ycc@local-ycc-plugins" in enabled:
    del enabled["ycc@local-ycc-plugins"]
    if not enabled:
        del data["enabledPlugins"]
    changed = True

if changed:
    # If the file is now empty after cleanup and it's settings.local.json,
    # just delete it rather than leaving an empty file.
    if not data and p.name == "settings.local.json":
        p.unlink()
        print(f"removed empty orphan file {p}")
    else:
        p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"removed orphaned 'local-ycc-plugins' entries from {p}")
PY
    done
}

# ---------------------------------------------------------------------------
# MCP: Cursor (~/.cursor/mcp.json)
# ---------------------------------------------------------------------------
sync_cursor_mcp_json() {
    if [[ ! -f "${MCP_CONFIG_SRC}" ]]; then
        err "MCP source not found: ${MCP_CONFIG_SRC}"
        exit 1
    fi
    if [[ ! -r "${MCP_CONFIG_SRC}" ]]; then
        err "MCP source not readable: ${MCP_CONFIG_SRC}"
        exit 1
    fi

    link_file "${MCP_CONFIG_SRC}" "${HOME}/.cursor/mcp.json"
}

# ---------------------------------------------------------------------------
# Step selection
# ---------------------------------------------------------------------------
# step_enabled <step> <target_valid_steps_csv>
# Decides whether <step> should run for the current target.
# - If --only was passed: run iff <step> is in the --only list.
# - Else: 'base' always runs; 'settings'/'mcp' run only if their flag is set.
# The target's valid steps are used for validation by validate_only_steps().
step_enabled() {
    local step="$1"
    if [[ "${EXCLUSIVE_STEPS:-0}" == "1" ]]; then
        # Exclusive mode: nothing runs unless it was explicitly selected, so a
        # target whose intents are all no-ops must not silently fall back to
        # 'base'.
        local s
        for s in "${ONLY_STEPS[@]}"; do
            [[ "$s" == "$step" ]] && return 0
        done
        return 1
    fi
    if [[ ${#ONLY_STEPS[@]} -gt 0 ]]; then
        local s
        for s in "${ONLY_STEPS[@]}"; do
            [[ "$s" == "$step" ]] && return 0
        done
        return 1
    fi
    case "$step" in
        base)     return 0 ;;
        settings) [[ "${SETTINGS:-0}" == "1" ]] ;;
        rules)    [[ "${RULES:-0}" == "1" ]] ;;
        mcp)      [[ "${MCP:-0}" == "1" ]] ;;
        hooks)    [[ "${HOOKS:-0}" == "1" ]] ;;
        *)        return 1 ;;
    esac
}

# valid_steps_for_target <target>
# Echo the comma-separated steps <target> supports for --only.
valid_steps_for_target() {
    case "$1" in
        claude) echo "base,settings,rules,mcp,hooks" ;;
        cursor) echo "base,settings,mcp,rules" ;;
        codex|opencode) echo "base,settings,rules" ;;
        *) err "valid_steps_for_target: unknown target '$1'"; exit 1 ;;
    esac
}

# validate_only_steps <target>
# If --only was passed, ensure every requested step is valid for the target.
validate_only_steps() {
    local target="$1"
    local valid_csv
    valid_csv="$(valid_steps_for_target "${target}")"
    if [[ "${EXCLUSIVE_STEPS:-0}" != "1" && ${#ONLY_STEPS[@]} -eq 0 ]]; then
        return 0
    fi

    local -a valid
    IFS=',' read -r -a valid <<< "$valid_csv"
    local requested found v
    for requested in "${ONLY_STEPS[@]}"; do
        found=0
        for v in "${valid[@]}"; do
            [[ "$v" == "$requested" ]] && { found=1; break; }
        done
        if [[ $found -eq 0 ]]; then
            err "--only step '${requested}' is not valid for target '${target}' (valid: ${valid_csv})"
            exit 1
        fi
    done
}

# ---------------------------------------------------------------------------
# Intent mapping ('sync' subcommand)
# ---------------------------------------------------------------------------
# Intents describe WHAT the user wants synced; each target maps them onto the
# steps it actually supports. An intent a target cannot execute is reported and
# skipped rather than silently falling back to another step.
VALID_INTENTS=(base settings rules mcp hooks plugins)

# intent_steps_for_target <target> <intent>
# Echo the comma-separated steps <intent> maps to for <target>. Empty output
# means the intent is a no-op there.
intent_steps_for_target() {
    local target="$1"
    local intent="$2"

    case "${target}:${intent}" in
        claude:base|claude:settings|claude:rules|claude:mcp) echo "${intent}" ;;
        # Hook activation lives in settings.json; hook scripts live in hooks/.
        claude:hooks) echo "settings,hooks" ;;
        # Claude plugin enablement is pure settings.json state (enabledPlugins,
        # extraKnownMarketplaces). Add 'base' explicitly to also run the CLI's
        # marketplace registration, which needs network access.
        claude:plugins) echo "settings" ;;

        cursor:base|cursor:rules|cursor:mcp) echo "${intent}" ;;
        cursor:settings) echo "settings" ;;
        cursor:hooks|cursor:plugins) echo "" ;;

        codex:base|codex:settings|codex:rules) echo "${intent}" ;;
        # Codex reads MCP servers and plugin enablement from config.toml.
        codex:mcp|codex:plugins) echo "settings" ;;
        codex:hooks) echo "" ;;

        opencode:base|opencode:settings|opencode:rules) echo "${intent}" ;;
        # opencode reads MCP servers and plugins from opencode.json.
        opencode:mcp|opencode:plugins) echo "settings" ;;
        opencode:hooks) echo "" ;;

        *) echo "" ;;
    esac
}

# configure_intents_for_target <target>
# Translate INTENTS into ONLY_STEPS for <target> and enable exclusive mode.
configure_intents_for_target() {
    local target="$1"
    local -a steps=()
    local intent mapped step

    for intent in "${INTENTS[@]}"; do
        mapped="$(intent_steps_for_target "${target}" "${intent}")"
        if [[ -z "${mapped}" ]]; then
            warn "intent '${intent}' is not supported by target '${target}' — skipping"
            continue
        fi
        local -a mapped_steps=()
        IFS=',' read -r -a mapped_steps <<< "${mapped}"
        for step in "${mapped_steps[@]}"; do
            local seen=0 existing
            for existing in "${steps[@]:-}"; do
                [[ "${existing}" == "${step}" ]] && seen=1 && break
            done
            [[ ${seen} -eq 0 ]] && steps+=("${step}")
        done
    done

    ONLY_STEPS=("${steps[@]:-}")
    # Drop the empty element bash leaves behind when expanding an empty array.
    if [[ ${#ONLY_STEPS[@]} -eq 1 && -z "${ONLY_STEPS[0]}" ]]; then
        ONLY_STEPS=()
    fi
    EXCLUSIVE_STEPS=1
}

intent_requested() {
    local requested="$1"
    local intent
    for intent in "${INTENTS[@]:-}"; do
        [[ "${intent}" == "${requested}" ]] && return 0
    done
    return 1
}

# config_groups_for_target <target>
# Return managed config groups selected for a structured settings file.
config_groups_for_target() {
    local target="$1"
    if [[ "${COMMAND}" != "sync" ]]; then
        case "${target}" in
            claude) echo "settings,hooks,plugins" ;;
            cursor) echo "settings" ;;
            codex|opencode) echo "settings,mcp,plugins" ;;
        esac
        return 0
    fi

    local -a groups=()
    local group
    for group in settings mcp plugins hooks; do
        intent_requested "${group}" || continue
        case "${target}:${group}" in
            claude:settings|claude:plugins|claude:hooks) groups+=("${group}") ;;
            cursor:settings) groups+=("settings") ;;
            codex:settings|codex:mcp|codex:plugins) groups+=("${group}") ;;
            opencode:settings|opencode:mcp|opencode:plugins) groups+=("${group}") ;;
        esac
    done
    local IFS=','
    echo "${groups[*]}"
}

# run_target <target> <function>
# Configure intent mapping (sync mode only), then run the target.
run_target() {
    local target="$1"
    local fn="$2"
    if [[ "${COMMAND}" == "sync" ]]; then
        configure_intents_for_target "${target}"
    fi
    "${fn}"
}

# ---------------------------------------------------------------------------
# Claude target (settings + mcp; no base)
# ---------------------------------------------------------------------------
sync_claude_target() {
    validate_only_steps "claude"

    local ran=0
    local base_ran=0
    if step_enabled base; then
        if [[ "${MODE:-local}" == "repo" ]]; then
            printf '\n%sClaude: register github repo as marketplace (yandy-r/claude-plugins)%s\n' "${BOLD}" "${NC}"
        else
            printf '\n%sClaude: register repo checkout as local marketplace%s\n' "${BOLD}" "${NC}"
        fi
        register_claude_marketplace "${MODE:-local}"
        ran=1
        base_ran=1
    fi
    if step_enabled settings; then
        printf '\n%sClaude: merge settings + copy statusline%s\n' "${BOLD}" "${NC}"
        # Structured merge keeps CLI-written marketplace entries and local
        # machine preferences while updating repo-managed model, hook and
        # plugin keys. This is safe even when 'base' ran in the same invocation.
        local claude_groups
        claude_groups="$(config_groups_for_target claude)"
        if [[ -n "${claude_groups}" ]]; then
            merge_settings_config \
                "claude-settings" \
                "${SCRIPT_DIR}/ycc/settings/settings.json" \
                "${HOME}/.claude/settings.json" \
                "${claude_groups}"
        fi
        if [[ "${COMMAND}" != "sync" ]] || intent_requested settings; then
            copy_settings_file "${SCRIPT_DIR}/ycc/settings/statusline-command.sh" "${HOME}/.claude/statusline-command.sh"
        fi
        ran=1
    fi
    if step_enabled rules; then
        printf '\n%sClaude: link rules (CLAUDE.md + AGENTS.md)%s\n' "${BOLD}" "${NC}"
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/CLAUDE.md" "${HOME}/.claude/CLAUDE.md"
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/AGENTS.md" "${HOME}/.claude/AGENTS.md"
        ran=1
    fi
    if step_enabled mcp; then
        printf '\n%sClaude: merge MCP into ~/.claude.json%s\n' "${BOLD}" "${NC}"
        merge_claude_mcp_json
        ran=1
    fi
    if step_enabled hooks; then
        printf '\n%sClaude: link hooks directory into ~/.claude/hooks%s\n' "${BOLD}" "${NC}"
        # Directory-level symlink so new hook scripts are picked up automatically.
        # link_file refuses to replace a real directory at the destination, so an
        # existing ~/.claude/hooks (non-symlink) surfaces as an error rather than
        # being silently clobbered.
        link_file "${SCRIPT_DIR}/ycc/settings/hooks" "${HOME}/.claude/hooks"
        ran=1
    fi
    if [[ $ran -eq 0 ]]; then
        warn "Claude target ran no steps (pass --settings, --rules, --mcp, --hooks, or --only ...)"
    fi
    printf '\n%sClaude sync complete.%s\n' "${BOLD}" "${NC}"
    if [[ $base_ran -eq 1 ]]; then
        if [[ "${MODE:-local}" == "repo" ]]; then
            warn "Run /reload-plugins or start a new Claude Code session. The 'ycc' marketplace in ~/.claude/settings.json now tracks the github source yandy-r/claude-plugins."
            warn "Updates: rerun 'claude plugin install ycc@ycc --scope user' (or use the in-Claude /plugins UI) to pull the latest published commit."
            warn "The Claude settings file now contains the CLI-written marketplace entry. Re-running the settings step merges repo-managed keys and preserves that entry."
        else
            local claude_repo_root_msg
            claude_repo_root_msg="$(realpath "${SCRIPT_DIR}")"
            warn "Run /reload-plugins or start a new Claude Code session. The 'ycc' marketplace in ~/.claude/settings.json now points at ${claude_repo_root_msg} (directory source)."
            warn "Edits in ycc/ apply on plugin reload. No rsync, no cache clear."
            warn "The Claude settings file now contains the CLI-written marketplace entry. Re-running the settings step merges repo-managed keys and preserves that entry."
            warn "If you move or rename this repo, rerun ./install.sh --target claude --only base."
        fi
    fi
}

# ---------------------------------------------------------------------------
# Codex marketplace (~/.agents/plugins/marketplace.json)
# Registers ycc as a marketplace source for Codex.
#
#   local mode: registers ./plugins/ycc relative to ~/.agents/plugins/marketplace.json.
#               The installer creates ~/.agents/plugins/ycc as a symlink to the
#               generated bundle so Codex accepts the marketplace schema while
#               still reading live local repo output.
#   repo  mode: registers yandy-r/claude-plugins@main as a github source.
#               Codex resolves the bundle from the remote git ref on install.
# ---------------------------------------------------------------------------
merge_codex_marketplace_json() {
    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }

    local mode="${1:-}"
    if [[ ! "$mode" =~ ^(local|repo)$ ]]; then
        err "merge_codex_marketplace_json: invalid or missing mode '${mode}' (expected local|repo)"
        exit 1
    fi

    local plugin_src="${2:-}"
    if [[ "$mode" == "local" && -z "${plugin_src}" ]]; then
        err "merge_codex_marketplace_json: local mode requires a plugin source path"
        exit 1
    fi

    local dest="${HOME}/.agents/plugins/marketplace.json"
    python3 - "$dest" "$mode" "$plugin_src" <<'PY'
import json
import sys
from pathlib import Path

dest_path = Path(sys.argv[1])
mode = sys.argv[2]
plugin_src = sys.argv[3]
payload = {
    "name": "local-ycc-plugins",
    "interface": {
        "displayName": "Local YCC Plugins",
    },
}
if mode == "local":
    if not plugin_src.startswith("./"):
        sys.stderr.write("error: Codex local plugin source path must start with ./\n")
        sys.exit(1)
    source_block = {
        "source": "local",
        "path": plugin_src,
    }
elif mode == "repo":
    source_block = {
        "source": "github",
        "repo": "yandy-r/claude-plugins",
        "ref": "main",
    }
else:
    sys.stderr.write(f"error: unsupported mode '{mode}'\n")
    sys.exit(1)
entry = {
    "name": "ycc",
    "source": source_block,
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    },
    "category": "Productivity",
}

if dest_path.exists():
    with open(dest_path, encoding="utf-8") as handle:
        current = json.load(handle)
    if not isinstance(current, dict):
        raise SystemExit(f"{dest_path} must contain a JSON object")
else:
    current = {}

marketplace_name = current.get("name") if isinstance(current.get("name"), str) and current["name"].strip() else payload["name"]
interface = current.get("interface")
if interface is None:
    interface = payload["interface"]
elif not isinstance(interface, dict):
    raise SystemExit(f"{dest_path}: interface must be an object when present")

plugins = current.get("plugins")
if plugins is None:
    plugins = []
elif not isinstance(plugins, list):
    raise SystemExit(f"{dest_path}: plugins must be an array when present")

updated = False
for index, item in enumerate(plugins):
    if isinstance(item, dict) and item.get("name") == "ycc":
        if item != entry:
            plugins[index] = entry
        updated = True
        break

if not updated:
    plugins.append(entry)

merged = {
    **current,
    "name": marketplace_name,
    "interface": interface,
    "plugins": plugins,
}

dest_path.parent.mkdir(parents=True, exist_ok=True)
with open(dest_path, "w", encoding="utf-8") as handle:
    json.dump(merged, handle, indent=2, ensure_ascii=False)
    handle.write("\n")
PY
    info "Merged ycc into ${dest}"
}

# ---------------------------------------------------------------------------
# Cursor sync (base + optional MCP + optional settings/rules)
# ---------------------------------------------------------------------------
sync_cursor_target() {
    validate_only_steps "cursor"

    local cursor_dir="${HOME}/.cursor"
    local scripts_dir="${SCRIPT_DIR}/scripts"

    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }

    mkdir -p "${cursor_dir}"

    local do_base=0 do_settings=0 do_mcp=0 do_rules=0
    step_enabled base && do_base=1
    step_enabled settings && do_settings=1
    step_enabled mcp && do_mcp=1
    step_enabled rules && do_rules=1

    [[ $do_base -eq 1 ]] && { command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }; }

    if [[ $do_base -eq 0 && $do_settings -eq 0 && $do_mcp -eq 0 && $do_rules -eq 0 ]]; then
        warn "Cursor target ran no steps"
        printf '\n%sCursor sync complete.%s\n' "${BOLD}" "${NC}"
        return 0
    fi

    local total=0
    [[ $do_base -eq 1 ]] && total=$((total + 4))
    [[ $do_settings -eq 1 ]] && total=$((total + 1))
    [[ $do_mcp -eq 1 ]] && total=$((total + 1))
    [[ $do_rules -eq 1 ]] && total=$((total + 1))
    local step=0

    if [[ $do_base -eq 1 ]]; then
        if [[ ! -d "${CURSOR_PLUGIN_DIR}" ]]; then
            err "Cursor plugin source directory not found: ${CURSOR_PLUGIN_DIR}"
            exit 1
        fi

        local gen_agents="${scripts_dir}/generate-cursor-agents.sh"
        local gen_skills="${scripts_dir}/generate-cursor-skills.sh"
        local gen_rules="${scripts_dir}/generate-cursor-rules.sh"
        local val_agents="${scripts_dir}/validate-cursor-agents.sh"
        local val_skills="${scripts_dir}/validate-cursor-skills.sh"
        local val_rules="${scripts_dir}/validate-cursor-rules.sh"

        local s
        for s in "${gen_agents}" "${gen_skills}" "${gen_rules}" "${val_agents}" "${val_skills}" "${val_rules}"; do
            if [[ ! -f "${s}" ]]; then
                err "Missing required script: ${s}"
                exit 1
            fi
            if [[ ! -r "${s}" ]]; then
                err "Script not readable: ${s}"
                exit 1
            fi
        done

        step=$((step + 1))
        printf '\n%s[%d/%d] Generate Cursor-native bundle%s\n' "${BOLD}" "$step" "$total" "${NC}"
        info "Running generate-cursor-agents.sh"
        bash "${gen_agents}"
        info "Running generate-cursor-skills.sh"
        bash "${gen_skills}"
        info "Running generate-cursor-rules.sh"
        bash "${gen_rules}"

        step=$((step + 1))
        printf '\n%s[%d/%d] Validate generated bundle%s\n' "${BOLD}" "$step" "$total" "${NC}"
        info "Running validate-cursor-agents.sh"
        bash "${val_agents}"
        info "Running validate-cursor-skills.sh"
        bash "${val_skills}"
        info "Running validate-cursor-rules.sh"
        bash "${val_rules}"

        step=$((step + 1))
        printf '\n%s[%d/%d] Format modified repository files%s\n' "${BOLD}" "$step" "$total" "${NC}"
        run_repo_style_format_modified

        step=$((step + 1))
        printf '\n%s[%d/%d] Sync bundle to ~/.cursor%s\n' "${BOLD}" "$step" "$total" "${NC}"

        local managed_units=(skills agents rules)
        local unit
        for unit in "${managed_units[@]}"; do
            local src_unit="${CURSOR_PLUGIN_DIR}/${unit}/"
            local dest_unit="${cursor_dir}/${unit}/"

            if [[ -d "${src_unit}" ]]; then
                mkdir -p "${dest_unit}"
                rsync -av --delete "${src_unit}" "${dest_unit}"
                info "Synced ${unit}/ → ${dest_unit}"
            elif [[ -d "${dest_unit}" ]]; then
                rm -rf "${dest_unit}"
                warn "Removed ${dest_unit} (missing from .cursor-plugin)"
            else
                warn "Source not found, skipping: ${src_unit}"
            fi
        done
    fi

    if [[ $do_settings -eq 1 ]]; then
        step=$((step + 1))
        printf '\n%s[%d/%d] Merge Cursor CLI settings%s\n' "${BOLD}" "$step" "$total" "${NC}"
        merge_settings_config \
            "cursor-cli" \
            "${CURSOR_CLI_CONFIG_SRC}" \
            "${cursor_dir}/cli-config.json" \
            "settings"
    fi

    if [[ $do_mcp -eq 1 ]]; then
        step=$((step + 1))
        printf '\n%s[%d/%d] Sync MCP to ~/.cursor/mcp.json%s\n' "${BOLD}" "$step" "$total" "${NC}"
        sync_cursor_mcp_json
    fi

    if [[ $do_rules -eq 1 ]]; then
        step=$((step + 1))
        printf '\n%s[%d/%d] Link Cursor rules (CLAUDE.md + AGENTS.md)%s\n' "${BOLD}" "$step" "$total" "${NC}"
        # NOTE: linked at the ~/.cursor/ top level, NOT inside ~/.cursor/rules/.
        # The base step's rsync --delete on ~/.cursor/rules/ would clobber a link
        # placed inside that directory.
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/CLAUDE.md" "${cursor_dir}/CLAUDE.md"
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/AGENTS.md" "${cursor_dir}/AGENTS.md"
    fi

    printf '\n%sCursor sync complete.%s\n' "${BOLD}" "${NC}"
}

# ---------------------------------------------------------------------------
# Codex sync (base: plugin + agents + marketplace; settings: config link)
# ---------------------------------------------------------------------------
sync_codex_target() {
    validate_only_steps "codex"

    local codex_plugin_dest="${HOME}/.codex/plugins/ycc"
    local codex_marketplace_plugin_dest="${HOME}/.agents/plugins/ycc"
    local codex_plugin_cache_container="${HOME}/.codex/plugins/cache/local-ycc-plugins/ycc"
    local codex_agents_dest="${HOME}/.codex/agents"
    local scripts_dir="${SCRIPT_DIR}/scripts"

    local do_base=0 do_settings=0 do_rules=0
    step_enabled base && do_base=1
    step_enabled settings && do_settings=1
    step_enabled rules && do_rules=1

    if [[ $do_base -eq 0 && $do_settings -eq 0 && $do_rules -eq 0 ]]; then
        warn "Codex target ran no steps"
        printf '\n%sCodex sync complete.%s\n' "${BOLD}" "${NC}"
        return 0
    fi

    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    # Local-mode base needs rsync + realpath for the symlink + agents sync.
    # Repo-mode base only writes the marketplace JSON, so those tools are not required.
    if [[ $do_base -eq 1 && "${MODE:-local}" == "local" ]]; then
        command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }
        command -v realpath >/dev/null 2>&1 || { err "realpath is required but not found"; exit 1; }
    fi

    local local_base_steps=5
    local repo_base_steps=1
    local total=0
    if [[ $do_base -eq 1 ]]; then
        if [[ "${MODE:-local}" == "repo" ]]; then
            total=$((total + repo_base_steps))
        else
            total=$((total + local_base_steps))
        fi
    fi
    [[ $do_settings -eq 1 ]] && total=$((total + 1))
    [[ $do_rules -eq 1 ]] && total=$((total + 1))
    local step=0

    if [[ $do_base -eq 1 && "${MODE:-local}" == "repo" ]]; then
        # Repo mode: Codex resolves the bundle from the github ref on install.
        # We only need to write the marketplace entry. Bundle regeneration stays
        # out-of-band via ./scripts/sync.sh --only codex.
        step=$((step + 1))
        printf '\n%s[%d/%d] Register github repo as marketplace source (yandy-r/claude-plugins@main)%s\n' "${BOLD}" "$step" "$total" "${NC}"
        merge_codex_marketplace_json "repo"
    elif [[ $do_base -eq 1 ]]; then
        mkdir -p "${codex_agents_dest}"

        if [[ ! -d "${SCRIPT_DIR}/.codex-plugin" ]]; then
            err "Codex plugin source directory not found: ${SCRIPT_DIR}/.codex-plugin"
            exit 1
        fi
        if [[ ! -d "${CODEX_PLUGIN_DIR}" ]]; then
            err "Codex plugin bundle root not found: ${CODEX_PLUGIN_DIR}"
            exit 1
        fi
        if [[ ! -d "${CODEX_AGENTS_DIR}" ]]; then
            err "Codex agent source directory not found: ${CODEX_AGENTS_DIR}"
            exit 1
        fi

        local gen_plugin="${scripts_dir}/generate-codex-plugin.sh"
        local gen_skills="${scripts_dir}/generate-codex-skills.sh"
        local gen_agents="${scripts_dir}/generate-codex-agents.sh"
        local val_plugin="${scripts_dir}/validate-codex-plugin.sh"
        local val_skills="${scripts_dir}/validate-codex-skills.sh"
        local val_agents="${scripts_dir}/validate-codex-agents.sh"

        local s
        for s in "${gen_plugin}" "${gen_skills}" "${gen_agents}" "${val_plugin}" "${val_skills}" "${val_agents}"; do
            if [[ ! -f "${s}" ]]; then
                err "Missing required script: ${s}"
                exit 1
            fi
            if [[ ! -r "${s}" ]]; then
                err "Script not readable: ${s}"
                exit 1
            fi
        done

        step=$((step + 1))
        printf '\n%s[%d/%d] Generate Codex-native bundle%s\n' "${BOLD}" "$step" "$total" "${NC}"
        info "Running generate-codex-skills.sh"
        bash "${gen_skills}"
        info "Running generate-codex-agents.sh"
        bash "${gen_agents}"
        info "Running generate-codex-plugin.sh"
        bash "${gen_plugin}"

        step=$((step + 1))
        printf '\n%s[%d/%d] Validate generated bundle%s\n' "${BOLD}" "$step" "$total" "${NC}"
        info "Running validate-codex-skills.sh"
        bash "${val_skills}"
        info "Running validate-codex-agents.sh"
        bash "${val_agents}"
        info "Running validate-codex-plugin.sh"
        bash "${val_plugin}"

        step=$((step + 1))
        printf '\n%s[%d/%d] Format modified repository files%s\n' "${BOLD}" "$step" "$total" "${NC}"
        run_repo_style_format_modified

        step=$((step + 1))
        printf '\n%s[%d/%d] Link plugin tree + sync custom agents%s\n' "${BOLD}" "$step" "$total" "${NC}"
        # Symlink (not rsync) the plugin tree so edits in .codex-plugin/ycc/ are
        # live for Codex after regeneration. Generated skill bodies reference
        # ~/.codex/plugins/ycc/... as absolute paths; the symlink keeps those
        # references valid.
        if [[ -d "${codex_plugin_dest}" && ! -L "${codex_plugin_dest}" ]]; then
            err "Stale Codex plugin copy at ${codex_plugin_dest} (left over from the pre-symlink rsync flow)."
            err "Remove it with:  rm -rf ${codex_plugin_dest}"
            err "Then re-run this command. The symlink will be created in its place."
            exit 1
        fi
        if [[ -d "${codex_marketplace_plugin_dest}" && ! -L "${codex_marketplace_plugin_dest}" ]]; then
            err "Stale Codex marketplace plugin copy at ${codex_marketplace_plugin_dest}."
            err "Remove it with:  rm -rf ${codex_marketplace_plugin_dest}"
            err "Then re-run this command. The symlink will be created in its place."
            exit 1
        fi
        if [[ -L "${codex_plugin_cache_container}" ]]; then
            rm "${codex_plugin_cache_container}"
        elif [[ -e "${codex_plugin_cache_container}" && ! -d "${codex_plugin_cache_container}" ]]; then
            err "Stale Codex plugin cache path at ${codex_plugin_cache_container}."
            err "Remove it with:  rm -f ${codex_plugin_cache_container}"
            err "Then re-run this command. A directory will be created in its place."
            exit 1
        fi
        link_file "${CODEX_PLUGIN_DIR}" "${codex_plugin_dest}"
        link_file "${CODEX_PLUGIN_DIR}" "${codex_marketplace_plugin_dest}"
        mkdir -p "${codex_plugin_cache_container}"
        rsync -a --delete "${CODEX_PLUGIN_DIR}/" "${codex_plugin_cache_container}/"
        info "Synced Codex enabled-plugin cache → ${codex_plugin_cache_container}"
        python3 - "${codex_plugin_cache_container}" <<'PY'
import json
import sys
from pathlib import Path

cache_root = Path(sys.argv[1])
source_manifest = cache_root / ".codex-plugin" / "plugin.json"
skills_manifest = cache_root / "skills" / ".codex-plugin" / "plugin.json"
skills_index = cache_root / "skills" / "_skills"
payload = json.loads(source_manifest.read_text(encoding="utf-8"))
payload["skills"] = "./_skills/"
skills_manifest.parent.mkdir(parents=True, exist_ok=True)
skills_manifest.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
skills_index.mkdir(exist_ok=True)
for child in sorted((cache_root / "skills").iterdir()):
    if not child.is_dir() or child.name in {".codex-plugin", "_skills"}:
        continue
    link = skills_index / child.name
    if link.exists() or link.is_symlink():
        link.unlink()
    link.symlink_to(child, target_is_directory=True)
PY
        info "Wrote Codex cache compatibility manifest → ${codex_plugin_cache_container}/skills/.codex-plugin/plugin.json"
        mkdir -p "${codex_agents_dest}"
        rsync -av --delete "${CODEX_AGENTS_DIR}/" "${codex_agents_dest}/"
        info "Synced Codex custom agents → ${codex_agents_dest}"

        step=$((step + 1))
        printf '\n%s[%d/%d] Register repo as local marketplace source%s\n' "${BOLD}" "$step" "$total" "${NC}"
        merge_codex_marketplace_json "local" "./plugins/ycc"
    fi

    if [[ $do_settings -eq 1 ]]; then
        step=$((step + 1))
        printf '\n%s[%d/%d] Merge Codex config (config.toml)%s\n' "${BOLD}" "$step" "$total" "${NC}"
        # Merge managed keys only: trusted-project entries, MCP tokens,
        # connector IDs and comments in the user's config.toml are preserved.
        local codex_groups
        codex_groups="$(config_groups_for_target codex)"
        if [[ -n "${codex_groups}" ]]; then
            merge_settings_config \
                "codex-config" \
                "${SCRIPT_DIR}/.codex-plugin/config/config.toml" \
                "${HOME}/.codex/config.toml" \
                "${codex_groups}"
        fi
    fi

    if [[ $do_rules -eq 1 ]]; then
        step=$((step + 1))
        printf '\n%s[%d/%d] Link Codex rules (default.rules + CLAUDE.md + AGENTS.md)%s\n' "${BOLD}" "$step" "$total" "${NC}"
        link_file       "${SCRIPT_DIR}/.codex-plugin/config/default.rules" "${HOME}/.codex/rules/default.rules"
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/CLAUDE.md"       "${HOME}/.codex/CLAUDE.md"
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/AGENTS.md"       "${HOME}/.codex/AGENTS.md"
    fi

    printf '\n%sCodex sync complete.%s\n' "${BOLD}" "${NC}"
    if [[ $do_base -eq 1 ]]; then
        if [[ "${MODE:-local}" == "repo" ]]; then
            warn "Restart Codex; the 'local-ycc-plugins' marketplace in ~/.agents/plugins/marketplace.json now tracks the github source yandy-r/claude-plugins@main."
            warn "Updates: install ycc through the Codex /plugins UI to pull the latest published commit. No local symlink, no agents rsync."
            warn "If you also want to iterate on ycc/ source locally, regenerate the bundle with ./scripts/sync.sh --only codex and switch back to --mode local."
        else
            local codex_plugin_src_msg
            codex_plugin_src_msg="$(realpath "${CODEX_PLUGIN_DIR}")"
            warn "Restart Codex; the plugin tree at ${codex_plugin_dest} now symlinks into ${codex_plugin_src_msg} and is registered via the 'local-ycc-plugins' marketplace."
            warn "Local marketplace source uses ${codex_marketplace_plugin_dest} -> ${codex_plugin_src_msg}; the enabled-plugin cache root is refreshed at ${codex_plugin_cache_container}."
            warn "Rerun ./scripts/sync.sh --only codex after editing ycc/ to refresh the Codex bundle."
            warn "If you move or rename this repo, rerun ./install.sh --target codex --only base to refresh the symlinks."
        fi
    fi
}

# ---------------------------------------------------------------------------
# opencode sync (base: skills + agents + commands; settings: config + rules)
# ---------------------------------------------------------------------------
sync_opencode_target() {
    validate_only_steps "opencode"

    local opencode_dir="${HOME}/.config/opencode"
    local scripts_dir="${SCRIPT_DIR}/scripts"

    local do_base=0 do_settings=0 do_rules=0
    step_enabled base && do_base=1
    step_enabled settings && do_settings=1
    step_enabled rules && do_rules=1

    if [[ $do_base -eq 0 && $do_settings -eq 0 && $do_rules -eq 0 ]]; then
        warn "opencode target ran no steps"
        printf '\n%sopencode sync complete.%s\n' "${BOLD}" "${NC}"
        return 0
    fi

    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    [[ $do_base -eq 1 ]] && { command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }; }

    local total=0
    [[ $do_base -eq 1 ]] && total=$((total + 4))
    [[ $do_settings -eq 1 ]] && total=$((total + 1))
    [[ $do_rules -eq 1 ]] && total=$((total + 1))
    local step=0

    if [[ $do_base -eq 1 ]]; then
        if [[ ! -d "${OPENCODE_PLUGIN_DIR}" ]]; then
            err "opencode plugin source directory not found: ${OPENCODE_PLUGIN_DIR}"
            exit 1
        fi

        local gen_skills="${scripts_dir}/generate-opencode-skills.sh"
        local gen_agents="${scripts_dir}/generate-opencode-agents.sh"
        local gen_commands="${scripts_dir}/generate-opencode-commands.sh"
        local gen_plugin="${scripts_dir}/generate-opencode-plugin.sh"
        local val_skills="${scripts_dir}/validate-opencode-skills.sh"
        local val_agents="${scripts_dir}/validate-opencode-agents.sh"
        local val_commands="${scripts_dir}/validate-opencode-commands.sh"
        local val_plugin="${scripts_dir}/validate-opencode-plugin.sh"

        local s
        for s in "${gen_skills}" "${gen_agents}" "${gen_commands}" "${gen_plugin}" \
                 "${val_skills}" "${val_agents}" "${val_commands}" "${val_plugin}"; do
            if [[ ! -f "${s}" ]]; then
                err "Missing required script: ${s}"
                exit 1
            fi
            if [[ ! -r "${s}" ]]; then
                err "Script not readable: ${s}"
                exit 1
            fi
        done

        mkdir -p "${opencode_dir}"

        step=$((step + 1))
        printf '\n%s[%d/%d] Generate opencode-native bundle%s\n' "${BOLD}" "$step" "$total" "${NC}"
        info "Running generate-opencode-skills.sh"
        bash "${gen_skills}"
        info "Running generate-opencode-agents.sh"
        bash "${gen_agents}"
        info "Running generate-opencode-commands.sh"
        bash "${gen_commands}"
        info "Running generate-opencode-plugin.sh"
        bash "${gen_plugin}"

        step=$((step + 1))
        printf '\n%s[%d/%d] Validate generated bundle%s\n' "${BOLD}" "$step" "$total" "${NC}"
        info "Running validate-opencode-skills.sh"
        bash "${val_skills}"
        info "Running validate-opencode-agents.sh"
        bash "${val_agents}"
        info "Running validate-opencode-commands.sh"
        bash "${val_commands}"
        info "Running validate-opencode-plugin.sh"
        bash "${val_plugin}"

        step=$((step + 1))
        printf '\n%s[%d/%d] Format modified repository files%s\n' "${BOLD}" "$step" "$total" "${NC}"
        run_repo_style_format_modified

        step=$((step + 1))
        printf '\n%s[%d/%d] Sync bundle to ~/.config/opencode%s\n' "${BOLD}" "$step" "$total" "${NC}"

        # `shared/` carries the cross-skill scripts and references that
        # ycc/skills/_shared/... gets rewritten to at generation time
        # (~/.config/opencode/shared/...). It MUST stay in this list — see
        # scripts/validate-opencode-install-coverage.sh which enforces that
        # every <dir> referenced in the bundle is either rsynced here or
        # explicitly allowlisted as a user-global/runtime path.
        local managed_units=(skills agents commands shared)
        local unit
        for unit in "${managed_units[@]}"; do
            local src_unit="${OPENCODE_PLUGIN_DIR}/${unit}/"
            local dest_unit="${opencode_dir}/${unit}/"

            if [[ -d "${src_unit}" ]]; then
                mkdir -p "${dest_unit}"
                rsync -av --delete "${src_unit}" "${dest_unit}"
                info "Synced ${unit}/ → ${dest_unit}"
            elif [[ -d "${dest_unit}" ]]; then
                rm -rf "${dest_unit}"
                warn "Removed ${dest_unit} (missing from .opencode-plugin)"
            else
                warn "Source not found, skipping: ${src_unit}"
            fi
        done

        # opencode ALSO reads bundles from the Claude-compat path .claude/skills.
        # We deliberately do not write to that path from the opencode target so
        # users who also run `--target claude` don't end up with two copies.
    fi

    if [[ $do_settings -eq 1 ]]; then
        step=$((step + 1))
        printf '\n%s[%d/%d] Merge opencode config (opencode.json)%s\n' "${BOLD}" "$step" "$total" "${NC}"
        mkdir -p "${opencode_dir}"
        # Merge managed keys only: per-machine model overrides, provider
        # credentials and unknown keys in the user's opencode.json are kept.
        local opencode_groups
        opencode_groups="$(config_groups_for_target opencode)"
        if [[ -n "${opencode_groups}" ]]; then
            merge_settings_config \
                "opencode-config" \
                "${OPENCODE_PLUGIN_DIR}/opencode.json" \
                "${opencode_dir}/opencode.json" \
                "${opencode_groups}"
        fi
    fi

    if [[ $do_rules -eq 1 ]]; then
        step=$((step + 1))
        printf '\n%s[%d/%d] Link opencode rules (AGENTS.md)%s\n' "${BOLD}" "$step" "$total" "${NC}"
        mkdir -p "${opencode_dir}"
        # opencode's AGENTS.md is generator-produced from
        # ycc/settings/rules/CLAUDE.md (the same user-global ruleset the other
        # targets symlink directly). See scripts/generate_opencode_plugin.py
        # for the text transforms applied during generation. We link to the
        # bundle's AGENTS.md — not directly to ycc/settings/rules/ — so the
        # transformed copy is what lands in ~/.config/opencode/.
        link_file "${OPENCODE_PLUGIN_DIR}/AGENTS.md" "${opencode_dir}/AGENTS.md"
    fi

    printf '\n%sopencode sync complete.%s\n' "${BOLD}" "${NC}"
    if [[ $do_base -eq 1 ]]; then
        warn "Restart opencode to pick up the new skills/agents/commands."
    fi
}

# ---------------------------------------------------------------------------
# Target selection
# ---------------------------------------------------------------------------
ALL_TARGETS=(claude cursor codex opencode)

# is_known_target <target>
is_known_target() {
    local known
    for known in "${ALL_TARGETS[@]}"; do
        [[ "${known}" == "$1" ]] && return 0
    done
    return 1
}

# supports_repo_mode <target>
# cursor and opencode read bundles from local directories only.
supports_repo_mode() {
    [[ "$1" == "claude" || "$1" == "codex" ]]
}

# resolve_targets <csv>
# Populate TARGETS from a comma-separated --target value. 'all' expands to
# every target (minus repo-incapable ones under --mode repo) and must stand
# alone. Duplicates are dropped; order is preserved.
resolve_targets() {
    local csv="$1"
    local -a requested=()
    local target existing seen
    IFS=',' read -r -a requested <<< "${csv// /}"
    TARGETS=()

    if [[ ${#requested[@]} -eq 0 ]]; then
        err "--target requires at least one target"
        exit 1
    fi

    if [[ " ${requested[*]} " == *" all "* ]]; then
        if [[ ${#requested[@]} -ne 1 ]]; then
            err "--target 'all' cannot be combined with other targets"
            exit 1
        fi
        if [[ "${MODE}" == "repo" ]]; then
            warn "--mode repo: skipping cursor and opencode targets (no remote-source concept)."
            warn "  use --target cursor / --target opencode (default --mode local) to install those bundles."
        fi
        for target in "${ALL_TARGETS[@]}"; do
            if [[ "${MODE}" == "repo" ]] && ! supports_repo_mode "${target}"; then
                continue
            fi
            TARGETS+=("${target}")
        done
        return 0
    fi

    for target in "${requested[@]}"; do
        if [[ -z "${target}" ]]; then
            err "--target contains an empty value"
            exit 1
        fi
        if ! is_known_target "${target}"; then
            err "Unknown target: ${target} (supported: ${ALL_TARGETS[*]}, all)"
            exit 1
        fi
        seen=0
        for existing in "${TARGETS[@]:-}"; do
            [[ "${existing}" == "${target}" ]] && { seen=1; break; }
        done
        if [[ ${seen} -eq 0 ]]; then
            TARGETS+=("${target}")
        fi
    done
}

# preflight_targets
# Reject every invalid target/mode/--only combination before any target runs,
# so a multi-target invocation never stops half-applied.
preflight_targets() {
    local target
    for target in "${TARGETS[@]}"; do
        if [[ "${MODE}" == "repo" ]] && ! supports_repo_mode "${target}"; then
            err "--mode repo is not supported by the ${target} target"
            err "  ${target} has no remote-source concept; it reads bundles from local directories."
            err "  use --mode local (default), or --target all to skip it automatically."
            exit 1
        fi
        if [[ "${COMMAND}" != "sync" ]]; then
            validate_only_steps "${target}"
        fi
    done
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
TARGET=""
TARGETS=()
MODE="local"
COMMAND="legacy"
MCP=0
SETTINGS=0
RULES=0
HOOKS=0
FORCE=0
EXCLUSIVE_STEPS=0
ONLY_STEPS=()
INTENTS=()

# Optional ergonomic subcommand. Invocations that begin with --target retain
# the legacy CLI unchanged.
if [[ "${1:-}" == "sync" ]]; then
    COMMAND="sync"
    shift
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            [[ $# -lt 2 ]] && { err "--target requires an argument"; exit 1; }
            TARGET="$2"
            shift 2
            ;;
        --mode)
            [[ $# -lt 2 ]] && { err "--mode requires an argument (local|repo)"; exit 1; }
            MODE="$2"
            if [[ ! "$MODE" =~ ^(local|repo)$ ]]; then
                err "Invalid --mode: ${MODE} (supported: local, repo)"
                exit 1
            fi
            shift 2
            ;;
        --only)
            [[ $# -lt 2 ]] && { err "--only requires a comma-separated list of steps"; exit 1; }
            IFS=',' read -r -a ONLY_STEPS <<< "$2"
            if [[ ${#ONLY_STEPS[@]} -eq 0 ]]; then
                err "--only requires at least one step"
                exit 1
            fi
            shift 2
            ;;
        --intent)
            [[ $# -lt 2 ]] && { err "--intent requires a comma-separated list of intents"; exit 1; }
            IFS=',' read -r -a INTENTS <<< "$2"
            shift 2
            ;;
        --mcp)
            MCP=1
            shift
            ;;
        --settings)
            SETTINGS=1
            shift
            ;;
        --rules)
            RULES=1
            shift
            ;;
        --hooks)
            HOOKS=1
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "${TARGET}" ]]; then
    err "Missing required --target flag"
    usage
    exit 1
fi

if [[ "${COMMAND}" == "sync" ]]; then
    if [[ ${#INTENTS[@]} -eq 0 ]]; then
        err "sync requires --intent <intent,...>"
        exit 1
    fi
    if [[ ${#ONLY_STEPS[@]} -gt 0 || "${SETTINGS}" == "1" || "${RULES}" == "1" || "${MCP}" == "1" || "${HOOKS}" == "1" ]]; then
        err "sync --intent cannot be combined with --only, --settings, --rules, --mcp, or --hooks"
        exit 1
    fi

    declare -A seen_intents=()
    unique_intents=()
    for intent in "${INTENTS[@]}"; do
        if [[ -z "${intent}" ]]; then
            err "--intent contains an empty value"
            exit 1
        fi
        intent_valid=0
        for allowed in "${VALID_INTENTS[@]}"; do
            [[ "${intent}" == "${allowed}" ]] && intent_valid=1 && break
        done
        if [[ ${intent_valid} -eq 0 ]]; then
            err "unknown intent '${intent}' (valid: ${VALID_INTENTS[*]})"
            exit 1
        fi
        if [[ -z "${seen_intents[${intent}]:-}" ]]; then
            unique_intents+=("${intent}")
            seen_intents["${intent}"]=1
        fi
    done
    INTENTS=("${unique_intents[@]}")
elif [[ ${#INTENTS[@]} -gt 0 ]]; then
    err "--intent requires the 'sync' subcommand"
    exit 1
fi

if [[ ${#ONLY_STEPS[@]} -gt 0 ]]; then
    EXCLUSIVE_STEPS=1
    if [[ "${SETTINGS}" == "1" ]]; then
        warn "--settings is ignored when --only is used"
    fi
    if [[ "${RULES}" == "1" ]]; then
        warn "--rules is ignored when --only is used"
    fi
    if [[ "${MCP}" == "1" ]]; then
        warn "--mcp is ignored when --only is used"
    fi
    if [[ "${HOOKS}" == "1" ]]; then
        warn "--hooks is ignored when --only is used"
    fi
fi

resolve_targets "${TARGET}"
preflight_targets
for target in "${TARGETS[@]}"; do
    run_target "${target}" "sync_${target}_target"
done
