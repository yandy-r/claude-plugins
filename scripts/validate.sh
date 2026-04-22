#!/usr/bin/env bash
# Unified validate entrypoint — run every validator that guards the plugin
# source-of-truth directories and their generated Cursor/Codex/opencode bundles.
#
# Usage:
#   ./scripts/validate.sh                       # all targets for all plugins
#   ./scripts/validate.sh --only inventory      # single target
#   ./scripts/validate.sh --only cursor,codex   # comma-separated subset
#   ./scripts/validate.sh --only yci            # yci-only validation
#
# Targets: inventory, cursor, codex, opencode, json, yci
#   - inventory  validates ycc skill↔command pairing and the shared inventory
#   - json       validates .claude-plugin/marketplace.json (once) plus each
#                plugin's .claude-plugin/plugin.json
#   - yci        validates the full yci plugin surface via validate-yci-skills.sh
# Plugins: ycc (full validators), yci (Claude-native surface validated by validate-yci-skills.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Plugin list — add new plugins here as they gain validators.
PLUGINS=(ycc yci)

VALID_TARGETS=(inventory cursor codex opencode json yci)
TARGETS=("${VALID_TARGETS[@]}")

usage() {
    cat <<EOF
Usage: $(basename "$0") [--only <targets>]

Run every validator for all plugin source-of-truth directories and their
generated bundles.

Options:
  --only <targets>   Comma-separated subset (valid: ${VALID_TARGETS[*]})
  -h, --help         Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --only inventory
  $(basename "$0") --only cursor,codex
  $(basename "$0") --only yci
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --only)
            [[ $# -lt 2 ]] && { echo "validate.sh: --only requires an argument" >&2; exit 1; }
            IFS=',' read -r -a TARGETS <<<"$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "validate.sh: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

for target in "${TARGETS[@]}"; do
    valid=0
    for v in "${VALID_TARGETS[@]}"; do
        [[ "$target" == "$v" ]] && valid=1 && break
    done
    if [[ "$valid" -eq 0 ]]; then
        echo "validate.sh: unknown target '$target' (valid: ${VALID_TARGETS[*]})" >&2
        exit 1
    fi
done

fail() {
    echo "validate.sh: FAILED at '$1'" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Per-plugin validator dispatch
# ---------------------------------------------------------------------------

# Run a single cross-target validator for the ycc plugin (unchanged from pre-refactor).
run_ycc_target() {
    case "$1" in
        inventory)
            echo "== validate: inventory =="
            "${REPO_ROOT}/scripts/validate-inventory.sh" || fail "validate-inventory.sh"
            echo "== validate: ycc skill↔command pairing =="
            "${REPO_ROOT}/scripts/validate-ycc-commands.sh" || fail "validate-ycc-commands.sh"
            ;;
        cursor)
            echo "== validate: cursor agents =="
            "${REPO_ROOT}/scripts/validate-cursor-agents.sh" || fail "validate-cursor-agents.sh"
            echo "== validate: cursor skills =="
            "${REPO_ROOT}/scripts/validate-cursor-skills.sh" || fail "validate-cursor-skills.sh"
            echo "== validate: cursor rules =="
            "${REPO_ROOT}/scripts/validate-cursor-rules.sh" || fail "validate-cursor-rules.sh"
            ;;
        codex)
            echo "== validate: codex skills =="
            "${REPO_ROOT}/scripts/validate-codex-skills.sh" || fail "validate-codex-skills.sh"
            echo "== validate: codex agents =="
            "${REPO_ROOT}/scripts/validate-codex-agents.sh" || fail "validate-codex-agents.sh"
            echo "== validate: codex plugin =="
            "${REPO_ROOT}/scripts/validate-codex-plugin.sh" || fail "validate-codex-plugin.sh"
            ;;
        opencode)
            echo "== validate: opencode skills =="
            "${REPO_ROOT}/scripts/validate-opencode-skills.sh" || fail "validate-opencode-skills.sh"
            echo "== validate: opencode agents =="
            "${REPO_ROOT}/scripts/validate-opencode-agents.sh" || fail "validate-opencode-agents.sh"
            echo "== validate: opencode commands =="
            "${REPO_ROOT}/scripts/validate-opencode-commands.sh" || fail "validate-opencode-commands.sh"
            echo "== validate: opencode plugin =="
            "${REPO_ROOT}/scripts/validate-opencode-plugin.sh" || fail "validate-opencode-plugin.sh"
            ;;
        # json and yci are cross-plugin targets handled outside this function.
    esac
}

# Run a single validator for the yci plugin.
# Future yci cross-target validators can be added here if the bundle grows
# beyond the current Claude-native surface.
run_yci_target() {
    case "$1" in
        yci)
            echo "== validate: yci skills =="
            "${REPO_ROOT}/scripts/validate-yci-skills.sh" || fail "validate-yci-skills.sh"
            ;;
        # Future breadcrumb: cursor|codex|opencode|inventory cases go here.
    esac
}

# Dispatch a target for a named plugin.
run_plugin_target() {
    local plugin="$1"
    local target="$2"
    case "${plugin}" in
        ycc)
            run_ycc_target "${target}"
            ;;
        yci)
            run_yci_target "${target}"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Cross-plugin targets (run once, not per-plugin)
# ---------------------------------------------------------------------------

run_cross_target() {
    case "$1" in
        json)
            echo "== validate: marketplace and plugin manifests =="
            # Shared marketplace — validated once.
            python3 -m json.tool "${REPO_ROOT}/.claude-plugin/marketplace.json" > /dev/null \
                || fail ".claude-plugin/marketplace.json"
            # Per-plugin plugin.json — loop over all plugins.
            for plugin in "${PLUGINS[@]}"; do
                python3 -m json.tool "${REPO_ROOT}/${plugin}/.claude-plugin/plugin.json" > /dev/null \
                    || fail "${plugin}/.claude-plugin/plugin.json"
            done
            echo "OK: manifest JSON is valid."
            echo "== validate: hooks symlink =="
            "${REPO_ROOT}/scripts/validate-hooks.sh" || fail "validate-hooks.sh"
            ;;
        yci)
            # yci is handled per-plugin in run_yci_target; iterate all plugins
            # so that only yci gets called for this target key.
            for plugin in "${PLUGINS[@]}"; do
                run_plugin_target "${plugin}" "yci"
            done
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Main dispatch loop
# ---------------------------------------------------------------------------

# Targets that are cross-plugin (not dispatched per-plugin from the outer loop).
is_cross_target() {
    case "$1" in
        json|yci) return 0 ;;
        *)         return 1 ;;
    esac
}

for target in "${TARGETS[@]}"; do
    if is_cross_target "${target}"; then
        run_cross_target "${target}"
    else
        # Per-plugin targets: run each plugin's validator for this target.
        for plugin in "${PLUGINS[@]}"; do
            run_plugin_target "${plugin}" "${target}"
        done
    fi
done

echo "validate.sh: done (${TARGETS[*]})"
