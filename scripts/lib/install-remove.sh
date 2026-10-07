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
