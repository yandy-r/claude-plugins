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

usage() {
    cat <<EOF
Usage: $(basename "$0") --target <target> [--settings] [--mcp] [--force] [--only <steps>]

Sync plugin assets to an IDE configuration directory.

Options:
  --target <target>   Target: claude, cursor, codex, opencode, or all
  --settings          Additive: also run the target's 'settings' step.
  --mcp               Additive: also run the target's 'mcp' step.
  --force             Replace a real (non-symlink) rules file (CLAUDE.md /
                      AGENTS.md) at the destination. Without --force, the
                      rules linker refuses to overwrite user-authored files.
  --only <steps>      Exclusive: run only the comma-separated steps
                      (e.g. --only settings, --only mcp,settings).
                      Overrides defaults and --settings/--mcp.
  --help              Show this help message

Semantics:
  Default (no --only):
    - Run the target's 'base' step (if any).
    - Additionally run 'settings' / 'mcp' if their flag is passed.
  With --only <steps>:
    - Run exactly the listed steps. Nothing else.

Target steps:
  claude    settings | mcp
            settings: symlink ycc/settings/{settings.json,statusline-command.sh}
                      AND ycc/settings/rules/{CLAUDE.md,AGENTS.md} into ~/.claude/.
            mcp:      merge mcp-configs/mcp.json mcpServers into ~/.claude.json.
            (no base; claude is flag-driven.)
  cursor    base | mcp | settings
            base:     generate + validate + format + rsync bundle to ~/.cursor/.
            mcp:      symlink mcp-configs/mcp.json → ~/.cursor/mcp.json.
            settings: symlink ycc/settings/rules/{CLAUDE.md,AGENTS.md} into
                      ~/.cursor/ (top level — NOT inside ~/.cursor/rules/, which
                      is rsynced with --delete during 'base').
  codex     base | settings
            base:     generate + validate + format + rsync plugin & agents +
                      merge marketplace entry.
            settings: symlink .codex-plugin/config/{config.toml,default.rules}
                      AND ycc/settings/rules/{CLAUDE.md,AGENTS.md} into ~/.codex/.
  opencode  base | settings
            base:     generate + validate + format + rsync skills/agents/commands
                      into ~/.config/opencode/.
            settings: symlink .opencode-plugin/{opencode.json,AGENTS.md} into
                      ~/.config/opencode/ (opencode's AGENTS.md is generator-
                      produced from the repo CLAUDE.md, not the generic
                      ycc/settings/rules tree). opencode reads MCP from
                      opencode.json, so enable MCP via --settings — there is no
                      separate mcp step.
  all       Run claude then cursor then codex then opencode; step flags propagate.

Examples:
  $(basename "$0") --target claude --settings --mcp
  $(basename "$0") --target claude --only mcp
  $(basename "$0") --target cursor                       # base only
  $(basename "$0") --target cursor --mcp                 # base + mcp
  $(basename "$0") --target cursor --settings            # base + rules symlinks
  $(basename "$0") --target cursor --only settings       # rules only
  $(basename "$0") --target codex --settings             # base + settings
  $(basename "$0") --target codex --only settings        # settings only
  $(basename "$0") --target opencode                     # base only
  $(basename "$0") --target opencode --settings          # base + symlink config + rules
  $(basename "$0") --target all --settings --mcp
  $(basename "$0") --target all --settings --force       # install rules everywhere,
                                                         # overwriting user files
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
        mcp)      [[ "${MCP:-0}" == "1" ]] ;;
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
    validate_only_steps "claude" "settings,mcp"

    local ran=0
    if step_enabled settings; then
        printf '\n%sClaude: link settings + statusline + rules%s\n' "${BOLD}" "${NC}"
        link_file       "${SCRIPT_DIR}/ycc/settings/settings.json"         "${HOME}/.claude/settings.json"
        link_file       "${SCRIPT_DIR}/ycc/settings/statusline-command.sh" "${HOME}/.claude/statusline-command.sh"
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/CLAUDE.md"       "${HOME}/.claude/CLAUDE.md"
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/AGENTS.md"       "${HOME}/.claude/AGENTS.md"
        ran=1
    fi
    if step_enabled mcp; then
        printf '\n%sClaude: merge MCP into ~/.claude.json%s\n' "${BOLD}" "${NC}"
        merge_claude_mcp_json
        ran=1
    fi
    if [[ $ran -eq 0 ]]; then
        warn "Claude target ran no steps (pass --settings, --mcp, or --only ...)"
    fi
    printf '\n%sClaude sync complete.%s\n' "${BOLD}" "${NC}"
}

# ---------------------------------------------------------------------------
# Codex marketplace (~/.agents/plugins/marketplace.json)
# ---------------------------------------------------------------------------
merge_codex_marketplace_json() {
    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }

    local dest="${HOME}/.agents/plugins/marketplace.json"
    python3 - "$dest" <<'PY'
import json
import sys
from pathlib import Path

dest_path = Path(sys.argv[1])
payload = {
    "name": "local-ycc-plugins",
    "interface": {
        "displayName": "Local YCC Plugins",
    },
}
entry = {
    "name": "ycc",
    "source": {
        "source": "local",
        "path": "./.codex/plugins/ycc",
    },
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
    validate_only_steps "cursor" "base,mcp,settings"

    local cursor_dir="${HOME}/.cursor"
    local scripts_dir="${SCRIPT_DIR}/scripts"

    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }

    mkdir -p "${cursor_dir}"

    local do_base=0 do_mcp=0 do_settings=0
    step_enabled base && do_base=1
    step_enabled mcp && do_mcp=1
    step_enabled settings && do_settings=1

    if [[ $do_base -eq 0 && $do_mcp -eq 0 && $do_settings -eq 0 ]]; then
        warn "Cursor target ran no steps"
        printf '\n%sCursor sync complete.%s\n' "${BOLD}" "${NC}"
        return 0
    fi

    local total=0
    [[ $do_base -eq 1 ]] && total=$((total + 4))
    [[ $do_mcp -eq 1 ]] && total=$((total + 1))
    [[ $do_settings -eq 1 ]] && total=$((total + 1))
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

    if [[ $do_settings -eq 1 ]]; then
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
    validate_only_steps "codex" "base,settings"

    local codex_plugins_dir="${HOME}/.codex/plugins"
    local codex_plugin_dest="${codex_plugins_dir}/ycc"
    local codex_agents_dest="${HOME}/.codex/agents"
    local scripts_dir="${SCRIPT_DIR}/scripts"

    local do_base=0 do_settings=0
    step_enabled base && do_base=1
    step_enabled settings && do_settings=1

    if [[ $do_base -eq 0 && $do_settings -eq 0 ]]; then
        warn "Codex target ran no steps"
        printf '\n%sCodex sync complete.%s\n' "${BOLD}" "${NC}"
        return 0
    fi

    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    [[ $do_base -eq 1 ]] && { command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }; }

    local total=0
    [[ $do_base -eq 1 ]] && total=$((total + 5))
    [[ $do_settings -eq 1 ]] && total=$((total + 1))
    local step=0

    if [[ $do_base -eq 1 ]]; then
        mkdir -p "${codex_plugins_dir}" "${codex_agents_dest}"

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
        printf '\n%s[%d/%d] Sync plugin source + agents%s\n' "${BOLD}" "$step" "$total" "${NC}"
        mkdir -p "${codex_plugin_dest}" "${codex_agents_dest}"
        rsync -av --delete "${CODEX_PLUGIN_DIR}/" "${codex_plugin_dest}/"
        info "Synced Codex plugin source → ${codex_plugin_dest}"
        rsync -av --delete "${CODEX_AGENTS_DIR}/" "${codex_agents_dest}/"
        info "Synced Codex custom agents → ${codex_agents_dest}"

        step=$((step + 1))
        printf '\n%s[%d/%d] Sync user marketplace entry%s\n' "${BOLD}" "$step" "$total" "${NC}"
        merge_codex_marketplace_json
    fi

    if [[ $do_settings -eq 1 ]]; then
        step=$((step + 1))
        printf '\n%s[%d/%d] Link Codex config files + rules%s\n' "${BOLD}" "$step" "$total" "${NC}"
        link_file       "${SCRIPT_DIR}/.codex-plugin/config/config.toml"   "${HOME}/.codex/config.toml"
        link_file       "${SCRIPT_DIR}/.codex-plugin/config/default.rules" "${HOME}/.codex/rules/default.rules"
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/CLAUDE.md"       "${HOME}/.codex/CLAUDE.md"
        link_rules_file "${SCRIPT_DIR}/ycc/settings/rules/AGENTS.md"       "${HOME}/.codex/AGENTS.md"
    fi

    printf '\n%sCodex sync complete.%s\n' "${BOLD}" "${NC}"
    if [[ $do_base -eq 1 ]]; then
        warn "Restart Codex, then open /plugins and install ycc from your local marketplace if it is not already installed."
    fi
}

# ---------------------------------------------------------------------------
# opencode sync (base: skills + agents + commands; settings: config + rules)
# ---------------------------------------------------------------------------
sync_opencode_target() {
    validate_only_steps "opencode" "base,settings"

    local opencode_dir="${HOME}/.config/opencode"
    local scripts_dir="${SCRIPT_DIR}/scripts"

    local do_base=0 do_settings=0
    step_enabled base && do_base=1
    step_enabled settings && do_settings=1

    if [[ $do_base -eq 0 && $do_settings -eq 0 ]]; then
        warn "opencode target ran no steps"
        printf '\n%sopencode sync complete.%s\n' "${BOLD}" "${NC}"
        return 0
    fi

    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    [[ $do_base -eq 1 ]] && { command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }; }

    local total=0
    [[ $do_base -eq 1 ]] && total=$((total + 4))
    [[ $do_settings -eq 1 ]] && total=$((total + 1))
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

        local managed_units=(skills agents commands)
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
        printf '\n%s[%d/%d] Link opencode config and rules%s\n' "${BOLD}" "$step" "$total" "${NC}"
        mkdir -p "${opencode_dir}"
        link_file "${OPENCODE_PLUGIN_DIR}/opencode.json" "${opencode_dir}/opencode.json"
        # NOTE: opencode's AGENTS.md is generator-produced (transformed from the
        # repo-root CLAUDE.md — see scripts/generate_opencode_plugin.py) and
        # therefore intentionally does NOT use ycc/settings/rules/. Do not
        # "unify" this path with the other targets without first changing the
        # generator; it ships ycc-aware rules via the opencode bundle contract.
        link_file "${OPENCODE_PLUGIN_DIR}/AGENTS.md"    "${opencode_dir}/AGENTS.md"
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
    sync_claude_target
    sync_cursor_target
    sync_codex_target
    sync_opencode_target
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
TARGET=""
MCP=0
SETTINGS=0
FORCE=0
ONLY_STEPS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            [[ $# -lt 2 ]] && { err "--target requires an argument"; exit 1; }
            TARGET="$2"
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
    if [[ "${MCP}" == "1" ]]; then
        warn "--mcp is ignored when --only is used"
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
