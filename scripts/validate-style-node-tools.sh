#!/usr/bin/env bash
# Contract test for the Node CLI resolution in style.sh (resolve_node_bin).
# Lint and format must run the tool version the lockfile pins, so every Node CLI
# comes from the project's node_modules/.bin. A checkout without node_modules has
# to fail loudly instead of letting `npx` resolve an arbitrary registry or cache
# version that disagrees with CI. `npx` is poisoned on PATH here: any fallback to
# it shows up in the invocation log and fails the test.
#
# Both the source-of-truth bundle copy and the repo-root vendored copy are
# exercised, so a mirror that drifts back to `npx` fails here too.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUNDLE_STYLE="${REPO_ROOT}/ycc/skills/formatters/scripts/bundle/style.sh"
ROOT_STYLE="${REPO_ROOT}/scripts/style.sh"

style=''
tmp=''

fail() {
  echo "validate-style-node-tools: FAIL [$(basename "$(dirname "$style")")] $*" >&2
  exit 1
}

# The "no node_modules" cases only mean something when no ancestor directory
# supplies one either.
assert_no_ancestor_node_modules() {
  local dir="$1"
  local previous=''
  while [[ -n "$dir" && "$dir" != "$previous" ]]; do
    [[ -d "$dir/node_modules/.bin" ]] &&
      fail "fixture is not hermetic: ${dir}/node_modules/.bin exists"
    previous="$dir"
    dir="$(dirname "$dir")"
  done
}

make_stub() { # project_dir bin_name
  local bin_dir="$1/node_modules/.bin"
  mkdir -p "$bin_dir"
  cat >"$bin_dir/$2" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename "$0")" "$*" >>"$STYLE_TEST_LOG"
EOF
  chmod +x "$bin_dir/$2"
}

declare -a run_env=()

run() { # label project_dir style_args...
  local label="$1"
  local project_dir="$2"
  shift 2

  local dir="$tmp/run-$label"
  mkdir -p "$dir"
  touch "$dir/log"

  set +e
  env PATH="$tmp/bin:$PATH" PROJECT_ROOT="$project_dir" STYLE_TEST_LOG="$dir/log" \
    "${run_env[@]}" "$style" "$@" >"$dir/out" 2>"$dir/err"
  echo $? >"$dir/status"
  set -e
  run_env=()
}

status() { cat "$tmp/run-$1/status"; }
log() { cat "$tmp/run-$1/log"; }
err() { cat "$tmp/run-$1/err"; }

assert_no_npx() { # label
  grep -q '^npx ' "$tmp/run-$1/log" &&
    fail "$1 fell back to npx: $(log "$1")"
  return 0
}

run_suite() { # style_script
  style="$1"
  tmp="$(cd "$(mktemp -d)" && pwd -P)"

  mkdir -p "$tmp/bin"
  cat >"$tmp/bin/npx" <<'EOF'
#!/usr/bin/env bash
printf 'npx %s\n' "$*" >>"$STYLE_TEST_LOG"
exit 90
EOF
  chmod +x "$tmp/bin/npx"

  # --- docs track without node_modules: fail loudly, never reach npx ---------
  local docs_bare="$tmp/docs-bare"
  mkdir -p "$docs_bare"
  printf '# Title\n' >"$docs_bare/README.md"
  assert_no_ancestor_node_modules "$docs_bare"

  run docs-missing "$docs_bare" lint --docs
  [[ $(status docs-missing) != 0 ]] ||
    fail "docs lint without node_modules exited 0: $(cat "$tmp/run-docs-missing/out")"
  assert_no_npx docs-missing
  grep -q 'node_modules/.bin/markdownlint' "$tmp/run-docs-missing/err" ||
    fail "docs lint did not name the missing markdownlint binary: $(err docs-missing)"
  grep -q 'pnpm install' "$tmp/run-docs-missing/err" ||
    fail "docs lint did not tell the user to install dependencies: $(err docs-missing)"

  # --- docs track with node_modules: run the local binaries ------------------
  local docs_local="$tmp/docs-local"
  mkdir -p "$docs_local"
  printf '# Title\n' >"$docs_local/README.md"
  make_stub "$docs_local" prettier
  make_stub "$docs_local" markdownlint

  run docs-local "$docs_local" lint --docs
  [[ $(status docs-local) == 0 ]] ||
    fail "docs lint with node_modules failed: $(err docs-local)"
  grep -q '^markdownlint .*README.md' "$tmp/run-docs-local/log" ||
    fail "local markdownlint was not invoked: $(log docs-local)"
  grep -q '^prettier --check .*README.md' "$tmp/run-docs-local/log" ||
    fail "local prettier was not invoked: $(log docs-local)"
  assert_no_npx docs-local

  # --- a nested docs dir resolves node_modules from a parent -----------------
  local nested="$tmp/nested"
  mkdir -p "$nested/docs"
  printf '# Nested\n' >"$nested/docs/guide.md"
  make_stub "$nested" prettier
  make_stub "$nested" markdownlint

  run_env=("DOCS_PROJECT_DIR=$nested/docs")
  run docs-nested "$nested" lint --docs
  [[ $(status docs-nested) == 0 ]] ||
    fail "nested docs lint failed: $(err docs-nested)"
  grep -q '^prettier --check .*guide.md' "$tmp/run-docs-nested/log" ||
    fail "nested docs lint did not resolve prettier from the parent node_modules: $(log docs-nested)"
  assert_no_npx docs-nested

  # --- ts track without node_modules: fail loudly ----------------------------
  local ts_bare="$tmp/ts-bare"
  mkdir -p "$ts_bare"
  printf '{}\n' >"$ts_bare/package.json"
  printf '{}\n' >"$ts_bare/tsconfig.json"
  printf 'export const answer = 42;\n' >"$ts_bare/index.ts"
  assert_no_ancestor_node_modules "$ts_bare"

  run ts-missing "$ts_bare" lint --ts
  [[ $(status ts-missing) != 0 ]] ||
    fail "ts lint without node_modules exited 0: $(cat "$tmp/run-ts-missing/out")"
  grep -q '@biomejs/biome' "$tmp/run-ts-missing/err" ||
    fail "ts lint did not name the missing biome package: $(err ts-missing)"
  assert_no_npx ts-missing

  # --- ts track with node_modules: run the local binaries --------------------
  local ts_local="$tmp/ts-local"
  mkdir -p "$ts_local"
  printf '{}\n' >"$ts_local/package.json"
  printf '{}\n' >"$ts_local/tsconfig.json"
  printf 'export const answer = 42;\n' >"$ts_local/index.ts"
  make_stub "$ts_local" biome
  make_stub "$ts_local" tsc

  run ts-local "$ts_local" lint --ts
  [[ $(status ts-local) == 0 ]] ||
    fail "ts lint with node_modules failed: $(err ts-local)"
  grep -q '^biome ci .*index.ts' "$tmp/run-ts-local/log" ||
    fail "local biome was not invoked: $(log ts-local)"
  grep -q '^tsc --noEmit' "$tmp/run-ts-local/log" ||
    fail "local tsc was not invoked: $(log ts-local)"
  assert_no_npx ts-local

  # --- format also uses the local binaries -----------------------------------
  local fmt_local="$tmp/fmt-local"
  mkdir -p "$fmt_local"
  printf '# Title\n' >"$fmt_local/README.md"
  make_stub "$fmt_local" prettier

  run fmt-local "$fmt_local" format --docs
  [[ $(status fmt-local) == 0 ]] ||
    fail "docs format with node_modules failed: $(err fmt-local)"
  grep -q '^prettier --write .*README.md' "$tmp/run-fmt-local/log" ||
    fail "local prettier was not invoked by format: $(log fmt-local)"
  assert_no_npx fmt-local

  local fmt_bare="$tmp/fmt-bare"
  mkdir -p "$fmt_bare"
  printf '# Title\n' >"$fmt_bare/README.md"
  assert_no_ancestor_node_modules "$fmt_bare"

  run fmt-missing "$fmt_bare" format --docs
  [[ $(status fmt-missing) != 0 ]] ||
    fail "docs format without node_modules exited 0: $(cat "$tmp/run-fmt-missing/out")"
  assert_no_npx fmt-missing

  rm -rf "$tmp"
  tmp=''
}

cleanup() {
  [[ -n "$tmp" ]] && rm -rf "$tmp"
  return 0
}
trap cleanup EXIT

run_suite "$BUNDLE_STYLE"
run_suite "$ROOT_STYLE"

echo "OK: style.sh resolves Node CLIs from node_modules and fails loudly without them."
