#!/usr/bin/env bash
#
# Behavioral tests for the ycc:backport helper scripts:
#   ycc/skills/backport/scripts/find-pending.sh   (with a stub gh on PATH)
#   ycc/skills/backport/scripts/cherry-pick-pr.sh (local repos, --sha)
#
# Every test runs in throwaway git repos under a temp dir with an isolated git
# config, so the caller's repositories and global git settings are never used.
# Worktrees created by cherry-pick-pr.sh live under the sandbox as well.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKPORT_SCRIPTS="${REPO_ROOT}/ycc/skills/backport/scripts"
FIND_PENDING="${BACKPORT_SCRIPTS}/find-pending.sh"
CHERRY_PICK="${BACKPORT_SCRIPTS}/cherry-pick-pr.sh"

PASS=0
FAIL=0

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

# Git hooks (pre-push runs validate.sh) export GIT_DIR, GIT_WORK_TREE,
# GIT_INDEX_FILE and friends. Left set, they would point every sandbox git
# call at the caller's repository, so clear all repo-local git variables.
while IFS= read -r git_var; do
  unset "$git_var"
done < <(git rev-parse --local-env-vars)
unset git_var

SANDBOX_ROOT="$(mktemp -d)"
trap 'rm -rf "${SANDBOX_ROOT}"' EXIT

# Isolated git identity/config for every git call in this script.
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
  local actual="$1" expected="$2" name="$3"
  assert_eq "$actual" "$expected" "$name (exit $expected)"
}

# mkrepo — create a repo with one commit on main and a bare origin; echo path.
mkrepo() {
  local dir origin
  dir="$(mktemp -d "${SANDBOX_ROOT}/repo.XXXXXX")"
  origin="${dir}.origin.git"
  git init -q --bare "$origin"
  git -C "$dir" init -q
  # Refuse to continue if git resolved anything but the sandbox repo.
  if [[ "$(cd "$dir" && git rev-parse --absolute-git-dir)" != "${dir}/.git" ]]; then
    echo "test-release-backport: git did not resolve the sandbox repo; aborting" >&2
    exit 1
  fi
  echo "seed" >"${dir}/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -m "chore: seed"
  git -C "$dir" remote add origin "$origin"
  git -C "$dir" push -q origin main 2>/dev/null
  git -C "$dir" remote set-head origin main >/dev/null 2>&1
  echo "$dir"
}

# write_releasing <dir> <block-body> [table-and-prose] — write RELEASING.md.
write_releasing() {
  local dir="$1" body="$2" rest="${3:-}"
  {
    echo "# Releasing"
    echo
    echo "<!-- ycc-release-state"
    printf '%s\n' "$body"
    echo "-->"
    [[ -n "$rest" ]] && printf '\n%s\n' "$rest"
  } >"${dir}/RELEASING.md"
}

# get_key <output> <key> — value of key=value in output.
get_key() {
  printf '%s\n' "$1" | sed -n "s/^$2=//p"
}

# Worktrees created by cherry-pick-pr.sh (via setup-worktree.sh) go here.
export YCC_WORKTREE_ROOT="${SANDBOX_ROOT}/worktrees"

# ---------------------------------------------------------------------------
# Stub gh: answers from canned JSON files in $GH_STUB_DIR
# ---------------------------------------------------------------------------

STUB_BIN="${SANDBOX_ROOT}/stub-bin"
mkdir -p "$STUB_BIN"
cat >"${STUB_BIN}/gh" <<'STUB'
#!/usr/bin/env bash
# Stub gh for test-release-backport.sh. Canned responses:
#   auth status               -> exit ${GH_STUB_AUTH_RC:-0}
#   label list ...            -> $GH_STUB_DIR/labels.json
#   pr list ... --label L     -> $GH_STUB_DIR/label_<L>.json   ([] if absent)
#   pr list ... --base B      -> $GH_STUB_DIR/base_<B>.json    ([] if absent)
# ':' and '/' in L and B become '_'.
set -euo pipefail
echo "$*" >>"${GH_STUB_DIR}/calls.log"
key() { local v="$1"; v="${v//\//_}"; printf '%s' "${v//:/_}"; }
emit() { if [[ -f "$1" ]]; then cat "$1"; else echo '[]'; fi; }
case "${1:-} ${2:-}" in
  "auth status") exit "${GH_STUB_AUTH_RC:-0}" ;;
  "label list") emit "${GH_STUB_DIR}/labels.json"; exit 0 ;;
  "pr list")
    shift 2
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --label) emit "${GH_STUB_DIR}/label_$(key "$2").json"; exit 0 ;;
        --base) emit "${GH_STUB_DIR}/base_$(key "$2").json"; exit 0 ;;
      esac
      shift
    done
    ;;
esac
echo "gh stub: unsupported call: $*" >&2
exit 1
STUB
chmod +x "${STUB_BIN}/gh"

# new_stub_dir — fresh canned-response directory; echo its path.
new_stub_dir() {
  mktemp -d "${SANDBOX_ROOT}/gh-stub.XXXXXX"
}

run_find_pending() {
  local stub="$1"
  shift
  GH_STUB_DIR="$stub" PATH="${STUB_BIN}:${PATH}" bash "$FIND_PENDING" "$@"
}

# ---------------------------------------------------------------------------
# find-pending.sh
# ---------------------------------------------------------------------------

# seed_find_pending_repo — repo whose state has release/0.6 active and
# release/0.5 frozen; echo path.
seed_find_pending_repo() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "model: release-branches
trunk: main
maintenance: release/0.6
frozen: release/0.5"
  echo "$repo"
}

seed_find_pending_stub() {
  local stub="$1"
  cat >"${stub}/labels.json" <<'JSON'
[{"name":"backport:0.6"},{"name":"backport:0.5"},{"name":"bug"},{"name":"needs-backport:0.6"}]
JSON
  cat >"${stub}/label_backport_0.6.json" <<'JSON'
[
  {"number":10,"title":"fix: ten","mergeCommit":{"oid":"aaaa000000000000000000000000000000000010"}},
  {"number":12,"title":"fix: twelve","mergeCommit":{"oid":"aaaa000000000000000000000000000000000012"}},
  {"number":1,"title":"fix(api): one\twith tab","mergeCommit":{"oid":"aaaa000000000000000000000000000000000001"}}
]
JSON
  cat >"${stub}/label_backport_0.5.json" <<'JSON'
[{"number":11,"title":"fix: eleven","mergeCommit":{"oid":"aaaa000000000000000000000000000000000011"}}]
JSON
  cat >"${stub}/label_needs-backport_0.6.json" <<'JSON'
[{"number":99,"title":"fix: wrong prefix","mergeCommit":{"oid":"aaaa000000000000000000000000000000000099"}}]
JSON
  cat >"${stub}/base_release_0.6.json" <<'JSON'
[{"number":13,"body":"Backport of #12\n\nOriginal summary."}]
JSON
}

test_find_pending() {
  local repo stub out err rc expected
  repo="$(seed_find_pending_repo)"
  stub="$(new_stub_dir)"
  seed_find_pending_stub "$stub"
  err="${stub}/stderr"
  out="$(run_find_pending "$stub" --repo "$repo" 2>"$err")"
  rc=$?
  assert_exit "$rc" 0 "find-pending: success"
  expected="$(printf '%s\t%s\t%s\t%s\n%s\t%s\t%s\t%s' \
    1 release/0.6 aaaa000000000000000000000000000000000001 "fix(api): one with tab" \
    10 release/0.6 aaaa000000000000000000000000000000000010 "fix: ten")"
  assert_eq "$out" "$expected" "find-pending: pending pairs, sorted, #12 excluded, #1 not matched by 'Backport of #12'"
  assert_contains "$(cat "$err")" "skip: #11 (backport:0.5): release/0.5 is not an active maintenance branch" \
    "find-pending: frozen-branch label reported as skipped"
  if grep -q "^99"$'\t' <<<"$out" || grep -q -- "--label needs-backport" "${stub}/calls.log"; then
    ko "find-pending: labels without the prefix are ignored"
  else
    ok "find-pending: labels without the prefix are ignored"
  fi
  if grep -q -- "--base release/0.5" "${stub}/calls.log"; then
    ko "find-pending: frozen branches are never queried for backport PRs"
  else
    ok "find-pending: frozen branches are never queried for backport PRs"
  fi
}

test_find_pending_label_prefix() {
  local repo stub out
  repo="$(mkrepo)"
  write_releasing "$repo" "model: release-branches
trunk: main
maintenance: release/2.1
backport_label: bp-{X.Y}"
  stub="$(new_stub_dir)"
  echo '[{"name":"bp-2.1"},{"name":"backport:2.1"}]' >"${stub}/labels.json"
  echo '[{"number":7,"title":"fix: seven","mergeCommit":{"oid":"bbbb"}}]' >"${stub}/label_bp-2.1.json"
  echo '[{"number":8,"title":"fix: eight","mergeCommit":{"oid":"cccc"}}]' >"${stub}/label_backport_2.1.json"
  out="$(run_find_pending "$stub" --repo "$repo" 2>/dev/null)"
  assert_eq "$out" "$(printf '7\trelease/2.1\tbbbb\tfix: seven')" "find-pending: prefix derived from backport_label"
  out="$(run_find_pending "$stub" --repo "$repo" --label-prefix "backport:" 2>/dev/null)"
  assert_eq "$out" "$(printf '8\trelease/2.1\tcccc\tfix: eight')" "find-pending: --label-prefix overrides the prefix"
}

test_find_pending_state() {
  local repo stub out rc
  stub="$(new_stub_dir)"
  repo="$(mkrepo)"
  out="$(run_find_pending "$stub" --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 1 "find-pending: no RELEASING.md"
  assert_contains "$out" "/ycc:release-model" "find-pending: no RELEASING.md points at release-model"

  write_releasing "$repo" "model: trunk-only
trunk: main"
  out="$(run_find_pending "$stub" --repo "$repo" 2>/dev/null)"
  rc=$?
  assert_exit "$rc" 0 "find-pending: trunk-only"
  assert_eq "$out" "" "find-pending: trunk-only prints nothing"

  write_releasing "$repo" "model: nope
trunk: main"
  run_find_pending "$stub" --repo "$repo" >/dev/null 2>&1
  rc=$?
  assert_exit "$rc" 2 "find-pending: malformed state"
}

test_find_pending_gh_unavailable() {
  local repo stub nogh tool out rc
  repo="$(seed_find_pending_repo)"
  stub="$(new_stub_dir)"
  seed_find_pending_stub "$stub"

  nogh="${SANDBOX_ROOT}/no-gh-bin"
  mkdir -p "$nogh"
  for tool in dirname sed git jq sort grep cat; do
    ln -sf "$(command -v "$tool")" "${nogh}/${tool}"
  done
  out="$(PATH="$nogh" "$BASH" "$FIND_PENDING" --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 1 "find-pending: gh missing"
  assert_contains "$out" "'gh' is not installed" "find-pending: gh missing message"

  out="$(GH_STUB_AUTH_RC=1 run_find_pending "$stub" --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 1 "find-pending: gh unauthenticated"
  assert_contains "$out" "gh auth login" "find-pending: gh unauthenticated message"
}

# ---------------------------------------------------------------------------
# cherry-pick-pr.sh
# ---------------------------------------------------------------------------

# mkrelease_repo — repo with release/0.5 active on origin; echo path.
mkrelease_repo() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "model: release-branches
trunk: main
maintenance: release/0.5
frozen: release/0.4"
  printf 'line one\nline two\n' >"${repo}/app.txt"
  git -C "$repo" add RELEASING.md app.txt
  git -C "$repo" commit -q -m "chore: release state"
  git -C "$repo" push -q origin main
  git -C "$repo" push -q origin main:refs/heads/release/0.5
  echo "$repo"
}

# commit_on_main <repo> <file> <content> <subject> — commit; echo the sha.
commit_on_main() {
  local repo="$1" file="$2" content="$3" subject="$4"
  printf '%s\n' "$content" >"${repo}/${file}"
  git -C "$repo" add "$file"
  git -C "$repo" commit -q -m "$subject"
  git -C "$repo" push -q origin main
  git -C "$repo" rev-parse HEAD
}

run_cherry_pick() {
  bash "$CHERRY_PICK" "$@"
}

test_cherry_pick_clean() {
  local repo sha out rc wt branch msg
  repo="$(mkrelease_repo)"
  sha="$(commit_on_main "$repo" guard.txt "guard" "fix(core): add a guard (#42)")"
  out="$(run_cherry_pick 42 release/0.5 --sha "$sha" --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 0 "cherry-pick: clean pick"
  wt="$(get_key "$out" worktree)"
  branch="$(get_key "$out" branch)"
  assert_eq "$branch" "backport/0.5/42-fix-core-add-a-guard" "cherry-pick: branch name from PR number and subject"
  assert_contains "$wt" "${YCC_WORKTREE_ROOT}/" "cherry-pick: worktree under YCC_WORKTREE_ROOT"
  msg="$(git -C "$wt" log -1 --format=%B)"
  assert_contains "$msg" "(cherry picked from commit ${sha})" "cherry-pick: -x trailer in the commit message"
  assert_eq "$(git -C "$wt" rev-parse HEAD~1)" "$(git -C "$repo" rev-parse origin/release/0.5)" \
    "cherry-pick: branch starts from origin/release/0.5"
  if git -C "$repo" ls-remote --heads origin | grep -q "backport/"; then
    ko "cherry-pick: never pushes"
  else
    ok "cherry-pick: never pushes"
  fi
  run_cherry_pick 42 release/0.5 --sha "$sha" --repo "$repo" >/dev/null 2>&1
  rc=$?
  assert_exit "$rc" 1 "cherry-pick: existing backport branch refused"
}

test_cherry_pick_merge_commit() {
  local repo sha out rc wt
  repo="$(mkrelease_repo)"
  git -C "$repo" checkout -q -b feat/m
  echo "m" >"${repo}/m.txt"
  git -C "$repo" add m.txt
  git -C "$repo" commit -q -m "fix: m"
  git -C "$repo" checkout -q main
  git -C "$repo" merge -q --no-ff feat/m -m "Merge pull request #44 from feat/m"
  git -C "$repo" push -q origin main
  sha="$(git -C "$repo" rev-parse HEAD)"
  out="$(run_cherry_pick 44 release/0.5 --sha "$sha" --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 0 "cherry-pick: true merge commit picked with -m 1"
  wt="$(get_key "$out" worktree)"
  if [[ -f "${wt}/m.txt" ]]; then
    ok "cherry-pick: merge commit content applied"
  else
    ko "cherry-pick: merge commit content applied" "$out"
  fi
}

test_cherry_pick_conflict() {
  local repo sha out rc wt
  repo="$(mkrelease_repo)"
  git -C "$repo" checkout -q -b rel-edit origin/release/0.5
  printf 'line one (release)\nline two\n' >"${repo}/app.txt"
  git -C "$repo" commit -q -am "fix: release-only edit"
  git -C "$repo" push -q origin rel-edit:release/0.5
  git -C "$repo" checkout -q main
  sha="$(commit_on_main "$repo" app.txt "$(printf 'line one (trunk)\nline two')" "fix: trunk edit")"
  out="$(run_cherry_pick 43 release/0.5 --sha "$sha" --repo "$repo" 2>/dev/null)"
  rc=$?
  assert_exit "$rc" 3 "cherry-pick: conflict"
  assert_eq "$(get_key "$out" conflicts)" "app.txt" "cherry-pick: conflicts listed"
  wt="$(get_key "$out" worktree)"
  if [[ -n "$wt" ]] && git -C "$wt" rev-parse -q --verify CHERRY_PICK_HEAD >/dev/null; then
    ok "cherry-pick: worktree left mid-cherry-pick"
  else
    ko "cherry-pick: worktree left mid-cherry-pick" "$out"
  fi
  assert_eq "$(get_key "$out" branch)" "backport/0.5/43-fix-trunk-edit" "cherry-pick: branch reported on conflict"
}

test_cherry_pick_already_applied() {
  local repo sha out rc
  repo="$(mkrelease_repo)"
  sha="$(commit_on_main "$repo" both.txt "both" "fix: both")"
  git -C "$repo" push -q origin "${sha}:refs/heads/release/0.5"
  out="$(run_cherry_pick 46 release/0.5 --sha "$sha" --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 1 "cherry-pick: change already on the target"
  if git -C "$repo" show-ref --verify --quiet refs/heads/backport/0.5/46-fix-both; then
    ko "cherry-pick: empty pick cleans up its branch" "$out"
  else
    ok "cherry-pick: empty pick cleans up its branch"
  fi
}

test_cherry_pick_refusals() {
  local repo sha out rc
  repo="$(mkrelease_repo)"
  sha="$(git -C "$repo" rev-parse HEAD)"
  out="$(run_cherry_pick 42 release/0.4 --sha "$sha" --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 1 "cherry-pick: frozen target refused"
  assert_contains "$out" "not an active maintenance branch" "cherry-pick: frozen target message"

  out="$(run_cherry_pick 42 release/0.9 --sha "$sha" --repo "$repo" 2>&1)"
  rc=$?
  assert_exit "$rc" 1 "cherry-pick: unknown target refused"

  run_cherry_pick 42 main --sha "$sha" --repo "$repo" >/dev/null 2>&1
  rc=$?
  assert_exit "$rc" 1 "cherry-pick: non-release target rejected"

  run_cherry_pick abc release/0.5 --sha "$sha" --repo "$repo" >/dev/null 2>&1
  rc=$?
  assert_exit "$rc" 1 "cherry-pick: non-numeric PR rejected"

  write_releasing "$repo" "model: release-branches
trunk: main
maintenance: hotfix"
  run_cherry_pick 42 release/0.5 --sha "$sha" --repo "$repo" >/dev/null 2>&1
  rc=$?
  assert_exit "$rc" 2 "cherry-pick: malformed state"
}

# ---------------------------------------------------------------------------

test_find_pending
test_find_pending_label_prefix
test_find_pending_state
test_find_pending_gh_unavailable
test_cherry_pick_clean
test_cherry_pick_merge_commit
test_cherry_pick_conflict
test_cherry_pick_already_applied
test_cherry_pick_refusals

echo
echo "release-backport tests: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
