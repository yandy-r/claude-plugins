#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
  SCRIPT_BASE_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" >/dev/null 2>&1 && pwd)"
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"

  if [[ "$SCRIPT_PATH" != /* ]]; then
    SCRIPT_PATH="${SCRIPT_BASE_DIR}/${SCRIPT_PATH}"
  fi
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" >/dev/null 2>&1 && pwd)"

# shellcheck source=bin/lib/modified-files.sh
source "$SCRIPT_DIR/lib/modified-files.sh"

PROJECT_ROOT="$(detect_project_root)"
readonly PROJECT_ROOT
readonly RUST_PROJECT_DIR="${RUST_PROJECT_DIR:-$PROJECT_ROOT}"
readonly TS_PROJECT_DIR="${TS_PROJECT_DIR:-$PROJECT_ROOT}"
readonly DOCS_PROJECT_DIR="${DOCS_PROJECT_DIR:-$PROJECT_ROOT}"
readonly PYTHON_PROJECT_DIR="${PYTHON_PROJECT_DIR:-$PROJECT_ROOT}"
readonly GO_PROJECT_DIR="${GO_PROJECT_DIR:-$PROJECT_ROOT}"

print_skip() {
  local section_name="$1"
  local reason="$2"
  echo "=== ${section_name} ==="
  echo "Skipping: ${reason}"
}

print_info() {
  echo "[INFO] $*"
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    return 1
  fi
}

relativize_paths() {
  local base_dir="${1%/}"
  shift

  local path_value
  for path_value in "$@"; do
    if [[ "$path_value" == "$base_dir/"* ]]; then
      printf '%s\n' "${path_value#"$base_dir"/}"
    elif [[ "$path_value" == "$base_dir" ]]; then
      printf '.\n'
    fi
  done
}

path_prefix_for() {
  local target_dir="$1"
  local prefix

  prefix="$(path_relative_to_root "$PROJECT_ROOT" "$target_dir" || true)"
  if [[ -n "$prefix" ]]; then
    printf '%s/\n' "$prefix"
  else
    printf '\n'
  fi
}

project_has_paths() {
  local base_dir="$1"
  shift

  local prefix
  prefix="$(path_prefix_for "$base_dir")"

  local first_path=''
  first_path="$(list_repo_paths "$prefix" "$@" | head -n 1 || true)"
  [[ -n "$first_path" ]]
}

directory_has_suffixes() {
  local target_dir="$1"
  shift

  local suffix
  for suffix in "$@"; do
    if find "$target_dir" -type f ! -path '*/.git/*' -name "*${suffix}" -print -quit | grep -q .; then
      return 0
    fi
  done

  return 1
}

detect_docs_project() {
  local target_dir="${1:-$DOCS_PROJECT_DIR}"

  [[ -f "$target_dir/package.json" ]] ||
    [[ -f "$target_dir/.prettierrc" ]] ||
    [[ -f "$target_dir/.prettierrc.json" ]] ||
    [[ -f "$target_dir/.prettierrc.yml" ]] ||
    [[ -f "$target_dir/.prettierrc.yaml" ]] ||
    directory_has_suffixes "$target_dir" ".md" ".mdx" ".json" ".jsonc" ".yaml" ".yml"
}

detect_python_project() {
  local target_dir="${1:-$PYTHON_PROJECT_DIR}"

  [[ -f "$target_dir/pyproject.toml" ]] ||
    [[ -f "$target_dir/requirements.txt" ]] ||
    [[ -f "$target_dir/setup.py" ]] ||
    directory_has_suffixes "$target_dir" ".py" ".pyi"
}

can_init_python_project() {
  local target_dir="${1:-$PYTHON_PROJECT_DIR}"

  [[ ! -f "$target_dir/pyproject.toml" ]] && detect_python_project "$target_dir"
}

detect_go_project() {
  local target_dir="${1:-$GO_PROJECT_DIR}"

  [[ -f "$target_dir/go.mod" ]] ||
    directory_has_suffixes "$target_dir" ".go"
}

run_rust_lint() {
  local fix="$1"
  local modified_only="$2"
  local exit_code=0

  if [[ ! -f "$RUST_PROJECT_DIR/Cargo.toml" ]]; then
    print_skip "Rust" "no Cargo.toml found in ${RUST_PROJECT_DIR}"
    return 0
  fi

  if ! require_command cargo; then
    return 1
  fi

  local rust_prefix
  rust_prefix="$(path_prefix_for "$RUST_PROJECT_DIR")"

  if (( modified_only )); then
    local -a rust_files=()
    mapfile -t rust_files < <(list_modified_repo_paths "$rust_prefix" ".rs")

    if (( ${#rust_files[@]} == 0 )); then
      echo "=== Rust ==="
      echo "No modified Rust files."
      return 0
    fi

    echo "=== Rust: rustfmt ==="
    local -a rust_relative_files=()
    mapfile -t rust_relative_files < <(relativize_paths "$RUST_PROJECT_DIR" "${rust_files[@]}")

    if (( fix )); then
      (cd "$RUST_PROJECT_DIR" && cargo fmt --all -- "${rust_relative_files[@]}") || exit_code=1
    else
      (cd "$RUST_PROJECT_DIR" && cargo fmt --all -- --check "${rust_relative_files[@]}") || exit_code=1
    fi

    echo "=== Rust: clippy (workspace scope) ==="
    if (( fix )); then
      (cd "$RUST_PROJECT_DIR" && cargo clippy --all-targets --fix --allow-dirty -- -D warnings) || exit_code=1
    else
      (cd "$RUST_PROJECT_DIR" && cargo clippy --all-targets -- -D warnings) || exit_code=1
    fi

    return "$exit_code"
  fi

  echo "=== Rust: rustfmt ==="
  if (( fix )); then
    (cd "$RUST_PROJECT_DIR" && cargo fmt --all) || exit_code=1
  else
    (cd "$RUST_PROJECT_DIR" && cargo fmt --all -- --check) || exit_code=1
  fi

  echo "=== Rust: clippy ==="
  if (( fix )); then
    (cd "$RUST_PROJECT_DIR" && cargo clippy --all-targets --fix --allow-dirty -- -D warnings) || exit_code=1
  else
    (cd "$RUST_PROJECT_DIR" && cargo clippy --all-targets -- -D warnings) || exit_code=1
  fi

  return "$exit_code"
}

run_ts_lint() {
  local fix="$1"
  local modified_only="$2"
  local exit_code=0

  if [[ ! -f "$TS_PROJECT_DIR/package.json" ]]; then
    print_skip "TypeScript" "no package.json found in ${TS_PROJECT_DIR}"
    return 0
  fi

  if ! require_command npx; then
    return 1
  fi

  local ts_prefix
  ts_prefix="$(path_prefix_for "$TS_PROJECT_DIR")"

  if (( modified_only )); then
    local -a ts_biome_files=()
    local -a ts_typecheck_files=()
    mapfile -t ts_biome_files < <(list_modified_repo_paths "$ts_prefix" \
      ".ts" ".tsx" ".js" ".jsx" ".mjs" ".cjs" ".mts" ".cts" ".css")
    mapfile -t ts_typecheck_files < <(list_modified_repo_paths "$ts_prefix" \
      ".ts" ".tsx" ".mts" ".cts")

    if (( ${#ts_biome_files[@]} == 0 )); then
      echo "=== TypeScript ==="
      echo "No modified frontend source files."
    else
      echo "=== TypeScript: biome ==="
      local -a ts_relative_biome_files=()
      mapfile -t ts_relative_biome_files < <(relativize_paths "$TS_PROJECT_DIR" "${ts_biome_files[@]}")

      if (( fix )); then
        (cd "$TS_PROJECT_DIR" && npx @biomejs/biome check --fix "${ts_relative_biome_files[@]}") || exit_code=1
      else
        (cd "$TS_PROJECT_DIR" && npx @biomejs/biome ci "${ts_relative_biome_files[@]}") || exit_code=1
      fi
    fi

    if (( ${#ts_typecheck_files[@]} > 0 )); then
      if compgen -G "$TS_PROJECT_DIR/tsconfig*.json" >/dev/null; then
        echo "=== TypeScript: tsc (project scope) ==="
        (cd "$TS_PROJECT_DIR" && npx tsc --noEmit) || exit_code=1
      else
        print_skip "TypeScript: tsc" "no tsconfig*.json found in ${TS_PROJECT_DIR}"
      fi
    fi

    return "$exit_code"
  fi

  echo "=== TypeScript: biome ==="
  (cd "$TS_PROJECT_DIR" && npx @biomejs/biome ci .) || exit_code=1

  if compgen -G "$TS_PROJECT_DIR/tsconfig*.json" >/dev/null; then
    echo "=== TypeScript: tsc ==="
    (cd "$TS_PROJECT_DIR" && npx tsc --noEmit) || exit_code=1
  else
    print_skip "TypeScript: tsc" "no tsconfig*.json found in ${TS_PROJECT_DIR}"
  fi

  return "$exit_code"
}

run_shell_lint() {
  local modified_only="$1"

  if ! require_command shellcheck; then
    return 1
  fi

  local -a shell_files=()
  if (( modified_only )); then
    mapfile -t shell_files < <(list_modified_repo_paths "" ".sh")
    if (( ${#shell_files[@]} == 0 )); then
      echo "=== Shell ==="
      echo "No modified shell scripts."
      return 0
    fi
  else
    mapfile -t shell_files < <(list_repo_paths "" ".sh")
    if (( ${#shell_files[@]} == 0 )); then
      echo "=== Shell ==="
      echo "No shell scripts found."
      return 0
    fi
  fi

  echo "=== Shell: shellcheck ==="
  shellcheck --severity=warning "${shell_files[@]}"
}

run_python_lint() {
  local fix="$1"
  local modified_only="$2"
  local exit_code=0

  if ! detect_python_project; then
    print_skip "Python" "no Python files or config found in ${PYTHON_PROJECT_DIR}"
    return 0
  fi

  if ! require_command ruff; then
    return 1
  fi
  if ! require_command black; then
    return 1
  fi

  local python_prefix
  python_prefix="$(path_prefix_for "$PYTHON_PROJECT_DIR")"

  if (( modified_only )); then
    local -a python_files=()
    mapfile -t python_files < <(list_modified_repo_paths "$python_prefix" ".py" ".pyi")

    if (( ${#python_files[@]} == 0 )); then
      echo "=== Python ==="
      echo "No modified Python files."
      return 0
    fi

    echo "=== Python: ruff ==="
    local -a python_relative_files=()
    mapfile -t python_relative_files < <(relativize_paths "$PYTHON_PROJECT_DIR" "${python_files[@]}")
    if (( fix )); then
      (cd "$PYTHON_PROJECT_DIR" && ruff check --fix "${python_relative_files[@]}") || exit_code=1
      (cd "$PYTHON_PROJECT_DIR" && black "${python_relative_files[@]}") || exit_code=1
    else
      (cd "$PYTHON_PROJECT_DIR" && ruff check "${python_relative_files[@]}") || exit_code=1
      echo "=== Python: black ==="
      (cd "$PYTHON_PROJECT_DIR" && black --check "${python_relative_files[@]}") || exit_code=1
    fi

    return "$exit_code"
  fi

  echo "=== Python: ruff ==="
  if (( fix )); then
    (cd "$PYTHON_PROJECT_DIR" && ruff check --fix .) || exit_code=1
    echo "=== Python: black ==="
    (cd "$PYTHON_PROJECT_DIR" && black .) || exit_code=1
  else
    (cd "$PYTHON_PROJECT_DIR" && ruff check .) || exit_code=1
    echo "=== Python: black ==="
    (cd "$PYTHON_PROJECT_DIR" && black --check .) || exit_code=1
  fi

  return "$exit_code"
}

run_go_lint() {
  local fix="$1"
  local modified_only="$2"

  if ! detect_go_project; then
    print_skip "Go" "no Go files or module found in ${GO_PROJECT_DIR}"
    return 0
  fi

  if ! require_command golangci-lint; then
    return 1
  fi

  if (( modified_only )); then
    local go_prefix
    go_prefix="$(path_prefix_for "$GO_PROJECT_DIR")"
    local -a go_files=()
    mapfile -t go_files < <(list_modified_repo_paths "$go_prefix" ".go")

    if (( ${#go_files[@]} == 0 )); then
      echo "=== Go ==="
      echo "No modified Go files."
      return 0
    fi
  fi

  echo "=== Go: golangci-lint ==="
  if (( fix )); then
    (cd "$GO_PROJECT_DIR" && golangci-lint run --fix ./...)
  else
    (cd "$GO_PROJECT_DIR" && golangci-lint run ./...)
  fi
}

run_rust_format() {
  local modified_only="$1"

  if [[ ! -f "$RUST_PROJECT_DIR/Cargo.toml" ]]; then
    print_skip "Rust" "no Cargo.toml found in ${RUST_PROJECT_DIR}"
    return 0
  fi

  if ! require_command cargo; then
    return 1
  fi

  local rust_prefix
  rust_prefix="$(path_prefix_for "$RUST_PROJECT_DIR")"

  if (( modified_only )); then
    local -a rust_files=()
    mapfile -t rust_files < <(list_modified_repo_paths "$rust_prefix" ".rs")

    if (( ${#rust_files[@]} == 0 )); then
      echo "=== Rust ==="
      echo "No modified Rust files."
      return 0
    fi

    echo "=== Rust: rustfmt ==="
    local -a rust_relative_files=()
    mapfile -t rust_relative_files < <(relativize_paths "$RUST_PROJECT_DIR" "${rust_files[@]}")
    (cd "$RUST_PROJECT_DIR" && cargo fmt --all -- "${rust_relative_files[@]}")
    return 0
  fi

  echo "=== Rust: rustfmt ==="
  (cd "$RUST_PROJECT_DIR" && cargo fmt --all)
}

run_ts_format() {
  local modified_only="$1"

  if [[ ! -f "$TS_PROJECT_DIR/package.json" ]]; then
    print_skip "TypeScript/JavaScript" "no package.json found in ${TS_PROJECT_DIR}"
    return 0
  fi

  if ! require_command npx; then
    return 1
  fi

  local ts_prefix
  ts_prefix="$(path_prefix_for "$TS_PROJECT_DIR")"

  if (( modified_only )); then
    local -a ts_files=()
    mapfile -t ts_files < <(list_modified_repo_paths "$ts_prefix" \
      ".ts" ".tsx" ".js" ".jsx" ".mjs" ".cjs" ".mts" ".cts" ".css")

    if (( ${#ts_files[@]} == 0 )); then
      echo "=== TypeScript/JavaScript ==="
      echo "No modified frontend source files."
      return 0
    fi

    echo "=== TypeScript/JavaScript: biome ==="
    local -a ts_relative_files=()
    mapfile -t ts_relative_files < <(relativize_paths "$TS_PROJECT_DIR" "${ts_files[@]}")
    (cd "$TS_PROJECT_DIR" && npx @biomejs/biome format --write "${ts_relative_files[@]}")
    (cd "$TS_PROJECT_DIR" && npx @biomejs/biome check --fix "${ts_relative_files[@]}")
    return 0
  fi

  echo "=== TypeScript/JavaScript: biome ==="
  (cd "$TS_PROJECT_DIR" && npx @biomejs/biome format --write .)
  (cd "$TS_PROJECT_DIR" && npx @biomejs/biome check --fix .)
}

run_docs_format() {
  local modified_only="$1"

  if ! detect_docs_project; then
    print_skip "Markdown/JSON/YAML" "no package.json, prettier config, or docs files found in ${DOCS_PROJECT_DIR}"
    return 0
  fi

  if ! require_command npx; then
    return 1
  fi

  local docs_prefix
  docs_prefix="$(path_prefix_for "$DOCS_PROJECT_DIR")"

  local -a prettier_args=()
  if [[ -f "$DOCS_PROJECT_DIR/.prettierignore" ]]; then
    prettier_args+=(--ignore-path "$DOCS_PROJECT_DIR/.prettierignore")
  fi
  if [[ -f "$DOCS_PROJECT_DIR/.prettierrc" ]]; then
    prettier_args+=(--config "$DOCS_PROJECT_DIR/.prettierrc")
  fi

  local -a docs_files=()
  if (( modified_only )); then
    mapfile -t docs_files < <(list_modified_repo_paths "$docs_prefix" ".md" ".mdx" ".json" ".jsonc" ".yaml" ".yml")
    if (( ${#docs_files[@]} == 0 )); then
      echo "=== Markdown/JSON/YAML ==="
      echo "No modified Markdown, JSON, or YAML files."
      return 0
    fi
  else
    mapfile -t docs_files < <(list_repo_paths "$docs_prefix" ".md" ".mdx" ".json" ".jsonc" ".yaml" ".yml")
    if (( ${#docs_files[@]} == 0 )); then
      echo "=== Markdown/JSON/YAML ==="
      echo "No Markdown, JSON, or YAML files found."
      return 0
    fi
  fi

  echo "=== Markdown/JSON/YAML: prettier ==="
  local -a docs_relative_files=()
  mapfile -t docs_relative_files < <(relativize_paths "$DOCS_PROJECT_DIR" "${docs_files[@]}")
  (cd "$DOCS_PROJECT_DIR" && npx prettier --write "${docs_relative_files[@]}" "${prettier_args[@]}")
}

run_python_format() {
  local modified_only="$1"

  if ! detect_python_project; then
    print_skip "Python" "no Python files or config found in ${PYTHON_PROJECT_DIR}"
    return 0
  fi

  if ! require_command black; then
    return 1
  fi

  local python_prefix
  python_prefix="$(path_prefix_for "$PYTHON_PROJECT_DIR")"

  if (( modified_only )); then
    local -a python_files=()
    mapfile -t python_files < <(list_modified_repo_paths "$python_prefix" ".py" ".pyi")

    if (( ${#python_files[@]} == 0 )); then
      echo "=== Python ==="
      echo "No modified Python files."
      return 0
    fi

    echo "=== Python: black ==="
    local -a python_relative_files=()
    mapfile -t python_relative_files < <(relativize_paths "$PYTHON_PROJECT_DIR" "${python_files[@]}")
    (cd "$PYTHON_PROJECT_DIR" && black "${python_relative_files[@]}")
    return 0
  fi

  echo "=== Python: black ==="
  (cd "$PYTHON_PROJECT_DIR" && black .)
}

run_go_format() {
  local modified_only="$1"

  if ! detect_go_project; then
    print_skip "Go" "no Go files or module found in ${GO_PROJECT_DIR}"
    return 0
  fi

  if ! require_command gofmt; then
    return 1
  fi
  if ! require_command goimports; then
    return 1
  fi

  local go_prefix
  go_prefix="$(path_prefix_for "$GO_PROJECT_DIR")"

  local -a go_files=()
  if (( modified_only )); then
    mapfile -t go_files < <(list_modified_repo_paths "$go_prefix" ".go")
    if (( ${#go_files[@]} == 0 )); then
      echo "=== Go ==="
      echo "No modified Go files."
      return 0
    fi
  else
    mapfile -t go_files < <(list_repo_paths "$go_prefix" ".go")
    if (( ${#go_files[@]} == 0 )); then
      echo "=== Go ==="
      echo "No Go files found."
      return 0
    fi
  fi

  echo "=== Go: gofmt ==="
  local -a go_relative_files=()
  mapfile -t go_relative_files < <(relativize_paths "$GO_PROJECT_DIR" "${go_files[@]}")
  (cd "$GO_PROJECT_DIR" && gofmt -w "${go_relative_files[@]}")

  echo "=== Go: goimports ==="
  (cd "$GO_PROJECT_DIR" && goimports -w "${go_relative_files[@]}")
}

style_usage() {
  cat <<'EOF'
Usage: style.sh <command> [options]

Commands:
  lint     Run linters for the current project root
  format   Format files for the current project root
  init     Initialize formatter/linter config files

Examples:
  style.sh lint --fix --python
  style.sh format --modified --go
  style.sh init --python --go --target ~/projects/my-app
EOF
}

lint_usage() {
  cat <<'EOF'
Usage: style.sh lint [--fix] [--modified] [--rust] [--ts] [--python] [--go] [--shell] [--all]

Environment overrides:
  PROJECT_ROOT       Explicit project root. Defaults to the git root for $PWD.
  RUST_PROJECT_DIR   Directory containing Cargo.toml. Defaults to PROJECT_ROOT.
  TS_PROJECT_DIR     Directory for package.json / tsconfig.json / biome runs.
                     Defaults to PROJECT_ROOT.
  PYTHON_PROJECT_DIR Directory for Python config and source files. Defaults to PROJECT_ROOT.
  GO_PROJECT_DIR     Directory for go.mod and Go source files. Defaults to PROJECT_ROOT.

Options:
  --fix       Apply auto-fixes where supported
  --modified  Limit file-based linting to modified git files
  --rust      Rust only (clippy + rustfmt check)
  --ts        TypeScript only (biome + tsc when tsconfig exists)
  --python    Python only (ruff + black --check)
  --go        Go only (golangci-lint)
  --shell     Shell scripts only (shellcheck)
  --all       All supported lint checks (default)
EOF
}

format_usage() {
  cat <<'EOF'
Usage: style.sh format [--modified] [--rust] [--ts] [--docs] [--python] [--go] [--all]

Environment overrides:
  PROJECT_ROOT       Explicit project root. Defaults to the git root for $PWD.
  RUST_PROJECT_DIR   Directory containing Cargo.toml. Defaults to PROJECT_ROOT.
  TS_PROJECT_DIR     Directory for package.json / biome runs. Defaults to PROJECT_ROOT.
  DOCS_PROJECT_DIR   Directory for prettier runs. Defaults to PROJECT_ROOT.
  PYTHON_PROJECT_DIR Directory for Python config and source files. Defaults to PROJECT_ROOT.
  GO_PROJECT_DIR     Directory for go.mod and Go source files. Defaults to PROJECT_ROOT.

Options:
  --modified  Limit file-based formatting to modified git files
  --rust      Rust only (rustfmt)
  --ts        TypeScript / JavaScript only (biome)
  --docs      Markdown / JSON / YAML only (prettier)
  --python    Python only (black)
  --go        Go only (gofmt + goimports)
  --all       All supported formatters (default)
EOF
}

init_usage() {
  cat <<'EOF'
Usage: style.sh init [--docs] [--python] [--go] [--all] [--target DIR] [--force] [--yes] [--dry-run]

Initialize formatter/linter config files for the current project root or a target directory.

Options:
  --docs             Initialize markdownlint and prettier config files
  --python           Initialize Python Ruff + Black config via pyproject.toml
  --go               Initialize .golangci.yml config
  --all              Initialize docs, Python, and Go config files
  -t, --target <dir> Target directory (default: PROJECT_ROOT)
  --force            Overwrite existing files without prompt
  -y, --yes          Non-interactive mode; keep existing files
  --dry-run          Show actions without writing files
EOF
}

run_lint_command() {
  local fix=0
  local modified_only=0
  local run_rust=0
  local run_ts=0
  local run_python=0
  local run_go=0
  local run_shell=0
  local exit_code=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fix) fix=1; shift ;;
      --modified) modified_only=1; shift ;;
      --rust) run_rust=1; shift ;;
      --ts) run_ts=1; shift ;;
      --python) run_python=1; shift ;;
      --go) run_go=1; shift ;;
      --shell) run_shell=1; shift ;;
      --all) run_rust=1; run_ts=1; run_python=1; run_go=1; run_shell=1; shift ;;
      --help|-h) lint_usage; exit 0 ;;
      *) echo "Unknown arg for lint: $1" >&2; lint_usage >&2; exit 1 ;;
    esac
  done

  if (( !run_rust && !run_ts && !run_python && !run_go && !run_shell )); then
    run_rust=1
    run_ts=1
    run_python=1
    run_go=1
    run_shell=1
  fi

  if (( run_rust )); then
    run_rust_lint "$fix" "$modified_only" || exit_code=1
  fi
  if (( run_ts )); then
    run_ts_lint "$fix" "$modified_only" || exit_code=1
  fi
  if (( run_python )); then
    run_python_lint "$fix" "$modified_only" || exit_code=1
  fi
  if (( run_go )); then
    run_go_lint "$fix" "$modified_only" || exit_code=1
  fi
  if (( run_shell )); then
    run_shell_lint "$modified_only" || exit_code=1
  fi

  exit "$exit_code"
}

run_format_command() {
  local modified_only=0
  local run_rust=0
  local run_ts=0
  local run_docs=0
  local run_python=0
  local run_go=0
  local exit_code=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --modified) modified_only=1; shift ;;
      --rust) run_rust=1; shift ;;
      --ts) run_ts=1; shift ;;
      --docs) run_docs=1; shift ;;
      --python) run_python=1; shift ;;
      --go) run_go=1; shift ;;
      --all) run_rust=1; run_ts=1; run_docs=1; run_python=1; run_go=1; shift ;;
      --help|-h) format_usage; exit 0 ;;
      *) echo "Unknown arg for format: $1" >&2; format_usage >&2; exit 1 ;;
    esac
  done

  if (( !run_rust && !run_ts && !run_docs && !run_python && !run_go )); then
    run_rust=1
    run_ts=1
    run_docs=1
    run_python=1
    run_go=1
  fi

  if (( run_rust )); then
    run_rust_format "$modified_only" || exit_code=1
  fi
  if (( run_ts )); then
    run_ts_format "$modified_only" || exit_code=1
  fi
  if (( run_docs )); then
    run_docs_format "$modified_only" || exit_code=1
  fi
  if (( run_python )); then
    run_python_format "$modified_only" || exit_code=1
  fi
  if (( run_go )); then
    run_go_format "$modified_only" || exit_code=1
  fi

  if (( exit_code == 0 )); then
    echo "All formatting complete."
  fi
  exit "$exit_code"
}

run_init_command() {
  local init_docs=0
  local init_python=0
  local init_go=0
  local target_dir="$PROJECT_ROOT"
  local -a passthrough_args=()
  local target_set=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --docs) init_docs=1; shift ;;
      --python) init_python=1; shift ;;
      --go) init_go=1; shift ;;
      --all) init_docs=1; init_python=1; init_go=1; shift ;;
      -t|--target)
        if [[ $# -lt 2 ]]; then
          echo "Missing value for $1" >&2
          init_usage >&2
          exit 1
        fi
        target_dir="$2"
        target_set=1
        passthrough_args+=("$1" "$2")
        shift 2
        ;;
      --force|--dry-run|-y|--yes)
        passthrough_args+=("$1")
        shift
        ;;
      --help|-h)
        init_usage
        exit 0
        ;;
      *)
        if (( target_set )); then
          echo "Unknown arg for init: $1" >&2
          init_usage >&2
          exit 1
        fi
        target_dir="$1"
        target_set=1
        passthrough_args+=("$1")
        shift
        ;;
    esac
  done

  local resolved_target
  resolved_target="$(cd "$target_dir" >/dev/null 2>&1 && pwd)" || {
    echo "Target directory does not exist: $target_dir" >&2
    exit 1
  }

  if (( !init_docs && !init_python && !init_go )); then
    if detect_docs_project "$resolved_target"; then
      init_docs=1
    fi
    if can_init_python_project "$resolved_target"; then
      init_python=1
    fi
    if detect_go_project "$resolved_target"; then
      init_go=1
    fi
  fi

  if (( !init_docs && !init_python && !init_go )); then
    print_info "No supported config families detected. Defaulting to docs initialization."
    init_docs=1
  fi

  local -a init_args=()
  if (( init_docs )); then
    init_args+=(--docs)
  fi
  if (( init_python )); then
    init_args+=(--python)
  fi
  if (( init_go )); then
    init_args+=(--go)
  fi

  "$SCRIPT_DIR/init-formatters.sh" "${init_args[@]}" "${passthrough_args[@]}"
}

main() {
  if (( $# == 0 )); then
    style_usage
    exit 1
  fi

  local command="$1"
  shift

  case "$command" in
    lint)
      run_lint_command "$@"
      ;;
    format)
      run_format_command "$@"
      ;;
    init)
      run_init_command "$@"
      ;;
    --help|-h|help)
      style_usage
      ;;
    *)
      echo "Unknown command: $command" >&2
      style_usage >&2
      exit 1
      ;;
  esac
}

main "$@"
