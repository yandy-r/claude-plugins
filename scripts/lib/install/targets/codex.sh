# shellcheck shell=bash
# codex.sh — the Codex target: implements the per-target contract that install.sh
# dispatches through (see scripts/lib/install/steps.sh):
#   codex_valid_steps, codex_intent_steps <intent>, codex_config_groups,
#   codex_supports_repo_mode, sync_codex_target, remove_codex_target
#
# Sourced by install.sh (never run directly); inherits SCRIPT_DIR and the
# shared helpers from core.sh / steps.sh / bundle.sh.

# shellcheck disable=SC2034  # read by the codex sync/remove steps.
CODEX_PLUGIN_DIR="${SCRIPT_DIR}/.codex-plugin/ycc"
# shellcheck disable=SC2034  # read by the codex sync/remove steps.
CODEX_AGENTS_DIR="${SCRIPT_DIR}/.codex-plugin/agents"

# codex_valid_steps — comma-separated steps Codex accepts for --only.
codex_valid_steps() { echo "base,skills,agents,settings,rules,mcp"; }

# codex_intent_steps <intent> — steps <intent> maps to; empty means no-op.
codex_intent_steps() {
    case "$1" in
        skills|agents) echo "$1" ;;
        # Codex has no command layer.
        commands) echo "" ;;
        # Mods are Claude Code only for now (see cursor_intent_steps).
        mods) echo "" ;;
        # MCP has its own scope-aware step; plugin enablement lives in
        # config.toml.
        base|settings|rules|mcp) echo "$1" ;;
        plugins) echo "settings" ;;
        hooks) echo "" ;;
        *) echo "" ;;
    esac
}

# codex_config_groups — default managed config groups for config.toml.
# MCP servers are owned by the scope-aware 'mcp' step.
codex_config_groups() { echo "settings,plugins"; }

codex_supports_repo_mode() { return 0; }
