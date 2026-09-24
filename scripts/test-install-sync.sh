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

# run_install <home> <args...> — run install.sh sandboxed; capture output.
# Runs from <home>/project (not a git repo) so project-scoped steps write
# there and never into this checkout.
run_install() {
    local home="$1"
    shift
    (
        cd "${home}/project" || exit 1
        HOME="${home}" \
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
out="$(run_install "${home}" --target claude --intent settings)"
assert_contains "${out}" "--intent requires the 'sync' or 'remove' subcommand" "--intent rejected in legacy mode"

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
out="$(run_install "${home}" --target claude,codex --only hooks)"
assert_contains "${out}" "--only step 'hooks' is not valid for target 'codex'" "legacy --only validated across all targets"
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
echo "== install.sh legacy CLI still works =="

home="$(new_home)"
out="$(run_install "${home}" --target claude --only rules)"
assert_contains "${out}" "link rules" "legacy --only rules runs"
assert_not_contains "${out}" "register repo checkout" "legacy --only stays exclusive"

home="$(new_home)"
out="$(run_install "${home}" --target claude --only bogus)"
assert_contains "${out}" "is not valid for target" "legacy --only validates steps"

echo
echo "== install.sh: --project / --global MCP scope =="

home="$(new_home)"
out="$(run_install "${home}" --target claude --project --global)"
assert_contains "${out}" "mutually exclusive" "--project and --global rejected together"

home="$(new_home)"
out="$(run_install "${home}" --target claude --only settings,mcp --project)"
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
run_install "${home}" --target claude --only mcp --global >/dev/null
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
out="$(run_install "${home}" remove --target claude --only settings)"
assert_contains "${out}" "remove does not support step 'settings'" "remove rejects unsupported steps"

home="$(new_home)"
cat > "${home}/project/.mcp.json" <<'JSON'
{ "mcpServers": { "mine": { "url": "https://mine" } } }
JSON
run_install "${home}" --target claude --only mcp >/dev/null
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
run_install "${home}" --target codex --only mcp --global >/dev/null
run_install "${home}" remove --target codex --only mcp --global >/dev/null
merged="$(cat "${home}/.codex/config.toml")"
assert_contains "${merged}" "# keep me" "codex remove keeps comments"
assert_contains "${merged}" "[mcp_servers.internal]" "codex remove keeps user server"
assert_not_contains "${merged}" "[mcp_servers.playwright]" "codex remove drops managed server"

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

echo
printf 'test-install-sync: %d passed, %d failed\n' "${PASS}" "${FAIL}"
[[ ${FAIL} -eq 0 ]]
