#!/usr/bin/env bash
# apply-hooks.sh
# Wire a pre-commit hook that runs `./scripts/style.sh lint --modified --fix`.
# Chooses between lefthook (preferred) and husky based on what the project uses.
#
# Usage: apply-hooks.sh --target <dir> --profile-file <path>
#                       [--tool=auto|lefthook|husky|native]
#                       [--template-dir <dir>] [--dry-run] [--force]

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DEFAULT_TEMPLATE_DIR="${SCRIPT_DIR}/../references/templates"

target=""
profile_file=""
tool="auto"
template_dir="$DEFAULT_TEMPLATE_DIR"
dry_run=false
force=false

usage() {
    cat >&2 <<'EOF'
Usage: apply-hooks.sh --target <dir> --profile-file <path>
                      [--tool=auto|lefthook|husky|native]
                      [--template-dir <dir>] [--dry-run] [--force]
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)        target="$2"; shift 2 ;;
        --target=*)      target="${1#*=}"; shift ;;
        --profile-file)  profile_file="$2"; shift 2 ;;
        --profile-file=*) profile_file="${1#*=}"; shift ;;
        --tool)          tool="$2"; shift 2 ;;
        --tool=*)        tool="${1#*=}"; shift ;;
        --template-dir)  template_dir="$2"; shift 2 ;;
        --template-dir=*) template_dir="${1#*=}"; shift ;;
        --dry-run)       dry_run=true; shift ;;
        --force)         force=true; shift ;;
        -h|--help)       usage; exit 0 ;;
        *) echo "[apply-hooks] ERROR: unknown arg: $1" >&2; usage; exit 1 ;;
    esac
done

[[ -z "$target" ]]         && { echo "[apply-hooks] ERROR: --target is required" >&2; exit 1; }
[[ -z "$profile_file" ]]   && { echo "[apply-hooks] ERROR: --profile-file is required" >&2; exit 1; }
[[ ! -d "$target" ]]       && { echo "[apply-hooks] ERROR: target not a directory: $target" >&2; exit 1; }
[[ ! -f "$profile_file" ]] && { echo "[apply-hooks] ERROR: profile file missing: $profile_file" >&2; exit 1; }

target="$(cd "$target" && pwd)"

info() { echo "[apply-hooks] $*"; }
warn() { echo "[apply-hooks] WARN: $*" >&2; }

get_profile() {
    local key="$1"
    awk -F= -v k="$key" '$1 == k { print $2; found=1; exit } END { if (!found) print "" }' "$profile_file"
}

has_git="$(get_profile has_git)"
has_lefthook="$(get_profile has_lefthook)"
has_husky="$(get_profile has_husky)"

if [[ "$has_git" != "true" ]]; then
    echo "[apply-hooks] ERROR: target is not a git repository: $target" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Resolve tool
# ---------------------------------------------------------------------------
if [[ "$tool" == "auto" ]]; then
    if   [[ "$has_lefthook" == "true" ]]; then tool="lefthook"
    elif [[ "$has_husky"    == "true" ]]; then tool="husky"
    else                                        tool="lefthook"
    fi
    info "tool=auto resolved to: $tool"
fi

install_lefthook() {
    local tpl="$template_dir/lefthook.yml.tmpl"
    [[ ! -f "$tpl" ]] && { echo "[apply-hooks] ERROR: template missing: $tpl" >&2; exit 1; }

    local dest="$target/lefthook.yml"
    if [[ -f "$dest" && "$force" != "true" ]]; then
        info "lefthook.yml already exists; skipping (pass --force to overwrite)"
        return 0
    fi

    if $dry_run; then
        info "[dry-run] would write $dest"
        return 0
    fi

    cp "$tpl" "$dest"
    info "wrote $dest"
    warn "run 'lefthook install' (once) to activate git hooks"
    warn "bypass a single commit with: git commit --no-verify"
}

install_husky() {
    local tpl="$template_dir/husky-pre-commit.tmpl"
    [[ ! -f "$tpl" ]] && { echo "[apply-hooks] ERROR: template missing: $tpl" >&2; exit 1; }

    local husky_dir="$target/.husky"
    local dest="$husky_dir/pre-commit"

    if [[ -f "$dest" && "$force" != "true" ]]; then
        info ".husky/pre-commit already exists; skipping (pass --force to overwrite)"
        return 0
    fi

    if $dry_run; then
        info "[dry-run] would write $dest"
        return 0
    fi

    mkdir -p "$husky_dir"
    cp "$tpl" "$dest"
    chmod +x "$dest"
    info "wrote $dest"
    warn "ensure 'husky install' ran (usually via package.json prepare script)"
    warn "bypass a single commit with: git commit --no-verify"
}

install_native() {
    local dest="$target/.git/hooks/pre-commit"
    if [[ -f "$dest" && "$force" != "true" ]]; then
        info ".git/hooks/pre-commit already exists; skipping (pass --force to overwrite)"
        return 0
    fi

    if $dry_run; then
        info "[dry-run] would write $dest"
        return 0
    fi

    cat > "$dest" <<'EOF'
#!/usr/bin/env sh
# Managed by ycc:formatters (native install — not shared via git).
# To bypass once: git commit --no-verify
set -e
./scripts/style.sh lint --modified --fix
./scripts/style.sh format --modified
git diff --name-only --diff-filter=ACMR | xargs -r git add
EOF
    chmod +x "$dest"
    info "wrote $dest"
    warn "native hook is LOCAL ONLY — it is not shared via git. Prefer lefthook for repo-wide install."
    warn "bypass a single commit with: git commit --no-verify"
}

case "$tool" in
    lefthook) install_lefthook ;;
    husky)    install_husky ;;
    native)   install_native ;;
    *) echo "[apply-hooks] ERROR: unknown tool: $tool" >&2; exit 1 ;;
esac

exit 0
