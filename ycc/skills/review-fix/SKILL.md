---
name: review-fix
description: Plan and apply fixes for findings from a code-review artifact produced by /ycc:code-review. Parses the review file (local or PR), filters findings by severity threshold, groups them into dependency-safe batches (same-file findings stay together, different files can run in parallel), dispatches ycc:review-fixer agents to apply each fix, updates the Status field in the source review file in place (Open → Fixed or Failed), runs validation after changes, and writes a fix report to docs/prps/reviews/fixes/. Pass `--parallel` to fan out independent fixes across parallel review-fixer agents. Pass `--severity <CRITICAL|HIGH|MEDIUM|LOW>` to change the minimum severity threshold (default HIGH). Pass `--dry-run` to preview the fix plan without applying changes. Use when the user asks to "fix review findings", "apply review fixes", "review-fix PR 42", "fix the code review", or says "/review-fix". Adapted from PRPs-agentic-eng by Wirasm.
argument-hint: '<path/to/review.md | pr-number | blank> [--parallel] [--severity <level>] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - MultiEdit
  - Agent
  - AskUserQuestion
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(find:*)
  - Bash(mkdir:*)
  - Bash(git:*)
  - Bash(npm:*)
  - Bash(pnpm:*)
  - Bash(yarn:*)
  - Bash(bun:*)
  - Bash(npx:*)
  - Bash(cargo:*)
  - Bash(go:*)
  - Bash(pytest:*)
  - Bash(python:*)
  - Bash(python3:*)
  - Bash(make:*)
---

# Review Fix

Plan and apply fixes for code-review findings. Reads a review artifact produced by `/ycc:code-review`, filters by severity, plans dependency-safe fix batches, dispatches `ycc:review-fixer` agents to apply each fix, updates the Status field in the review file in place, and writes a fix report.

> Adapted from PRPs-agentic-eng by Wirasm. Part of the PRP workflow series.

**Core philosophy**: The review artifact is the source of truth. Every finding has a stable ID and a Status field. This skill processes findings one at a time (or in parallel batches), updates the Status, and produces an auditable fix trail.

**Golden rule**: Never modify a finding's `Suggested fix` field. If a fix doesn't work as suggested, mark it `Failed` and let the human decide.

---

## Phase 0 — DETECT

### Flag Parsing

Extract flags from `$ARGUMENTS` before treating the remainder as the input:

| Flag                 | Effect                                                                                                              |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `--parallel`         | Dispatch `ycc:review-fixer` agents in parallel per batch. Level 1+2 validation between batches. Fail-stop behavior. |
| `--severity <level>` | Minimum severity to fix: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`. Default: `HIGH` (fixes CRITICAL + HIGH).              |
| `--dry-run`          | Print the fix plan and stop. Do not dispatch fixers, do not modify any files.                                       |

Strip these flags from `$ARGUMENTS` and set `PARALLEL_MODE`, `MIN_SEVERITY`, and `DRY_RUN`. The remaining text is the input selector.

### Input Resolution

Determine the review artifact path from the stripped `$ARGUMENTS`:

| Input Pattern           | Detection                 | Action                                                              |
| ----------------------- | ------------------------- | ------------------------------------------------------------------- |
| Path ending in `.md`    | Explicit review file path | Use as-is                                                           |
| Pure digits (e.g. `42`) | PR number                 | Resolve to `docs/prps/reviews/pr-42-review.md`                      |
| Empty / blank           | No input                  | Find latest file in `docs/prps/reviews/` and prompt user to confirm |

For the "find latest" case:

```bash
ls -t docs/prps/reviews/*.md 2>/dev/null | head -1
```

If no review file found:

```
Error: No review artifact found.
Run /ycc:code-review first to produce a review artifact.
```

Verify the file exists before proceeding:

```bash
test -f "$REVIEW_FILE" || { echo "Error: review file not found: $REVIEW_FILE"; exit 1; }
```

### Package Manager Detection

Detect the project type-check and test commands (used for between-batch validation in parallel mode and for passing to each `ycc:review-fixer` agent):

| File Exists         | Stack  | Type-check                      | Tests           |
| ------------------- | ------ | ------------------------------- | --------------- |
| `bun.lockb`         | bun    | `bun run typecheck`             | `bun test`      |
| `pnpm-lock.yaml`    | pnpm   | `pnpm typecheck` / `pnpm tsc`   | `pnpm test`     |
| `yarn.lock`         | yarn   | `yarn typecheck`                | `yarn test`     |
| `package-lock.json` | npm    | `npx tsc --noEmit`              | `npm test`      |
| `Cargo.toml`        | cargo  | `cargo check`                   | `cargo test`    |
| `go.mod`            | go     | `go vet ./...`                  | `go test ./...` |
| `pyproject.toml`    | python | project-specific (mypy/pyright) | `pytest`        |

Record the commands as `TYPECHECK_CMD` and `TEST_CMD` for later phases.

---

## Phase 1 — LOAD

Read the review artifact:

```bash
cat "$REVIEW_FILE"
```

Parse the `## Findings` section. For each `### <SEVERITY>` block, extract every finding matching this pattern:

```
- **[F###]** `file:line` — description
  - **Status**: Open | Fixed | Failed
  - **Category**: <category>
  - **Suggested fix**: <fix>
```

Build an in-memory list of `Finding` objects with fields:

- `id` (e.g., `F042`)
- `severity` (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`)
- `file`
- `line`
- `description`
- `status`
- `category`
- `suggested_fix`

If the file is not in the expected format or no findings are found, stop with:

```
Error: Review file has no parseable findings or is not in the expected format.
See the Review Artifact Format section of /ycc:code-review.
```

If every finding already has `Status: Fixed` or `Status: Failed`, stop with:

```
All findings in this review have already been processed.
  Fixed:  N
  Failed: M
Nothing to do.
```

**CHECKPOINT**: Review loaded. All findings parsed. At least one `Status: Open` finding exists.

---

## Phase 2 — FILTER

Apply filters in this order, tracking what was dropped and why:

### 2a. Status filter

Keep only findings with `Status: Open`. Already-`Fixed` and already-`Failed` findings are preserved in the file but not re-processed.

### 2b. Severity filter

Compare each finding's severity against `MIN_SEVERITY` using this order: `CRITICAL > HIGH > MEDIUM > LOW`. Drop findings below the threshold.

### 2c. Fix-suggestion filter

Drop findings without a non-empty `Suggested fix` field. These require human judgment and are not safe to auto-apply.

### 2d. Missing-file filter

For each remaining finding, verify the file exists:

```bash
test -f "$FILE"
```

Drop findings whose file no longer exists (likely already refactored).

### 2e. Report filter results

Print a summary:

```
Filter Results:
  Total findings:              N
  Already Fixed:               A
  Already Failed:              B
  Below severity threshold:    C  (threshold: HIGH)
  No suggested fix:            D
  Missing files:               E
  Eligible for fixing:         M
```

If `M == 0`, stop with: "No eligible findings to fix."

---

## Phase 3 — PLAN

Group the eligible findings into batches. The goal is maximum parallelism without write conflicts.

### Batching rules

1. **Findings in the same file go in the same group.** Concurrent edits to one file cause write conflicts, so same-file findings are ALWAYS processed sequentially within a single `ycc:review-fixer` agent.
2. **Findings in different files are parallel candidates.** They can go in the same batch and be dispatched concurrently.
3. **Within a same-file group, sort by line number DESCENDING.** This ensures earlier edits don't shift the line numbers of later findings.
4. **Severity ordering across batches**: process CRITICAL findings first, then HIGH, then MEDIUM, then LOW. This gives the user the highest-value fixes immediately and ensures that if the pipeline stops mid-run, the worst issues are addressed first.

### Batch construction algorithm

```
1. Group eligible findings by file → same_file_groups[]
2. Sort same_file_groups by max severity of the group (CRITICAL first)
3. For each severity level (CRITICAL, HIGH, MEDIUM, LOW):
     - Collect all same_file_groups whose MAX severity matches this level
     - If those groups are all for different files, they become one batch (parallel-eligible)
     - Otherwise split into multiple batches (unlikely since groups are keyed by file)
4. Within each group, sort findings by line number DESCENDING
```

### Display the plan

```
Fix Plan:
  Eligible findings:  M
  Same-file groups:   G
  Batches:            B
  Max parallel width: W  (largest batch size)

Batch 1 (CRITICAL, 3 fixes, 3 files):
  - F001 (src/auth.ts:42)     SQL injection in user lookup
  - F002 (src/api.ts:17)      Missing null check
  - F003 (src/db/query.ts:8)  Unescaped input

Batch 2 (HIGH, 2 fixes, 1 file with 2 findings):
  - src/utils/format.ts:
      - F005 (line 112) Function exceeds 50 lines
      - F004 (line 78)  Missing error handling

...
```

### Dry-run gate

If `DRY_RUN=true`, stop here. Print a reminder:

```
Dry run complete. To apply fixes, re-run without --dry-run:
  /ycc:review-fix $REVIEW_FILE [--parallel] [--severity <level>]
```

**CHECKPOINT**: Plan built. Batches computed. User has seen the plan.

---

## Phase 4 — EXECUTE

Branch based on `PARALLEL_MODE`.

### Path A — Sequential Execution (default)

Process batches in order. Within each batch, process findings (or same-file groups) one at a time.

For each finding or group:

1. **Dispatch a single `ycc:review-fixer` agent** with the Finding spec (Shape A for single, Shape B for same-file group). Include `SOURCE REVIEW FILE` and `PROJECT TYPE-CHECK COMMAND` in the prompt.

2. **Wait for the agent to return** its success or failure report.

3. **Update the source review file in place**:
   - On `STATUS: Fixed` → use `Edit` to change the finding's `**Status**: Open` line to `**Status**: Fixed`
   - On `STATUS: Failed` → use `Edit` to change the finding's `**Status**: Open` line to `**Status**: Failed`

4. **Track progress** in a todo list:
   - `[done] F042 — Fixed`
   - `[failed] F043 — Failed: <blocker>`

5. **Continue** to the next finding. Do NOT stop on a failure — continue processing remaining findings so the user gets a full picture.

### Path B — Parallel Execution (`PARALLEL_MODE=true`)

Process batches sequentially; within each batch, dispatch all review-fixer agents in parallel.

For each batch:

1. **Dispatch review-fixer agents in parallel** — Use a **SINGLE message** with **MULTIPLE `Agent` tool calls**, one per finding or same-file group in the batch:
   - `subagent_type`: `"ycc:review-fixer"`
   - `description`: e.g., `"Fix F042: missing null check in payments.ts"`
   - `prompt`: The Finding spec (Shape A or Shape B) plus `SOURCE REVIEW FILE` and `PROJECT TYPE-CHECK COMMAND`

2. **Wait for all agents in the batch to complete** before proceeding.

3. **Collect results and update the review file**:
   - For each `STATUS: Fixed` → `Edit` the review file to update that finding's `**Status**: Open` → `**Status**: Fixed`
   - For each `STATUS: Failed` → `Edit` the review file to update that finding's `**Status**: Open` → `**Status**: Failed`

4. **Between-batch validation (Levels 1 + 2)** — After each batch (except the last), run:

   ```bash
   $TYPECHECK_CMD
   $TEST_CMD
   ```

   - If both pass: log `[done] Batch N: K fixes — validation pass` and proceed.
   - If either fails: **STOP** the parallel pipeline. Report which batch broke validation. Use `AskUserQuestion` to ask:
     - "Resume sequentially from next batch"
     - "Abort and leave current state as-is"
     - "Skip remaining findings and jump to Phase 5 (verify + report)"

5. **Track progress** in todos per batch, not per finding.

### Handling failures

If a `ycc:review-fixer` agent returns `STATUS: Failed`:

- **Do NOT retry** the same fix automatically. The agent already judged the Suggested fix to be incompatible.
- Mark the finding as `Failed` in the review file.
- Include the agent's `BLOCKER` and `RECOMMENDATION` in the fix report.
- Continue with remaining findings.

**CHECKPOINT**: All eligible batches processed. Review file updated with Fixed/Failed statuses. Deviations logged.

---

## Phase 5 — VERIFY

Run project-level validation on the final state:

```bash
$TYPECHECK_CMD
$TEST_CMD
```

Record pass/fail for each. Do NOT rollback fixes on failure — the user decides what to do. This phase is diagnostic: it tells the user whether the codebase is in a good state after all fixes landed.

---

## Phase 6 — REPORT

### Create the fix report

```bash
mkdir -p docs/prps/reviews/fixes
```

Derive the report filename from the source review:

| Source                                              | Report                                                   |
| --------------------------------------------------- | -------------------------------------------------------- |
| `docs/prps/reviews/pr-42-review.md`                 | `docs/prps/reviews/fixes/pr-42-fixes.md`                 |
| `docs/prps/reviews/local-20260408-143022-review.md` | `docs/prps/reviews/fixes/local-20260408-143022-fixes.md` |

### Report template

```markdown
# Fix Report: <source-name>

**Source**: <source review path>
**Applied**: <ISO date>
**Mode**: Sequential | Parallel (N batches, max width W)
**Severity threshold**: <CRITICAL|HIGH|MEDIUM|LOW>

## Summary

- **Total findings in source**: N
- **Already processed before this run**:
  - Fixed: A
  - Failed: B
- **Eligible this run**: M
- **Applied this run**:
  - Fixed: X
  - Failed: Y
- **Skipped this run**:
  - Below severity threshold: C
  - No suggested fix: D
  - Missing file: E

## Fixes Applied

| ID   | Severity | File             | Line | Status | Notes                                                               |
| ---- | -------- | ---------------- | ---- | ------ | ------------------------------------------------------------------- |
| F001 | CRITICAL | src/auth.ts      | 42   | Fixed  |                                                                     |
| F002 | HIGH     | src/api.ts       | 17   | Fixed  |                                                                     |
| F003 | HIGH     | src/db/query.ts  | 8    | Failed | Type error after edit; suggested fix referenced non-existent method |
| F005 | HIGH     | src/utils/fmt.ts | 112  | Fixed  | Same-file group with F004                                           |
| F004 | HIGH     | src/utils/fmt.ts | 78   | Fixed  | Processed in descending line order                                  |

## Files Changed

- `src/auth.ts` (Fixed F001)
- `src/api.ts` (Fixed F002)
- `src/utils/fmt.ts` (Fixed F004, F005)

## Failed Fixes

### F003 — `src/db/query.ts:8`

**Severity**: HIGH
**Category**: Security
**Description**: Unescaped input in raw SQL query
**Suggested fix (from review)**: Use `db.query('... WHERE id = $1', [userId])`
**Blocker**: `Property 'query' does not exist on type 'Connection'`. The connection type in this codebase exposes `execute`, not `query`.
**Recommendation**: Update the review's Suggested fix to use `db.execute(...)` and re-run `/ycc:review-fix`.

## Validation Results

| Check      | Result                |
| ---------- | --------------------- |
| Type check | Pass / Fail / Skipped |
| Tests      | Pass / Fail / Skipped |

## Next Steps

- Re-run `/ycc:code-review <same target>` to verify the remaining open findings and confirm fixes resolved the issues
- Address failed fixes manually using the Blocker + Recommendation notes above
- Run `/ycc:git-workflow` to commit the changes when satisfied
```

---

## Phase 7 — OUTPUT

Report to the user:

```
## Review Fixes Complete

**Source**: <source review path>
**Report**: docs/prps/reviews/fixes/<name>-fixes.md
**Mode**: Sequential | Parallel (N batches, max width W)

### This Run
- Eligible: M
- Fixed:    X
- Failed:   Y
- Skipped:  C (below threshold) + D (no suggestion) + E (missing file)

### Source Review File Updated
The source review at <path> has been updated in place:
  F001..F00X are now marked Status: Fixed
  F00Y..F00Z are now marked Status: Failed
  All other findings remain Status: Open

### Validation
  Type check: <Pass|Fail>
  Tests:      <Pass|Fail>

### Next Steps
  /ycc:code-review <same target>   # re-review to verify fixes landed
  /ycc:git-workflow                # commit the fixes when satisfied
```

---

## Handling Edge Cases

### No `Status` field on a finding

The review artifact format requires `Status` on every finding. If a finding lacks a `Status` line, treat it as `Status: Open` but print a warning:

```
Warning: Finding F### has no Status field. Treating as Open.
Fix the source review file format — see the Review Artifact Format section of /ycc:code-review.
```

### File was modified between review and fix

If the finding's line number no longer points to the described code (because the file changed since the review was written), the `ycc:review-fixer` agent will detect this and return `STATUS: Failed` with a stale-line blocker. Mark the finding as `Failed` in the review file and include "stale line — file modified since review" in the report notes.

### Review file points to a deleted file

Covered by the missing-file filter in Phase 2. Skipped, not Failed.

### Fix introduces new findings

`/ycc:review-fix` does not recursively scan for new findings. Re-run `/ycc:code-review` after fixes to catch any regressions.

### User interrupts mid-run

The review file is updated incrementally after each agent returns, so if the run is interrupted, the file reflects the current partial state. Re-running `/ycc:review-fix` on the same review file will skip findings that are already `Fixed` or `Failed` and resume from the next `Open` one.

---

## Success Criteria

- **PLAN_VALID**: The fix plan respects same-file sequentialization and different-file parallelism
- **REVIEW_UPDATED**: Every attempted finding has its `Status` updated in the source review file
- **REPORT_CREATED**: A fix report is written to `docs/prps/reviews/fixes/`
- **VALIDATION_RUN**: Phase 5 type-check + tests completed (even if they failed)
- **NO_UNAUTHORIZED_COMMITS**: This skill never runs `git add`, `git commit`, or `git push`

---

## Comparison with related skills

| Skill                    | Purpose                                                                                          |
| ------------------------ | ------------------------------------------------------------------------------------------------ |
| `/ycc:code-review`       | Produces a review artifact with findings and `Status: Open`                                      |
| `/ycc:review-fix` (this) | Consumes a review artifact and applies fixes, updating `Status` to `Fixed` or `Failed`           |
| `/ycc:prp-implement`     | Executes a PRP plan file with per-task validation — a different workflow, different input format |
| `/ycc:git-workflow`      | Commits changes after fixes land                                                                 |

---

## Important Notes

- **In-place Status updates**: The source review file is the source of truth. This skill mutates it in place via `Edit`, updating only the `Status` line of each processed finding. All other content is preserved.
- **No scope creep**: Each `ycc:review-fixer` agent is scope-disciplined — it fixes exactly what the finding specifies. If the fix reveals a larger issue, the agent reports it, but the skill does not chase down related problems.
- **Resumable**: Re-running on the same review file skips already-processed findings.
- **Audit trail**: The combination of (a) updated source review file and (b) fix report gives a complete history of what was attempted, what succeeded, and why.
- **Parallel safety**: Parallel mode never dispatches two agents to the same file concurrently.
- **No auto-commit**: The skill reports success and suggests `/ycc:git-workflow` as the next step. It does not commit changes itself.
