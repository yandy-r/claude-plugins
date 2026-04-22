#!/usr/bin/env bash
set -euo pipefail

artifact=""
signing_json=""
output=""
metadata=""

usage() {
    cat >&2 <<'EOF'
Usage: sign-bundle.sh --artifact <path> --signing-json <path> --output <sig-path> --metadata <json-path>
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --artifact) artifact="${2:-}"; shift 2 ;;
        --signing-json) signing_json="${2:-}"; shift 2 ;;
        --output) output="${2:-}"; shift 2 ;;
        --metadata) metadata="${2:-}"; shift 2 ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done

[[ -n "${artifact}" && -n "${signing_json}" && -n "${output}" && -n "${metadata}" ]] || usage
[[ -f "${artifact}" && -f "${signing_json}" ]] || usage

method="$(python3 -c 'import json,sys; print((json.load(open(sys.argv[1])) or {}).get("method",""))' "${signing_json}")"
key_ref="$(python3 -c 'import json,sys; print((json.load(open(sys.argv[1])) or {}).get("key_ref",""))' "${signing_json}")"
identity="$(python3 -c 'import json,sys; print((json.load(open(sys.argv[1])) or {}).get("identity",""))' "${signing_json}")"
pubkey="$(python3 -c 'import json,sys; print((json.load(open(sys.argv[1])) or {}).get("pubkey",""))' "${signing_json}")"

if [[ -z "${method}" || -z "${key_ref}" ]]; then
    printf '[eb-signing-unavailable] Missing compliance.signing method or key_ref\n' >&2
    exit 7
fi

case "${method}" in
    minisign)
        command -v minisign >/dev/null 2>&1 || { printf '[eb-signing-unavailable] minisign not installed\n' >&2; exit 7; }
        minisign -S -s "${key_ref}" -m "${artifact}" -x "${output}"
        ;;
    ssh-keygen-y-sign)
        command -v ssh-keygen >/dev/null 2>&1 || { printf '[eb-signing-unavailable] ssh-keygen not installed\n' >&2; exit 7; }
        [[ -n "${identity}" ]] || { printf '[eb-signing-unavailable] ssh-keygen-y-sign requires identity\n' >&2; exit 7; }
        ssh-keygen -Y sign -f "${key_ref}" -n yci-evidence -I "${identity}" < "${artifact}" > "${output}"
        ;;
    *)
        printf '[eb-signing-unavailable] Unsupported signing method: %s\n' "${method}" >&2
        exit 7
        ;;
esac

python3 - "${metadata}" "${method}" "${key_ref}" "${identity}" "${pubkey}" "${output}" <<'PY'
import json
import sys
payload = {
    "method": sys.argv[2],
    "key_ref": sys.argv[3],
    "identity": sys.argv[4],
    "pubkey": sys.argv[5],
    "signature_path": sys.argv[6],
}
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2, sort_keys=True)
PY
