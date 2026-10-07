# shellcheck shell=bash
# opencode.sh — the opencode target: implements the per-target contract that install.sh
# dispatches through (see scripts/lib/install/steps.sh):
#   opencode_valid_steps, opencode_intent_steps <intent>, opencode_config_groups,
#   opencode_supports_repo_mode, sync_opencode_target, remove_opencode_target
#
# Sourced by install.sh (never run directly); inherits SCRIPT_DIR and the
# shared helpers from core.sh / steps.sh / bundle.sh.

# shellcheck disable=SC2034  # read by the opencode sync/remove and MCP steps.
OPENCODE_PLUGIN_DIR="${SCRIPT_DIR}/.opencode-plugin"

# opencode_valid_steps — comma-separated steps opencode accepts for --only.
opencode_valid_steps() { echo "base,skills,agents,commands,settings,rules,mcp"; }

# opencode_intent_steps <intent> — steps <intent> maps to; empty means no-op.
opencode_intent_steps() {
    case "$1" in
        skills|agents|commands) echo "$1" ;;
        # Mods are Claude Code only for now (see cursor_intent_steps).
        mods) echo "" ;;
        # MCP has its own scope-aware step; plugin enablement lives in
        # opencode.json.
        base|settings|rules|mcp) echo "$1" ;;
        plugins) echo "settings" ;;
        hooks) echo "" ;;
        *) echo "" ;;
    esac
}

# opencode_config_groups — default managed config groups for opencode.json.
# MCP servers are owned by the scope-aware 'mcp' step.
opencode_config_groups() { echo "settings,plugins"; }

# opencode reads bundles from local directories only.
opencode_supports_repo_mode() { return 1; }
