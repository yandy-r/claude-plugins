#!/usr/bin/env bash
# install-codex.sh — install / uninstall the ycc plugin inside Codex.
#
# Sourced by install.sh (never run directly); relies on its helpers (info,
# warn, err) and globals (HOME, CODEX_PLUGIN_DIR).
#
# Codex 0.160+ ships a plugin CLI: 'codex plugin add ycc@<marketplace>'
# snapshots the plugin into ~/.codex/plugins/cache/<marketplace>/ycc/<version>/
# and enables it in config.toml. Older Codex builds have no such command; for
# them the installer still writes the flat enabled-plugin cache by hand.

CODEX_MARKETPLACE_JSON="${HOME}/.agents/plugins/marketplace.json"
CODEX_PLUGIN_CACHE="${HOME}/.codex/plugins/cache/local-ycc-plugins/ycc"

# codex_plugin_cli_supported — true when the codex CLI has 'plugin add'.
codex_plugin_cli_supported() {
    command -v codex >/dev/null 2>&1 && codex plugin add --help >/dev/null 2>&1
}

# codex_marketplace_name — the name of the marketplace holding ycc (the
# installer keeps an existing name when it merges its entry).
codex_marketplace_name() {
    python3 - "${CODEX_MARKETPLACE_JSON}" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as handle:
        name = json.load(handle).get("name")
except (OSError, ValueError, AttributeError):
    name = None
print(name if isinstance(name, str) and name.strip() else "local-ycc-plugins")
PY
}

# remove_legacy_codex_cache — drop the flat cache older installers wrote at
# cache/local-ycc-plugins/ycc/ (plugin files directly inside, no version
# directory). Codex's own versioned cache lives in the same directory, so the
# flat copy would shadow it.
remove_legacy_codex_cache() {
    local cache="${CODEX_PLUGIN_CACHE}"
    if [[ -L "${cache}" ]]; then
        rm "${cache}"
        info "removed legacy Codex cache link ${cache}"
    elif [[ -d "${cache}/.codex-plugin" ]]; then
        rm -rf "${cache}"
        info "removed legacy flat Codex cache ${cache}"
    fi
}

# refresh_legacy_codex_cache — pre-CLI Codex: mirror the bundle into the
# enabled-plugin cache root and write its skills compatibility manifest.
refresh_legacy_codex_cache() {
    local cache="${CODEX_PLUGIN_CACHE}"
    if [[ -L "${cache}" ]]; then
        rm "${cache}"
    elif [[ -e "${cache}" && ! -d "${cache}" ]]; then
        err "Stale Codex plugin cache path at ${cache}."
        err "Remove it with:  rm -f ${cache}"
        exit 1
    fi
    mkdir -p "${cache}"
    rsync -a --delete "${CODEX_PLUGIN_DIR}/" "${cache}/"
    info "Synced Codex enabled-plugin cache → ${cache}"
    python3 - "${cache}" <<'PY'
import json
import sys
from pathlib import Path

cache_root = Path(sys.argv[1])
source_manifest = cache_root / ".codex-plugin" / "plugin.json"
skills_manifest = cache_root / "skills" / ".codex-plugin" / "plugin.json"
skills_index = cache_root / "skills" / "_skills"
payload = json.loads(source_manifest.read_text(encoding="utf-8"))
payload["skills"] = "./_skills/"
skills_manifest.parent.mkdir(parents=True, exist_ok=True)
skills_manifest.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
skills_index.mkdir(exist_ok=True)
for child in sorted((cache_root / "skills").iterdir()):
    if not child.is_dir() or child.name in {".codex-plugin", "_skills"}:
        continue
    link = skills_index / child.name
    if link.exists() or link.is_symlink():
        link.unlink()
    link.symlink_to(child, target_is_directory=True)
PY
    info "Wrote Codex cache compatibility manifest → ${cache}/skills/.codex-plugin/plugin.json"
}

# install_codex_plugin — install + enable ycc from its registered marketplace.
# Re-running refreshes Codex's snapshot of the plugin.
install_codex_plugin() {
    if ! codex_plugin_cli_supported; then
        warn "'codex plugin add' is unavailable (codex CLI missing or older than 0.160); writing the legacy cache instead."
        refresh_legacy_codex_cache
        return 0
    fi
    remove_legacy_codex_cache
    local selector
    selector="ycc@$(codex_marketplace_name)"
    info "Running: codex plugin add ${selector}"
    codex plugin add "${selector}" || warn "'codex plugin add ${selector}' returned non-zero — check 'codex plugin list'"
}

# uninstall_codex_plugin — undo install_codex_plugin through the CLI; a
# plugin that is not installed is reported, not fatal.
uninstall_codex_plugin() {
    codex_plugin_cli_supported || return 0
    [[ -f "${CODEX_MARKETPLACE_JSON}" ]] || return 0
    local selector
    selector="ycc@$(codex_marketplace_name)"
    info "Running: codex plugin remove ${selector}"
    codex plugin remove "${selector}" || warn "'codex plugin remove ${selector}' returned non-zero — check 'codex plugin list'"
}
