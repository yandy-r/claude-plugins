#!/usr/bin/env bash
# ================================================================
# Formatter Config Initializer
# ================================================================
# Initializes formatter and linter configuration files in a target project:
# - Docs: .markdownlint.json, .markdownlintignore, .prettierrc, .prettierignore
# - Python: pyproject.toml with Ruff + Black config
# - Go: .golangci.yml via go-tools.sh --generate

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

success() {
  echo -e "${BLUE}[SUCCESS]${NC} $*"
}

usage() {
  cat <<'EOF'
Usage:
  init-formatters.sh [options] [target-directory]

Options:
  --docs               Initialize markdownlint and Prettier config files
  --md                 Initialize markdownlint config files
  --prettier           Initialize Prettier config files
  --python             Initialize Python Ruff + Black config via pyproject.toml
  --go                 Initialize .golangci.yml via go-tools.sh --generate
  --all                Initialize docs, Python, and Go config files
  -t, --target <dir>   Target directory (default: current directory)
  --force              Overwrite existing files without prompt
  -y, --yes            Non-interactive mode (skip overwrite prompts, keep existing files)
  --dry-run            Show actions without writing files
  -h, --help           Show this help

Examples:
  init-formatters.sh --all ~/projects/my-app
  init-formatters.sh --docs --python --target ~/projects/my-app
  init-formatters.sh --go --dry-run .
EOF
}

resolve_script_dir() {
  local source="${BASH_SOURCE[0]}"
  while [[ -L "${source}" ]]; do
    local dir
    dir="$(cd -P "$(dirname "${source}")" && pwd)"
    source="$(readlink "${source}")"
    [[ "${source}" != /* ]] && source="${dir}/${source}"
  done
  cd -P "$(dirname "${source}")" && pwd
}

resolve_dotfiles_root() {
  local script_dir="$1"
  local explicit_root="${DOTFILES_ROOT:-}"
  local -a candidates=()

  if [[ -n "${explicit_root}" ]]; then
    candidates+=("${explicit_root}")
  fi

  candidates+=(
    "${script_dir}/.."
    "${HOME}/.config/dotfiles"
    "${PWD}"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "${candidate}/.markdownlint.json" ]] &&
      [[ -f "${candidate}/.markdownlintignore" ]] &&
      [[ -f "${candidate}/.prettierrc" ]] &&
      [[ -f "${candidate}/.prettierignore" ]]; then
      cd "${candidate}" && pwd
      return 0
    fi
  done

  return 1
}

SCRIPT_DIR="$(resolve_script_dir)"
if ! DOTFILES_ROOT="$(resolve_dotfiles_root "${SCRIPT_DIR}")"; then
  error "Could not locate dotfiles root containing formatter templates."
  error "Set DOTFILES_ROOT to your dotfiles path and retry."
  exit 1
fi

INIT_DOCS=false
INIT_MD=false
INIT_PRETTIER=false
INIT_PYTHON=false
INIT_GO=false
FORCE=false
DRY_RUN=false
ASSUME_YES=false
TARGET_DIR="${PWD}"
TARGET_SET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --docs)
      INIT_DOCS=true
      INIT_MD=true
      INIT_PRETTIER=true
      shift
      ;;
    --md)
      INIT_MD=true
      shift
      ;;
    --prettier)
      INIT_PRETTIER=true
      shift
      ;;
    --python)
      INIT_PYTHON=true
      shift
      ;;
    --go)
      INIT_GO=true
      shift
      ;;
    --all)
      INIT_DOCS=true
      INIT_MD=true
      INIT_PRETTIER=true
      INIT_PYTHON=true
      INIT_GO=true
      shift
      ;;
    -t|--target)
      if [[ $# -lt 2 ]]; then
        error "Missing value for $1"
        usage
        exit 1
      fi
      TARGET_DIR="$2"
      TARGET_SET=true
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    -y|--yes)
      ASSUME_YES=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      error "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [[ "${TARGET_SET}" == true ]]; then
        error "Target directory already set. Unexpected argument: $1"
        usage
        exit 1
      fi
      TARGET_DIR="$1"
      TARGET_SET=true
      shift
      ;;
  esac
done

if [[ "${INIT_DOCS}" == true ]]; then
  INIT_MD=true
  INIT_PRETTIER=true
fi

if [[ "${INIT_MD}" == false && "${INIT_PRETTIER}" == false && "${INIT_PYTHON}" == false && "${INIT_GO}" == false ]]; then
  info "No formatter selection provided. Defaulting to --all."
  INIT_DOCS=true
  INIT_MD=true
  INIT_PRETTIER=true
  INIT_PYTHON=true
  INIT_GO=true
fi

if [[ ! -d "${TARGET_DIR}" ]]; then
  error "Target directory does not exist: ${TARGET_DIR}"
  exit 1
fi

TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"

created=0
overwritten=0
skipped=0
failed=0

copy_template() {
  local src_rel="$1"
  local dest_rel="$2"
  local src="${DOTFILES_ROOT}/${src_rel}"
  local dest="${TARGET_DIR}/${dest_rel}"
  local action="create"

  if [[ ! -f "${src}" ]]; then
    error "Template not found: ${src}"
    ((failed++)) || true
    return
  fi

  if [[ -e "${dest}" ]]; then
    action="overwrite"
    if [[ "${FORCE}" != true ]]; then
      if [[ "${ASSUME_YES}" == true ]]; then
        warn "Exists, keeping current file: ${dest}"
        ((skipped++)) || true
        return
      fi

      read -r -p "Overwrite existing file ${dest}? [y/N] " response
      if [[ ! "${response}" =~ ^[Yy]$ ]]; then
        info "Keeping existing file: ${dest}"
        ((skipped++)) || true
        return
      fi
    fi
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    info "[dry-run] Would ${action}: ${dest}"
    if [[ "${action}" == "overwrite" ]]; then
      ((overwritten++)) || true
    else
      ((created++)) || true
    fi
    return
  fi

  cp "${src}" "${dest}"
  if [[ "${action}" == "overwrite" ]]; then
    success "Overwrote: ${dest}"
    ((overwritten++)) || true
  else
    success "Created: ${dest}"
    ((created++)) || true
  fi
}

generate_go_config() {
  local dest="${TARGET_DIR}/.golangci.yml"
  local action="create"

  if [[ -e "${dest}" ]]; then
    action="overwrite"
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    info "[dry-run] Would ${action}: ${dest}"
    if [[ "${action}" == "overwrite" ]]; then
      ((overwritten++)) || true
    else
      ((created++)) || true
    fi
    return
  fi

  if GO_TOOLS_FORCE="${FORCE}" GO_TOOLS_ASSUME_YES="${ASSUME_YES}" GO_TOOLS_DRY_RUN=false \
    "${DOTFILES_ROOT}/bin/go-tools.sh" "${TARGET_DIR}" --generate; then
    if [[ "${action}" == "overwrite" ]]; then
      ((overwritten++)) || true
    else
      ((created++)) || true
    fi
  else
    ((failed++)) || true
  fi
}

init_python_config() {
  local dest="${TARGET_DIR}/pyproject.toml"

  if [[ -e "${dest}" ]]; then
    error "Refusing to overwrite existing Python project file: ${dest}"
    error "Merge the Ruff/Black settings from bin/templates/python-pyproject.toml manually."
    ((failed++)) || true
    return
  fi

  copy_template "bin/templates/python-pyproject.toml" "pyproject.toml"
}

info "Target directory: ${TARGET_DIR}"
info "Selected initializers:"
[[ "${INIT_MD}" == true ]] && info "  - markdownlint"
[[ "${INIT_PRETTIER}" == true ]] && info "  - prettier"
[[ "${INIT_PYTHON}" == true ]] && info "  - python"
[[ "${INIT_GO}" == true ]] && info "  - go"
[[ "${DRY_RUN}" == true ]] && warn "Dry run mode enabled; no files will be written"

if [[ "${INIT_MD}" == true ]]; then
  copy_template ".markdownlint.json" ".markdownlint.json"
  copy_template ".markdownlintignore" ".markdownlintignore"
fi

if [[ "${INIT_PRETTIER}" == true ]]; then
  copy_template ".prettierrc" ".prettierrc"
  copy_template ".prettierignore" ".prettierignore"
fi

if [[ "${INIT_PYTHON}" == true ]]; then
  init_python_config
fi

if [[ "${INIT_GO}" == true ]]; then
  generate_go_config
fi

echo
info "Summary:"
echo "  Created: ${created}"
echo "  Overwritten: ${overwritten}"
echo "  Skipped: ${skipped}"
echo "  Failed: ${failed}"

if [[ "${failed}" -gt 0 ]]; then
  exit 1
fi

success "Formatter initialization complete."
