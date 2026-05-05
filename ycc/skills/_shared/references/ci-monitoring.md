# CI Monitoring Reference

Consumed by `ycc:git-workflow` (Phase 6) and `ycc:prp-pr` (Phase 7) when the
`--ci` flag is passed. This document defines the policy, caps, failure
classification, termination signals, audit schema, and loop protocol that both
skills implement. The execution logic lives in
`${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/ci-monitor.sh`. This document and
that script are the single source of truth — both skills consume them and must
not diverge from either.

---

## Trust Boundary

`--ci` grants the following standing authorization for the duration of one skill
invocation:

- **Loop authorization**: the skill may invoke `ci-monitor.sh` repeatedly, apply
  code fixes, commit, and push — bounded by the caps in the next section.
- **One-time prompt**: at loop start the skill renders a confirmation block
  showing the resolved caps (PR number, head branch, `--max-pushes`,
  `--max-same-failure`, `--timeout-min`) and the non-toggleable safety
  constraints below. The user must confirm before the first iteration. Skip this
  prompt by passing `--ci-yes` (for non-interactive callers).
- **Non-toggleable safety constraints** (cannot be overridden by any flag):
  - Never `git push --force` or `git push --force-with-lease`.
  - Never commit with `--no-verify`.
  - Only push to the PR head branch (the branch `gh pr view` reports as
    `headRefName`).
  - Refuse to operate if the head branch equals the repository default branch
    (exits `RESULT=refused-default-branch`, code 2).
- **Audit log**: every script invocation appends a JSONL record to
  `~/.claude/session-data/ci-watch/<pr>-<utc-timestamp>.log`. The path is
  determined once at loop start and reused for all iterations.

---

## Caps and Defaults

| Flag                    | Default | Purpose                                                    |
| ----------------------- | ------- | ---------------------------------------------------------- |
| `--ci-max-pushes`       | 5       | Hard cap on auto-pushes per invocation                     |
| `--ci-max-same-failure` | 3       | Bail after the same failure signature recurs N times       |
| `--ci-timeout-min`      | 30      | Wall-clock cap in minutes from first iteration to bail     |
| `--ci-yes`              | (off)   | Skip the one-time auth prompt (non-interactive)            |
| `--ci-dry-run`          | (off)   | Wire-test only — script returns `RESULT=green` immediately |

Skills pass these as `--max-pushes`, `--max-same-failure`, `--timeout-min`, and
`--dry-run` to `ci-monitor.sh`. `--ci-yes` is consumed by the skill layer (no
script flag).

---

## Failure Classification

The script's `classify_failure()` function matches log content in priority order.
The table below reproduces the exact categories and strategies.

| Category           | Fixable      | Strategy                                                                                                                                             |
| ------------------ | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lint`             | yes          | Run repo formatter/linter; commit `fix(ci): apply linter fixes`                                                                                      |
| `format`           | yes          | Run formatter; commit `fix(ci): apply formatting`                                                                                                    |
| `type-check`       | yes          | LLM reads error, applies typed fix at the source; commit `fix(<area>): <summary>`                                                                    |
| `unit-test`        | yes          | LLM reads failing test + source, applies fix to source (preferred) or test; commit `fix(<area>): <summary>`                                          |
| `build`            | yes          | LLM reads error, applies fix (missing import, syntax, dep version); commit `fix(<area>): <summary>`                                                  |
| `integration-test` | no (default) | Bail with diagnosis — too risky to auto-fix                                                                                                          |
| `infra`            | no           | Bail; surface to user — runner outage, network failure                                                                                               |
| `secret-missing`   | no           | Bail; surface to user — required secret/env var absent                                                                                               |
| `flake-suspected`  | retry-once   | `gh run rerun --failed <id>`; emits `RESULT=rerun-pending` so the caller waits and re-invokes. If same failure recurs, escalate to `bail-nonfixable` |
| `unknown`          | no           | Bail with full log excerpt — cannot classify                                                                                                         |

Classification order is fixed: `lint` → `format` → `type-check` → `unit-test` →
`build` → `integration-test` → `infra` → `secret-missing` → `flake-suspected` →
`unknown`. The first matching pattern wins.

For `flake-suspected`: the script logs `action=rerun`, calls
`gh run rerun --failed <run_id>`, and exits `RESULT=rerun-pending` (code 21).
The caller MUST sleep ~30s and re-invoke without applying any fix. If the same
signature appears a second time with a prior `rerun` entry in the log, the script
escalates directly to `bail-nonfixable` (code 11) without another rerun.

---

## Termination Policy

The script writes `RESULT=<value>` to stdout before exiting with the
corresponding code.

| RESULT=                  | Exit code | Meaning                                                                  |
| ------------------------ | --------- | ------------------------------------------------------------------------ |
| `green`                  | 0         | All checks pass                                                          |
| `handoff`                | 20        | Caller must apply fix + commit + push, then re-invoke                    |
| `rerun-pending`          | 21        | Flake-suspected; caller must sleep ~30s, then re-invoke (no fix applied) |
| `bail-recurrence`        | 10        | Same signature recurred ≥ `--ci-max-same-failure` times                  |
| `bail-nonfixable`        | 11        | Failure category is non-fixable (or flake exhausted retries)             |
| `bail-pushes`            | 12        | Push count ≥ `--ci-max-pushes`                                           |
| `bail-timeout`           | 13        | Wall-clock ≥ `--ci-timeout-min`, or checks never registered              |
| `pr-not-found`           | 2         | PR does not exist or is unreachable                                      |
| `refused-default-branch` | 2         | Will not operate when head branch equals the default branch              |

Exit code 1 is reserved for argument/usage errors and never appears in the loop.

---

## Loop Protocol

The SKILL.md files for `ycc:git-workflow` and `ycc:prp-pr` implement the
following LLM-side loop. The script is a single-shot checker; the loop lives in
the skill.

1. **One-time auth prompt** (skip if `--ci-yes`): render resolved caps + safety
   constraints to the user; require confirmation before proceeding.

2. **Initialize audit log path**: compute
   `~/.claude/session-data/ci-watch/<pr>-<utc-iso-timestamp>.log`. Create the
   directory if absent. Reuse this same path for every iteration in the session.

3. **Loop iteration**: invoke `ci-monitor.sh` with all resolved caps plus
   `--log-file <path>`:

   ```
   ci-monitor.sh \
     --pr <number> \
     --branch <head-branch> \
     --base <base-branch> \
     --max-pushes <N> \
     --max-same-failure <N> \
     --timeout-min <N> \
     --log-file <path> \
     [--dry-run]
   ```

4. **Branch on stdout `RESULT=...`**:
   - **`green`** — render success block (CI passed, no further pushes needed);
     exit phase.

   - **`handoff`** — read the following fields from stdout:
     - `RUN_ID` — GitHub Actions run ID of the failing run
     - `WORKFLOW` — workflow name
     - `JOB` — first failing job name
     - `CATEGORY` — failure category (from classification table above)
     - `SIGNATURE` — 16-hex failure signature
     - `LOG_EXCERPT_FILE` — path to a temp file containing the raw log
     - `SUGGESTED_COMMIT_TYPE` — always `fix`
     - `SUGGESTED_COMMIT_SCOPE` — always `ci`

     Apply fix per the Failure Classification table strategy for `CATEGORY`.
     Validate the commit message via
     `${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/scripts/validate-commit.sh`.
     Push to head branch (no `--force`, no `--no-verify`).
     Delete or ignore `LOG_EXCERPT_FILE` after reading.
     Goto step 3.

   - **`rerun-pending`** — flake suspected; the script already triggered
     `gh run rerun --failed`. Do NOT apply any fix. Sleep ~30s to let the rerun
     register, then goto step 3 to observe the new run's outcome.

   - **`bail-recurrence`** / **`bail-nonfixable`** / **`bail-pushes`** /
     **`bail-timeout`** — render a diagnosis block citing:
     - The audit log path
     - The `RESULT=` value and any `REASON=` line emitted by the script
     - The cap or constraint that fired
       Exit phase; do not push further.

   - **`pr-not-found`** / **`refused-default-branch`** — surface the error
     directly; do not enter the loop.

---

## Audit Log Schema

One JSONL record per `ci-monitor.sh` invocation, appended to the log file.

```json
{
  "timestamp": "2026-05-05T12:34:56Z",
  "iteration": 1,
  "pr": 42,
  "run_id": 12345,
  "workflow": "CI",
  "conclusion": "failure",
  "classification": "lint",
  "action": "handoff",
  "push_count": 1,
  "signature": "a1b2c3d4e5f60789"
}
```

Field definitions (matching `log_jsonl()` in the script):

| Field            | Type                  | Meaning                                                                                                                                                              |
| ---------------- | --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `timestamp`      | string (ISO 8601 UTC) | Time the record was written                                                                                                                                          |
| `iteration`      | integer               | Log line count + 1 before this append (1-based)                                                                                                                      |
| `pr`             | integer               | PR number passed via `--pr`                                                                                                                                          |
| `run_id`         | integer               | GitHub Actions `databaseId`; `0` when not applicable                                                                                                                 |
| `workflow`       | string                | Workflow name from `gh run list`; empty string when not applicable                                                                                                   |
| `conclusion`     | string                | `success`, `failure`, or empty for pre-check bail                                                                                                                    |
| `classification` | string                | Category from `classify_failure()`; empty when classification did not run                                                                                            |
| `action`         | string                | One of: `green`, `handoff`, `rerun`, `bail-pushes`, `bail-timeout`, `bail-recurrence`, `bail-nonfixable`. (`rerun` corresponds to `RESULT=rerun-pending` on stdout.) |
| `push_count`     | integer               | Number of `handoff` actions recorded in the log before this entry                                                                                                    |
| `signature`      | string                | 16-hex failure signature; empty string when not computed                                                                                                             |

Optional fields (present only in specific cases):

| Field            | When present          |
| ---------------- | --------------------- |
| `"dry_run":true` | `--dry-run` mode only |

---

## Idempotency

- Re-invoking `--ci` against an already-open PR detects the PR via
  `gh pr list --head <branch>` (or the PR number the user supplied); no
  duplicate PR is created.
- The push counter (`push_count`) resets to zero at the start of each skill
  invocation because the audit log path is timestamp-suffixed — a new session
  writes a new log file and the script counts `action=handoff` entries within
  that file only.
- Because log files are timestamp-suffixed, no two sessions overwrite each
  other's logs.
- Pushes from a prior session are NOT counted toward the current session's
  `--ci-max-pushes` cap.

---

## Safety Constraints (Non-Toggleable)

These rules are enforced by the skill layer and the script; no flag can override
them:

- Never `git push --force` or `git push --force-with-lease` to any branch.
- Never commit with `--no-verify`; all hooks must pass.
- Only push to the PR head branch (`headRefName` as reported by `gh pr view`).
- Refuse if the head branch equals the repository default branch
  (`refused-default-branch`, exit 2).
- Fixes are applied only to source files identified by the CI log — no
  speculative refactors outside the failure scope.
- Commit messages must pass `validate-commit.sh` before the push is made.

---

## Failure Signature

The script computes a failure signature via `compute_signature()`:

```
sig = sha256( workflow_name + "|" + normalize(first_failing_step) )
    truncated to the first 16 hex characters
```

Normalization of the step name: lowercase, collapse whitespace runs to a single
space, strip leading/trailing whitespace.

The resulting 16-hex string (e.g. `a1b2c3d4e5f60789`) uniquely identifies the
combination of workflow and first failing step. The recurrence cap
(`--ci-max-same-failure`) triggers when the script finds that this signature
already appears in the audit log at least `N-1` times before the current
iteration — meaning the N-th occurrence of the same root cause triggers bail.

This definition of "same failure" deliberately ignores transient differences
(log verbosity, timestamps, line numbers outside the step name) and fires only
when the same workflow step keeps failing, which is the strongest signal that
auto-fixing is not converging.

---

## When NOT to Use `--ci`

- **Documentation-only PRs**: no CI failure to fix; `--ci` adds overhead with
  no benefit.
- **Novel third-party service configuration**: infra and secret failures bail
  immediately, but if the entire PR is CI infrastructure changes, auto-fixing
  risks introducing incorrect config.
- **When the user wants to review every change**: `--ci` applies fixes and pushes
  autonomously within the caps; use it only when that level of automation is
  acceptable.
- **Default branch PRs**: the script refuses (`refused-default-branch`); do not
  pass `--ci` when working directly on `main`/`master`.
- **Repos without `gh` CLI access**: the script depends on `gh`; it will fail
  on invocation if `gh` is not authenticated or the repo is inaccessible.

---

## References

- `${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/ci-monitor.sh` — loop execution script
- `${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/SKILL.md` — Phase 6 (CI monitoring loop)
- `${CLAUDE_PLUGIN_ROOT}/skills/prp-pr/SKILL.md` — Phase 7 (CI monitoring loop)
- `${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/scripts/validate-commit.sh` — commit message validator
