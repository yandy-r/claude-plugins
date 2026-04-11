#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# install.sh — sync plugin assets to target IDE config directories
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_PLUGIN_DIR="${SCRIPT_DIR}/.cursor-plugin"
CODEX_PLUGIN_DIR="${SCRIPT_DIR}/.codex-plugin/ycc"
CODEX_AGENTS_DIR="${SCRIPT_DIR}/.codex-plugin/agents"
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

usage() {
    cat <<EOF
Usage: $(basename "$0") --target <target>

Sync plugin assets to an IDE configuration directory.

Options:
  --target <target>   Target: claude, cursor, codex, or all
  --help              Show this help message

Targets:
  claude   Merge mcp-configs/mcp.json mcpServers into ~/.claude.json (user scope)
  cursor   Generate Cursor-native agents/skills/rules, validate, rsync bundle to
           ~/.cursor/, then copy MCP config to ~/.cursor/mcp.json
  codex    Generate Codex-native plugin + agents, validate, sync plugin source to
           ~/.codex/plugins/ycc, sync agents to ~/.codex/agents, and merge the
           ycc entry into ~/.agents/plugins/marketplace.json
  all      Run claude then cursor then codex pipelines

Examples:
  $(basename "$0") --target claude
  $(basename "$0") --target cursor
  $(basename "$0") --target codex
  $(basename "$0") --target all
EOF
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
    local cursor_dir="${HOME}/.cursor"
    local dest="${cursor_dir}/mcp.json"

    if [[ ! -f "${MCP_CONFIG_SRC}" ]]; then
        err "MCP source not found: ${MCP_CONFIG_SRC}"
        exit 1
    fi
    if [[ ! -r "${MCP_CONFIG_SRC}" ]]; then
        err "MCP source not readable: ${MCP_CONFIG_SRC}"
        exit 1
    fi

    mkdir -p "${cursor_dir}"
    install -m0644 "${MCP_CONFIG_SRC}" "${dest}"
    info "Synced MCP config → ${dest}"
}

# ---------------------------------------------------------------------------
# Claude target (MCP only)
# ---------------------------------------------------------------------------
sync_claude_target() {
    printf '\n%sClaude: merge MCP into ~/.claude.json%s\n' "${BOLD}" "${NC}"
    merge_claude_mcp_json
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
# Cursor sync (bundle + MCP)
# ---------------------------------------------------------------------------
sync_cursor_target() {
    local cursor_dir="${HOME}/.cursor"
    local scripts_dir="${SCRIPT_DIR}/scripts"

    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }

    mkdir -p "${cursor_dir}"

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

    printf '\n%s[1/4] Generate Cursor-native bundle%s\n' "${BOLD}" "${NC}"
    info "Running generate-cursor-agents.sh"
    bash "${gen_agents}"
    info "Running generate-cursor-skills.sh"
    bash "${gen_skills}"
    info "Running generate-cursor-rules.sh"
    bash "${gen_rules}"

    printf '\n%s[2/4] Validate generated bundle%s\n' "${BOLD}" "${NC}"
    info "Running validate-cursor-agents.sh"
    bash "${val_agents}"
    info "Running validate-cursor-skills.sh"
    bash "${val_skills}"
    info "Running validate-cursor-rules.sh"
    bash "${val_rules}"

    printf '\n%s[3/4] Sync bundle to ~/.cursor%s\n' "${BOLD}" "${NC}"

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

    printf '\n%s[4/4] Sync MCP to ~/.cursor/mcp.json%s\n' "${BOLD}" "${NC}"
    sync_cursor_mcp_json

    printf '\n%sCursor sync complete.%s\n' "${BOLD}" "${NC}"
}

# ---------------------------------------------------------------------------
# Codex sync (plugin source + agents + marketplace)
# ---------------------------------------------------------------------------
sync_codex_target() {
    local codex_plugins_dir="${HOME}/.codex/plugins"
    local codex_plugin_dest="${codex_plugins_dir}/ycc"
    local codex_agents_dest="${HOME}/.codex/agents"
    local scripts_dir="${SCRIPT_DIR}/scripts"

    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }

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

    printf '\n%s[1/4] Generate Codex-native bundle%s\n' "${BOLD}" "${NC}"
    info "Running generate-codex-skills.sh"
    bash "${gen_skills}"
    info "Running generate-codex-agents.sh"
    bash "${gen_agents}"
    info "Running generate-codex-plugin.sh"
    bash "${gen_plugin}"

    printf '\n%s[2/4] Validate generated bundle%s\n' "${BOLD}" "${NC}"
    info "Running validate-codex-skills.sh"
    bash "${val_skills}"
    info "Running validate-codex-agents.sh"
    bash "${val_agents}"
    info "Running validate-codex-plugin.sh"
    bash "${val_plugin}"

    printf '\n%s[3/4] Sync plugin source + agents%s\n' "${BOLD}" "${NC}"
    mkdir -p "${codex_plugin_dest}" "${codex_agents_dest}"
    rsync -av --delete "${CODEX_PLUGIN_DIR}/" "${codex_plugin_dest}/"
    info "Synced Codex plugin source → ${codex_plugin_dest}"
    rsync -av --delete "${CODEX_AGENTS_DIR}/" "${codex_agents_dest}/"
    info "Synced Codex custom agents → ${codex_agents_dest}"

    printf '\n%s[4/4] Sync user marketplace entry%s\n' "${BOLD}" "${NC}"
    merge_codex_marketplace_json

    printf '\n%sCodex sync complete.%s\n' "${BOLD}" "${NC}"
    warn "Restart Codex, then open /plugins and install ycc from your local marketplace if it is not already installed."
}

# ---------------------------------------------------------------------------
# All targets
# ---------------------------------------------------------------------------
sync_all_targets() {
    sync_claude_target
    sync_cursor_target
    sync_codex_target
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            [[ $# -lt 2 ]] && { err "--target requires an argument"; exit 1; }
            TARGET="$2"
            shift 2
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
    all)
        sync_all_targets
        ;;
    *)
        err "Unknown target: ${TARGET} (supported: claude, cursor, codex, all)"
        exit 1
        ;;
esac
