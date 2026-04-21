#!/usr/bin/env bash
# yci — customer-isolation detection library.
#
# Sourceable. Exposes:
#   isolation_check_payload [--payload-file <path>]
#     Reads PreToolUse JSON from stdin (or --payload-file) and prints a single
#     decision JSON on stdout: {"decision":"allow"} or
#     {"decision":"deny","collision":{...}}.
#
# Inputs (environment):
#   YCI_ACTIVE_CUSTOMER        — required; the active customer id
#   YCI_DATA_ROOT_RESOLVED     — required; canonicalized yci data root
#
# Exit: 0 on decision emitted (allow OR deny); non-zero on internal error only.
#
# No `set -euo pipefail` — sourceable library.

# ---------------------------------------------------------------------------
# Resolve script directory at source time (hermetic).
# ---------------------------------------------------------------------------

_CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
_CI_SCRIPTS="${_CI_DIR}/scripts"

# Source path and allowlist helpers. Track missing-helpers at source time so
# isolation_check_payload can emit a fail-closed deny rather than silently
# falling through to allow when a helper function would be undefined at call
# time.
_CI_BROKEN=""

if [ ! -f "${_CI_SCRIPTS}/path-match.sh" ]; then
    printf 'yci guard: path-match.sh not found at %s\n' "${_CI_SCRIPTS}/path-match.sh" >&2
    _CI_BROKEN="path-match.sh missing"
else
    # shellcheck source=/dev/null
    source "${_CI_SCRIPTS}/path-match.sh"
fi

if [ ! -f "${_CI_SCRIPTS}/allowlist.sh" ]; then
    printf 'yci guard: allowlist.sh not found at %s\n' "${_CI_SCRIPTS}/allowlist.sh" >&2
    _CI_BROKEN="${_CI_BROKEN:+${_CI_BROKEN}; }allowlist.sh missing"
else
    # shellcheck source=/dev/null
    source "${_CI_SCRIPTS}/allowlist.sh"
fi

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# _ci_json_escape STRING
# Escapes backslash, double-quote, and control characters for embedding in JSON.
_ci_json_escape() {
    python3 -c 'import json,sys; print(json.dumps(sys.argv[1])[1:-1])' "$1"
}

# _ci_jq BUNDLE_JSON KEY_PATH
# Extracts a list at KEY_PATH from a JSON bundle and prints one item per line.
# KEY_PATH examples: '.artifact_roots', '.tokens.ipv4', '.tokens.hostname'
_ci_jq() {
    python3 -c '
import json, sys
data = json.loads(sys.argv[1])
path = sys.argv[2].strip(".").split(".")
cur = data
for p in path:
    if isinstance(cur, dict) and p in cur:
        cur = cur[p]
    else:
        cur = []
        break
if isinstance(cur, list):
    print("\n".join(str(x) for x in cur))
' "$1" "$2"
}

# ---------------------------------------------------------------------------
# Public function
# ---------------------------------------------------------------------------

# isolation_check_payload [--payload-file <path>]
#
# Reads the PreToolUse JSON payload and emits a single-line decision on stdout.
# Returns:
#   0  — decision emitted (allow or deny)
#   1  — internal error (missing required env vars)
isolation_check_payload() {
    # -----------------------------------------------------------------------
    # 0. Fail-closed if helpers were missing at source time. Without the
    #    helpers the collision loops would silently skip their checks and the
    #    function would emit {"decision":"allow"} — a real safety hole.
    # -----------------------------------------------------------------------
    if [ -n "${_CI_BROKEN:-}" ]; then
        printf 'yci guard: detection library broken at source time (%s); fail-closed deny emitted.\n' \
            "$_CI_BROKEN" >&2
        printf '{"decision":"deny","collision":{"active":"?","foreign":"?","kind":"internal-error","evidence":"detect.sh helpers missing: %s"}}\n' \
            "$_CI_BROKEN"
        return 0
    fi

    # -----------------------------------------------------------------------
    # 1. Guard env
    # -----------------------------------------------------------------------
    if [ -z "${YCI_ACTIVE_CUSTOMER:-}" ] || [ -z "${YCI_DATA_ROOT_RESOLVED:-}" ]; then
        printf 'yci guard: isolation_check_payload called without YCI_ACTIVE_CUSTOMER or YCI_DATA_ROOT_RESOLVED\n' >&2
        return 1
    fi

    # -----------------------------------------------------------------------
    # 2. Read payload
    # -----------------------------------------------------------------------
    local payload
    if [ "${1:-}" = "--payload-file" ]; then
        local payload_file="${2:-}"
        if [ -z "$payload_file" ]; then
            printf 'yci guard: --payload-file requires a path argument\n' >&2
            return 1
        fi
        if [ ! -r "$payload_file" ]; then
            printf 'yci guard: payload file not readable: %s\n' "$payload_file" >&2
            return 1
        fi
        payload="$(< "$payload_file")"
    else
        payload="$(cat)"
    fi

    # -----------------------------------------------------------------------
    # 3. Enumerate foreign customers
    # -----------------------------------------------------------------------
    local profiles_dir="${YCI_DATA_ROOT_RESOLVED}/profiles"
    local -a foreigns=()
    if [ -d "$profiles_dir" ]; then
        while IFS= read -r f; do
            local base
            base="$(basename "$f" .yaml)"
            # Skip underscore-prefixed (template-like files)
            case "$base" in _*) continue ;; esac
            # Skip allowlist sidecars (<customer>.allowlist.yaml)
            case "$base" in *.allowlist) continue ;; esac
            [ "$base" != "$YCI_ACTIVE_CUSTOMER" ] && foreigns+=("$base")
        done < <(find "$profiles_dir" -maxdepth 1 -name '*.yaml' 2>/dev/null)
    fi

    # Zero foreigns → allow short-circuit
    if [ "${#foreigns[@]}" -eq 0 ]; then
        printf '{"decision":"allow"}\n'
        return 0
    fi

    # -----------------------------------------------------------------------
    # 4. Extract candidates
    # -----------------------------------------------------------------------
    local cand_paths cand_tokens
    cand_paths="$(printf '%s' "$payload" | python3 "${_CI_SCRIPTS}/extract-paths.py")"
    cand_tokens="$(printf '%s' "$payload" | python3 "${_CI_SCRIPTS}/extract-tokens.py")"

    # -----------------------------------------------------------------------
    # 5. Load allowlist for the active customer
    # -----------------------------------------------------------------------
    if ! allowlist_load "$YCI_DATA_ROOT_RESOLVED" "$YCI_ACTIVE_CUSTOMER"; then
        printf 'yci guard: allowlist load failed; treating as empty allowlist.\n' >&2
        # Arrays populated in allowlist.sh and consumed via allowlist_contains
        # (cross-file usage is invisible to the linter).
        # shellcheck disable=SC2034
        ALLOWLIST_PATHS=()
        # shellcheck disable=SC2034
        ALLOWLIST_TOKENS=()
    fi

    # -----------------------------------------------------------------------
    # 6. Iterate foreign customers
    # -----------------------------------------------------------------------
    local fc
    for fc in "${foreigns[@]}"; do
        local bundle_json bundle_rc
        bundle_json="$(python3 "${_CI_SCRIPTS}/inventory-fingerprint.py" \
            --data-root "$YCI_DATA_ROOT_RESOLVED" --customer "$fc" 2>/dev/null)"
        bundle_rc=$?
        if [ "$bundle_rc" -ne 0 ]; then
            printf 'yci guard: failed to build fingerprint bundle for foreign customer %s (rc=%d); skipping.\n' \
                "$fc" "$bundle_rc" >&2
            continue
        fi

        # -------------------------------------------------------------------
        # 6a. Path collision check
        # -------------------------------------------------------------------
        local fc_roots
        fc_roots="$(_ci_jq "$bundle_json" '.artifact_roots')"

        while IFS= read -r cand_path; do
            [ -z "$cand_path" ] && continue
            while IFS= read -r froot; do
                [ -z "$froot" ] && continue
                if path_is_under "$cand_path" "$froot"; then
                    if ! allowlist_contains path "$cand_path"; then
                        local resolved
                        resolved="$(path_canonicalize "$cand_path")"
                        printf '{"decision":"deny","collision":{"active":"%s","foreign":"%s","kind":"path","evidence":"%s","resolved":"%s"}}\n' \
                            "$YCI_ACTIVE_CUSTOMER" \
                            "$fc" \
                            "$(_ci_json_escape "$cand_path")" \
                            "$(_ci_json_escape "$resolved")"
                        return 0
                    fi
                fi
            done <<< "$fc_roots"
        done <<< "$cand_paths"

        # -------------------------------------------------------------------
        # 6b. Token collision check
        # -------------------------------------------------------------------
        while IFS=$'\t' read -r cat tok; do
            [ -z "$cat" ] && continue
            local fc_tokens
            fc_tokens="$(_ci_jq "$bundle_json" ".tokens.${cat}")"
            while IFS= read -r ftok; do
                [ -z "$ftok" ] && continue
                if [ "$tok" = "$ftok" ]; then
                    if ! allowlist_contains "$cat" "$tok"; then
                        printf '{"decision":"deny","collision":{"active":"%s","foreign":"%s","kind":"token","category":"%s","evidence":"%s"}}\n' \
                            "$YCI_ACTIVE_CUSTOMER" \
                            "$fc" \
                            "$cat" \
                            "$(_ci_json_escape "$tok")"
                        return 0
                    fi
                fi
            done <<< "$fc_tokens"
        done <<< "$cand_tokens"
    done

    # -----------------------------------------------------------------------
    # 7. No collision
    # -----------------------------------------------------------------------
    printf '{"decision":"allow"}\n'
    return 0
}
