#!/usr/bin/env bash
# Behavioral tests for install.sh argument parsing, intent mapping and the
# merge-based settings steps.
#
# Every test runs against a throwaway HOME so the caller's real ~/.claude,
# ~/.codex, ~/.cursor and ~/.config/opencode are never touched.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL="${REPO_ROOT}/install.sh"

PASS=0
FAIL=0

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

# Per-user dir overrides would escape the sandbox HOME.
unset XDG_BIN_HOME XDG_DATA_HOME XDG_CONFIG_HOME BASH_COMPLETION_USER_DIR

SANDBOX_ROOT="$(mktemp -d)"
trap 'rm -rf "${SANDBOX_ROOT}"' EXIT

# new_home — create an isolated HOME and echo its path.
new_home() {
    local home
    home="$(mktemp -d "${SANDBOX_ROOT}/home.XXXXXX")"
    mkdir -p "${home}/.claude" "${home}/.codex" "${home}/.cursor" "${home}/.config/opencode" "${home}/project"
    echo "${home}"
}

# Stub 'claude' and 'codex' CLIs record their arguments, so plugin steps are
# checked without touching a real plugin registry.
STUB_BIN="${SANDBOX_ROOT}/stub-bin"
mkdir -p "${STUB_BIN}"
cat > "${STUB_BIN}/claude" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${CLAUDE_STUB_LOG}"
SH
cat > "${STUB_BIN}/codex" <<'SH'
#!/usr/bin/env bash
[[ " $* " == *" --help "* ]] && exit 0
printf 'codex %s\n' "$*" >> "${CLAUDE_STUB_LOG}"
SH
chmod +x "${STUB_BIN}/claude" "${STUB_BIN}/codex"

# run_install <home> <args...> — run install.sh sandboxed; capture output.
# Runs from <home>/project (not a git repo) so project-scoped steps write
# there and never into this checkout.
run_install() {
    local home="$1"
    shift
    (
        cd "${home}/project" || exit 1
        HOME="${home}" \
        PATH="${STUB_BIN}:${PATH}" \
        CLAUDE_STUB_LOG="${home}/claude-calls.log" \
        YCC_MANAGED_CONFIG_STATE="${home}/.config/ycc/managed-config-state.json" \
            bash "${INSTALL}" "$@" 2>&1
    )
}

ok() {
    PASS=$((PASS + 1))
    printf '%s[pass]%s %s\n' "${GREEN}" "${NC}" "$1"
}

ko() {
    FAIL=$((FAIL + 1))
    printf '%s[FAIL]%s %s\n' "${RED}" "${NC}" "$1"
    [[ -n "${2:-}" ]] && printf '       %s\n' "$2"
}

assert_contains() {
    local haystack="$1" needle="$2" name="$3"
    if [[ "${haystack}" == *"${needle}"* ]]; then
        ok "${name}"
    else
        ko "${name}" "expected to find: ${needle}"
    fi
}

assert_not_contains() {
    local haystack="$1" needle="$2" name="$3"
    if [[ "${haystack}" != *"${needle}"* ]]; then
        ok "${name}"
    else
        ko "${name}" "unexpectedly found: ${needle}"
    fi
}

echo "== install.sh: command is required =="

home="$(new_home)"
out="$(run_install "${home}" --target claude --only rules)"
assert_contains "${out}" "missing or unknown command '--target'" "bare --target rejected"
assert_contains "${out}" "install --target claude --only rules" "bare --target suggests install"
assert_not_contains "${out}" "link rules" "bare --target runs nothing"

home="$(new_home)"
out="$(run_install "${home}")"
assert_contains "${out}" "Usage:" "no command prints usage"

home="$(new_home)"
out="$(run_install "${home}" bogus --target claude)"
assert_contains "${out}" "missing or unknown command 'bogus'" "unknown command rejected"

home="$(new_home)"
out="$(run_install "${home}" install --target claude --intent settings)"
assert_contains "${out}" "--intent requires the 'sync' or 'remove' subcommand" "install rejects --intent"

echo
echo "== install.sh sync: argument validation =="

home="$(new_home)"
out="$(run_install "${home}" sync --target claude)"
assert_contains "${out}" "sync requires --intent" "sync without --intent fails"

home="$(new_home)"
out="$(run_install "${home}" sync --target claude --intent settings,bogus)"
assert_contains "${out}" "unknown intent 'bogus'" "unknown intent rejected"

home="$(new_home)"
out="$(run_install "${home}" sync --target claude --intent "settings,,mcp")"
assert_contains "${out}" "--intent contains an empty value" "empty intent token rejected"

home="$(new_home)"
out="$(run_install "${home}" sync --target claude --intent settings --only settings)"
assert_contains "${out}" "cannot be combined with --only" "sync rejects --only"

home="$(new_home)"
out="$(run_install "${home}" sync --target claude --intent settings --hooks)"
assert_contains "${out}" "cannot be combined with --only" "sync rejects additive flags"

home="$(new_home)"
out="$(run_install "${home}" install --target claude --intent settings)"
assert_contains "${out}" "--intent requires the 'sync' or 'remove' subcommand" "--intent rejected by install"

home="$(new_home)"
out="$(run_install "${home}" sync --intent settings)"
assert_contains "${out}" "Missing required --target" "sync still requires --target"

echo
echo "== install.sh: multiple targets =="

home="$(new_home)"
out="$(run_install "${home}" sync --target codex,claude,opencode --intent mcp)"
assert_contains "${out}" "Codex sync complete" "multi-target runs codex"
assert_contains "${out}" "Claude sync complete" "multi-target runs claude"
assert_contains "${out}" "opencode sync complete" "multi-target runs opencode"
assert_not_contains "${out}" "Cursor sync complete" "multi-target skips unlisted cursor"
assert_contains "$(cat "${home}/project/.mcp.json")" '"mcpServers"' "multi-target merges claude MCP into project scope"

home="$(new_home)"
out="$(run_install "${home}" sync --target claude,claude --intent mcp)"
count="$(grep -c "Claude sync complete" <<< "${out}")"
if [[ "${count}" == "1" ]]; then ok "duplicate targets run once"; else ko "duplicate targets run once" "ran ${count} times"; fi

home="$(new_home)"
out="$(run_install "${home}" sync --target claude,bogus --intent mcp)"
assert_contains "${out}" "Unknown target: bogus" "unknown target in list rejected"
assert_not_contains "${out}" "Claude sync complete" "unknown target fails before any target runs"

home="$(new_home)"
out="$(run_install "${home}" sync --target "claude,,codex" --intent mcp)"
assert_contains "${out}" "--target contains an empty value" "empty target token rejected"

home="$(new_home)"
out="$(run_install "${home}" sync --target all,claude --intent mcp)"
assert_contains "${out}" "'all' cannot be combined" "all must stand alone"

home="$(new_home)"
out="$(run_install "${home}" sync --target claude,cursor --intent mcp --mode repo)"
assert_contains "${out}" "--mode repo is not supported by the cursor target" "repo mode rejects listed cursor"
assert_not_contains "${out}" "Claude sync complete" "repo-mode rejection happens before any target runs"

home="$(new_home)"
out="$(run_install "${home}" install --target claude,codex --only hooks)"
assert_contains "${out}" "--only step 'hooks' is not valid for target 'codex'" "install --only validated across all targets"
assert_not_contains "${out}" "Claude sync complete" "--only rejection happens before any target runs"

echo
echo "== install.sh sync: no implicit base =="

home="$(new_home)"
out="$(run_install "${home}" sync --target claude --intent settings)"
assert_not_contains "${out}" "register repo checkout as local marketplace" "sync --intent settings does not run base"

home="$(new_home)"
out="$(run_install "${home}" sync --target cursor --intent plugins)"
assert_contains "${out}" "intent 'plugins' is not supported by target 'cursor'" "unsupported intent reported"
assert_not_contains "${out}" "Generate Cursor-native bundle" "unsupported-only intent does not fall back to base"

home="$(new_home)"
out="$(run_install "${home}" sync --target codex --intent hooks)"
assert_contains "${out}" "intent 'hooks' is not supported by target 'codex'" "codex hooks is a no-op"

echo
echo "== install.sh sync: claude settings merge =="

home="$(new_home)"
cat > "${home}/.claude/settings.json" <<'JSON'
{
  "tui": "fullscreen",
  "editorMode": "vim",
  "env": { "MY_LOCAL_TOKEN": "keep-me" }
}
JSON
out="$(run_install "${home}" sync --target claude --intent settings)"
merged="$(cat "${home}/.claude/settings.json")"
assert_contains "${merged}" '"editorMode": "vim"' "unmanaged local key preserved"
assert_contains "${merged}" '"MY_LOCAL_TOKEN": "keep-me"' "unmanaged env leaf preserved"
assert_contains "${merged}" '"claude-fable-5-1"' "managed model applied"
assert_contains "${merged}" '"CLAUDE_CODE_SUBAGENT_MODEL": "opus[1m]"' "subagent model applied"

# The marketplace entry the Claude CLI writes must survive a settings sync;
# this is the regression the old copy-based flow could not avoid.
home="$(new_home)"
cat > "${home}/.claude/settings.json" <<'JSON'
{
  "extraKnownMarketplaces": {
    "cli-written": { "source": { "source": "github", "repo": "someone/else" } }
  }
}
JSON
run_install "${home}" sync --target claude --intent settings,plugins >/dev/null
merged="$(cat "${home}/.claude/settings.json")"
assert_contains "${merged}" '"cli-written"' "CLI-written marketplace entry preserved"
assert_contains "${merged}" '"ycc"' "repo marketplace entry added"

echo
echo "== install.sh sync: claude mods =="

# run_install already puts the stub claude/codex CLIs first on PATH.
run_install_stubbed() {
    run_install "$@"
}

home="$(new_home)"
out="$(run_install_stubbed "${home}" sync --target claude --intent mods)"
calls="$(cat "${home}/claude-calls.log" 2>/dev/null)"
assert_contains "${calls}" "plugin marketplace add $(realpath "${REPO_ROOT}/ycc/mods") --scope user" "mods registers the ycc-mods marketplace from the checkout"
assert_contains "${calls}" "plugin install status-bar@ycc-mods --scope user" "mods installs each listed mod"
assert_not_contains "${calls}" "ycc@ycc" "mods does not run base"
assert_not_contains "${out}" "merge settings" "mods does not merge settings"
assert_contains "${out}" "Claude sync complete" "mods sync completes"

home="$(new_home)"
cat > "${home}/.claude/settings.json" <<'JSON'
{ "env": { "CLAUDE_CODE_PLUGIN_DIRS": "~/.claude/mods/status-bar" } }
JSON
out="$(run_install_stubbed "${home}" sync --target claude --intent mods)"
assert_contains "${out}" "also loads a 'status-bar' folder" "sideloaded copy of a mod is flagged"

home="$(new_home)"
out="$(run_install_stubbed "${home}" sync --target codex,cursor,opencode --intent mods)"
assert_contains "${out}" "intent 'mods' is not supported by target 'codex'" "codex mods is a no-op"
assert_contains "${out}" "intent 'mods' is not supported by target 'opencode'" "opencode mods is a no-op"
assert_not_contains "$(cat "${home}/claude-calls.log" 2>/dev/null)" "plugin" "non-claude targets never call the claude CLI"

home="$(new_home)"
out="$(run_install_stubbed "${home}" install --target claude --only mods)"
assert_not_contains "${out}" "is not valid for target 'claude'" "--only mods is valid for claude"
assert_contains "$(cat "${home}/claude-calls.log" 2>/dev/null)" "status-bar@ycc-mods" "install --only mods installs the mods"

echo
echo "== install.sh sync: local edits are respected =="

home="$(new_home)"
run_install "${home}" sync --target claude --intent settings >/dev/null
python3 - "${home}/.claude/settings.json" <<'PY'
import json, sys, pathlib
p = pathlib.Path(sys.argv[1])
data = json.loads(p.read_text())
data["model"] = "my-own-model"
p.write_text(json.dumps(data, indent=2) + "\n")
PY
out="$(run_install "${home}" sync --target claude --intent settings)"
assert_contains "${out}" "kept your local value at /model" "local edit preserved with warning"
assert_contains "$(cat "${home}/.claude/settings.json")" '"my-own-model"' "local model value intact"

out="$(run_install "${home}" sync --target claude --intent settings --force)"
assert_contains "$(cat "${home}/.claude/settings.json")" '"claude-fable-5-1"' "--force restores repo value"

echo
echo "== install.sh sync: codex config merge =="

home="$(new_home)"
cat > "${home}/.codex/config.toml" <<'TOML'
# local machine notes
model = "gpt-5.6-sol"

[projects."/home/me/secret-project"]
trust_level = "trusted"

[mcp_servers.internal]
url = "https://internal.example"
TOML
out="$(run_install "${home}" sync --target codex --intent settings,mcp --force)"
merged="$(cat "${home}/.codex/config.toml")"
assert_contains "${merged}" "# local machine notes" "TOML comment preserved"
assert_contains "${merged}" '[projects."/home/me/secret-project"]' "trusted project preserved"
assert_contains "${merged}" "[mcp_servers.internal]" "local MCP server preserved"
assert_contains "${merged}" 'model = "gpt-6-astra"' "managed model applied"
assert_contains "${merged}" 'default_subagent_model = "gpt-5.6-sol"' "subagent model applied"

if python3 -c "import tomllib,sys,pathlib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())" "${home}/.codex/config.toml"; then
    ok "merged config.toml still parses"
else
    ko "merged config.toml still parses"
fi

echo
echo "== install.sh sync: opencode + cursor =="

home="$(new_home)"
cat > "${home}/.config/opencode/opencode.json" <<'JSON'
{
  "model": "9router/Frontier",
  "provider": { "9router": { "options": { "apiKey": "sk-local-secret" } } },
  "plugins": ["@user/local-plugin"]
}
JSON
run_install "${home}" sync --target opencode --intent settings,plugins >/dev/null
merged="$(cat "${home}/.config/opencode/opencode.json")"
assert_contains "${merged}" "sk-local-secret" "local provider credentials preserved"
assert_contains "${merged}" "@user/local-plugin" "local plugin preserved"
assert_contains "${merged}" "@prevalentware/opencode-goal-plugin" "repo plugin added"

home="$(new_home)"
run_install "${home}" sync --target cursor --intent settings >/dev/null
assert_contains "$(cat "${home}/.cursor/cli-config.json")" '"claude-fable-5-1"' "cursor CLI model applied"

echo
echo "== install.sh install (step flags) =="

home="$(new_home)"
out="$(run_install "${home}" install --target claude --only rules)"
assert_contains "${out}" "link rules" "install --only rules runs"
assert_not_contains "${out}" "register repo checkout" "install --only stays exclusive"

home="$(new_home)"
out="$(run_install "${home}" install --target claude --only bogus)"
assert_contains "${out}" "is not valid for target" "install --only validates steps"

echo
echo "== install.sh: --project / --global MCP scope =="

home="$(new_home)"
out="$(run_install "${home}" install --target claude --project --global)"
assert_contains "${out}" "mutually exclusive" "--project and --global rejected together"

home="$(new_home)"
out="$(run_install "${home}" install --target claude --only settings,mcp --project)"
assert_contains "${out}" "--project is not supported by step 'settings'" "--project rejects non-project steps"
assert_not_contains "${out}" "Claude sync complete" "--project rejection happens before any target runs"

home="$(new_home)"
run_install "${home}" sync --target all --intent mcp >/dev/null
for f in .mcp.json .cursor/mcp.json .codex/config.toml opencode.json; do
    if [[ -f "${home}/project/${f}" ]]; then ok "project MCP written: ${f}"; else ko "project MCP written: ${f}"; fi
done
if [[ ! -e "${home}/.claude.json" && ! -e "${home}/.cursor/mcp.json" ]]; then
    ok "project scope leaves global MCP files alone"
else
    ko "project scope leaves global MCP files alone"
fi

home="$(new_home)"
run_install "${home}" install --target claude --only mcp --global >/dev/null
assert_contains "$(cat "${home}/.claude.json")" '"mcpServers"' "--global writes ~/.claude.json"
if [[ ! -e "${home}/project/.mcp.json" ]]; then ok "--global leaves project alone"; else ko "--global leaves project alone"; fi

echo
echo "== install.sh remove =="

home="$(new_home)"
out="$(run_install "${home}" remove --target claude)"
assert_contains "${out}" "remove requires --only <steps> or --intent <intents>" "remove requires a selection"

home="$(new_home)"
out="$(run_install "${home}" remove --target claude --mcp)"
assert_contains "${out}" "remove does not accept --settings" "remove rejects additive flags"

home="$(new_home)"
out="$(run_install "${home}" remove --target claude --only mcp --mode repo)"
assert_contains "${out}" "remove does not accept --mode" "remove rejects --mode"

home="$(new_home)"
out="$(run_install "${home}" remove --target claude --only settings --project)"
assert_contains "${out}" "--project is not supported by step 'settings'" "remove keeps the --project guard"

home="$(new_home)"
cat > "${home}/project/.mcp.json" <<'JSON'
{ "mcpServers": { "mine": { "url": "https://mine" } } }
JSON
run_install "${home}" install --target claude --only mcp >/dev/null
out="$(run_install "${home}" remove --target claude --only mcp)"
assert_contains "${out}" "Claude remove complete" "remove runs for claude"
merged="$(cat "${home}/project/.mcp.json")"
assert_contains "${merged}" '"mine"' "remove keeps user-added server"
assert_not_contains "${merged}" '"playwright"' "remove drops managed server"

home="$(new_home)"
run_install "${home}" sync --target all --intent mcp --global >/dev/null
run_install "${home}" remove --target all --intent mcp --global >/dev/null
for f in .claude.json .cursor/mcp.json .codex/config.toml .config/opencode/opencode.json; do
    if [[ ! -e "${home}/${f}" ]]; then ok "global remove cleans ${f}"; else ko "global remove cleans ${f}"; fi
done

home="$(new_home)"
cat > "${home}/.codex/config.toml" <<'TOML'
# keep me
[mcp_servers.internal]
url = "https://internal.example"
TOML
run_install "${home}" install --target codex --only mcp --global >/dev/null
run_install "${home}" remove --target codex --only mcp --global >/dev/null
merged="$(cat "${home}/.codex/config.toml")"
assert_contains "${merged}" "# keep me" "codex remove keeps comments"
assert_contains "${merged}" "[mcp_servers.internal]" "codex remove keeps user server"
assert_not_contains "${merged}" "[mcp_servers.playwright]" "codex remove drops managed server"

echo
echo "== install.sh remove: settings, rules, hooks, plugins =="

home="$(new_home)"
cat > "${home}/.claude/settings.json" <<'JSON'
{ "editorMode": "vim", "env": { "MY_LOCAL_TOKEN": "keep-me" } }
JSON
run_install "${home}" sync --target claude --intent settings,rules,hooks,plugins >/dev/null
out="$(run_install "${home}" remove --target claude --intent settings,rules,hooks,plugins)"
assert_contains "${out}" "Claude remove complete" "claude remove of every config intent completes"
merged="$(cat "${home}/.claude/settings.json")"
assert_contains "${merged}" '"editorMode": "vim"' "claude remove keeps unmanaged keys"
assert_contains "${merged}" '"MY_LOCAL_TOKEN": "keep-me"' "claude remove keeps unmanaged env leaf"
assert_not_contains "${merged}" '"claude-fable-5-1"' "claude remove drops managed model"
assert_not_contains "${merged}" '"pluginMarketplaces"' "claude remove takes back appended list items"
assert_not_contains "${merged}" '"hooks"' "claude remove drops managed hooks"
for f in CLAUDE.md AGENTS.md hooks statusline-command.sh; do
    if [[ ! -e "${home}/.claude/${f}" && ! -L "${home}/.claude/${f}" ]]; then ok "claude remove cleans ~/.claude/${f}"; else ko "claude remove cleans ~/.claude/${f}"; fi
done

home="$(new_home)"
run_install "${home}" sync --target claude --intent settings,plugins >/dev/null
python3 - "${home}/.claude/settings.json" <<'PY2'
import json, sys, pathlib
p = pathlib.Path(sys.argv[1])
data = json.loads(p.read_text())
data["model"] = "my-own-model"
p.write_text(json.dumps(data, indent=2) + "\n")
PY2
out="$(run_install "${home}" remove --target claude --intent settings)"
assert_contains "${out}" "kept your local value at /model" "remove keeps an edited managed value"
assert_contains "$(cat "${home}/.claude/settings.json")" '"enabledPlugins"' "remove --intent settings leaves the plugins group"
run_install "${home}" remove --target claude --intent settings,plugins --force >/dev/null
if [[ ! -e "${home}/.claude/settings.json" ]]; then ok "remove --force takes edited values too"; else ko "remove --force takes edited values too" "$(cat "${home}/.claude/settings.json")"; fi

home="$(new_home)"
echo "# mine" > "${home}/.claude/CLAUDE.md"
echo "custom" > "${home}/.claude/statusline-command.sh"
out="$(run_install "${home}" remove --target claude --intent rules,settings --force)"
assert_contains "$(cat "${home}/.claude/CLAUDE.md")" "# mine" "remove never deletes a real rules file"
assert_contains "${out}" "not installed by ycc" "remove reports foreign rules file"
if [[ ! -e "${home}/.claude/statusline-command.sh" ]]; then ok "remove --force takes an edited statusline"; else ko "remove --force takes an edited statusline"; fi

home="$(new_home)"
echo "custom" > "${home}/.claude/statusline-command.sh"
out="$(run_install "${home}" remove --target claude --intent settings)"
assert_contains "${out}" "kept ${home}/.claude/statusline-command.sh" "remove keeps an edited statusline"

home="$(new_home)"
cat > "${home}/.cursor/cli-config.json" <<'JSON'
{ "privacyMode": 1, "permissions": { "allow": ["Shell(ls)"], "deny": [] } }
JSON
run_install "${home}" sync --target cursor --intent settings,rules >/dev/null
run_install "${home}" remove --target cursor --intent settings,rules >/dev/null
merged="$(cat "${home}/.cursor/cli-config.json")"
assert_contains "${merged}" '"privacyMode": 1' "cursor remove keeps unmanaged keys"
assert_contains "${merged}" '"Shell(ls)"' "cursor remove keeps user permission entries"
assert_contains "${merged}" '"deny": []' "cursor remove keeps required permission keys"
assert_not_contains "${merged}" '"modelId"' "cursor remove drops managed model"
if [[ ! -L "${home}/.cursor/CLAUDE.md" ]]; then ok "cursor remove unlinks rules"; else ko "cursor remove unlinks rules"; fi

home="$(new_home)"
cat > "${home}/.codex/config.toml" <<'TOML'
# local machine notes
[projects."/home/me/secret-project"]
trust_level = "trusted"
TOML
run_install "${home}" sync --target codex --intent settings,plugins,rules >/dev/null
run_install "${home}" remove --target codex --intent settings,plugins,rules >/dev/null
merged="$(cat "${home}/.codex/config.toml")"
assert_contains "${merged}" "# local machine notes" "codex settings remove keeps comments"
assert_contains "${merged}" '[projects."/home/me/secret-project"]' "codex settings remove keeps trusted projects"
assert_not_contains "${merged}" "model =" "codex settings remove drops managed model"
assert_not_contains "${merged}" "[plugins." "codex plugins remove drops managed plugin tables"
for f in .codex/rules/default.rules .codex/CLAUDE.md .codex/AGENTS.md; do
    if [[ ! -L "${home}/${f}" ]]; then ok "codex remove unlinks ${f}"; else ko "codex remove unlinks ${f}"; fi
done

home="$(new_home)"
cat > "${home}/.config/opencode/opencode.json" <<'JSON'
{
  "provider": { "9router": { "options": { "apiKey": "sk-local-secret" } } },
  "plugins": ["@user/local-plugin"]
}
JSON
run_install "${home}" sync --target opencode --intent settings,plugins,rules >/dev/null
run_install "${home}" remove --target opencode --intent settings,plugins,rules >/dev/null
merged="$(cat "${home}/.config/opencode/opencode.json")"
assert_contains "${merged}" "sk-local-secret" "opencode remove keeps provider credentials"
assert_contains "${merged}" "@user/local-plugin" "opencode remove keeps user plugin"
assert_not_contains "${merged}" "@prevalentware/opencode-goal-plugin" "opencode remove takes back repo plugin"
if [[ ! -L "${home}/.config/opencode/AGENTS.md" ]]; then ok "opencode remove unlinks AGENTS.md"; else ko "opencode remove unlinks AGENTS.md"; fi

echo
echo "== install.sh remove: base and mods =="

REPO_REAL="$(realpath "${REPO_ROOT}")"

home="$(new_home)"
out="$(run_install_stubbed "${home}" remove --target claude --intent base,mods)"
calls="$(cat "${home}/claude-calls.log" 2>/dev/null)"
assert_contains "${calls}" "plugin uninstall ycc@ycc --scope user" "claude base remove uninstalls ycc"
assert_contains "${calls}" "plugin marketplace remove ycc --scope user" "claude base remove drops the ycc marketplace"
assert_contains "${calls}" "plugin uninstall status-bar@ycc-mods --scope user" "claude mods remove uninstalls each mod"
assert_contains "${calls}" "plugin marketplace remove ycc-mods --scope user" "claude mods remove drops the ycc-mods marketplace"
assert_contains "${out}" "Claude remove complete" "claude base/mods remove completes"

# Base installs are simulated (copies + links shaped like the real step) so
# the test never runs the generators.
home="$(new_home)"
for unit in skills agents rules; do
    mkdir -p "${home}/.cursor/${unit}"
    cp -R "${REPO_ROOT}/.cursor-plugin/${unit}/." "${home}/.cursor/${unit}/"
done
mkdir -p "${home}/.cursor/skills/my-own-skill"
run_install "${home}" remove --target cursor --intent base >/dev/null
if [[ -d "${home}/.cursor/skills/my-own-skill" ]]; then ok "cursor base remove keeps user skills"; else ko "cursor base remove keeps user skills"; fi
leftover="$(find "${home}/.cursor/skills" -mindepth 1 -maxdepth 1 -printf '%f\n')"
if [[ "${leftover}" == "my-own-skill" ]]; then ok "cursor base remove drops bundle skills"; else ko "cursor base remove drops bundle skills" "${leftover}"; fi
if [[ ! -e "${home}/.cursor/agents" ]]; then ok "cursor base remove drops emptied agents dir"; else ko "cursor base remove drops emptied agents dir"; fi

home="$(new_home)"
for unit in skills agents commands shared; do
    mkdir -p "${home}/.config/opencode/${unit}"
    cp -R "${REPO_ROOT}/.opencode-plugin/${unit}/." "${home}/.config/opencode/${unit}/"
done
run_install "${home}" remove --target opencode --intent base >/dev/null
leftover="$(find "${home}/.config/opencode" -mindepth 1 | head -3)"
if [[ -z "${leftover}" ]]; then ok "opencode base remove drops the bundle"; else ko "opencode base remove drops the bundle" "${leftover}"; fi

home="$(new_home)"
mkdir -p "${home}/.codex/plugins/cache/local-ycc-plugins/ycc/skills" "${home}/.agents/plugins" "${home}/.codex/agents"
ln -s "${REPO_REAL}/.codex-plugin/ycc" "${home}/.codex/plugins/ycc"
ln -s "${REPO_REAL}/.codex-plugin/ycc" "${home}/.agents/plugins/ycc"
cp -R "${REPO_ROOT}/.codex-plugin/agents/." "${home}/.codex/agents/"
echo 'name = "mine"' > "${home}/.codex/agents/mine.toml"
cat > "${home}/.agents/plugins/marketplace.json" <<'JSON'
{
  "name": "local-ycc-plugins",
  "interface": { "displayName": "Local YCC Plugins" },
  "plugins": [{ "name": "ycc", "source": { "source": "local", "path": "./plugins/ycc" } }, { "name": "other" }]
}
JSON
run_install "${home}" remove --target codex --intent base >/dev/null
assert_contains "$(cat "${home}/claude-calls.log" 2>/dev/null)" "codex plugin remove ycc@local-ycc-plugins" "codex base remove uninstalls through the codex CLI"
for f in .codex/plugins/ycc .agents/plugins/ycc .codex/plugins/cache/local-ycc-plugins; do
    if [[ ! -e "${home}/${f}" && ! -L "${home}/${f}" ]]; then ok "codex base remove cleans ${f}"; else ko "codex base remove cleans ${f}"; fi
done
if [[ "$(find "${home}/.codex/agents" -mindepth 1 -maxdepth 1 -printf '%f\n')" == "mine.toml" ]]; then ok "codex base remove keeps only user agents"; else ko "codex base remove keeps only user agents"; fi
merged="$(cat "${home}/.agents/plugins/marketplace.json")"
assert_contains "${merged}" '"other"' "codex base remove keeps other marketplace plugins"
assert_not_contains "${merged}" '"ycc"' "codex base remove drops the ycc marketplace entry"

home="$(new_home)"
mkdir -p "${home}/.agents/plugins"
cat > "${home}/.agents/plugins/marketplace.json" <<'JSON'
{ "name": "local-ycc-plugins", "interface": { "displayName": "Local YCC Plugins" }, "plugins": [{ "name": "ycc" }] }
JSON
run_install "${home}" remove --target codex --intent base >/dev/null
if [[ ! -e "${home}/.agents/plugins/marketplace.json" ]]; then ok "codex base remove deletes a marketplace left empty"; else ko "codex base remove deletes a marketplace left empty"; fi

home="$(new_home)"
mkdir -p "${home}/.codex/plugins"
ln -s /elsewhere "${home}/.codex/plugins/ycc"
out="$(run_install "${home}" remove --target codex --intent base)"
if [[ -L "${home}/.codex/plugins/ycc" ]]; then ok "codex base remove keeps a foreign link"; else ko "codex base remove keeps a foreign link"; fi

# Codex plugin install through the CLI (lib level; the full base step runs
# the generators). The legacy flat cache must go so Codex's versioned
# snapshot is the only copy.
home="$(new_home)"
mkdir -p "${home}/.codex/plugins/cache/local-ycc-plugins/ycc/.codex-plugin" "${home}/.agents/plugins"
echo '{ "name": "local-ycc-plugins", "plugins": [] }' > "${home}/.agents/plugins/marketplace.json"
out="$(cd "${home}" && HOME="${home}" PATH="${STUB_BIN}:${PATH}" CLAUDE_STUB_LOG="${home}/claude-calls.log" bash -c '
    info() { echo "[ok] $1"; }; warn() { echo "[!!] $1"; }; err() { echo "[err] $1"; }
    SCRIPT_DIR="$1"; source "$1/scripts/lib/install/targets/codex.sh"; install_codex_plugin' _ "${REPO_ROOT}" 2>&1)"
assert_contains "$(cat "${home}/claude-calls.log" 2>/dev/null)" "codex plugin add ycc@local-ycc-plugins" "codex base installs ycc through the codex CLI"
if [[ ! -e "${home}/.codex/plugins/cache/local-ycc-plugins/ycc" ]]; then ok "codex base drops the legacy flat cache"; else ko "codex base drops the legacy flat cache" "${out}"; fi
assert_contains "$(cat "${REPO_ROOT}/scripts/lib/install/targets/codex.sh")" 'merge_codex_marketplace_json "local" "./.agents/plugins/ycc"' "codex marketplace path resolves from the marketplace root"

echo
echo "== install.sh: skills / agents / commands slices =="

# Claude slices need no generation, so they run for real in the sandbox.
home="$(new_home)"
mkdir -p "${home}/.claude/skills/my-own-skill"
out="$(run_install "${home}" install --target claude --only skills,agents,commands)"
assert_not_contains "${out}" "register repo checkout" "claude slices do not run base"
for d in skills/git-workflow skills/_shared agents/codebase-advisor.md commands/clean.md; do
    if [[ -e "${home}/.claude/${d}" ]]; then ok "claude slice installs ~/.claude/${d}"; else ko "claude slice installs ~/.claude/${d}"; fi
done
if [[ ! -e "${home}/.claude/plugins" ]]; then ok "claude slices register no plugin"; else ko "claude slices register no plugin"; fi
skill="$(cat "${home}/.claude/skills/git-workflow/SKILL.md")"
assert_not_contains "${skill}" 'CLAUDE_PLUGIN_ROOT}/skills' "claude slice rewrites plugin-root paths"
assert_contains "${skill}" "${home}/.claude/skills/" "claude slice points paths at ~/.claude/skills"
assert_not_contains "$(cat "${home}/.claude/commands/"*.md)" '/ycc:clean' "claude slice strips the ycc: namespace"
if [[ -d "${home}/.claude/skills/my-own-skill" ]]; then ok "claude slice leaves user skills alone"; else ko "claude slice leaves user skills alone"; fi
out="$(run_install "${home}" install --target claude --only skills)"
assert_contains "${out}" "entries up to date" "claude slice rerun is idempotent"

home="$(new_home)"
mkdir -p "${home}/.claude/skills/git-workflow" && echo "# mine" > "${home}/.claude/skills/git-workflow/SKILL.md"
out="$(run_install "${home}" install --target claude --only skills)"
assert_contains "${out}" "refusing to replace ${home}/.claude/skills/git-workflow" "claude slice refuses a foreign entry"
assert_contains "$(cat "${home}/.claude/skills/git-workflow/SKILL.md")" "# mine" "claude slice keeps the foreign entry"
run_install "${home}" install --target claude --only skills --force >/dev/null
assert_not_contains "$(cat "${home}/.claude/skills/git-workflow/SKILL.md")" "# mine" "claude slice --force replaces it"

run_install "${home}" remove --target claude --intent skills >/dev/null
if [[ ! -e "${home}/.claude/skills" ]]; then ok "claude skills remove takes back every entry"; else ko "claude skills remove takes back every entry" "$(ls "${home}/.claude/skills")"; fi

home="$(new_home)"
out="$(run_install "${home}" sync --target cursor,codex --intent commands)"
assert_contains "${out}" "intent 'commands' is not supported by target 'cursor'" "cursor skips commands intent"
assert_contains "${out}" "intent 'commands' is not supported by target 'codex'" "codex skips commands intent"
assert_not_contains "${out}" "Generate" "unsupported commands intent generates nothing"

home="$(new_home)"
out="$(run_install "${home}" install --target claude,cursor --only commands)"
assert_contains "${out}" "step 'commands' is not supported by target 'cursor' — skipping" "install --only skips a slice a target lacks"
if [[ -e "${home}/.claude/commands/clean.md" ]]; then ok "install --only commands still runs where supported"; else ko "install --only commands still runs where supported" "${out}"; fi

# A copy the 'base' step mirrored is identical to the bundle, so a slice
# remove takes it back even without a recorded install.
home="$(new_home)"
for unit in skills agents rules; do
    mkdir -p "${home}/.cursor/${unit}"
    cp -R "${REPO_ROOT}/.cursor-plugin/${unit}/." "${home}/.cursor/${unit}/"
done
mkdir -p "${home}/.cursor/skills/my-own-skill"
run_install "${home}" remove --target cursor --intent skills >/dev/null
leftover="$(find "${home}/.cursor/skills" -mindepth 1 -maxdepth 1 -printf '%f\n')"
if [[ "${leftover}" == "my-own-skill" ]]; then ok "cursor skills remove drops only bundle skills"; else ko "cursor skills remove drops only bundle skills" "${leftover}"; fi
if [[ -n "$(ls -A "${home}/.cursor/agents")" && -n "$(ls -A "${home}/.cursor/rules")" ]]; then ok "cursor skills remove keeps agents + rules"; else ko "cursor skills remove keeps agents + rules"; fi

home="$(new_home)"
for unit in skills agents commands shared; do
    mkdir -p "${home}/.config/opencode/${unit}"
    cp -R "${REPO_ROOT}/.opencode-plugin/${unit}/." "${home}/.config/opencode/${unit}/"
done
run_install "${home}" remove --target opencode --intent agents,commands >/dev/null
leftover="$(find "${home}/.config/opencode" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort | tr '\n' ' ')"
if [[ "${leftover}" == "shared skills " ]]; then ok "opencode agents,commands remove keeps skills + shared"; else ko "opencode agents,commands remove keeps skills + shared" "${leftover}"; fi
run_install "${home}" remove --target opencode --intent skills >/dev/null
leftover="$(find "${home}/.config/opencode" -mindepth 1 | head -3)"
if [[ -z "${leftover}" ]]; then ok "opencode skills remove takes shared/ too"; else ko "opencode skills remove takes shared/ too" "${leftover}"; fi

# The slice helper directly (no generators): Codex skills land in
# ~/.codex/skills with plugin paths re-pointed there.
home="$(new_home)"
HOME="${home}" YCC_MANAGED_CONFIG_STATE="${home}/.config/ycc/managed-config-state.json" \
    python3 "${REPO_ROOT}/scripts/install_slices.py" install --target codex --slice skills >/dev/null
if [[ -f "${home}/.codex/skills/git-workflow/SKILL.md" && -d "${home}/.codex/skills/_shared/scripts" ]]; then ok "codex skills slice installs into ~/.codex/skills"; else ko "codex skills slice installs into ~/.codex/skills"; fi
if [[ ! -e "${home}/.codex/plugins" ]]; then ok "codex skills slice links no plugin"; else ko "codex skills slice links no plugin"; fi
if ! grep -rq '[~]/.codex/plugins/ycc/s' "${home}/.codex/skills"; then ok "codex skills slice re-points plugin paths"; else ko "codex skills slice re-points plugin paths"; fi
if ! grep -rq '\.\./\.\./\.\./shared/' "${home}/.codex/skills"; then ok "codex skills slice re-points relative shared paths"; else ko "codex skills slice re-points relative shared paths"; fi

# Codex slices are standalone: removing them never touches the plugin.
home="$(new_home)"
mkdir -p "${home}/.agents/plugins" "${home}/.codex/agents" "${home}/.codex/plugins"
ln -s "${REPO_REAL}/.codex-plugin/ycc" "${home}/.codex/plugins/ycc"
cp -R "${REPO_ROOT}/.codex-plugin/agents/." "${home}/.codex/agents/"
echo 'name = "mine"' > "${home}/.codex/agents/mine.toml"
echo '{ "name": "local-ycc-plugins", "plugins": [{ "name": "ycc" }] }' > "${home}/.agents/plugins/marketplace.json"
run_install "${home}" remove --target codex --intent agents,skills >/dev/null
if [[ "$(find "${home}/.codex/agents" -mindepth 1 -printf '%f\n')" == "mine.toml" ]]; then ok "codex agents remove keeps only user agents"; else ko "codex agents remove keeps only user agents"; fi
if [[ -L "${home}/.codex/plugins/ycc" ]]; then ok "codex slice remove keeps the plugin link"; else ko "codex slice remove keeps the plugin link"; fi
assert_contains "$(cat "${home}/.agents/plugins/marketplace.json")" '"ycc"' "codex slice remove keeps the marketplace entry"

echo
echo "== install.sh cli / completion =="

home="$(new_home)"
bin="${home}/.local/bin"
out="$(PATH="${bin}:${PATH}" run_install "${home}" cli)"
if [[ "$(readlink "${bin}/ycc")" == "${INSTALL}" ]]; then ok "cli links ycc into ~/.local/bin"; else ko "cli links ycc into ~/.local/bin" "${out}"; fi
out="$(PATH="${bin}:${PATH}" run_install "${home}" cli)"
assert_contains "${out}" "link up-to-date" "cli rerun is a no-op"

# The regression: a linked command run outside the repo must find its helpers
# and write project MCP into the caller's directory.
out="$(cd "${home}/project" && HOME="${home}" YCC_MANAGED_CONFIG_STATE="${home}/state.json" "${bin}/ycc" sync --target claude --intent mcp 2>&1)"
assert_contains "$(cat "${home}/project/.mcp.json" 2>/dev/null)" '"mcpServers"' "linked ycc merges project MCP from outside the repo"

home="$(new_home)"
mkdir -p "${home}/mybin" && echo "mine" > "${home}/mybin/ycc"
out="$(run_install "${home}" cli --dir "${home}/mybin")"
assert_contains "${out}" "refusing to replace existing" "cli refuses foreign file without --force"
run_install "${home}" cli --dir "${home}/mybin" --force >/dev/null
if [[ "$(readlink "${home}/mybin/ycc")" == "${INSTALL}" ]]; then ok "cli --dir --force replaces"; else ko "cli --dir --force replaces"; fi

home="$(new_home)"
out="$(run_install "${home}" cli --dir "${home}/offpath")"
assert_contains "${out}" "is not on PATH" "cli warns when dir is off PATH"

home="$(new_home)"
for sh in bash zsh fish; do
    out="$(run_install "${home}" completion --shell "${sh}")"
    assert_contains "${out}" "ycc" "completion prints ${sh} script"
done
out="$(run_install "${home}" completion --shell tcsh)"
assert_contains "${out}" "unsupported shell 'tcsh'" "completion rejects unknown shell"

home="$(new_home)"
run_install "${home}" completion --shell bash --install >/dev/null
run_install "${home}" completion --shell zsh --install >/dev/null
run_install "${home}" completion --shell fish --install >/dev/null
for f in .local/share/bash-completion/completions/ycc .local/share/zsh/site-functions/_ycc .config/fish/completions/ycc.fish; do
    if [[ -L "${home}/${f}" ]]; then ok "completion installed: ${f}"; else ko "completion installed: ${f}"; fi
done
rm "${home}/.local/share/zsh/site-functions/_ycc" && echo "mine" > "${home}/.local/share/zsh/site-functions/_ycc"
out="$(run_install "${home}" completion --shell zsh --install)"
assert_contains "${out}" "refusing to replace existing" "completion --install refuses real file without --force"
run_install "${home}" completion --shell zsh --install --force >/dev/null
if [[ -L "${home}/.local/share/zsh/site-functions/_ycc" ]]; then ok "completion --install --force replaces"; else ko "completion --install --force replaces"; fi

if bash -n "${REPO_ROOT}/scripts/completions/ycc.bash"; then ok "bash completion parses"; else ko "bash completion parses"; fi
if ! command -v zsh >/dev/null || zsh -n "${REPO_ROOT}/scripts/completions/_ycc"; then ok "zsh completion parses"; else ko "zsh completion parses"; fi
if ! command -v fish >/dev/null || fish -n "${REPO_ROOT}/scripts/completions/ycc.fish"; then ok "fish completion parses"; else ko "fish completion parses"; fi
out="$(bash -c 'source "$1"; COMP_WORDS=(ycc sync --target claude,co); COMP_CWORD=3; _ycc; echo "${COMPREPLY[*]}"' _ "${REPO_ROOT}/scripts/completions/ycc.bash")"
assert_contains "${out}" "claude,codex" "bash completion completes comma lists"

# source_install_libs — load install.sh's libs (no side effects at source time)
# into the current shell, the same way install.sh does.
# shellcheck disable=SC1090,SC1091  # paths are built from REPO_ROOT at runtime.
source_install_libs() {
    SCRIPT_DIR="${REPO_ROOT}"
    eval "$(sed -n 's/^ALL_TARGETS=(\(.*\))$/ALL_TARGETS=(\1)/p' "${INSTALL}")"
    local f
    for f in core steps bundle cli; do source "${REPO_ROOT}/scripts/lib/install/${f}.sh"; done
    for f in "${ALL_TARGETS[@]}"; do source "${REPO_ROOT}/scripts/lib/install/targets/${f}.sh"; done
}

# Every target in ALL_TARGETS implements the per-target lib contract.
missing="$(bash -c 'REPO_ROOT="$1"; INSTALL="$2"; '"$(declare -f source_install_libs)"'
    source_install_libs
    for t in "${ALL_TARGETS[@]}"; do
        for fn in "${t}_valid_steps" "${t}_intent_steps" "${t}_config_groups" "${t}_supports_repo_mode"; do
            declare -F "${fn}" >/dev/null || printf " %s" "${fn}"
        done
    done' _ "${REPO_ROOT}" "${INSTALL}" 2>&1)"
if [[ -z "${missing}" ]]; then ok "every target defines the lib contract"; else ko "every target defines the lib contract" "missing:${missing}"; fi

# Completion lists must track install.sh: every intent, and every step any
# target accepts for --only.
intents="$(bash -c 'REPO_ROOT="$1"; INSTALL="$2"; '"$(declare -f source_install_libs)"'
    source_install_libs; echo "${VALID_INTENTS[*]}"' _ "${REPO_ROOT}" "${INSTALL}")"
steps="$(bash -c 'REPO_ROOT="$1"; INSTALL="$2"; '"$(declare -f source_install_libs)"'
    source_install_libs; for t in "${ALL_TARGETS[@]}"; do valid_steps_for_target "$t"; done' _ "${REPO_ROOT}" "${INSTALL}" \
    | tr ',' '\n' | awk '!seen[$0]++' | tr '\n' ' ')"
for f in _ycc ycc.bash ycc.fish; do
    assert_contains "$(cat "${REPO_ROOT}/scripts/completions/${f}")" "${intents}" "${f} completes every intent"
    only_line="$(grep -E -- 'only' "${REPO_ROOT}/scripts/completions/${f}" | grep -E 'base' | head -1)"
    missing=""
    for word in ${steps}; do
        [[ " ${only_line//[\"\']/ } " == *" ${word} "* ]] || missing+=" ${word}"
    done
    if [[ -z "${missing}" ]]; then ok "${f} --only completes every step"; else ko "${f} --only completes every step" "missing:${missing}"; fi
done

echo
printf 'test-install-sync: %d passed, %d failed\n' "${PASS}" "${FAIL}"
[[ ${FAIL} -eq 0 ]]
