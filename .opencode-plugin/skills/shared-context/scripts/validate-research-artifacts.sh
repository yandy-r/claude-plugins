#!/usr/bin/env bash
# Validates research artifact files for shared-context
# Usage: validate-research-artifacts.sh <feature-dir>
#
# Checks that all 4 research agent outputs exist, are non-empty,
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
    "research-architecture.md"
    "research-patterns.md"
    "research-integration.md"
    "research-docs.md"
)

echo "Validating research artifacts in: $feature_dir"
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
        research-architecture.md)
            require_any_heading "$path" "system/components section" \
                "## System Overview" "## Relevant Components" "## Architecture Overview"
            require_any_heading "$path" "integration section" \
                "## Integration Points" "## Data Flow" "## Key Dependencies"
            ;;
        research-patterns.md)
            require_any_heading "$path" "patterns section" \
                "## Architectural Patterns" "## Patterns to Follow" "## Code Conventions"
            ;;
        research-integration.md)
            require_any_heading "$path" "API/database section" \
                "## API Endpoints" "## Database" "## External Services"
            ;;
        research-docs.md)
            require_any_heading "$path" "documentation section" \
                "## Must-Read Documents" "## Architecture Docs" "## Documentation Gaps"
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
