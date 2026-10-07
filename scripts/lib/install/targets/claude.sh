# shellcheck shell=bash
# claude.sh — the Claude target: implements the per-target contract that install.sh
# dispatches through (see scripts/lib/install/steps.sh):
#   claude_valid_steps, claude_intent_steps <intent>, claude_config_groups,
#   claude_supports_repo_mode, sync_claude_target, remove_claude_target
#
# Sourced by install.sh (never run directly); inherits SCRIPT_DIR and the
# shared helpers from core.sh / steps.sh / bundle.sh.

# claude_valid_steps — comma-separated steps Claude accepts for --only.
claude_valid_steps() { echo "base,skills,agents,commands,settings,rules,mcp,hooks,mods"; }

# claude_intent_steps <intent> — steps <intent> maps to; empty means no-op.
claude_intent_steps() {
    case "$1" in
        base|settings|rules|mcp) echo "$1" ;;
        # Hook activation lives in settings.json; hook scripts live in hooks/.
        hooks) echo "settings,hooks" ;;
        # Claude plugin enablement is pure settings.json state (enabledPlugins,
        # extraKnownMarketplaces). Add 'base' explicitly to also run the CLI's
        # marketplace registration, which needs network access.
        plugins) echo "settings" ;;
        # Mods install from the ycc-mods marketplace via the claude CLI.
        mods) echo "mods" ;;
        # skills/agents/commands install standalone entries into the tool's
        # own user dirs; 'base' ships the whole bundle/plugin.
        skills|agents|commands) echo "$1" ;;
        *) echo "" ;;
    esac
}

# claude_config_groups — default managed config groups for settings.json.
# The intent filter (and its order) lives in config_groups_for_target.
claude_config_groups() { echo "settings,hooks,plugins"; }

claude_supports_repo_mode() { return 0; }
