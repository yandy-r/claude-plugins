#!/usr/bin/env bash
#
# Behavioral tests for ycc/skills/_shared/scripts/backport-audit.sh, the
# pre-tag gate used by ycc:releaser (patch releases) and ycc:backport --audit.
#
# Every test runs in throwaway git repos under a temp dir with an isolated git
# config and a stub gh on PATH, so no real repository or GitHub API is used.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
AUDIT="${REPO_ROOT}/ycc/skills/_shared/scripts/backport-audit.sh"

PASS=0
FAIL=0

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

# Git hooks export GIT_DIR and friends; left set, they would point sandbox git
# calls at the caller's repository.
while IFS= read -r git_var; do
  unset "$git_var"
done < <(git rev-parse --local-env-vars)
unset git_var

SANDBOX_ROOT="$(mktemp -d)"
trap 'rm -rf "${SANDBOX_ROOT}"' EXIT

export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="${SANDBOX_ROOT}/gitconfig"
cat >"${GIT_CONFIG_GLOBAL}" <<'EOF'
[user]
	name = ycc test
	email = ycc-test@example.invalid
[init]
	defaultBranch = main
[commit]
	gpgsign = false
[tag]
	gpgsign = false
EOF

ok() {
  PASS=$((PASS + 1))
  printf '%s[pass]%s %s\n' "${GREEN}" "${NC}" "$1"
}

ko() {
  FAIL=$((FAIL + 1))
  printf '%s[FAIL]%s %s\n' "${RED}" "${NC}" "$1"
  [[ -n "${2:-}" ]] && printf '       %s\n' "$2"
}

assert_eq() {
  local actual="$1" expected="$2" name="$3"
  if [[ "$actual" == "$expected" ]]; then
    ok "$name"
  else
    ko "$name" "expected: $(printf '%q' "$expected") got: $(printf '%q' "$actual")"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" name="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    ok "$name"
  else
    ko "$name" "missing: $needle"
  fi
}

assert_exit() {
  assert_eq "$1" "$2" "$3 (exit $2)"
}

# write_releasing <dir> <block-body> — write a RELEASING.md with a state block.
write_releasing() {
  printf '# Releasing\n\n<!-- ycc-release-state\n%s\n-->\n' "$2" >"$1/RELEASING.md"
}

# commit <dir> <message> — commit a change with the given message; echo SHA.
commit() {
  echo "$2" >>"$1/log.txt"
  git -C "$1" add log.txt
  git -C "$1" commit -q -m "$2"
  git -C "$1" rev-parse HEAD
}

# Fixed SHA of the trunk fix that reached release/0.5 by plain cherry-pick -x
# with no backport PR (a manual backport).
PICKED_SHA="cccc000000000000000000000000000000000011"

# seed_repo — main with v0.5.0 and a later v0.6.0; release/0.5 cut from v0.5.0
# with a v0.5.1 patch and a cherry-pick -x commit; all pushed to a bare origin.
seed_repo() {
  local dir origin
  dir="$(mktemp -d "${SANDBOX_ROOT}/repo.XXXXXX")"
  origin="${dir}.origin.git"
  git init -q --bare "$origin"
  git -C "$dir" init -q
  if [[ "$(cd "$dir" && git rev-parse --absolute-git-dir)" != "${dir}/.git" ]]; then
    echo "test-release-backport-audit: git did not resolve the sandbox repo; aborting" >&2
    exit 1
  fi
  write_releasing "$dir" "model: release-branches
trunk: main
maintenance: release/0.5"
  git -C "$dir" add RELEASING.md
  commit "$dir" "chore(release): v0.5.0" >/dev/null
  git -C "$dir" tag -a v0.5.0 -m v0.5.0
  git -C "$dir" branch release/0.5
  commit "$dir" "feat: trunk work" >/dev/null
  git -C "$dir" tag -a v0.6.0 -m v0.6.0
  git -C "$dir" switch -q release/0.5
  commit "$dir" "fix: picked by hand

(cherry picked from commit ${PICKED_SHA})" >/dev/null
  commit "$dir" "chore(release): v0.5.1" >/dev/null
  git -C "$dir" tag -a v0.5.1 -m v0.5.1
  git -C "$dir" switch -q main
  git -C "$dir" remote add origin "$origin"
  git -C "$dir" push -q origin main release/0.5 --tags 2>/dev/null
  echo "$dir"
}

# ---------------------------------------------------------------------------
# Stub gh: answers from canned JSON files in $GH_STUB_DIR
# ---------------------------------------------------------------------------

STUB_BIN="${SANDBOX_ROOT}/stub-bin"
mkdir -p "$STUB_BIN"
cat >"${STUB_BIN}/gh" <<'STUB'
#!/usr/bin/env bash
# Stub gh for test-release-backport-audit.sh. Canned responses:
#   auth status                   -> exit ${GH_STUB_AUTH_RC:-0}
#   pr list ... --label L         -> $GH_STUB_DIR/label_<L>.json
#   pr list ... --search Q        -> $GH_STUB_DIR/search.json
#   pr list ... --base B (other)  -> $GH_STUB_DIR/base_<B>.json
# ':' and '/' in L and B become '_'. A missing file answers [].
set -euo pipefail
echo "$*" >>"${GH_STUB_DIR}/calls.log"
key() { local v="$1"; v="${v//\//_}"; printf '%s' "${v//:/_}"; }
emit() { if [[ -f "$1" ]]; then cat "$1"; else echo '[]'; fi; }
case "${1:-} ${2:-}" in
  "auth status") exit "${GH_STUB_AUTH_RC:-0}" ;;
  "pr list")
    shift 2
    label="" search="" base=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --label) label="$2"; shift ;;
        --search) search="$2"; shift ;;
        --base) base="$2"; shift ;;
      esac
      shift
    done
    if [[ -n "$label" ]]; then emit "${GH_STUB_DIR}/label_$(key "$label").json"
    elif [[ -n "$search" ]]; then emit "${GH_STUB_DIR}/search.json"
    else emit "${GH_STUB_DIR}/base_$(key "$base").json"
    fi
    exit 0
    ;;
esac
echo "gh stub: unsupported call: $*" >&2
exit 1
STUB
chmod +x "${STUB_BIN}/gh"

new_stub_dir() {
  mktemp -d "${SANDBOX_ROOT}/gh-stub.XXXXXX"
}

run_audit() {
  local stub="$1"
  shift
  GH_STUB_DIR="$stub" PATH="${STUB_BIN}:${PATH}" bash "$AUDIT" "$@"
}

# row <status> <pr> <sha> <title> <detail> — one expected output line.
row() {
  printf '%s\t%s\t%s\t%s\t%s' "$@"
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_clean() {
  local repo stub out rc
  repo="$(seed_repo)"
  stub="$(new_stub_dir)"
  cat >"${stub}/label_backport_0.5.json" <<JSON
[
  {"number":10,"title":"fix: ten","mergeCommit":{"oid":"aaaa000000000000000000000000000000000010"}},
  {"number":11,"title":"fix: eleven","mergeCommit":{"oid":"${PICKED_SHA}"}}
]
JSON
  echo '[{"number":20,"state":"MERGED","body":"Backport of #10 to release/0.5."}]' >"${stub}/base_release_0.5.json"
  cat >"${stub}/search.json" <<'JSON'
[
  {"number":10,"title":"fix: ten","labels":[{"name":"backport:0.5"}],"mergeCommit":{"oid":"aaaa000000000000000000000000000000000010"}},
  {"number":30,"title":"feat: thirty","labels":[],"mergeCommit":{"oid":"aaaa000000000000000000000000000000000030"}}
]
JSON
  out="$(run_audit "$stub" release/0.5 --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 0 "audit: every labelled PR backported, no unlabelled fix"
  assert_eq "$out" "$(row ok 10 aaaa000000000000000000000000000000000010 "fix: ten" "#20")
$(row ok 11 "$PICKED_SHA" "fix: eleven" "cherry-pick cccc000")
since=v0.5.1" "audit: merged twin and cherry-pick trailer both count as backported"
  assert_contains "$(cat "${stub}/calls.log")" "--state merged --base main --label backport:0.5" \
    "audit: labelled query is scoped to merged trunk PRs"
}

test_findings() {
  local repo stub out rc
  repo="$(seed_repo)"
  stub="$(new_stub_dir)"
  cat >"${stub}/label_backport_0.5.json" <<'JSON'
[
  {"number":14,"title":"fix: fourteen","mergeCommit":{"oid":"aaaa000000000000000000000000000000000014"}},
  {"number":12,"title":"fix: twelve","mergeCommit":{"oid":"aaaa000000000000000000000000000000000012"}},
  {"number":13,"title":"fix: thirteen","mergeCommit":{"oid":"aaaa000000000000000000000000000000000013"}}
]
JSON
  cat >"${stub}/base_release_0.5.json" <<'JSON'
[
  {"number":22,"state":"CLOSED","body":"Backport of #13"},
  {"number":23,"state":"OPEN","body":"Backport of #14"},
  {"number":24,"state":"MERGED","body":"Backport of #120"},
  {"number":25,"state":"MERGED","body":"Backport of #33"}
]
JSON
  cat >"${stub}/search.json" <<'JSON'
[
  {"number":32,"title":"chore: bug by label","labels":[{"name":"type:bug"},{"name":"backport:0.6"}],"mergeCommit":{"oid":"aaaa000000000000000000000000000000000032"}},
  {"number":31,"title":"fix(api): trunk only?","labels":[],"mergeCommit":{"oid":"aaaa000000000000000000000000000000000031"}},
  {"number":33,"title":"fix!: backported without label","labels":[],"mergeCommit":{"oid":"aaaa000000000000000000000000000000000033"}},
  {"number":34,"title":"docs: fix typo","labels":[],"mergeCommit":{"oid":"aaaa000000000000000000000000000000000034"}}
]
JSON
  out="$(run_audit "$stub" 0.5 --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 3 "audit: findings"
  assert_eq "$out" "$(row missing 12 aaaa000000000000000000000000000000000012 "fix: twelve" "no backport PR")
$(row missing 13 aaaa000000000000000000000000000000000013 "fix: thirteen" "backport #22 closed unmerged")
$(row in-review 14 aaaa000000000000000000000000000000000014 "fix: fourteen" "#23")
$(row unlabelled 31 aaaa000000000000000000000000000000000031 "fix(api): trunk only?" "no backport:0.5 label")
$(row unlabelled 32 aaaa000000000000000000000000000000000032 "chore: bug by label" "no backport:0.5 label (has backport:0.6)")
$(row ok 33 aaaa000000000000000000000000000000000033 "fix!: backported without label" "#25")
since=v0.5.1" "audit: blocking rows first; 'Backport of #120' is not a twin of #12; docs: is not a fix"
}

test_window() {
  local repo stub rc date
  repo="$(seed_repo)"
  stub="$(new_stub_dir)"
  run_audit "$stub" release/0.5 --repo "$repo" >/dev/null 2>&1
  date="$(TZ=UTC git -C "$repo" for-each-ref --format='%(creatordate:iso-strict-local)' refs/tags/v0.5.1)"
  assert_contains "$(cat "${stub}/calls.log")" "--search merged:>=${date}" \
    "audit: default window starts at the newest tag on release/X.Y (v0.5.1, not trunk's v0.6.0)"
  : >"${stub}/calls.log"
  run_audit "$stub" release/0.5 --repo "$repo" --since v0.5.0 >"${stub}/out" 2>&1
  rc=$?
  assert_exit "$rc" 0 "audit: --since with nothing to report"
  date="$(TZ=UTC git -C "$repo" for-each-ref --format='%(creatordate:iso-strict-local)' refs/tags/v0.5.0)"
  assert_contains "$(cat "${stub}/calls.log")" "--search merged:>=${date}" "audit: --since v0.5.0 sweeps the whole line"
  assert_eq "$(cat "${stub}/out")" "since=v0.5.0" "audit: since line names the window"
  run_audit "$stub" release/0.5 --repo "$repo" --since no-such-ref >/dev/null 2>&1
  assert_exit "$?" 1 "audit: unknown --since ref"
}

test_refusals() {
  local repo stub out rc
  stub="$(new_stub_dir)"
  repo="$(seed_repo)"

  run_audit "$stub" --repo "$repo" >/dev/null 2>&1
  assert_exit "$?" 1 "audit: line is required"
  run_audit "$stub" release/next --repo "$repo" >/dev/null 2>&1
  assert_exit "$?" 1 "audit: line must be X.Y"

  out="$(run_audit "$stub" release/0.4 --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 1 "audit: release branch missing on origin"
  assert_contains "$out" "release/0.4 does not exist on origin" "audit: names the missing branch"

  GH_STUB_AUTH_RC=1 run_audit "$stub" release/0.5 --repo "$repo" >/dev/null 2>&1
  assert_exit "$?" 1 "audit: gh not authenticated"

  write_releasing "$repo" "model: trunk-only
trunk: main"
  out="$(run_audit "$stub" release/0.5 --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 1 "audit: trunk-only has nothing to audit"
  assert_contains "$out" "only release-branches" "audit: explains the model"

  write_releasing "$repo" "model: release-branches"
  run_audit "$stub" release/0.5 --repo "$repo" >/dev/null 2>&1
  assert_exit "$?" 2 "audit: malformed state"

  rm "${repo}/RELEASING.md"
  run_audit "$stub" release/0.5 --repo "$repo" >/dev/null 2>&1
  assert_exit "$?" 1 "audit: no RELEASING.md"
}

if [[ ! -x "$AUDIT" ]]; then
  ko "backport-audit.sh is executable"
else
  test_clean
  test_findings
  test_window
  test_refusals
fi

printf '\nrelease-backport-audit tests: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
