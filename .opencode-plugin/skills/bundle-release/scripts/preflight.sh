#!/usr/bin/env bash
# Pre-flight gate for the bundle-release skill.
# Checks that the git working tree is clean, versions are in parity across
# ycc/.opencode-plugin/plugin.json and .opencode-plugin/marketplace.json, and warns
# if not on the main branch.
#
# Usage:
#   preflight.sh
#   preflight.sh -h|--help
#
# Exits 0 on success and prints: current_version=<ver>, branch=<name>
# Exits 1 on hard failure (tree dirty or version parity violation)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

usage() {
    cat <<EOF
Usage: preflight.sh

Gate checks before a ycc release:
  1. git working tree is clean
  2. current version parity across ycc/.opencode-plugin/plugin.json
     and .opencode-plugin/marketplace.json
  3. warn if not on main branch

Exits 0 on success and prints: current_version=<ver>, branch=<name>
Exits 1 on hard failure (tree dirty or version parity violation)
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

PLUGIN_VERSION="$(read_json_value "${REPO_ROOT}/ycc/.opencode-plugin/plugin.json" '["version"]')"
MARKETPLACE_META_VERSION="$(read_json_value "${REPO_ROOT}/.opencode-plugin/marketplace.json" '["metadata"]["version"]')"
MARKETPLACE_PLUGIN_VERSION="$(read_json_value "${REPO_ROOT}/.opencode-plugin/marketplace.json" '["plugins"][0]["version"]')"

if ! [[ "${PLUGIN_VERSION}" == "${MARKETPLACE_META_VERSION}" && "${PLUGIN_VERSION}" == "${MARKETPLACE_PLUGIN_VERSION}" ]]; then
    echo "preflight.sh: FAIL: version parity violation" >&2
    echo "  ycc/.opencode-plugin/plugin.json .version           = ${PLUGIN_VERSION}" >&2
    echo "  .opencode-plugin/marketplace.json .metadata.version = ${MARKETPLACE_META_VERSION}" >&2
    echo "  .opencode-plugin/marketplace.json .plugins[0].version = ${MARKETPLACE_PLUGIN_VERSION}" >&2
    exit 1
fi

# --- Success ---
echo "preflight.sh: OK"
echo "current_version=${PLUGIN_VERSION}"
echo "branch=${BRANCH}"
