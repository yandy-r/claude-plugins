#!/usr/bin/env bash
# Pre-flight gate for the bundle-release skill.
# Checks that the git working tree is clean, versions are in parity across
# ycc/.claude-plugin/plugin.json and .claude-plugin/marketplace.json, warns
# if not on the main branch, and scans hand-edited docs for stale semver
# literals that don't match the current version.
#
# Usage:
#   preflight.sh
#   preflight.sh -h|--help
#
# Exits 0 on success and prints: current_version=<ver>, branch=<name>
# Exits 1 on hard failure (tree dirty, version parity violation, or stale
# version literal detected in hand-edited docs)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

usage() {
    cat <<'EOF'
Usage: preflight.sh

Gate checks before a ycc release:
  1. git working tree is clean
  2. current version parity across ycc/.claude-plugin/plugin.json
     and .claude-plugin/marketplace.json
  3. warn if not on main branch
  4. no stale version literals (version: X.Y.Z or "version": "X.Y.Z")
     in hand-edited docs where the semver does not match the current
     version. Example literals should use the "<managed by the
     bundle-release skill>" placeholder — or match the current version.

Exits 0 on success and prints: current_version=<ver>, branch=<name>
Exits 1 on hard failure (tree dirty, version parity, or stale literal)
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "preflight.sh: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# --- Check 1: clean git tree ---
cd "${REPO_ROOT}"
if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git status --porcelain)" ]]; then
    echo "preflight.sh: FAIL: git working tree is not clean" >&2
    git status --short >&2
    exit 1
fi

# --- Check 2: current branch warn ---
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "${BRANCH}" != "main" ]]; then
    echo "preflight.sh: WARN: current branch is '${BRANCH}', not 'main'" >&2
fi

# --- Check 3: version parity ---
read_json_value() {
    python3 -c "import json,sys; print(json.load(open(sys.argv[1]))$2)" "$1"
}

PLUGIN_VERSION="$(read_json_value "${REPO_ROOT}/ycc/.claude-plugin/plugin.json" '["version"]')"
MARKETPLACE_META_VERSION="$(read_json_value "${REPO_ROOT}/.claude-plugin/marketplace.json" '["metadata"]["version"]')"
MARKETPLACE_PLUGIN_VERSION="$(read_json_value "${REPO_ROOT}/.claude-plugin/marketplace.json" '["plugins"][0]["version"]')"

if ! [[ "${PLUGIN_VERSION}" == "${MARKETPLACE_META_VERSION}" && "${PLUGIN_VERSION}" == "${MARKETPLACE_PLUGIN_VERSION}" ]]; then
    echo "preflight.sh: FAIL: version parity violation" >&2
    echo "  ycc/.claude-plugin/plugin.json .version           = ${PLUGIN_VERSION}" >&2
    echo "  .claude-plugin/marketplace.json .metadata.version = ${MARKETPLACE_META_VERSION}" >&2
    echo "  .claude-plugin/marketplace.json .plugins[0].version = ${MARKETPLACE_PLUGIN_VERSION}" >&2
    exit 1
fi

# --- Check 4: no stale version literals in hand-edited docs ---
#
# Scans a fixed allowlist of hand-edited files for patterns that look like
# version declarations in an example (version: X.Y.Z or "version": "X.Y.Z").
# Any matched semver that does not equal PLUGIN_VERSION is flagged as stale
# — the author should either bump the example to match or replace it with
# the "<managed by /ycc:bundle-release>" placeholder.
#
# Prose mentions of older versions (e.g., "2.0.0 breaking change") are not
# matched because the pattern requires a "version" key preceding the semver.
#
# Generated bundles (.opencode-plugin, .cursor-plugin, .codex-plugin) and
# historical directories (docs/releases, docs/plans, docs/research,
# docs/internal) are excluded.

scan_targets=(
    "${REPO_ROOT}/CLAUDE.md"
    "${REPO_ROOT}/AGENTS.md"
    "${REPO_ROOT}/README.md"
    "${REPO_ROOT}/docs/README.md"
)

stale_found=0
version_literal_re='[Vv]ersion"?[[:space:]]*[:=][[:space:]]*"?[0-9]+\.[0-9]+\.[0-9]+"?'
semver_re='[0-9]+\.[0-9]+\.[0-9]+'

for target in "${scan_targets[@]}"; do
    [[ -f "${target}" ]] || continue
    while IFS=: read -r lineno match; do
        [[ -n "${match}" ]] || continue
        sem="$(printf '%s' "${match}" | grep -oE "${semver_re}" | head -n1)"
        [[ -n "${sem}" ]] || continue
        if [[ "${sem}" != "${PLUGIN_VERSION}" ]]; then
            rel="${target#"${REPO_ROOT}"/}"
            echo "preflight.sh: FAIL: stale version literal (${sem} != ${PLUGIN_VERSION}) at ${rel}:${lineno}" >&2
            echo "    ${match}" >&2
            stale_found=1
        fi
    done < <(grep -nE "${version_literal_re}" "${target}" 2>/dev/null || true)
done

if [[ ${stale_found} -eq 1 ]]; then
    echo "preflight.sh: HINT: update the literal to match ${PLUGIN_VERSION}, or replace it with the '<managed by the bundle-release skill>' placeholder." >&2
    exit 1
fi

# --- Success ---
echo "preflight.sh: OK"
echo "current_version=${PLUGIN_VERSION}"
echo "branch=${BRANCH}"
