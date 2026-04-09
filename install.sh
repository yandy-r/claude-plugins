#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# install.sh — sync plugin assets to target IDE config directories
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_PLUGIN_DIR="${SCRIPT_DIR}/.cursor-plugin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${GREEN}[ok]${NC}  %s\n" "$1"; }
warn()  { printf "${YELLOW}[!!]${NC}  %s\n" "$1"; }
err()   { printf "${RED}[err]${NC} %s\n" "$1" >&2; }

usage() {
    cat <<EOF
Usage: $(basename "$0") --target <target>

Sync plugin assets to an IDE configuration directory.

Options:
  --target <target>   Target IDE (cursor)
  --help              Show this help message

Targets:
  cursor   Sync skills/, agents/, and rules/ from .cursor-plugin/ to ~/.cursor/

Examples:
  $(basename "$0") --target cursor
EOF
}

# ---------------------------------------------------------------------------
# Cursor sync
# ---------------------------------------------------------------------------
sync_cursor() {
    local cursor_dir="${HOME}/.cursor"

    if [[ ! -d "${cursor_dir}" ]]; then
        err "Cursor config directory not found: ${cursor_dir}"
        exit 1
    fi

    command -v rsync >/dev/null 2>&1 || { err "rsync is required but not found"; exit 1; }

    if [[ ! -d "${CURSOR_PLUGIN_DIR}" ]]; then
        err "Cursor plugin source directory not found: ${CURSOR_PLUGIN_DIR}"
        exit 1
    fi

    local managed_units=(skills agents rules)
    local unit

    for unit in "${managed_units[@]}"; do
        local src_unit="${CURSOR_PLUGIN_DIR}/${unit}/"
        local dest_unit="${cursor_dir}/${unit}/"

        if [[ -d "${src_unit}" ]]; then
            mkdir -p "${dest_unit}"
            rsync -av --delete "${src_unit}" "${dest_unit}"
            info "Synced ${unit}/ → ${dest_unit}"
        elif [[ -d "${dest_unit}" ]]; then
            rm -rf "${dest_unit}"
            warn "Removed ${dest_unit} (missing from .cursor-plugin)"
        else
            warn "Source not found, skipping: ${src_unit}"
        fi
    done

    printf '\n%sCursor sync complete.%s\n' "${BOLD}" "${NC}"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            [[ $# -lt 2 ]] && { err "--target requires an argument"; exit 1; }
            TARGET="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "${TARGET}" ]]; then
    err "Missing required --target flag"
    usage
    exit 1
fi

case "${TARGET}" in
    cursor)
        sync_cursor
        ;;
    *)
        err "Unknown target: ${TARGET} (supported: cursor)"
        exit 1
        ;;
esac
