#!/usr/bin/env bash
# Tests for extract-tokens.py — category extraction + whitelist filtering.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

EXTRACTOR="${YCI_SCRIPTS_DIR}/extract-tokens.py"

_extractor_ok() {
    if [ ! -f "$EXTRACTOR" ]; then
        printf 'DIAGNOSTIC: extract-tokens.py not found at %s\n' "$EXTRACTOR" >&2
        return 1
    fi
    return 0
}

_run() {
    printf '%s' "$1" | python3 "$EXTRACTOR" 2>/dev/null
}

# ---------------------------------------------------------------------------
test_ipv4_whitelisted() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "ipv4_wl: skipped"; return 0; }
    local out
    out="$(_run '{"tool_name":"Write","tool_input":{"content":"server 127.0.0.1"}}')"
    assert_not_contains "$out" "127.0.0.1" "ipv4_wl: loopback not emitted"
}

test_ipv4_real() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "ipv4_real: skipped"; return 0; }
    local out
    out="$(_run '{"tool_name":"Write","tool_input":{"content":"host 10.2.2.2"}}')"
    assert_contains "$out" "ipv4" "ipv4_real: category emitted"
    assert_contains "$out" "10.2.2.2" "ipv4_real: token emitted"
}

test_ipv6_real() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "ipv6_real: skipped"; return 0; }
    local out
    # Use a full-form non-whitelisted IPv6 address (compressed forms like ::1 match only
    # the loopback part; full-colon-separated form is required for the regex).
    out="$(_run '{"tool_name":"Write","tool_input":{"content":"connect 2001:db9:0:1:2:3:4:5"}}')"
    assert_contains "$out" "ipv6" "ipv6_real: category emitted"
    assert_contains "$out" "2001:db9:0:1:2:3:4:5" "ipv6_real: token emitted"
}

test_ipv6_whitelisted() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "ipv6_wl: skipped"; return 0; }
    local out
    out="$(_run '{"tool_name":"Write","tool_input":{"content":"loopback ::1"}}')"
    assert_not_contains "$out" "::1" "ipv6_wl: loopback not emitted"
}

test_hostname_real() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "hostname_real: skipped"; return 0; }
    local out
    out="$(_run '{"tool_name":"Write","tool_input":{"content":"target bb01.bigbank.corp"}}')"
    assert_contains "$out" "hostname" "hostname_real: category emitted"
    assert_contains "$out" "bb01.bigbank.corp" "hostname_real: token emitted"
}

test_hostname_whitelisted() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "hostname_wl: skipped"; return 0; }
    local out
    out="$(_run '{"tool_name":"Write","tool_input":{"content":"see example.com for docs"}}')"
    assert_not_contains "$out" "example.com" "hostname_wl: example.com not emitted"
}

test_asn() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "asn: skipped"; return 0; }
    local out
    out="$(_run '{"tool_name":"Write","tool_input":{"content":"prefix from AS65001"}}')"
    assert_contains "$out" "asn" "asn: category emitted"
    assert_contains "$out" "AS65001" "asn: token emitted"
}

test_sow_ref() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "sow_ref: skipped"; return 0; }
    local out
    out="$(_run '{"tool_name":"Write","tool_input":{"content":"per SOW-1234 this is done"}}')"
    assert_contains "$out" "sow-ref" "sow_ref: category emitted"
    assert_contains "$out" "SOW-1234" "sow_ref: token emitted"
}

test_credential_ref() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "cred_ref: skipped"; return 0; }
    local out
    out="$(_run '{"tool_name":"Write","tool_input":{"content":"password vault:prod/db/password"}}')"
    assert_contains "$out" "credential-ref" "cred_ref: category emitted"
    assert_contains "$out" "vault:prod/db/password" "cred_ref: token emitted"
}

test_content_cap() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "content_cap: skipped"; return 0; }
    # Build content > 1 MiB
    local json
    json="$(python3 -c "
import json
payload = {'tool_name': 'Write', 'tool_input': {'content': 'a' * 1100000}}
print(json.dumps(payload))
")"
    local stderr_out
    stderr_out="$(printf '%s' "$json" | python3 "$EXTRACTOR" 2>&1 1>/dev/null)"
    assert_contains "$stderr_out" "truncated:tokens" "content_cap: truncation warning emitted"
}

test_invalid_json() {
    local _sb="$1"
    _extractor_ok || { _yci_test_report PASS "tokens_invalid_json: skipped"; return 0; }
    local stderr_out rc
    stderr_out="$(printf 'not json' | python3 "$EXTRACTOR" 2>&1 1>/dev/null)"; rc=$?
    assert_contains "$stderr_out" "truncated:tokens:invalid-json" "tokens_invalid_json: marker on stderr"
    assert_exit 0 "$rc" "tokens_invalid_json: exits 0"
}

# ---------------------------------------------------------------------------
with_sandbox test_ipv4_whitelisted
with_sandbox test_ipv4_real
with_sandbox test_ipv6_real
with_sandbox test_ipv6_whitelisted
with_sandbox test_hostname_real
with_sandbox test_hostname_whitelisted
with_sandbox test_asn
with_sandbox test_sow_ref
with_sandbox test_credential_ref
with_sandbox test_content_cap
with_sandbox test_invalid_json

yci_test_summary
