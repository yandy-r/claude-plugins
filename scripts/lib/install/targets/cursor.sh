# shellcheck shell=bash
# cursor.sh — the Cursor target: implements the per-target contract that install.sh
# dispatches through (see scripts/lib/install/steps.sh):
#   cursor_valid_steps, cursor_intent_steps <intent>, cursor_config_groups,
#   cursor_supports_repo_mode, sync_cursor_target, remove_cursor_target
#
# Sourced by install.sh (never run directly); inherits SCRIPT_DIR and the
# shared helpers from core.sh / steps.sh / bundle.sh.

# shellcheck disable=SC2034  # read by the cursor sync/remove steps.
CURSOR_PLUGIN_DIR="${SCRIPT_DIR}/.cursor-plugin"
# shellcheck disable=SC2034  # read by the cursor sync/remove steps.
CURSOR_CLI_CONFIG_SRC="${SCRIPT_DIR}/.cursor-plugin/config/cli-config.json"

# cursor_valid_steps — comma-separated steps Cursor accepts for --only.
cursor_valid_steps() { echo "base,skills,agents,settings,rules,mcp"; }

# cursor_intent_steps <intent> — steps <intent> maps to; empty means no-op.
cursor_intent_steps() {
    case "$1" in
        skills|agents) echo "$1" ;;
        # Cursor has no command layer.
        commands) echo "" ;;
        base|rules|mcp) echo "$1" ;;
        settings) echo "settings" ;;
        hooks|plugins) echo "" ;;
        # Mods are Claude Code only for now. A target gains them by mapping
        # 'mods' to a step that translates ycc/mods/<name> into that tool's
        # extension format; until then the intent is reported and skipped.
        mods) echo "" ;;
        *) echo "" ;;
    esac
}

# cursor_config_groups — default managed config groups for cli-config.json.
cursor_config_groups() { echo "settings"; }

# Cursor reads bundles from local directories only.
cursor_supports_repo_mode() { return 1; }
