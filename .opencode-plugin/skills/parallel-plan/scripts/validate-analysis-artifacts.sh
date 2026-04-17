#!/usr/bin/env bash
# Validates analysis artifact files for parallel-plan
# Usage: validate-analysis-artifacts.sh <feature-dir>
#
# Checks that all 3 analysis agent outputs exist, are non-empty,
# meet minimum size, and contain expected headings.
# Exits non-zero if any file is missing or invalid.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
RESOLVER="${SCRIPT_DIR}/../../../shared/scripts/resolve-plans-dir.sh"

# Source resolver to get PLANS_ROOT for path resolution
if [[ -f "$RESOLVER" ]]; then
    # shellcheck source=../../../shared/scripts/resolve-plans-dir.sh
    source "$RESOLVER"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

errors=0
warnings=0

log_error() {
    echo -e "${RED}ERROR:${NC} $1"
    ((errors++)) || true
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
    ((warnings++)) || true
}

log_success() {
    echo -e "${GREEN}OK:${NC} $1"
}

require_any_heading() {
    local file="$1"
    local label="$2"
    shift 2

    local found=false
    local heading
    for heading in "$@"; do
        if grep -q "^${heading}" "$file"; then
            found=true
            break
        fi
    done

    if [[ "$found" == true ]]; then
        log_success "$(basename "$file"): found ${label}"
    else
        log_error "$(basename "$file"): missing ${label} (expected one of: $*)"
    fi
}

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <feature-dir>"
    exit 1
fi

feature_dir="$1"

# Always resolve relative paths against PLANS_ROOT (from resolve-plans-dir.sh)
if [[ "$feature_dir" != /* && -n "${PLANS_ROOT:-}" ]]; then
    feature_dir="${PLANS_ROOT}/${feature_dir}"
fi

if [[ ! -d "$feature_dir" ]]; then
    log_error "Feature directory not found: $feature_dir"
    exit 1
fi

declare -a files=(
    "analysis-context.md"
    "analysis-code.md"
    "analysis-tasks.md"
)

echo "Validating analysis artifacts in: $feature_dir"
echo "=========================================="

for file in "${files[@]}"; do
    path="${feature_dir}/${file}"

    if [[ ! -f "$path" ]]; then
        log_error "${file}: file not found"
        continue
    fi

    if [[ ! -s "$path" ]]; then
        log_error "${file}: file is empty"
        continue
    fi

    size_bytes="$(wc -c < "$path" | tr -d ' ')"
    if [[ "$size_bytes" -lt 400 ]]; then
        log_warning "${file}: content is short (${size_bytes} bytes)"
    fi

    # Check for title heading
    if grep -q "^# " "$path"; then
        log_success "${file}: has title heading"
    else
        log_warning "${file}: missing title heading"
    fi

    # File-specific heading checks
    case "$file" in
        analysis-context.md)
            require_any_heading "$path" "summary section" \
                "## Executive Summary" "## Summary" "## Overview"
            require_any_heading "$path" "architecture section" \
                "## Architecture Context" "## Architecture" "## Critical Files Reference"
            ;;
        analysis-code.md)
            require_any_heading "$path" "summary section" \
                "## Executive Summary" "## Summary" "## Overview"
            require_any_heading "$path" "patterns section" \
                "## Implementation Patterns" "## Existing Code Structure" "## Code Conventions"
            ;;
        analysis-tasks.md)
            require_any_heading "$path" "summary section" \
                "## Executive Summary" "## Summary" "## Overview"
            require_any_heading "$path" "phase/task section" \
                "## Recommended Phase Structure" "## Task Granularity" "## Dependency Analysis"
            ;;
    esac
done

echo "=========================================="
echo "Errors: $errors"
echo "Warnings: $warnings"

if [[ $errors -gt 0 ]]; then
    exit 1
fi

exit 0
