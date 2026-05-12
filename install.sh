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

usage() {
    cat <<EOF
Usage: $(basename "$0") --target <target> [--mode <mode>] [--settings] [--rules] [--mcp] [--hooks] [--force] [--only <steps>]

Sync plugin assets to an IDE configuration directory.

Options:
  --target <target>   Target: claude, cursor, codex, opencode, or all
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
  --settings          Additive: COPY per-machine config files so local edits
                      (model, reasoning effort, statusline tweaks, MCP tokens,
                      marketplace entries written by the CLI, trusted-project
                      lists, ...) don't back-propagate into the repo. Refuses
                      to overwrite an existing real file without --force;
                      replaces symlinks in place with an info warning (so
                      upgrading from the old symlink flow is a no-op).
                      Mode-agnostic. Scope per target:
                        claude   — settings.json, statusline-command.sh
                        codex    — config.toml
                        opencode — opencode.json
                        cursor   — (no config; use --rules for CLAUDE.md/AGENTS.md)
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
  --force             Replace a real (non-symlink) file at the destination.
                        --settings: overwrite local edits in an existing
                                    config file with the repo copy.
                        --rules:    replace a user-authored CLAUDE.md /
                                    AGENTS.md with the repo symlink.
  --only <steps>      Exclusive: run only the comma-separated steps
                      (e.g. --only settings, --only rules,settings).
                      Overrides defaults and --settings/--rules/--mcp/--hooks.
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
            settings: COPY ycc/settings/{settings.json,statusline-command.sh}
                      into ~/.claude/. Per-machine edits (model, effortLevel,
                      marketplace entries, ...) no longer back-propagate into
                      the repo. Refuses to overwrite an existing real file
                      (e.g., one that already contains the CLI-written
                      marketplace entry) without --force.
            rules:    symlink ycc/settings/rules/{CLAUDE.md,AGENTS.md} into
                      ~/.claude/.
            mcp:      merge mcp-configs/mcp.json mcpServers into ~/.claude.json.
            hooks:    symlink ycc/settings/hooks/ into ~/.claude/hooks/, enabling
                      the WorktreeCreate hook (redirects harness-managed
                      worktrees to ~/.claude-worktrees/).
  cursor    base | mcp | rules
            base:     generate + validate + format + rsync bundle to ~/.cursor/.
            mcp:      symlink mcp-configs/mcp.json → ~/.cursor/mcp.json.
            rules:    symlink ycc/settings/rules/{CLAUDE.md,AGENTS.md} into
                      ~/.cursor/ (top level — NOT inside ~/.cursor/rules/, which
                      is rsynced with --delete during 'base').
                      (cursor has no 'settings' step — no per-machine config
                      file to copy.)
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
            settings: COPY .codex-plugin/config/config.toml into ~/.codex/.
                      Per-machine edits (model, reasoning effort, trusted
                      projects, MCP bearer tokens, ...) no longer back-
                      propagate into the repo.
            rules:    symlink .codex-plugin/config/default.rules AND
                      ycc/settings/rules/{CLAUDE.md,AGENTS.md} into ~/.codex/.
  opencode  base | settings | rules
            base:     generate + validate + format + rsync skills/agents/commands
                      into ~/.config/opencode/.
            settings: COPY .opencode-plugin/opencode.json into
                      ~/.config/opencode/. Per-machine edits (model, provider
                      tokens, MCP blocks) no longer back-propagate. opencode
                      reads MCP from opencode.json, so enable MCP via
                      --settings — there is no separate mcp step.
            rules:    symlink .opencode-plugin/AGENTS.md into
                      ~/.config/opencode/ (generator-produced from
                      ycc/settings/rules/CLAUDE.md — the same user-global
                      ruleset as every other target).
  all       Run claude then cursor then codex then opencode; step flags propagate.

Examples:
  $(basename "$0") --target claude                         # base only (register local marketplace)
  $(basename "$0") --target claude --only base             # same, exclusive
  $(basename "$0") --target claude --settings --rules      # base + copy settings + link rules
  $(basename "$0") --target claude --settings --rules --mcp
  $(basename "$0") --target claude --only settings         # copy settings only
  $(basename "$0") --target claude --only rules            # link rules only
  $(basename "$0") --target claude --only mcp
  $(basename "$0") --target claude --settings --force      # overwrite local settings.json with repo copy
  $(basename "$0") --target claude --hooks                 # base + WorktreeCreate hook
  $(basename "$0") --target claude --only hooks            # hooks only
  $(basename "$0") --target cursor                         # base only
  $(basename "$0") --target cursor --mcp                   # base + mcp
  $(basename "$0") --target cursor --rules                 # base + rules symlinks
  $(basename "$0") --target cursor --only rules            # rules only
  $(basename "$0") --target codex --settings --rules       # base + copy config + link rules
  $(basename "$0") --target codex --only settings          # copy config.toml only
  $(basename "$0") --target codex --only rules             # link default.rules + CLAUDE.md + AGENTS.md
  $(basename "$0") --target opencode                       # base only
  $(basename "$0") --target opencode --settings --rules    # base + copy opencode.json + link AGENTS.md
  $(basename "$0") --target all --settings --rules --mcp
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
merge_claude_mcp_json() {
    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }

    if [[ ! -f "${MCP_CONFIG_SRC}" ]]; then
        err "MCP source not found: ${MCP_CONFIG_SRC}"
        exit 1
    fi
    if [[ ! -r "${MCP_CONFIG_SRC}" ]]; then
        err "MCP source not readable: ${MCP_CONFIG_SRC}"
        exit 1
    fi

    local dest="${HOME}/.claude.json"
    python3 - "$MCP_CONFIG_SRC" "$dest" <<'PY'
import json
import sys
from pathlib import Path

src_path = Path(sys.argv[1])
dest_path = Path(sys.argv[2])

with open(src_path, encoding="utf-8") as f:
    src = json.load(f)
if "mcpServers" not in src or not isinstance(src["mcpServers"], dict):
    sys.stderr.write("error: mcp-configs/mcp.json must contain a top-level object mcpServers\n")
    sys.exit(1)
incoming = src["mcpServers"]

if dest_path.exists():
    with open(dest_path, encoding="utf-8") as f:
        try:
            dest = json.load(f)
        except json.JSONDecodeError as e:
            sys.stderr.write(f"error: invalid JSON in {dest_path}: {e}\n")
            sys.exit(1)
    if not isinstance(dest, dict):
        sys.stderr.write("error: ~/.claude.json must be a JSON object\n")
        sys.exit(1)
else:
    dest = {}

existing = dest.get("mcpServers")
if existing is None:
    existing = {}
elif not isinstance(existing, dict):
    sys.stderr.write("error: mcpServers in ~/.claude.json must be an object\n")
    sys.exit(1)

merged = {**existing, **incoming}
dest["mcpServers"] = merged

dest_path.parent.mkdir(parents=True, exist_ok=True)
with open(dest_path, "w", encoding="utf-8") as f:
    json.dump(dest, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    info "Merged mcpServers into ${dest}"
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

# validate_only_steps <target> <valid_steps_csv>
# If --only was passed, ensure every requested step is valid for the target.
validate_only_steps() {
    local target="$1"
    local valid_csv="$2"
    [[ ${#ONLY_STEPS[@]} -eq 0 ]] && return 0

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
# Claude target (settings + mcp; no base)
# ---------------------------------------------------------------------------
sync_claude_target() {
    validate_only_steps "claude" "base,settings,rules,mcp,hooks"

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
        printf '\n%sClaude: copy settings + statusline%s\n' "${BOLD}" "${NC}"
        # Copy (not symlink) so per-machine edits (model, effortLevel, MCP
        # toggles, CLI-added marketplace entries) don't back-propagate into
        # ycc/settings/settings.json. copy_settings_file refuses to overwrite
        # a real file without --force, preserving any marketplace entry written
        # by the 'base' step.
        #
        # If 'base' ran in this same invocation, ~/.claude/settings.json was
        # just written by the claude CLI (marketplace entry + enabledPlugins).
        # Copying the repo version over it would wipe that entry. Skip the
        # copy here — 'base' already materialized fresh content from the repo
        # as its starting point, so the file is up-to-date. If the user
        # explicitly wants to refresh from the repo, they can run
        # '--only settings --force' followed by '--only base' to re-register.
        if [[ $base_ran -eq 1 ]]; then
            info "skip: ${HOME}/.claude/settings.json (base just wrote the marketplace entry; re-copying would wipe it)"
        else
            copy_settings_file "${SCRIPT_DIR}/ycc/settings/settings.json" "${HOME}/.claude/settings.json"
        fi
        copy_settings_file "${SCRIPT_DIR}/ycc/settings/statusline-command.sh" "${HOME}/.claude/statusline-command.sh"
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
            warn "Heads up: ~/.claude/settings.json now contains the CLI-written marketplace entry. Re-running '--settings' without --force is blocked; with --force it overwrites the file with the repo version (wiping the marketplace entry), so re-run '--only base' afterwards to re-register."
        else
            local claude_repo_root_msg
            claude_repo_root_msg="$(realpath "${SCRIPT_DIR}")"
            warn "Run /reload-plugins or start a new Claude Code session. The 'ycc' marketplace in ~/.claude/settings.json now points at ${claude_repo_root_msg} (directory source)."
            warn "Edits in ycc/ apply on plugin reload. No rsync, no cache clear."
            warn "Heads up: ~/.claude/settings.json now contains the CLI-written marketplace entry. Re-running '--settings' without --force is blocked; with --force it overwrites the file with the repo version (wiping the marketplace entry), so re-run '--only base' afterwards to re-register."
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
    validate_only_steps "cursor" "base,mcp,rules"

    if [[ "${MODE:-local}" == "repo" ]]; then
        err "--mode repo is not supported by the cursor target"
        err "  cursor has no remote-source concept; it reads bundles from ~/.cursor/{skills,agents,rules}/."
        err "  use --mode local (default) to rsync the local bundle into ~/.cursor/."
        exit 1
    fi

    local cursor_dir="${HOME}/.cursor"
    local scripts_dir="${SCRIPT_DIR}/scripts"

    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }

    mkdir -p "${cursor_dir}"

    local do_base=0 do_mcp=0 do_rules=0
    step_enabled base && do_base=1
    step_enabled mcp && do_mcp=1
    step_enabled rules && do_rules=1

    if [[ $do_base -eq 0 && $do_mcp -eq 0 && $do_rules -eq 0 ]]; then
        warn "Cursor target ran no steps"
        printf '\n%sCursor sync complete.%s\n' "${BOLD}" "${NC}"
        return 0
    fi

    local total=0
    [[ $do_base -eq 1 ]] && total=$((total + 4))
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
    validate_only_steps "codex" "base,settings,rules"

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
        printf '\n%s[%d/%d] Copy Codex config (config.toml)%s\n' "${BOLD}" "$step" "$total" "${NC}"
        # Copy (not symlink) so per-machine edits (model, reasoning effort,
        # trusted-project entries, MCP tokens, ...) don't back-propagate into
        # .codex-plugin/config/config.toml.
        copy_settings_file "${SCRIPT_DIR}/.codex-plugin/config/config.toml" "${HOME}/.codex/config.toml"
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
    validate_only_steps "opencode" "base,settings,rules"

    if [[ "${MODE:-local}" == "repo" ]]; then
        err "--mode repo is not supported by the opencode target"
        err "  opencode has no remote-source concept; it reads bundles from ~/.config/opencode/{skills,agents,commands}/."
        err "  use --mode local (default) to rsync the local bundle into ~/.config/opencode/."
        exit 1
    fi

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
        printf '\n%s[%d/%d] Copy opencode config (opencode.json)%s\n' "${BOLD}" "$step" "$total" "${NC}"
        mkdir -p "${opencode_dir}"
        # Copy (not symlink) so per-machine edits (model, provider tokens, MCP
        # blocks) don't back-propagate into .opencode-plugin/opencode.json.
        copy_settings_file "${OPENCODE_PLUGIN_DIR}/opencode.json" "${opencode_dir}/opencode.json"
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
# All targets
# ---------------------------------------------------------------------------
sync_all_targets() {
    if [[ "${MODE:-local}" == "repo" ]]; then
        warn "--mode repo: skipping cursor and opencode targets (no remote-source concept)."
        warn "  use --target cursor / --target opencode (default --mode local) to install those bundles."
        sync_claude_target
        sync_codex_target
        return 0
    fi
    sync_claude_target
    sync_cursor_target
    sync_codex_target
    sync_opencode_target
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
TARGET=""
MODE="local"
MCP=0
SETTINGS=0
RULES=0
HOOKS=0
FORCE=0
ONLY_STEPS=()

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

if [[ ${#ONLY_STEPS[@]} -gt 0 ]]; then
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

case "${TARGET}" in
    claude)
        sync_claude_target
        ;;
    cursor)
        sync_cursor_target
        ;;
    codex)
        sync_codex_target
        ;;
    opencode)
        sync_opencode_target
        ;;
    all)
        sync_all_targets
        ;;
    *)
        err "Unknown target: ${TARGET} (supported: claude, cursor, codex, opencode, all)"
        exit 1
        ;;
esac
