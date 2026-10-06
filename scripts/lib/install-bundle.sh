#!/usr/bin/env bash
# install-bundle.sh — bundle selection for the install/sync/remove steps.
#
# Sourced by install.sh (never run directly); relies on its helpers (info,
# warn, err, step_enabled) and globals (SCRIPT_DIR, COMMAND, FORCE).
#
# 'base' ships a target's whole bundle (claude/codex: the registered plugin;
# cursor/opencode: the mirrored bundle dirs). The 'skills', 'agents' and
# 'commands' slices install just those entries, standalone, into the tool's
# own user directories (~/.claude/skills/<name>, ~/.codex/agents/<name>.toml,
# ...) via scripts/install_slices.py — no plugin registration involved.

SLICE_HELPER="${SCRIPT_DIR}/scripts/install_slices.py"

# selected_slices <slice...> — echo the given slices whose step is enabled.
selected_slices() {
    local -a picked=()
    local slice
    for slice in "$@"; do
        step_enabled "${slice}" && picked+=("${slice}")
    done
    echo "${picked[*]}"
}

# run_slice <target> <slice> — install (or, under 'remove', take back) one
# standalone slice. Entries ycc did not install are never replaced or
# removed without --force.
run_slice() {
    command -v python3 >/dev/null 2>&1 || { err "python3 is required but not found"; exit 1; }
    local action="install"
    # shellcheck disable=SC2153  # COMMAND is install.sh's subcommand global.
    [[ "${COMMAND}" == "remove" ]] && action="remove"
    local -a command=(python3 "${SLICE_HELPER}" "${action}" --target "$1" --slice "$2")
    [[ "${FORCE:-0}" == "1" ]] && command+=(--force)
    "${command[@]}"
}

# selected_bundle_units <unit...>
# Echo (space-separated) which generated bundle <unit>s need (re)generating:
# all of them when 'base' is enabled, otherwise the ones an enabled slice
# step installs. 'shared' (cross-skill helpers that skill bodies reference)
# rides along with 'skills'.
selected_bundle_units() {
    if step_enabled base; then
        echo "$*"
        return 0
    fi
    local -a picked=()
    local unit
    for unit in "$@"; do
        case "${unit}" in
            skills|agents|commands) step_enabled "${unit}" && picked+=("${unit}") ;;
            shared) step_enabled skills && picked+=(shared) ;;
        esac
    done
    echo "${picked[*]}"
}

# require_scripts <path...> — fail unless every helper script exists and is readable.
require_scripts() {
    local s
    for s in "$@"; do
        [[ -f "${s}" ]] || { err "Missing required script: ${s}"; exit 1; }
        [[ -r "${s}" ]] || { err "Script not readable: ${s}"; exit 1; }
    done
}

# sync_bundle_units <src_root> <dest_root> <unit...>
# Mirror each <src_root>/<unit>/ into <dest_root>/<unit>/ (rsync --delete). A
# unit the bundle no longer ships is removed from the destination.
sync_bundle_units() {
    local src_root="$1" dest_root="$2"
    shift 2
    local unit src_unit dest_unit
    for unit in "$@"; do
        src_unit="${src_root}/${unit}/"
        dest_unit="${dest_root}/${unit}/"
        if [[ -d "${src_unit}" ]]; then
            mkdir -p "${dest_unit}"
            rsync -av --delete "${src_unit}" "${dest_unit}"
            info "Synced ${unit}/ → ${dest_unit}"
        elif [[ -d "${dest_unit}" ]]; then
            rm -rf "${dest_unit}"
            warn "Removed ${dest_unit} (missing from $(basename "${src_root}"))"
        else
            warn "Source not found, skipping: ${src_unit}"
        fi
    done
}
