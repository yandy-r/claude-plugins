#!/usr/bin/env bash
# draft-changelog.sh — Emit a Markdown changelog fragment for a new release, grouped
# by conventional-commit type.  Input is the git log since the latest tag (or the
# last 50 commits if no tag exists).
#
# Usage:
#   draft-changelog.sh <new-version> [<from-ref>]
#
# Arguments:
#   new-version   Semver to title the fragment (e.g. 1.4.0 or v1.4.0).
#   from-ref      Optional explicit "since" ref.  Defaults to the latest tag, or
#                 HEAD~50 if no tag exists.
#
# Output goes to stdout.  Diagnostics go to stderr.

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "draft-changelog.sh: missing required argument: <new-version>" >&2
    echo "Usage: draft-changelog.sh <new-version> [<from-ref>]" >&2
    exit 1
fi

NEW_VERSION="$1"
FROM_REF="${2:-}"

# Normalize — strip leading v if present for the title; keep full tag for compare URL
TITLE_VERSION="${NEW_VERSION#v}"

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "draft-changelog.sh: not inside a git repository" >&2
    exit 1
fi

if [[ -z "${FROM_REF}" ]]; then
    FROM_REF="$(git describe --tags --abbrev=0 2>/dev/null || true)"
    if [[ -z "${FROM_REF}" ]]; then
        FROM_REF="HEAD~50"
    fi
fi

# Sanity check: the ref resolves
if ! git rev-parse --verify --quiet "${FROM_REF}" >/dev/null; then
    echo "draft-changelog.sh: ref not found: ${FROM_REF}" >&2
    exit 1
fi

DATE="$(date -u +%Y-%m-%d)"

# Collect commits in stable order (oldest → newest).  Records are NUL-separated
# so multi-line commit bodies survive round-trip.  Within a record, tab separates
# hash / subject / body.
LOG_TMP="$(mktemp)"
trap 'rm -f "${LOG_TMP}"' EXIT
git log "${FROM_REF}..HEAD" --no-merges --reverse -z \
    --format='%h%x09%s%x09%b' > "${LOG_TMP}"

if [[ ! -s "${LOG_TMP}" ]]; then
    echo "draft-changelog.sh: no commits between ${FROM_REF} and HEAD" >&2
    # Still emit a stub so the caller has a file to edit.
    cat <<EOF
# v${TITLE_VERSION} (${DATE})

## Summary

Maintenance release — no user-facing changes since ${FROM_REF}.

EOF
    exit 0
fi

# Bucketize.  Conventional-commit types: feat, fix, docs, chore, refactor, perf,
# test, build, ci, revert, style.  We also detect BREAKING CHANGE in body.
FEATURES=()
FIXES=()
BREAKING=()
DOCS=()
CHORE=()
OTHER=()

# Field separator = tab; subject carries type prefix.
# Regex patterns stored in variables — bash `[[ =~ ]]` is sensitive to quoting of
# parens when the pattern is inline.
_BREAKING_PREFIX_RE='^[a-z]+(\([^)]*\))?!'
_BREAKING_BODY_RE='BREAKING[[:space:]]CHANGE'

while IFS=$'\t' read -r -d '' hash subject body; do
    # Detect breaking change marker
    is_breaking=0
    if [[ "${subject}" =~ ${_BREAKING_PREFIX_RE} ]]; then
        is_breaking=1
    fi
    if [[ "${body}" =~ ${_BREAKING_BODY_RE} ]]; then
        is_breaking=1
    fi

    # Strip the conventional prefix for display
    display="${subject}"
    case "${subject}" in
        feat:*|feat\(*\):*)  bucket="features"  ;;
        feat!*|feat\(*\)!:*) bucket="features"; is_breaking=1 ;;
        fix:*|fix\(*\):*)    bucket="fixes"     ;;
        fix!*|fix\(*\)!:*)   bucket="fixes"; is_breaking=1 ;;
        docs:*|docs\(*\):*)  bucket="docs"      ;;
        chore:*|chore\(*\):*)  bucket="chore"   ;;
        refactor:*|refactor\(*\):*) bucket="chore" ;;
        perf:*|perf\(*\):*)  bucket="features"  ;;
        test:*|test\(*\):*)  bucket="chore"     ;;
        build:*|build\(*\):*)  bucket="chore"   ;;
        ci:*|ci\(*\):*)      bucket="chore"     ;;
        revert:*)            bucket="fixes"     ;;
        style:*|style\(*\):*)  bucket="chore"   ;;
        *)                   bucket="other"     ;;
    esac

    line="- ${display} (${hash})"
    if [[ ${is_breaking} -eq 1 ]]; then
        BREAKING+=("${line}")
    fi

    case "${bucket}" in
        features) FEATURES+=("${line}") ;;
        fixes)    FIXES+=("${line}")    ;;
        docs)     DOCS+=("${line}")     ;;
        chore)    CHORE+=("${line}")    ;;
        other)    OTHER+=("${line}")    ;;
    esac
done < "${LOG_TMP}"

# Emit markdown
printf '# v%s (%s)\n\n' "${TITLE_VERSION}" "${DATE}"
printf '## Summary\n\n'
printf '<!-- TODO: 1–3 sentence user-facing summary. Replace before committing. -->\n\n'

emit_section() {
    local title="$1"
    shift
    local entries=("$@")
    if [[ ${#entries[@]} -eq 0 ]]; then
        return
    fi
    printf '## %s\n\n' "${title}"
    printf '%s\n' "${entries[@]}"
    printf '\n'
}

if [[ ${#BREAKING[@]} -gt 0 ]]; then
    emit_section "Breaking Changes" "${BREAKING[@]}"
fi
emit_section "Features" "${FEATURES[@]}"
emit_section "Fixes" "${FIXES[@]}"
emit_section "Docs" "${DOCS[@]}"
emit_section "Chore" "${CHORE[@]}"

if [[ ${#OTHER[@]} -gt 0 ]]; then
    emit_section "Other" "${OTHER[@]}"
fi

printf '## Upgrade Notes\n\n'
printf '<!-- TODO: migration steps from the previous version, or "No action required." -->\n\n'

# Compare URL — best-effort from `git remote get-url origin`
REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
if [[ -n "${REMOTE_URL}" ]]; then
    # Normalize git@github.com:owner/repo.git → https://github.com/owner/repo
    http_url="${REMOTE_URL}"
    http_url="${http_url%.git}"
    http_url="${http_url/git@github.com:/https://github.com/}"
    # Only emit if latest tag exists (otherwise the compare URL is useless)
    prev_tag="$(git describe --tags --abbrev=0 2>/dev/null || true)"
    if [[ -n "${prev_tag}" ]]; then
        printf '**Full Changelog**: %s/compare/%s...v%s\n' "${http_url}" "${prev_tag}" "${TITLE_VERSION}"
    fi
fi

exit 0
