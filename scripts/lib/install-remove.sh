#!/usr/bin/env bash
# install-remove.sh — the 'remove' subcommand's per-target steps.
#
# Sourced by install.sh (never run directly); relies on its helpers (info,
# warn, err, step_enabled, merge_settings_config, config_groups_for_target,
# run_mcp_step, mods_plugin_names, selected_slices, run_slice, ...) and globals
# (SCRIPT_DIR, FORCE, ...).
#
# Every step undoes what the matching install step wrote and nothing else:
#   - structured config: managed entries only, via merge_managed_config.py
#     --remove (user-edited values survive unless --force)
#   - symlinks: removed only while they still point at this checkout
#   - copied files: removed only while byte-identical to the repo (or --force)
#   - mirrored bundles ('base'): only the entries the bundle ships
#   - standalone slices (skills/agents/commands): entries ycc recorded as
#     installed, or still identical to the bundle (see install_slices.py)
#   - CLI registrations: undone through the same CLI that made them

# remove_codex_marketplace_entry — drop the ycc entry from
# ~/.agents/plugins/marketplace.json; delete the file if the installer's
# scaffold is all that is left.
remove_codex_marketplace_entry() {
    local dest="${HOME}/.agents/plugins/marketplace.json"
    [[ -f "${dest}" ]] || { info "nothing to remove: ${dest}"; return 0; }
    python3 - "${dest}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
plugins = data.get("plugins") if isinstance(data, dict) else None
if not isinstance(plugins, list) or not any(isinstance(p, dict) and p.get("name") == "ycc" for p in plugins):
    print(f"  [ok] nothing to remove: {path}")
    sys.exit(0)
data["plugins"] = [p for p in plugins if not (isinstance(p, dict) and p.get("name") == "ycc")]
scaffold = {"name": "local-ycc-plugins", "interface": {"displayName": "Local YCC Plugins"}, "plugins": []}
if data == scaffold:
    path.unlink()
    print(f"  [ok] removed {path} (only the ycc entry was left)")
else:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"  [ok] removed the ycc entry from {path}")
PY
}

remove_codex_target() {
    validate_only_steps "codex"
    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    local codex_dir="${HOME}/.codex"

    if step_enabled mcp; then
        printf '\n%sCodex: remove MCP servers%s\n' "${BOLD}" "${NC}"
        run_mcp_step codex
    fi
    if step_enabled rules; then
        printf '\n%sCodex: unlink rules (default.rules + CLAUDE.md + AGENTS.md)%s\n' "${BOLD}" "${NC}"
        unlink_owned_link "${SCRIPT_DIR}/.codex-plugin/config/default.rules" "${codex_dir}/rules/default.rules"
        unlink_owned_link "${SCRIPT_DIR}/ycc/settings/rules/CLAUDE.md" "${codex_dir}/CLAUDE.md"
        unlink_owned_link "${SCRIPT_DIR}/ycc/settings/rules/AGENTS.md" "${codex_dir}/AGENTS.md"
    fi
    if step_enabled settings; then
        printf '\n%sCodex: remove managed config (config.toml)%s\n' "${BOLD}" "${NC}"
        remove_settings "codex-config" "${SCRIPT_DIR}/.codex-plugin/config/config.toml" \
            "${codex_dir}/config.toml" "$(config_groups_for_target codex)"
    fi
    remove_slices codex skills agents
    if step_enabled base; then
        printf '\n%sCodex: remove plugin links, cache, custom agents + marketplace entry%s\n' "${BOLD}" "${NC}"
        uninstall_codex_plugin
        unlink_owned_link "${CODEX_PLUGIN_DIR}" "${codex_dir}/plugins/ycc"
        unlink_owned_link "${CODEX_PLUGIN_DIR}" "${HOME}/.agents/plugins/ycc"
        # Whatever cache is left (the legacy hand-written copy, or a snapshot
        # the CLI could not remove) belongs to this marketplace entry.
        if [[ -e "${CODEX_PLUGIN_CACHE}" || -L "${CODEX_PLUGIN_CACHE}" ]]; then
            rm -rf "${CODEX_PLUGIN_CACHE}"
            info "removed ${CODEX_PLUGIN_CACHE}"
        fi
        rmdir "$(dirname "${CODEX_PLUGIN_CACHE}")" 2>/dev/null || true
        remove_mirrored_entries "${CODEX_AGENTS_DIR}" "${codex_dir}/agents"
        remove_codex_marketplace_entry
    fi
    printf '\n%sCodex remove complete.%s\n' "${BOLD}" "${NC}"
}

remove_opencode_target() {
    validate_only_steps "opencode"
    local opencode_dir="${HOME}/.config/opencode"

    if step_enabled mcp; then
        printf '\n%sopencode: remove MCP servers%s\n' "${BOLD}" "${NC}"
        run_mcp_step opencode
    fi
    if step_enabled rules; then
        printf '\n%sopencode: unlink rules (AGENTS.md)%s\n' "${BOLD}" "${NC}"
        unlink_owned_link "${OPENCODE_PLUGIN_DIR}/AGENTS.md" "${opencode_dir}/AGENTS.md"
    fi
    if step_enabled settings; then
        printf '\n%sopencode: remove managed config (opencode.json)%s\n' "${BOLD}" "${NC}"
        remove_settings "opencode-config" "${OPENCODE_PLUGIN_DIR}/opencode.json" \
            "${opencode_dir}/opencode.json" "$(config_groups_for_target opencode)"
    fi
    remove_slices opencode skills agents commands
    if step_enabled base; then
        printf '\n%sopencode: remove bundle from ~/.config/opencode%s\n' "${BOLD}" "${NC}"
        local unit
        for unit in skills agents commands shared; do
            remove_mirrored_entries "${OPENCODE_PLUGIN_DIR}/${unit}" "${opencode_dir}/${unit}"
        done
    fi
    printf '\n%sopencode remove complete.%s\n' "${BOLD}" "${NC}"
}
