# Plan: Professional Release Notes for `ycc:releaser`

## Summary

Bring the generic `ycc:releaser` skill to feature parity with `ycc:bundle-release` for release-notes quality and add an optional `--publish` affordance that runs `gh release create` (new release) or `gh release edit` (update an existing release whose body defaulted to GitHub auto-generated commit list). Today's `draft-changelog.sh` emits all conventional-commit types (including `docs:` and `chore:`) into top-level sections of the release body — a release with mostly maintenance work reads like a raw commit dump. This plan refactors `draft-changelog.sh` to consume the existing placeholder-driven `references/release-notes-template.md`, demotes documentation/chore/test/build/ci/style into a single collapsed **Maintenance** section, and adds a confirmation-gated `publish-release.sh` helper.

## User Story

As a **release manager** running `/ycc:releaser` on an external project, **I want** curated, filtered release notes (user-facing changes elevated, maintenance work demoted) and an opt-in `--publish` flag, **so that** the GitHub release page presents a professional changelog without me having to hand-edit the rendered file or run `gh` myself in a separate step.

## Problem → Solution

**Current**: `draft-changelog.sh` builds the entire markdown document inline via `printf`, ignoring `references/release-notes-template.md`. Its bash `case` bucketizer routes `docs:` → "Docs" section and `chore:`/`test:`/`build:`/`ci:`/`style:`/`refactor:` → "Chore" section, both rendered as first-class top-level headings. Phase 8 of `SKILL.md` emits a `gh release create --notes-file` block as text only — there is no execution path and no `gh release edit` path for releases already published with default GitHub-generated notes.

**Desired**: `draft-changelog.sh` becomes a placeholder-fill helper (mirroring `bundle-release/scripts/draft-notes.sh:103-156`) that consumes `references/release-notes-template.md` via Python heredoc substitution. The template is restructured so user-facing changes (Breaking / Features / Fixes) are top-level, maintenance work lives inside an HTML-collapsed `<details>` block, and the raw commit log is demoted to a tail "Commit Log" section. A new `scripts/publish-release.sh` detects whether the release exists and prints (default) or runs (with `--confirm`) the appropriate `gh release create` or `gh release edit --notes-file` invocation.

## Metadata

- **Complexity**: Medium (3 source files modified, 1 new script, 1 SKILL.md rewrite — all in a single skill)
- **Source PRD**: N/A (free-form context plan at `~/.claude/plans/parallel-no-worktree-the-ycc-releaser-mighty-pearl.md`)
- **PRD Phase**: N/A
- **Estimated Files**: 4 source files in `ycc/skills/releaser/` + 3 regenerated bundle copies (`.cursor-plugin/`, `.codex-plugin/`, `.opencode-plugin/`) + 1 new plan file (this file)

## Batches

Tasks grouped by dependency for parallel execution. Tasks within the same batch run concurrently; batches run in order.

| Batch | Tasks         | Depends On | Parallel Width |
| ----- | ------------- | ---------- | -------------- |
| B1    | 1.1, 1.2, 1.3 | —          | 3              |
| B2    | 2.1           | B1         | 1              |
| B3    | 3.1, 3.2      | B2         | 2              |

- **Total tasks**: 6
- **Total batches**: 3
- **Max parallel width**: 3
- **Concurrency safety**: Each Batch-1 task owns a different file; Batch-2 owns `SKILL.md` only; Batch-3 is read-only validation/smoke.

---

## UX Design

### Before

Release page rendered from current `draft-changelog.sh` output:

```
v9.9.9 (2026-05-01)
## Summary
<!-- TODO: 1–3 sentence user-facing summary. -->

## Features
- feat(api): add bulk-fetch endpoint (a1b2c3d)

## Fixes
- fix(parser): handle empty input (e4f5g6h)

## Docs                          ← noisy first-class section
- docs(readme): typo fix (i7j8k9l)
- docs: update changelog (m0n1o2p)

## Chore                         ← noisy first-class section
- chore(deps): bump axios (q3r4s5t)
- chore: regen lockfile (u6v7w8x)
- ci: cache node_modules (y9z0a1b)
- test: add fuzz cases (c2d3e4f)
- refactor: rename internals (g5h6i7j)
```

### After

Release page rendered from new template-fill flow:

```
v9.9.9 — 2026-05-01

## Summary
<curated 1–2 sentence summary written by the user>

## Highlights
- <top 1–3 things>

## Features
- feat(api): add bulk-fetch endpoint (a1b2c3d)

## Fixes
- fix(parser): handle empty input (e4f5g6h)

## Upgrade Notes
No action required.

<details><summary>Maintenance (5 commits)</summary>

- docs(readme): typo fix (i7j8k9l)
- docs: update changelog (m0n1o2p)
- chore(deps): bump axios (q3r4s5t)
- chore: regen lockfile (u6v7w8x)
- ci: cache node_modules (y9z0a1b)
- test: add fuzz cases (c2d3e4f)
- refactor: rename internals (g5h6i7j)

</details>

<details><summary>Commit Log</summary>

a1b2c3d feat(api): add bulk-fetch endpoint
e4f5g6h fix(parser): handle empty input
…

</details>

**Full Changelog**: https://github.com/owner/repo/compare/v9.9.8...v9.9.9
```

### Interaction Changes

| Touchpoint                  | Before                               | After                                                                       | Notes                              |
| --------------------------- | ------------------------------------ | --------------------------------------------------------------------------- | ---------------------------------- |
| `draft-changelog.sh` output | Markdown printed inline via `printf` | Placeholder-substituted markdown via `references/release-notes-template.md` | New `--template <path>` flag       |
| Release-page body           | Docs + Chore as top-level headings   | Maintenance collapsed inside `<details>`                                    | New `--exclude-internal` drops it  |
| Phase 8 `gh release` flow   | Always emit text only                | `--publish[=create\|edit\|auto]` runs the helper script                     | Helper requires `--confirm` to act |
| Existing release update     | No path                              | `gh release edit v<ver> --notes-file <path>`                                | Detected via `gh release view`     |

---

## Mandatory Reading

Files that MUST be read before implementing:

| Priority       | File                                                       | Lines         | Why                                                                                                 |
| -------------- | ---------------------------------------------------------- | ------------- | --------------------------------------------------------------------------------------------------- |
| P0 (critical)  | `ycc/skills/bundle-release/scripts/draft-notes.sh`         | 1-159         | Canonical template-fill pattern: arg parse, regex bucket via `grep -iE`, Python heredoc substitute  |
| P0 (critical)  | `ycc/skills/releaser/scripts/draft-changelog.sh`           | 1-176         | Current implementation being rewritten — preserve `<from-ref>` positional, breaking-detection regex |
| P0 (critical)  | `ycc/skills/releaser/SKILL.md`                             | 1-269         | Skill prompt — Phase 4 (changelog) and Phase 8 (emit commands) are the integration sites            |
| P0 (critical)  | `ycc/skills/releaser/references/release-notes-template.md` | 1-53          | Existing placeholder set already mirrors bundle-release; needs Maintenance + Commit Log sections    |
| P1 (important) | `ycc/skills/bundle-release/scripts/preflight.sh`           | 1-165         | Diagnostic-prefix vocabulary (`FAIL:` / `WARN:` / `HINT:`) and stdout-vs-stderr conventions         |
| P1 (important) | `ycc/skills/bundle-release/scripts/bump-version.sh`        | 72-109        | Atomic Python multi-file write idiom; semver regex shared across the bundle                         |
| P1 (important) | `ycc/skills/git-workflow/scripts/validate-commit.sh`       | 15-27,57      | Conventional-commit regex + canonical `VALID_TYPES` array — reuse list to avoid drift               |
| P1 (important) | `ycc/skills/bundle-release/SKILL.md`                       | 124-140       | Phase 7 emit-block precedent — releaser keeps emit-only as default, `--publish` is opt-in           |
| P2 (reference) | `scripts/generate_codex_skills.py`                         | 55-70,141-189 | Path-rewrite logic — confirms new `releaser/scripts/*.sh` will land in all 3 bundles cleanly        |
| P2 (reference) | `ycc/skills/_shared/scripts/`                              | listing       | No existing helper covers repo-root resolution / commit filtering — releaser must self-implement    |
| P2 (reference) | `.github/workflows/validate.yml`                           | 1-31          | CI runs only `./scripts/validate.sh` + lint; structural verification, no behavior tests             |

## External Documentation

| Topic               | Source                     | Key Takeaway                                                                                           |
| ------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------ |
| `gh release view`   | `gh release view --help`   | `--json url,tagName,body` is the read path; exits non-zero when tag has no release                     |
| `gh release create` | `gh release create --help` | `--notes-file <path>`, `--title <str>`, `--draft`, `--prerelease` — all already supported              |
| `gh release edit`   | `gh release edit --help`   | `--notes-file <path>` overwrites body. **Destructive**: no `--append`. Confirmation gate is mandatory. |

> **No external research needed beyond `gh` CLI surface area.** The work is entirely a refactor of an existing skill against an existing CLI tool.

---

## Patterns to Mirror

Code patterns discovered in the codebase. Follow these exactly.

### TEMPLATE_FILL (Python heredoc substitution)

```bash
# SOURCE: ycc/skills/bundle-release/scripts/draft-notes.sh:130-156
python3 - "${TEMPLATE}" "${OUT}" "${NEW_VERSION}" "${DATE_STR}" "${PREV_TAG}" "${COMMITS_RAW}" "${ADDED}" "${CHANGED}" "${REMOVED}" "${FIXED}" <<'PY'
import sys, pathlib
text = pathlib.Path(sys.argv[1]).read_text()
text = (text
        .replace("{{VERSION}}", sys.argv[3])
        .replace("{{COMMITS_FIXED}}", sys.argv[10]))
pathlib.Path(sys.argv[2]).write_text(text)
PY
```

### COMMIT_FILTER (anchored conventional-commit regex)

```bash
# SOURCE: ycc/skills/bundle-release/scripts/draft-notes.sh:116-127
filter() {
    local pattern="$1"
    local out
    out="$(echo "${COMMITS_RAW}" | grep -iE "${pattern}" || true)"
    [[ -z "${out}" ]] && out="TODO: none this release"
    echo "${out}"
}
ADDED="$(filter '^[a-f0-9]+ (feat|add)')"
```

### REFUSE_OVERWRITE (one-liner before any work)

```bash
# SOURCE: ycc/skills/bundle-release/scripts/draft-notes.sh:97-98
OUT="${REPO_ROOT}/docs/releases/${NEW_VERSION}.md"
[[ -e "${OUT}" ]] && { echo "draft-notes.sh: refuse: ${OUT} already exists" >&2; exit 1; }
```

### DIAGNOSTIC_PREFIX (FAIL/WARN/HINT severity vocabulary)

```bash
# SOURCE: ycc/skills/bundle-release/scripts/preflight.sh:35-37,156-158
echo "preflight.sh: FAIL: working tree is dirty" >&2
echo "  uncommitted changes:" >&2
echo "preflight.sh: HINT: stash or commit before re-running" >&2
```

### ARG_PARSE (loop with usage on error)

```bash
# SOURCE: ycc/skills/bundle-release/scripts/draft-notes.sh:60-89
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -*) echo "draft-notes.sh: unknown option: $1" >&2; usage >&2; exit 1 ;;
        *) [[ -z "${NEW_VERSION}" ]] && NEW_VERSION="$1" || { echo "unexpected"; exit 1; }; shift ;;
    esac
done
```

### SEMVER_VALIDATION (shared regex, two usages)

```bash
# SOURCE: ycc/skills/bundle-release/scripts/draft-notes.sh:91-94 (also bump-version.sh:72-75)
if ! [[ "${NEW_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "draft-notes.sh: invalid version '${NEW_VERSION}' — expected semver (e.g. 1.2.3)" >&2
    exit 1
fi
```

### TEMP_FILE_LIFECYCLE (mktemp + trap)

```bash
# SOURCE: ycc/skills/releaser/scripts/draft-changelog.sh:53-54
LOG_TMP="$(mktemp)"
trap 'rm -f "${LOG_TMP}"' EXIT
```

### CONVENTIONAL_TYPES (canonical list — avoid drift)

```bash
# SOURCE: ycc/skills/git-workflow/scripts/validate-commit.sh:57
VALID_TYPES=(feat fix docs style refactor test chore perf ci build revert)
```

### USER_VIEW_DESTRUCTIVE_FLAG (skill-layer convention; novel at script-layer)

```markdown
# SOURCE: ycc/skills/releaser/SKILL.md:30-31,251

- Never auto-commits, pushes, or publishes. The user reviews every change and runs
  the emitted commands manually.
```

> **Adapter note**: `--confirm` at the script layer is **NEW** — no precedent in the bundle. The `publish-release.sh` script must default to **print-only** (so it matches the existing emit-block discipline) and require an explicit `--confirm` flag to actually invoke `gh`. This is the minimum-surprise translation of the SKILL-layer convention into a script that can run gh.

---

## Files to Change

| File                                                                                                         | Action     | Justification                                                                                                                                                                                                                                          |
| ------------------------------------------------------------------------------------------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `ycc/skills/releaser/scripts/draft-changelog.sh`                                                             | UPDATE     | Replace inline `printf`-based output with template-fill flow. Add `--exclude-internal` and `--template` flags.                                                                                                                                         |
| `ycc/skills/releaser/references/release-notes-template.md`                                                   | UPDATE     | Restructure: Summary, Highlights, Breaking, Features, Fixes, Upgrade Notes, Maintenance (`<details>`), Commit Log, Full Changelog. New placeholders: `{{HIGHLIGHTS}}`, `{{INTERNAL}}`, `{{COMMITS}}`, `{{COMPARE_URL}}`.                               |
| `ycc/skills/releaser/scripts/publish-release.sh`                                                             | CREATE     | New helper: detects existing release, prints or (with `--confirm`) runs `gh release create`/`gh release edit`.                                                                                                                                         |
| `ycc/skills/releaser/SKILL.md`                                                                               | UPDATE     | `argument-hint` adds new flags. Phase 4 rewritten for template-fill flow. Phase 8 grows a `--publish` branch. Add allowed-tools entry for new script (auto-covered by `${CLAUDE_PLUGIN_ROOT}` glob — verify). Add a "What counts as Maintenance" note. |
| `.cursor-plugin/skills/releaser/`, `.codex-plugin/ycc/skills/releaser/`, `.opencode-plugin/skills/releaser/` | REGENERATE | Auto-regenerated by `./scripts/sync.sh`. Do NOT hand-edit.                                                                                                                                                                                             |

## NOT Building

- **Changes to `ycc:bundle-release`**: scoped strictly to ycc itself; out of scope here.
- **Multi-package monorepos**: this work assumes a single version-bearing manifest as releaser already does.
- **Non-`gh` release backends** (GitLab, Gitea, Forgejo): `--publish` is `gh`-specific. Other backends remain emit-only.
- **`gh release upload <artifact>` automation**: the existing emit block already documents this; no execution path added.
- **A `--force` flag**: `publish-release.sh` will refuse to overwrite without `--confirm`. There is no `--force` escape hatch.
- **A new shared helper under `ycc/skills/_shared/scripts/`**: bundle-release does NOT currently use commit-filter or template-fill helpers from the shared dir, so factoring one preemptively would be speculative. Re-evaluate if a third skill needs the same logic.
- **CI workflow tests for the new scripts**: the bundle has no shell unit-test infra. Verification is structural via `./scripts/validate.sh` + a manual smoke test (Task 3.2).

---

## Step-by-Step Tasks

### Task 1.1: Rewrite `draft-changelog.sh` to template-fill flow — Depends on [none]

- **BATCH**: B1
- **ACTION**: Rewrite `ycc/skills/releaser/scripts/draft-changelog.sh` to consume `references/release-notes-template.md` via Python heredoc substitution. Bucket commits by anchored conventional-commit regex. Categories: `BREAKING` (subject regex `^[a-z]+(\([^)]*\))?!` OR body `BREAKING CHANGE`), `FEATURES` (`^[a-f0-9]+ (feat|perf)`), `FIXES` (`^[a-f0-9]+ (fix|revert)`), `INTERNAL` (`^[a-f0-9]+ (docs|chore|test|build|ci|style|refactor)`), `OTHER` (everything not matched). Preserve `<new-version>` and `<from-ref>` positional args.
- **IMPLEMENT**: Add CLI flags `--exclude-internal` (drops the `{{INTERNAL}}` section by replacing with empty string) and `--template <path>` (default: `${SCRIPT_DIR}/../references/release-notes-template.md`). Output goes to **stdout** (so callers can pipe / redirect / inject). The script does NOT write to disk — refuse-overwrite happens at the caller level (Phase 4 of SKILL.md). Reuse the existing `mktemp`+`trap` log buffer and the `_BREAKING_PREFIX_RE`/`_BREAKING_BODY_RE` constants.
- **MIRROR**: `TEMPLATE_FILL`, `COMMIT_FILTER`, `ARG_PARSE`, `SEMVER_VALIDATION`, `TEMP_FILE_LIFECYCLE`, `DIAGNOSTIC_PREFIX`.
- **IMPORTS**: Bash 4+ (already required), `python3` (already used by other scripts), `git`, `mktemp`, `grep -iE`.
- **GOTCHA**:
  1. Existing script uses `git log --format='%h%x09%s%x09%b'` (NUL-separated, tab-internal). Bundle-release uses `git log --oneline`. **Pick one shape and stick with it for all greps** — switching mid-script causes regex misses. Recommendation: keep the existing tab-separated NUL records (current shape gives access to body for breaking-change detection) and feed `--oneline` separately into `{{COMMITS}}` for the raw log section.
  2. The `OTHER` bucket must NOT silently swallow non-conventional commits — emit them in Maintenance with a `(non-conventional)` suffix so the user sees them.
  3. `--exclude-internal` removes the `<details>` Maintenance block AND the leading-blank-line; otherwise the rendered notes get an orphaned blank section.
  4. Keep stdout-only contract — adding a `--out <path>` flag adds a new responsibility (overwrite refusal, mkdir -p). Out of scope here.
- **VALIDATE**: `bash ycc/skills/releaser/scripts/draft-changelog.sh 9.9.9-test 4dd8090..HEAD` exits 0 and emits markdown containing the strings `## Features`, `<details><summary>Maintenance`, and `## Commit Log`. With `--exclude-internal`, the output does NOT contain `<details><summary>Maintenance`. With `--template /tmp/empty.md` (file containing only `{{VERSION}}`), output is exactly `9.9.9-test\n`.

### Task 1.2: Restructure release-notes template — Depends on [none]

- **BATCH**: B1
- **ACTION**: Rewrite `ycc/skills/releaser/references/release-notes-template.md` to a placeholder-driven layout: H1 title → Summary → Highlights → Breaking Changes → Features → Fixes → Upgrade Notes → Maintenance (HTML `<details>`) → Commit Log (HTML `<details>`) → Full Changelog footer.
- **IMPLEMENT**: Use placeholders `{{VERSION}}`, `{{DATE}}`, `{{HIGHLIGHTS}}` (TODO stub), `{{BREAKING}}`, `{{FEATURES}}`, `{{FIXES}}`, `{{INTERNAL}}` (Maintenance section content; if empty, the `<details>` block must collapse cleanly), `{{COMMITS}}` (raw commit log), `{{COMPARE_URL}}` (full URL or empty), `{{PREVIOUS_TAG}}` (display only). Drop the old `{{DEPRECATIONS}}`, `{{DOCS}}`, `{{CHORE}}`, `{{OWNER}}`, `{{REPO}}` placeholders. Preserve the existing `<!-- TODO: ... -->` author-prompt comments for sections that need human curation (Summary, Highlights, Upgrade Notes).
- **MIRROR**: bundle-release's `release-notes-template.md` shape (Summary → Added → Changed → Removed → Fixed → Validation → Upgrade Notes → Commit Log) — adapt to the user-facing-vs-internal split.
- **IMPORTS**: N/A (markdown).
- **GOTCHA**:
  1. The `<details>`/`</details>` tags MUST be on their own lines with surrounding blank lines — GitHub-flavored markdown renders them as raw HTML otherwise. Use `<details><summary>Maintenance</summary>` on one line, blank line, list, blank line, `</details>`.
  2. If `{{INTERNAL}}` is empty (no maintenance commits OR `--exclude-internal`), the entire `<details>` block must vanish. Implement this by leaving the `{{INTERNAL}}` placeholder bare (no surrounding `<details>` tags in the template) and have `draft-changelog.sh` emit either a fully-formed `<details>...</details>` block OR an empty string.
  3. The Commit Log section must be wrapped in its own `<details>` so it's collapsed by default — release pages with 50+ commits otherwise dominate the body.
  4. Don't include the `## Contributors` or `## Artifacts` sections from the old template — both are out of scope and require external data the script doesn't have. If the user wants them, they edit the rendered file before running `gh`.
- **VALIDATE**: `python3 -c 'import pathlib; t=pathlib.Path("ycc/skills/releaser/references/release-notes-template.md").read_text(); assert all(p in t for p in ["{{VERSION}}","{{DATE}}","{{HIGHLIGHTS}}","{{BREAKING}}","{{FEATURES}}","{{FIXES}}","{{INTERNAL}}","{{COMMITS}}","{{COMPARE_URL}}","{{PREVIOUS_TAG}}"]); assert "{{DOCS}}" not in t and "{{CHORE}}" not in t'` exits 0.

### Task 1.3: Create `publish-release.sh` helper — Depends on [none]

- **BATCH**: B1
- **ACTION**: Create `ycc/skills/releaser/scripts/publish-release.sh`. Two positional args: `<tag>` (e.g. `v1.4.0`) and `<notes-file>` (path). One mode flag: `--mode=create|edit|auto` (default `auto`). One safety flag: `--confirm` (default off — print-only). Detection: `gh release view "<tag>" --json url,tagName 2>/dev/null` — exit 0 means release exists (use `edit` in auto mode), non-zero means missing (use `create` in auto mode).
- **IMPLEMENT**: When `--confirm` is absent, print exactly the resolved `gh` command and exit 0. When `--confirm` is present, run the command via `gh release create "<tag>" --notes-file "<notes-file>" --title "<tag>"` or `gh release edit "<tag>" --notes-file "<notes-file>"`. Reject `--mode=edit` if the release does not exist (`FAIL: cannot edit non-existent release`). Reject `--mode=create` if the release already exists (`FAIL: release already exists; use --mode=edit to overwrite`). Use the standard diagnostic-prefix vocabulary.
- **MIRROR**: `ARG_PARSE`, `DIAGNOSTIC_PREFIX`, `REFUSE_OVERWRITE` (style adapted: `FAIL: release already exists`).
- **IMPORTS**: `gh` (already in `allowed-tools`), `git` (for tag verification — optional sanity check via `git rev-parse <tag>`).
- **GOTCHA**:
  1. `gh release view` exits non-zero on **two distinct conditions**: tag has no release, AND tag does not exist. Distinguish via `git rev-parse "<tag>" 2>/dev/null` first — if the tag itself is missing, fail with a tag-creation hint, not a release-creation message.
  2. `gh release edit` is **destructive** — the new notes overwrite the existing body without confirmation prompt from `gh` itself. The `--confirm` gate is the only safety mechanism. Surface the existing body via `gh release view --json body --jq .body` BEFORE applying, in a `WARN:` block, when `--mode=edit` runs with `--confirm`.
  3. Notes file MUST be readable: `[[ -r "<notes-file>" ]]` guard before any gh call.
  4. Tag normalization: accept both `v1.4.0` and `1.4.0` as input; canonicalize to `v1.4.0` for the gh call (gh release matches by exact tag string).
  5. Bundle regeneration: this script flows through `./scripts/sync.sh` to all 3 bundles automatically (`scripts/generate_codex_skills.py:55-70`). Do NOT add `YCC_REPO_ROOT` resolution — that pattern is bundle-release-specific and would break this script when run from external projects.
  6. Make executable: `chmod +x ycc/skills/releaser/scripts/publish-release.sh` — the validator `find ycc/skills -name "*.sh" -not -executable` (per CLAUDE.md) must return empty.
- **VALIDATE**: `bash ycc/skills/releaser/scripts/publish-release.sh v9.9.9-test /etc/hostname` (note file exists; no real release) prints a `gh release create v9.9.9-test --notes-file /etc/hostname --title v9.9.9-test` line and exits 0 without invoking gh. With `--mode=edit`, exits 1 with `FAIL: cannot edit non-existent release v9.9.9-test`. With a missing notes file, exits 1 with `FAIL: notes file not readable`.

### Task 2.1: Update `SKILL.md` to wire new flags and flow — Depends on [1.1, 1.2, 1.3]

- **BATCH**: B2
- **ACTION**: Edit `ycc/skills/releaser/SKILL.md` to surface the new behavior.
- **IMPLEMENT**:
  1. **`argument-hint`** (line 4): append `[--exclude-internal] [--publish[=create|edit|auto]] [--confirm]`.
  2. **`allowed-tools`**: confirm `Bash(gh:*)` (already present, line 12) and the script glob (line 21) cover the new helper. No additions needed. (Verify with `grep` — do not blindly add.)
  3. **Phase 4 (lines 128-150)**: replace the bucketize-and-write narrative. New flow: (a) call `draft-changelog.sh <new-version>` and capture stdout; (b) write the captured stdout to `docs/releases/<new-version>.md` (or `.github/releases/<version>.md` if that path already exists); (c) update `CHANGELOG.md` by prepending a slim version of the same content (Summary + sections only, no `<details>` blocks) above `## [Unreleased]`. Mention the `--exclude-internal` flag and the `--template <path>` override.
  4. **New section after Phase 4** — "Internal vs. user-facing commits": one paragraph explaining what counts as Maintenance (`docs`, `chore`, `test`, `build`, `ci`, `style`, `refactor`) and that `--exclude-internal` drops the section entirely (use only when the release truly has zero internal-only churn worth surfacing).
  5. **Phase 8 (lines 210-236)**: keep the existing emit block as the default. When `--publish` was passed, append a paragraph: "Before running, confirm the rendered notes look correct. Then run `${CLAUDE_PLUGIN_ROOT}/skills/releaser/scripts/publish-release.sh v<new-version> <notes-path> --mode=<mode>` to preview, and re-run with `--confirm` to apply. Use `--mode=edit` only when you intentionally want to replace an existing release body — this is destructive."
  6. **Phase 9 (final summary)**: add `--publish` mode to the reported items list.
  7. **Important Notes**: add a bullet — "When `--publish` is used, the user STILL invokes `--confirm` manually. The skill never bypasses confirmation, even when the user passes `--publish` and `--confirm` together as initial arguments — surface the resolved command and STOP for explicit acknowledgement."
- **MIRROR**: `bundle-release/SKILL.md` Phase 7 emit shape (lines 124-140); current `releaser/SKILL.md` "Important Notes" tone.
- **IMPORTS**: N/A (Markdown).
- **GOTCHA**:
  1. The skill prompt currently says (line 31): "It emits the exact `git tag`, `git push`, and `gh release create` commands the user runs; **it never commits, pushes, or publishes on its own.**" The new `--publish` mode is a _user-opted_ deviation; the prose must be updated to read "...never commits, pushes, or publishes **without an explicit `--publish` and `--confirm` from the user**" — preserving the strict-default while documenting the opt-in.
  2. Don't add `mcp__github__*` work — the existing entry is fine; we're using the `gh` CLI, not the MCP toolset.
  3. Phase 7 (`--dry-run`) currently early-exits before Phase 8. Verify `--publish` interacts correctly: if both `--dry-run` and `--publish` are passed, `--dry-run` wins and the script must NOT run. Document this.
  4. Soft-cap discipline: SKILL.md is currently 269 lines. The additions should add ~40 lines, well under the ~500-line cap from CLAUDE.md.
- **VALIDATE**: `python3 -m json.tool` is irrelevant for `.md`; instead run `head -25 ycc/skills/releaser/SKILL.md` to spot-check the frontmatter argument-hint, and `grep -c '^## Phase ' ycc/skills/releaser/SKILL.md` to confirm phase count is unchanged (10 phases, with the new "Internal vs. user-facing" subsection nested under Phase 4 — not a new top-level phase).

### Task 3.1: Regenerate bundles and run validators — Depends on [2.1]

- **BATCH**: B3
- **ACTION**: Run `./scripts/sync.sh` to regenerate `.cursor-plugin/`, `.codex-plugin/`, `.opencode-plugin/`. Then run `./scripts/validate.sh` (matches CI). Both must exit 0.
- **IMPLEMENT**: Sequential: `./scripts/sync.sh && ./scripts/validate.sh`. After both succeed, spot-check that `.codex-plugin/ycc/skills/releaser/scripts/publish-release.sh`, `.cursor-plugin/skills/releaser/scripts/publish-release.sh`, and `.opencode-plugin/skills/releaser/scripts/publish-release.sh` exist and are executable. Confirm the rewritten `draft-changelog.sh` and template are present in all three.
- **MIRROR**: CLAUDE.md "Testing Changes" → "If you changed `ycc/skills/`, also regenerate and validate the compatibility bundles."
- **IMPORTS**: N/A (existing scripts).
- **GOTCHA**:
  1. The Codex generator rewrites `${CLAUDE_PLUGIN_ROOT}` paths to `~/.codex/plugins/ycc/...`. If the new `publish-release.sh` references `${SCRIPT_DIR}/../references/release-notes-template.md` (it shouldn't — it doesn't use the template), the rewrite is irrelevant. If it adds any `${CLAUDE_PLUGIN_ROOT}` references for documentation, add them to `VERBATIM_SKILL_FILES` in `scripts/generate_codex_common.py:87-96` first.
  2. The `restore_bundle_release_source_paths` post-rewrite hook (`scripts/generate_codex_skills.py:171-189`) is bundle-release-specific. Releaser does NOT need an analogous hook — confirm by checking the post-rewrite output for unintended path mangling.
  3. `npm run lint` runs shellcheck against `.sh` files. The new script must pass shellcheck cleanly. Common gotcha: bash array expansion in functions needs `${arr[@]+"${arr[@]}"}` to silence SC2068 under nounset.
- **VALIDATE**: `./scripts/sync.sh` exits 0; `./scripts/validate.sh` exits 0; `npm run lint` exits 0; `find ycc/skills/releaser -name '*.sh' -not -executable` outputs nothing; for `D in .cursor-plugin/skills/releaser .codex-plugin/ycc/skills/releaser .opencode-plugin/skills/releaser`, `test -x "$D/scripts/publish-release.sh"` succeeds.

### Task 3.2: End-to-end smoke test against this repo's history — Depends on [2.1]

- **BATCH**: B3
- **ACTION**: Run the rewritten scripts read-only against this repo's commit history to verify routing, layout, and `gh` command emission. Do NOT create commits, tags, or releases.
- **IMPLEMENT**:
  1. `bash ycc/skills/releaser/scripts/draft-changelog.sh 9.9.9-test 4dd8090..HEAD > /tmp/notes.md` (range covers commits including `chore: Bump Opencode default model to gpt-5.5` from `dba6a2b`).
  2. Inspect: `grep -A2 'Maintenance' /tmp/notes.md` shows the `chore:` and `docs:` commits inside the `<details>` block. `grep '## Features\|## Fixes' /tmp/notes.md` shows top-level user-facing sections (likely empty — fine for a maintenance window). The raw commit log is inside a `<details>` Commit Log block.
  3. Re-run with `--exclude-internal` and confirm `grep -c 'Maintenance' /tmp/notes-no-internal.md` is 0.
  4. `bash ycc/skills/releaser/scripts/publish-release.sh v9.9.9-test /tmp/notes.md` (no `--confirm`, no `--mode`): prints `gh release create v9.9.9-test --notes-file /tmp/notes.md --title v9.9.9-test` and exits 0. **Does not** invoke `gh`.
  5. `bash ycc/skills/releaser/scripts/publish-release.sh v9.9.9-test /tmp/notes.md --mode=edit`: exits 1 with `FAIL: cannot edit non-existent release v9.9.9-test` (since no such release exists on this repo).
  6. `bash ycc/skills/releaser/scripts/publish-release.sh v9.9.9-test /tmp/missing-notes.md`: exits 1 with `FAIL: notes file not readable`.
- **MIRROR**: existing manual-test discipline — no shell unit tests in the bundle, verification via observable script output.
- **IMPORTS**: `bash`, `grep`, `gh` (read-only `view` only).
- **GOTCHA**:
  1. The smoke test consumes recent commits including the very commit that lands this work. Verify the routing assumes "this commit is currently HEAD" rather than "the tag I claim to release contains it". Use the explicit range `4dd8090..HEAD` to avoid ambiguity.
  2. `gh release view` requires `gh` to be authenticated. If the user is not logged in, the script falls back to `git rev-parse <tag>` for tag existence — but cannot detect release existence. In that environment, `--mode=auto` should fail closed with a clear `WARN: gh not authenticated; cannot determine release state — re-run with explicit --mode=create or --mode=edit`.
  3. Don't leave `/tmp/notes.md` around at the end of the smoke run — `rm -f /tmp/notes.md /tmp/notes-no-internal.md /tmp/missing-notes.md` after the validation completes.
- **VALIDATE**: All six sub-commands behave as described. The `chore: Bump Opencode default model to gpt-5.5` (commit `dba6a2b`) appears inside the Maintenance `<details>` block, **not** in any top-level Features/Fixes section. Manual visual review of `/tmp/notes.md` confirms the layout matches the "After" UX diagram above.

---

## Testing Strategy

### Unit Tests

| Test                                      | Input                                           | Expected Output                                            | Edge Case? |
| ----------------------------------------- | ----------------------------------------------- | ---------------------------------------------------------- | ---------- |
| `draft-changelog.sh` routes `chore:`      | `4dd8090..HEAD` range                           | `chore: Bump Opencode...` in `<details>` Maintenance block | No         |
| `draft-changelog.sh --exclude-internal`   | Same range                                      | No `<details><summary>Maintenance` substring               | Yes        |
| `draft-changelog.sh` with empty range     | `HEAD..HEAD`                                    | "no commits between HEAD and HEAD" stub on stderr; exit 0  | Yes        |
| `draft-changelog.sh` BREAKING detection   | Commit with `feat!:` subject                    | `## Breaking Changes` section populated                    | Yes        |
| `draft-changelog.sh` template override    | `--template /tmp/empty.md` (`{{VERSION}}` only) | stdout = exactly `9.9.9-test\n`                            | Yes        |
| `publish-release.sh` create mode preview  | Non-existent tag, no `--confirm`                | Prints `gh release create v...` and exits 0                | No         |
| `publish-release.sh` auto detects missing | Non-existent tag, `--mode=auto`                 | Selects `create`, prints command                           | No         |
| `publish-release.sh` edit on missing      | Non-existent tag, `--mode=edit`                 | Exits 1 with `FAIL: cannot edit non-existent release`      | Yes        |
| `publish-release.sh` notes file missing   | `/tmp/does-not-exist.md`                        | Exits 1 with `FAIL: notes file not readable`               | Yes        |
| `publish-release.sh` tag normalization    | `1.4.0` (no `v` prefix)                         | Canonicalizes to `v1.4.0` in emitted command               | Yes        |

### Edge Cases Checklist

- [x] Empty input (`HEAD..HEAD` — covered)
- [x] Maximum size input (smoke test against entire repo history with `--from-ref=$(git rev-list --max-parents=0 HEAD)` — verify no unbounded mktemp growth)
- [x] Invalid types (non-conventional commit subject — must land in OTHER bucket within Maintenance with `(non-conventional)` suffix)
- [ ] Concurrent access (N/A — scripts are stateless and read git only)
- [x] Network failure (`gh` not authenticated → `publish-release.sh` `--mode=auto` fails closed with clear message)
- [x] Permission denied (notes file not readable → `FAIL: notes file not readable`)
- [x] **`gh release edit` overwrites existing body** — gated behind `--confirm` AND surfaced via `WARN:` block before applying

---

## Validation Commands

### Static Analysis

```bash
npm run lint
```

EXPECT: Zero shellcheck/ruff/markdownlint errors across the modified files.

### Unit Tests

> **No shell unit-test infra exists.** Unit-test rows in the table above are smoke-test commands run manually as part of Task 3.2.

### Bundle regeneration + structural validation

```bash
./scripts/sync.sh && ./scripts/validate.sh
```

EXPECT: Both exit 0. Generated `.cursor-plugin/skills/releaser/`, `.codex-plugin/ycc/skills/releaser/`, and `.opencode-plugin/skills/releaser/` carry the new `publish-release.sh`, the rewritten `draft-changelog.sh`, and the new template.

### JSON parity

```bash
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null
python3 -m json.tool ycc/.claude-plugin/plugin.json > /dev/null
```

EXPECT: Both exit 0 (no version bump needed for this work — it's a pre-existing-skill enhancement).

### Executability check

```bash
find ycc/skills/releaser -name '*.sh' -not -executable
```

EXPECT: Empty output.

### Smoke test (Task 3.2)

```bash
bash ycc/skills/releaser/scripts/draft-changelog.sh 9.9.9-test 4dd8090..HEAD > /tmp/notes.md
grep -q '<details><summary>Maintenance' /tmp/notes.md && echo "Maintenance section present"
grep -q 'chore: Bump Opencode' /tmp/notes.md && echo "chore commit present in notes"
bash ycc/skills/releaser/scripts/publish-release.sh v9.9.9-test /tmp/notes.md
rm -f /tmp/notes.md
```

EXPECT: Three "OK" prints; final command emits a `gh release create v9.9.9-test ...` line without invoking `gh`.

### Manual Validation

- [ ] Render `/tmp/notes.md` in GitHub's markdown preview (paste into a draft issue body) and confirm the Maintenance and Commit Log `<details>` blocks collapse correctly.
- [ ] Compare the rendered output side-by-side with a real prior release on `https://github.com/yandy-r/claude-plugins/releases` to confirm it reads as a curated changelog rather than a raw commit list.
- [ ] Confirm that running `/ycc:releaser 9.9.9 --publish=auto` (without `--confirm`) in a Claude Code session prints the resolved `gh` command and stops, requiring an explicit re-invocation with `--confirm`.

---

## Acceptance Criteria

- [ ] All 6 tasks completed across 3 batches
- [ ] `./scripts/sync.sh` and `./scripts/validate.sh` exit 0
- [ ] `npm run lint` exits 0
- [ ] `find ycc/skills/releaser -name '*.sh' -not -executable` outputs nothing
- [ ] `chore:` and `docs:` commits route to Maintenance section, NOT Features/Fixes
- [ ] `--exclude-internal` removes the Maintenance section cleanly (no orphan blank lines)
- [ ] `publish-release.sh` defaults to print-only; requires `--confirm` to invoke gh
- [ ] `--mode=edit` correctly detects existing-vs-missing release and gates accordingly
- [ ] SKILL.md preserves the "never auto-publishes" default; `--publish` is opt-in only
- [ ] Generated bundles in `.cursor-plugin/`, `.codex-plugin/`, `.opencode-plugin/` carry the new script and template

## Completion Checklist

- [ ] Code follows discovered patterns (TEMPLATE_FILL, COMMIT_FILTER, REFUSE_OVERWRITE, DIAGNOSTIC_PREFIX, ARG_PARSE, SEMVER_VALIDATION)
- [ ] Error handling matches the bundle-release `FAIL:`/`WARN:`/`HINT:` vocabulary
- [ ] Logging follows stdout-vs-stderr convention (results to stdout, diagnostics to stderr)
- [ ] No hardcoded paths (every script uses `${SCRIPT_DIR}` or `git rev-parse --show-toplevel`)
- [ ] SKILL.md `argument-hint` updated to reflect new flags
- [ ] No unnecessary scope additions (no shared helper extraction; no `--force` flag; no MCP-toolset migration)
- [ ] Self-contained — implementor did not need to ask additional questions during execution

## Risks

| Risk                                                                                                  | Likelihood | Impact                             | Mitigation                                                                                                                                                    |
| ----------------------------------------------------------------------------------------------------- | ---------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Template-shape change breaks downstream projects that pin the old `{{DOCS}}`/`{{CHORE}}` placeholders | Low        | Medium (rendered notes look weird) | The template ships with the skill; consumers don't pin headings. Call out the placeholder-set change in the SKILL.md "Important Notes" so audit users notice. |
| `gh release edit` overwrites existing release body destructively                                      | Medium     | High (lost release notes)          | `publish-release.sh` requires `--confirm`; `WARN:` block surfaces existing body before overwrite; no `--force` escape hatch.                                  |
| Codex/Cursor/opencode generator path-rewrites mangle the new script                                   | Low        | Medium (broken bundle)             | `./scripts/validate.sh` catches structural drift; CI runs the same. Treat any validation failure as a hard stop in Task 3.1.                                  |
| Researcher GAP: no precedent for script-layer `--confirm` flag                                        | Documented | Low                                | This plan establishes the pattern; mirror it if a future skill needs the same affordance.                                                                     |
| `gh` not authenticated in user's environment                                                          | Low        | Low                                | `publish-release.sh` `--mode=auto` fails closed with `WARN: gh not authenticated; re-run with explicit --mode=create or --mode=edit`.                         |
| Smoke test pollutes `/tmp`                                                                            | Low        | Trivial                            | Cleanup `rm -f /tmp/notes.md ...` at end of Task 3.2 sub-commands.                                                                                            |

## Notes

- **Why not factor a `_shared` helper?** Bundle-release is a self-contained, repo-specific orchestrator (with `YCC_REPO_ROOT` resolution and hard-coded paths). Releaser is generic and runs in any repo. The two share _patterns_ (template-fill, commit-filter regex) but not _callers_. Premature extraction would create coupling we don't need. Re-evaluate when a third skill needs the same logic.

- **Why script-layer `--confirm` rather than skill-layer?** The skill prompt already disciplines "never auto-publishes." But `--publish` is an opt-in deviation, and once the user opts in, the _script_ is the executable surface that must enforce the "no surprises" contract. A skill-layer-only gate would let the script be invoked directly (e.g., from a hook) and bypass the safety. Belt-and-suspenders: gate at both layers.

- **Why `<details>` for Maintenance instead of an `<h2>`?** GitHub's release-page renderer respects `<details>` and collapses by default. This puts the maintenance content one click away — visible to anyone who wants the audit, invisible to anyone scanning for headline changes. A nested `## Maintenance` heading would still look like a top-level section in the table-of-contents view.

- **Out-of-band**: this plan was written by the `ycc:prp-plan` skill in `--parallel --no-worktree` mode using 3 sub-agent researchers (`patterns-research`, `quality-research`, `infra-research`). The original lightweight plan lives at `~/.claude/plans/parallel-no-worktree-the-ycc-releaser-mighty-pearl.md`.
