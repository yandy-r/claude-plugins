#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUNDLE_ROOT="${REPO_ROOT}/ycc/skills/formatters/scripts/bundle"
PROFILE_SCRIPT="${REPO_ROOT}/ycc/skills/formatters/scripts/profile-style.sh"
STYLE_SCRIPT="${BUNDLE_ROOT}/style.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "validate-formatters-bundle: ${message}: expected '${expected}', got '${actual}'" >&2
    exit 1
  fi
}

read_profile_value() {
  local profile_file="$1"
  local key="$2"
  awk -F= -v target="$key" '$1 == target { print $2 }' "$profile_file"
}

assert_package_deps() {
  local package_json="$1"
  local expect_prettier="$2"
  python3 - "$package_json" "$expect_prettier" <<'PY'
import json, sys
path, expect_prettier = sys.argv[1], sys.argv[2] == "true"
data = json.load(open(path, encoding="utf-8"))
deps = data.get("devDependencies", {})

assert deps.get("@biomejs/biome") == "2.3.11", deps
assert deps.get("typescript") == "^5.6.3", deps

has_prettier = "prettier" in deps
has_markdownlint = "markdownlint-cli" in deps
if expect_prettier:
    assert has_prettier and has_markdownlint, deps
else:
    assert not has_prettier and not has_markdownlint, deps
PY
}

tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

python3 - "${REPO_ROOT}/scripts/style.sh" "${BUNDLE_ROOT}/style.sh" <<'PY'
import re, sys

def extract(path: str) -> list[str]:
    text = open(path, encoding="utf-8").read()
    match = re.search(r'BUNDLE_MANAGED_FILES=\(\n(.*?)\n\)', text, re.S)
    if not match:
        raise SystemExit(f"validate-formatters-bundle: could not parse BUNDLE_MANAGED_FILES from {path}")
    return re.findall(r'"([^"]+)"', match.group(1))

root_files = extract(sys.argv[1])
bundle_files = extract(sys.argv[2])
if root_files != bundle_files:
    raise SystemExit(
        "validate-formatters-bundle: root scripts/style.sh managed files are out of sync with source-of-truth bundle"
    )
PY

ts_auto_dir="${tmp_root}/ts-auto"
mkdir -p "${ts_auto_dir}/src"
cat > "${ts_auto_dir}/package.json" <<'EOF'
{
  "name": "ts-auto",
  "private": true
}
EOF
cat > "${ts_auto_dir}/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "strict": true
  },
  "include": ["src"]
}
EOF
cat > "${ts_auto_dir}/src/main.ts" <<'EOF'
export const value = 1;
EOF

ts_auto_profile="${tmp_root}/ts-auto.profile"
"${PROFILE_SCRIPT}" "${ts_auto_dir}" > "${ts_auto_profile}"
assert_eq "$(read_profile_value "${ts_auto_profile}" detect_ts)" "true" "ts-auto detect_ts"
assert_eq "$(read_profile_value "${ts_auto_profile}" detect_docs)" "false" "ts-auto detect_docs"

pkg_docs_dir="${tmp_root}/pkg-docs"
mkdir -p "${pkg_docs_dir}"
cat > "${pkg_docs_dir}/package.json" <<'EOF'
{
  "name": "pkg-docs",
  "private": true
}
EOF
cat > "${pkg_docs_dir}/config.json" <<'EOF'
{
  "name": "pkg-docs"
}
EOF

pkg_docs_profile="${tmp_root}/pkg-docs.profile"
"${PROFILE_SCRIPT}" "${pkg_docs_dir}" > "${pkg_docs_profile}"
assert_eq "$(read_profile_value "${pkg_docs_profile}" detect_ts)" "false" "pkg-docs detect_ts"
assert_eq "$(read_profile_value "${pkg_docs_profile}" detect_docs)" "true" "pkg-docs detect_docs"

ts_scaffold_dir="${tmp_root}/ts-scaffold"
mkdir -p "${ts_scaffold_dir}"
"${STYLE_SCRIPT}" init --copy --yes --target "${ts_scaffold_dir}" --ts >/dev/null
assert_package_deps "${ts_scaffold_dir}/package.json" "false"
test ! -f "${ts_scaffold_dir}/.prettierrc" || {
  echo "validate-formatters-bundle: TS-only scaffold should not create .prettierrc" >&2
  exit 1
}

ts_docs_scaffold_dir="${tmp_root}/ts-docs-scaffold"
mkdir -p "${ts_docs_scaffold_dir}"
"${STYLE_SCRIPT}" init --copy --yes --target "${ts_docs_scaffold_dir}" --ts --docs >/dev/null
assert_package_deps "${ts_docs_scaffold_dir}/package.json" "true"
test -f "${ts_docs_scaffold_dir}/.prettierrc" || {
  echo "validate-formatters-bundle: TS+docs scaffold should create .prettierrc" >&2
  exit 1
}
test -f "${ts_docs_scaffold_dir}/.markdownlint.json" || {
  echo "validate-formatters-bundle: TS+docs scaffold should create .markdownlint.json" >&2
  exit 1
}

docs_json_dir="${tmp_root}/docs-json"
mkdir -p "${docs_json_dir}"
cat > "${docs_json_dir}/config.json" <<'EOF'
{
  "name": "docs-json"
}
EOF

docs_json_profile="${tmp_root}/docs-json.profile"
"${PROFILE_SCRIPT}" "${docs_json_dir}" > "${docs_json_profile}"
assert_eq "$(read_profile_value "${docs_json_profile}" detect_ts)" "false" "docs-json detect_ts"
assert_eq "$(read_profile_value "${docs_json_profile}" detect_docs)" "true" "docs-json detect_docs"

templates_dir="${tmp_root}/templates-docs"
mkdir -p "${templates_dir}/scripts/templates"
cat > "${templates_dir}/scripts/templates/readme.md" <<'EOF'
# Template docs
EOF

template_paths="$(
  PROJECT_ROOT="${templates_dir}" \
  bash -lc '. "'"${BUNDLE_ROOT}"'/lib/modified-files.sh"; list_repo_paths "" ".md"'
)"
if ! printf '%s\n' "${template_paths}" | grep -Fq "${templates_dir}/scripts/templates/readme.md"; then
  echo "validate-formatters-bundle: scripts/templates/readme.md should remain lintable when user-authored" >&2
  exit 1
fi

echo "OK: formatter bundle smoke checks passed."
