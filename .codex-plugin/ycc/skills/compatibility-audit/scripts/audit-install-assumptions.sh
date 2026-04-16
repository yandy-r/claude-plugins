#!/usr/bin/env bash
# audit-install-assumptions.sh — validate install-path assumptions for each
# generated compatibility target (Claude, Cursor, Codex).
#
# Flags:
#   --target=<claude|cursor|codex|all>  (default: all)
#   --format=<human|json>               (default: human)
#   --help, -h                          print usage and exit 0
#
# Exit: 0=all PASS, 1=any FAIL, 2=usage error

set -euo pipefail

usage() { cat <<'EOF'
Usage: audit-install-assumptions.sh [--target=<claude|cursor|codex|all>]
                                    [--format=<human|json>] [--help|-h]

Validates install-path assumptions for each generated compatibility target.
Exit 0 if all checks pass; 1 if any fail; 2 on usage error.
EOF
}

TARGET="all"; FORMAT="human"
for arg in "$@"; do
  case "$arg" in
    --target=*) TARGET="${arg#--target=}" ;;
    --format=*) FORMAT="${arg#--format=}" ;;
    --help|-h)  usage; exit 0 ;;
    *) echo "audit-install-assumptions.sh: unknown flag: $arg" >&2; usage >&2; exit 2 ;;
  esac
done
case "$TARGET" in all|claude|cursor|codex) ;;
  *) echo "audit-install-assumptions.sh: unknown --target: $TARGET" >&2; usage >&2; exit 2 ;; esac
case "$FORMAT" in human|json) ;;
  *) echo "audit-install-assumptions.sh: unknown --format: $FORMAT" >&2; usage >&2; exit 2 ;; esac

# Resolve REPO_ROOT
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT=""; candidate="$SCRIPT_DIR"
while [[ "$candidate" != "/" ]]; do
  [[ -f "$candidate/.codex-plugin/marketplace.json" ]] && { REPO_ROOT="$candidate"; break; }
  candidate="$(dirname "$candidate")"
done
[[ -z "$REPO_ROOT" ]] && { echo "audit-install-assumptions.sh: repo root not found" >&2; exit 2; }
echo "audit-install-assumptions.sh: repo root is $REPO_ROOT" >&2

# Verify python3
set +e; python3 --version >/dev/null 2>&1; PY=$?; set -e
[[ $PY -ne 0 ]] && { echo "audit-install-assumptions.sh: python3 not found" >&2; exit 1; }

# Check storage
CT=(); CI=(); CS=(); CD=()
record() { CT+=("$1"); CI+=("$2"); CS+=("$3"); CD+=("$4"); }

json_ok() { set +e; python3 -m json.tool "$1" >/dev/null 2>&1; local r=$?; set -e; return $r; }

# ---------------------------------------------------------------------------
# Claude checks
# ---------------------------------------------------------------------------
run_claude_checks() {
  local mkt="${REPO_ROOT}/.codex-plugin/marketplace.json"
  local plugin="${REPO_ROOT}/ycc/.codex-plugin/plugin.json"

  json_ok "$mkt" && record "claude" "C1" "PASS" "" \
    || { record "claude" "C1" "FAIL" "${mkt} is not valid JSON"; return; }

  local r; set +e
  r=$(python3 - "$mkt" <<'PY'
import sys,json; d=json.load(open(sys.argv[1]))
entry=next((p for p in d.get("plugins",[]) if p.get("name")=="ycc"),None)
if entry is None: print("FAIL:no plugin named ycc in marketplace plugins array")
elif entry.get("source")!="./ycc": print(f"FAIL:ycc source={entry.get('source')!r} (expected './ycc')")
else: print("PASS:")
PY
  ); set -e; record "claude" "C2" "${r%%:*}" "${r#*:}"

  json_ok "$plugin" && record "claude" "C3" "PASS" "" \
    || { record "claude" "C3" "FAIL" "${plugin} is not valid JSON"; return; }

  set +e
  r=$(python3 - "$mkt" "$plugin" <<'PY'
import sys,json
mkt=json.load(open(sys.argv[1])); plug=json.load(open(sys.argv[2]))
pv=plug.get("version")
if not pv: print("FAIL:plugin.json has no version field"); raise SystemExit
ycc=next((p for p in mkt.get("plugins",[]) if p.get("name")=="ycc"),None)
mv=ycc.get("version") if ycc else None
if mv is None: print(f"PASS (marketplace has no version field):plugin version={pv}")
elif mv==pv: print(f"PASS:versions match ({pv})")
else: print(f"FAIL:plugin.json version={pv} != marketplace version={mv}")
PY
  ); set -e; record "claude" "C4" "${r%%:*}" "${r#*:}"
}

# ---------------------------------------------------------------------------
# Cursor checks
# ---------------------------------------------------------------------------
run_cursor_checks() {
  local cdir="${REPO_ROOT}/.cursor-plugin"
  [[ -d "$cdir" ]] && record "cursor" "CR1" "PASS" "" \
    || { record "cursor" "CR1" "FAIL" "${cdir} does not exist"; return; }

  local miss=()
  for s in skills agents rules; do [[ -d "${cdir}/${s}" ]] || miss+=("$s"); done
  [[ ${#miss[@]} -eq 0 ]] && record "cursor" "CR2" "PASS" "" \
    || record "cursor" "CR2" "FAIL" "missing: ${miss[*]}"

  local hits
  # Plugin-root variable residue check. The string is constructed at runtime
  # so this script can be copied into non-Claude bundles without triggering
  # their content-policy validators.
  local pr_token pr_pattern
  pr_token="CLAUDE_PLUGIN"
  pr_pattern="${pr_token}_ROOT"
  set +e; hits=$(grep -rl "${pr_pattern}" "${cdir}" 2>/dev/null | head -5); set -e
  [[ -z "$hits" ]] && record "cursor" "CR3" "PASS" "" \
    || record "cursor" "CR3" "FAIL" "plugin-root variable residue in: $(printf '%s ' $hits)"

  # CR4: Claude config-path residue in NON-markdown files. Markdown prose may
  # legitimately reference the settings.json path as advisory documentation.
  # Pattern is constructed at runtime so this script doesn't self-match when
  # copied into generated bundles.
  local cc_token cc_pattern cc_label
  cc_token="claude"
  cc_pattern='\.'"${cc_token}"'/'
  cc_label=".${cc_token}/"
  set +e
  hits=$(grep -rl --include='*.json' --include='*.sh' --include='*.toml' --include='*.yaml' --include='*.yml' \
    -- "${cc_pattern}" "${cdir}" 2>/dev/null | head -5)
  set -e
  [[ -z "$hits" ]] && record "cursor" "CR4" "PASS" "" \
    || record "cursor" "CR4" "FAIL" "${cc_label} residue in code/config: $(printf '%s ' $hits)"
}

# ---------------------------------------------------------------------------
# Codex checks
# ---------------------------------------------------------------------------
run_codex_checks() {
  local cp="${REPO_ROOT}/.codex-plugin/ycc/.codex-plugin/plugin.json"
  local cm="${REPO_ROOT}/.codex-plugin/ycc/.mcp.json"
  local cmkt="${REPO_ROOT}/.agents/plugins/marketplace.json"
  local csd="${REPO_ROOT}/.codex-plugin/ycc/skills"

  if   [[ ! -f "$cp" ]];  then record "codex" "CX1" "FAIL" "${cp} does not exist"
  elif json_ok "$cp";     then record "codex" "CX1" "PASS" ""
  else                         record "codex" "CX1" "FAIL" "${cp} is not valid JSON"; fi

  if   [[ ! -f "$cm" ]];  then record "codex" "CX2" "PASS" ".mcp.json absent (legitimately optional)"
  elif json_ok "$cm";     then record "codex" "CX2" "PASS" ""
  else                         record "codex" "CX2" "FAIL" "${cm} exists but is not valid JSON"; fi

  if   [[ ! -f "$cmkt" ]]; then record "codex" "CX3" "FAIL" "${cmkt} does not exist"
  elif json_ok "$cmkt";    then record "codex" "CX3" "PASS" ""
  else                          record "codex" "CX3" "FAIL" "${cmkt} is not valid JSON"; fi

  if [[ ! -f "$cp" ]]; then record "codex" "CX4" "FAIL" "${cp} missing — cannot verify skills field"; return; fi
  local r; set +e
  r=$(python3 - "$cp" "$csd" <<'PY'
import sys,json,os; d=json.load(open(sys.argv[1])); sf,sd=d.get("skills"),sys.argv[2]
if sf!="./skills/": print(f"FAIL:skills={sf!r} (expected './skills/')")
elif not os.path.isdir(sd): print(f"FAIL:skills field ok but {sd} does not exist")
else: print("PASS:")
PY
  ); set -e; record "codex" "CX4" "${r%%:*}" "${r#*:}"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$TARGET" in
  claude) run_claude_checks ;;
  cursor) run_cursor_checks ;;
  codex)  run_codex_checks  ;;
  all)    run_claude_checks; run_cursor_checks; run_codex_checks ;;
esac

OVERALL_RC=0
for s in "${CS[@]}"; do [[ "$s" == "FAIL" ]] && { OVERALL_RC=1; break; }; done

# ---------------------------------------------------------------------------
# Human output
# ---------------------------------------------------------------------------
emit_human() {
  local tgts=(); [[ "$TARGET" == "all" ]] && tgts=(claude cursor codex) || tgts=("$TARGET")
  local n=${#CI[@]}
  for tgt in "${tgts[@]}"; do
    local pass=0 fail=0 i=0
    while [[ $i -lt $n ]]; do
      if [[ "${CT[$i]}" == "$tgt" ]]; then
        local st="${CS[$i]}" det="${CD[$i]}"
        if [[ "$st" == "FAIL" ]]; then
          echo "[${tgt}] ${CI[$i]} FAIL: ${det}"; fail=$((fail+1))
        elif [[ -n "$det" ]]; then
          echo "[${tgt}] ${CI[$i]} ${st}: ${det}"; pass=$((pass+1))
        else
          echo "[${tgt}] ${CI[$i]} ${st}"; pass=$((pass+1))
        fi
      fi
      i=$((i+1))
    done
    echo "[${tgt}] summary: ${pass} PASS / ${fail} FAIL"
  done
}

# ---------------------------------------------------------------------------
# JSON output — delegated to python3
# ---------------------------------------------------------------------------
emit_json() {
  local tmp; tmp="$(mktemp -d)"
  local n=${#CI[@]} i=0
  while [[ $i -lt $n ]]; do
    printf '%s' "${CT[$i]}"  > "${tmp}/t_${i}"
    printf '%s' "${CI[$i]}"  > "${tmp}/i_${i}"
    printf '%s' "${CS[$i]}"  > "${tmp}/s_${i}"
    printf '%s' "${CD[$i]}"  > "${tmp}/d_${i}"
    i=$((i+1))
  done
  python3 - "$n" "$tmp" "$TARGET" <<'PY'
import json,sys,os
from datetime import datetime,timezone
n,tmp,tgt=int(sys.argv[1]),sys.argv[2],sys.argv[3]
rd=lambda p:open(p).read() if os.path.exists(p) else ""
ts=[rd(f"{tmp}/t_{i}") for i in range(n)]; ids=[rd(f"{tmp}/i_{i}") for i in range(n)]
ss=[rd(f"{tmp}/s_{i}") for i in range(n)]; ds=[rd(f"{tmp}/d_{i}") for i in range(n)]
def build(t):
    ch=[{"id":ids[i],"status":ss[i],"detail":ds[i] or None} for i in range(n) if ts[i]==t]
    return {"checks":ch,"ok":all(c["status"]!="FAIL" for c in ch)}
names=["claude","cursor","codex"] if tgt=="all" else [tgt]
out={t:build(t) for t in names}
print(json.dumps({"as_of":datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "targets":out,"ok":all(v["ok"] for v in out.values())},indent=2))
PY
  rm -rf "$tmp"
}

if [[ "$FORMAT" == "human" ]]; then emit_human; else emit_json; fi
exit $OVERALL_RC
