#!/usr/bin/env bash
# apply-ci.sh
# Render lint.yml.tmpl and install it at .github/workflows/lint.yml.
# Idempotent: refuses to overwrite existing workflow unless --force.
#
# Usage: apply-ci.sh --target <dir> --profile-file <path>
#                    [--template-dir <dir>] [--dry-run] [--force]

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DEFAULT_TEMPLATE_DIR="${SCRIPT_DIR}/../references/templates"

target=""
profile_file=""
template_dir="$DEFAULT_TEMPLATE_DIR"
dry_run=false
force=false

usage() {
    cat >&2 <<'EOF'
Usage: apply-ci.sh --target <dir> --profile-file <path>
                   [--template-dir <dir>] [--dry-run] [--force]
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)         target="$2"; shift 2 ;;
        --target=*)       target="${1#*=}"; shift ;;
        --profile-file)   profile_file="$2"; shift 2 ;;
        --profile-file=*) profile_file="${1#*=}"; shift ;;
        --template-dir)   template_dir="$2"; shift 2 ;;
        --template-dir=*) template_dir="${1#*=}"; shift ;;
        --dry-run)        dry_run=true; shift ;;
        --force)          force=true; shift ;;
        -h|--help)        usage; exit 0 ;;
        *) echo "[apply-ci] ERROR: unknown arg: $1" >&2; usage; exit 1 ;;
    esac
done

[[ -z "$target" ]]         && { echo "[apply-ci] ERROR: --target is required" >&2; exit 1; }
[[ -z "$profile_file" ]]   && { echo "[apply-ci] ERROR: --profile-file is required" >&2; exit 1; }
[[ ! -d "$target" ]]       && { echo "[apply-ci] ERROR: target not a directory: $target" >&2; exit 1; }
[[ ! -f "$profile_file" ]] && { echo "[apply-ci] ERROR: profile file missing: $profile_file" >&2; exit 1; }

target="$(cd "$target" && pwd)"
tpl="$template_dir/lint.yml.tmpl"
[[ ! -f "$tpl" ]] && { echo "[apply-ci] ERROR: template missing: $tpl" >&2; exit 1; }

info() { echo "[apply-ci] $*"; }

dest="$target/.github/workflows/lint.yml"
if [[ -f "$dest" && "$force" != "true" ]]; then
    info "$dest already exists; skipping (pass --force to overwrite)"
    exit 0
fi

export APPLY_CI_TEMPLATE="$tpl"
export APPLY_CI_PROFILE="$profile_file"

rendered="$(python3 <<'PYEOF'
import os, re
from pathlib import Path

tpl = Path(os.environ["APPLY_CI_TEMPLATE"]).read_text(encoding="utf-8")
profile_text = Path(os.environ["APPLY_CI_PROFILE"]).read_text(encoding="utf-8")

profile = {}
for line in profile_text.splitlines():
    if "=" not in line:
        continue
    k, _, v = line.partition("=")
    profile[k.strip()] = v.strip()

flags = {
    "IF_RUST":   profile.get("detect_rust")   == "true",
    "IF_GO":     profile.get("detect_go")     == "true",
    "IF_TS":     profile.get("detect_ts")     == "true",
    "IF_PYTHON": profile.get("detect_python") == "true",
    "IF_DOCS":   profile.get("detect_docs")   == "true",
    "IF_SHELL":  profile.get("detect_shell")  == "true",
}

pat = re.compile(r"\{\{#(\w+)\}\}(.*?)\{\{/\1\}\}", re.DOTALL)
out = pat.sub(lambda m: m.group(2) if flags.get(m.group(1), False) else "", tpl)
out = re.sub(r"\n{3,}", "\n\n", out)
print(out, end="")
PYEOF
)"

if $dry_run; then
    info "[dry-run] would write $dest"
    printf '%s' "$rendered" | head -20
    exit 0
fi

mkdir -p "$(dirname "$dest")"
printf '%s' "$rendered" > "$dest"
info "wrote $dest"

exit 0
