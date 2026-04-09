#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# install.sh — sync ycc plugin assets to target IDE config directories
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YCC_DIR="${SCRIPT_DIR}/ycc"

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

Sync ycc plugin assets to an IDE configuration directory.

Options:
  --target <target>   Target IDE (cursor)
  --help              Show this help message

Targets:
  cursor   Sync skills/, agents/, and rules/ to ~/.cursor/

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

    # Sync skills and agents from ycc/
    local ycc_dirs=(skills agents)

    for dir in "${ycc_dirs[@]}"; do
        local src="${YCC_DIR}/${dir}/"
        local dest="${cursor_dir}/${dir}/"

        if [[ ! -d "${src}" ]]; then
            warn "Source not found, skipping: ${src}"
            continue
        fi

        mkdir -p "${dest}"
        rsync -av --update "${src}" "${dest}"
        info "Synced ${dir}/ → ${dest}"
    done

    # Sync rules from .cursor/rules/ (repo root)
    local rules_src="${SCRIPT_DIR}/.cursor/rules/"
    local rules_dest="${cursor_dir}/rules/"

    if [[ ! -d "${rules_src}" ]]; then
        warn "Source not found, skipping: ${rules_src}"
    else
        mkdir -p "${rules_dest}"
        rsync -av --update "${rules_src}" "${rules_dest}"
        info "Synced rules/ → ${rules_dest}"
    fi

    printf "\n${BOLD}Cursor sync complete.${NC}\n"
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
