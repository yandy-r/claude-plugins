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

# unlink_owned_link <src> <dest> — remove <dest> if it is our symlink to <src>.
unlink_owned_link() {
    local src="$1" dest="$2"
    if [[ ! -e "${dest}" && ! -L "${dest}" ]]; then
        info "nothing to remove: ${dest}"
    elif [[ -L "${dest}" && "$(readlink "${dest}")" == "${src}" ]]; then
        rm "${dest}"
        info "removed link ${dest}"
    else
        warn "kept ${dest}: not a link to ${src} (not installed by ycc)"
    fi
}

# remove_copied_file <src> <dest> — remove a file the installer copied.
remove_copied_file() {
    local src="$1" dest="$2"
    if [[ ! -e "${dest}" && ! -L "${dest}" ]]; then
        info "nothing to remove: ${dest}"
        return 0
    fi
    local ours=0
    if [[ -L "${dest}" ]]; then
        # Pre-copy installs symlinked the file instead.
        [[ "$(readlink "${dest}")" == "${src}" ]] && ours=1
    elif [[ -f "${dest}" ]]; then
        if cmp -s "${src}" "${dest}" || [[ "${FORCE}" == "1" ]]; then
            ours=1
        fi
    fi
    if [[ ${ours} -eq 1 ]]; then
        rm "${dest}"
        info "removed ${dest}"
    else
        warn "kept ${dest}: it differs from the repo copy (re-run with --force to remove it)"
    fi
}

# remove_mirrored_entries <src_dir> <dest_dir> — delete each top-level entry
# the bundle ships from the installed mirror, then the mirror if left empty.
# Entries a newer or older bundle shipped under other names are not touched.
remove_mirrored_entries() {
    local src_dir="$1" dest_dir="$2"
    if [[ ! -d "${dest_dir}" ]]; then
        info "nothing to remove: ${dest_dir}"
        return 0
    fi
    [[ -d "${src_dir}" ]] || { warn "bundle source missing, skipping: ${src_dir}"; return 0; }
    local entry name count=0
    for entry in "${src_dir}"/* "${src_dir}"/.[!.]*; do
        [[ -e "${entry}" || -L "${entry}" ]] || continue
        name="$(basename "${entry}")"
        if [[ -e "${dest_dir}/${name}" || -L "${dest_dir}/${name}" ]]; then
            rm -rf "${dest_dir:?}/${name}"
            count=$((count + 1))
        fi
    done
    info "removed ${count} bundle entr$([[ ${count} -eq 1 ]] && echo y || echo ies) from ${dest_dir}"
    if rmdir "${dest_dir}" 2>/dev/null; then
        info "removed empty directory ${dest_dir}"
    fi
}

# remove_slices <target> <slice...> — take back each enabled standalone slice.
remove_slices() {
    local target="$1" slice
    shift
    for slice in $(selected_slices "$@"); do
        printf '\n%s%s: remove standalone %s%s\n' "${BOLD}" "${target}" "${slice}" "${NC}"
        run_slice "${target}" "${slice}"
    done
}

# remove_settings <profile> <src> <dest> <groups> — strip managed config keys.
remove_settings() {
    [[ -n "$4" ]] || return 0
    info "Removing managed keys ($4) from $3"
    merge_settings_config "$1" "$2" "$3" "$4" --remove
}

# run_claude_cli <args...> — a failed uninstall is reported, not fatal: the
# plugin or marketplace may simply not be registered.
run_claude_cli() {
    info "Running: claude $*"
    claude "$@" || warn "'claude $*' returned non-zero — check 'claude plugin list'"
}

require_claude_cli() {
    command -v claude >/dev/null 2>&1 || { err "'claude' CLI is required but not found in PATH"; exit 1; }
}

remove_claude_target() {
    validate_only_steps "claude"
    local claude_dir="${HOME}/.claude"

    if step_enabled mods; then
        printf '\n%sClaude: uninstall mods + the ycc-mods marketplace%s\n' "${BOLD}" "${NC}"
        require_claude_cli
        local name
        while IFS= read -r name; do
            [[ -n "${name}" ]] && run_claude_cli plugin uninstall "${name}@${MODS_MARKETPLACE_NAME}" --scope user
        done < <(mods_plugin_names)
        run_claude_cli plugin marketplace remove "${MODS_MARKETPLACE_NAME}" --scope user
    fi
    if step_enabled hooks; then
        printf '\n%sClaude: unlink hooks directory%s\n' "${BOLD}" "${NC}"
        unlink_owned_link "${SCRIPT_DIR}/ycc/settings/hooks" "${claude_dir}/hooks"
    fi
    if step_enabled mcp; then
        printf '\n%sClaude: remove MCP servers%s\n' "${BOLD}" "${NC}"
        run_mcp_step claude
    fi
    if step_enabled rules; then
        printf '\n%sClaude: unlink rules (CLAUDE.md + AGENTS.md)%s\n' "${BOLD}" "${NC}"
        unlink_owned_link "${SCRIPT_DIR}/ycc/settings/rules/CLAUDE.md" "${claude_dir}/CLAUDE.md"
        unlink_owned_link "${SCRIPT_DIR}/ycc/settings/rules/AGENTS.md" "${claude_dir}/AGENTS.md"
    fi
    if step_enabled settings; then
        printf '\n%sClaude: remove managed settings + statusline%s\n' "${BOLD}" "${NC}"
        remove_settings "claude-settings" "${SCRIPT_DIR}/ycc/settings/settings.json" \
            "${claude_dir}/settings.json" "$(config_groups_for_target claude)"
        if [[ ${#INTENTS[@]} -eq 0 ]] || intent_requested settings; then
            remove_copied_file "${SCRIPT_DIR}/ycc/settings/statusline-command.sh" "${claude_dir}/statusline-command.sh"
        fi
    fi
    remove_slices claude skills agents commands
    if step_enabled base; then
        printf '\n%sClaude: uninstall ycc + the ycc marketplace%s\n' "${BOLD}" "${NC}"
        require_claude_cli
        run_claude_cli plugin uninstall ycc@ycc --scope user
        run_claude_cli plugin marketplace remove ycc --scope user
    fi
    printf '\n%sClaude remove complete.%s\n' "${BOLD}" "${NC}"
}

remove_cursor_target() {
    validate_only_steps "cursor"
    local cursor_dir="${HOME}/.cursor"

    if step_enabled rules; then
        printf '\n%sCursor: unlink rules (CLAUDE.md + AGENTS.md)%s\n' "${BOLD}" "${NC}"
        unlink_owned_link "${SCRIPT_DIR}/ycc/settings/rules/CLAUDE.md" "${cursor_dir}/CLAUDE.md"
        unlink_owned_link "${SCRIPT_DIR}/ycc/settings/rules/AGENTS.md" "${cursor_dir}/AGENTS.md"
    fi
    if step_enabled mcp; then
        printf '\n%sCursor: remove MCP servers%s\n' "${BOLD}" "${NC}"
        run_mcp_step cursor
    fi
    if step_enabled settings; then
        printf '\n%sCursor: remove managed CLI settings%s\n' "${BOLD}" "${NC}"
        remove_settings "cursor-cli" "${CURSOR_CLI_CONFIG_SRC}" "${cursor_dir}/cli-config.json" "settings"
    fi
    remove_slices cursor skills agents
    if step_enabled base; then
        printf '\n%sCursor: remove bundle from ~/.cursor%s\n' "${BOLD}" "${NC}"
        local unit
        for unit in skills agents rules; do
            remove_mirrored_entries "${CURSOR_PLUGIN_DIR}/${unit}" "${cursor_dir}/${unit}"
        done
    fi
    printf '\n%sCursor remove complete.%s\n' "${BOLD}" "${NC}"
}

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
