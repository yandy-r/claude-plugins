---
name: quick-review
description: Fast interactive review of uncommitted changes. Prints findings inline
  (no file written by default), then asks Apply fixes / Save to file / Discard. Writing
  only happens on confirmation. Hands off to $review-fix on "Apply fixes". Designed
  for short, low-friction code changes where opening a full $code-review artifact
  is overkill. Pass `--parallel` to fan out across 3 standalone code-reviewer sub-agents
  (correctness, security, quality). Pass `--team` (Codex runtime only; not available
  in bundle invocations) for the same fan-out as a coordinated agent team. `--parallel`
  and `--team` are mutually exclusive. Pass `--yes` to auto-confirm (Apply fixes)
  or `--save` to auto-confirm (Save to file) for scripted use. Pass `--severity <CRITICAL|HIGH|MEDIUM|LOW>`
  to forward the minimum severity threshold to $review-fix (default HIGH). Use when
  the user asks to "quick review", "fast review", "review what I have", "on-the-fly
  review", or says "/quick-review". `$code-review --quick` delegates here.
---

# Quick Review

Interactive low-friction review of uncommitted changes. Output is **inline**;
a review artifact is only written on confirmation.

**Input**: `$ARGUMENTS`

**Core rule**: You will **NOT** write a review artifact until the user
explicitly selects "Apply fixes" or "Save to file". "Discard" writes nothing.

---

## Phase 0 — Parse flags

Extract flags from `$ARGUMENTS`:

| Flag                 | Effect                                                                                                                                                                                                    |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--parallel`         | Fan out REVIEW across 3 standalone `code-reviewer` sub-agents (correctness, security, quality) and merge findings. Works in Claude Code, Cursor, and Codex bundles.                                   |
| `--team`             | (Codex runtime only; not available in bundle invocations) Same 3-reviewer fan-out as a coordinated agent team with `create an agent group`, shared `the task tracker`, per-reviewer `record the task`, and coordinated shutdown. Heavier dispatch, richer communication. |
| `--yes`              | Skip the confirmation prompt in Phase 4 and behave as "Apply fixes". Mutually exclusive with `--save`.                                                                                                    |
| `--save`             | Skip the confirmation prompt in Phase 4 and behave as "Save to file" (write artifact, print Next steps, exit). Mutually exclusive with `--yes`.                                                           |
| `--severity <level>` | Forwarded to `$review-fix` during hand-off. Valid: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`. Default: `HIGH`. Ignored on "Save to file" / "Discard".                                                       |
| `--no-worktree`      | Accepted as a **no-op**. Quick mode never creates a worktree. Emit a note: `--no-worktree has no effect in quick mode.`                                                                                   |

Strip these from `$ARGUMENTS` and set `PARALLEL_MODE`, `AGENT_TEAM_MODE`,
`AUTO_YES`, `AUTO_SAVE`, and `MIN_SEVERITY` (default `HIGH`). The remaining
text MUST be empty; if not, abort with:

```
Error: $quick-review takes no positional argument (only flags).
```

**Validation**:

- `--parallel` and `--team` mutually exclusive → abort with: `--parallel and --team are mutually exclusive. Pick one.`
- `--yes` and `--save` mutually exclusive → abort with: `--yes and --save are mutually exclusive. Pick one.`
- `--team` in a Cursor/Codex bundle (no `create an agent group` tool) → abort with: `--team is not supported in bundle invocations; use --parallel instead.`
- `--severity` value not one of `CRITICAL|HIGH|MEDIUM|LOW` → abort with: `Invalid --severity value. Use CRITICAL, HIGH, MEDIUM, or LOW.`

---

## Phase 1 — GATHER

```bash
git diff --name-only HEAD
```

If the output is empty, print `Nothing to review.` and exit. Do NOT prompt,
do NOT write anything.

Capture the list of changed files as `CHANGED_FILES` for the REVIEW phase.

---

## Phase 2 — REVIEW

The shape of this phase depends on `PARALLEL_MODE` and `AGENT_TEAM_MODE`:

| Flags             | Path                                        |
| ----------------- | ------------------------------------------- |
| Neither set       | **Path A** — single-pass review (default)   |
| `PARALLEL_MODE`   | **Path B** — 3 parallel sub-agent reviewers |
| `AGENT_TEAM_MODE` | **Path C** — 3-reviewer agent team          |

Findings from all paths stay **in memory** — do not write to disk yet.

### Path A — Single-Pass Review (default)

Read each changed file in full and apply the **Local / Quick Review —
Single-Pass Checklist** and **Severity Rubric** from:

```
~/.codex/plugins/ycc/shared/references/review-checklist.md
```

### Path B — Parallel Sub-Agent Review (`PARALLEL_MODE=true`)

Dispatch **3 standalone `code-reviewer` sub-agents in parallel** in a SINGLE
message with MULTIPLE `Agent` tool calls. Use the **Local / Quick Mode Roster**
and **Standard Findings Format** from:

```
~/.codex/plugins/ycc/shared/references/review-checklist.md
```

Each reviewer prompt must include:

1. The list of changed files (`git diff --name-only HEAD`)
2. Its assigned focus and checklist items (from the roster table)
3. The severity rubric
4. A directive to return findings in the Standard Findings Format

Apply the **Merge Procedure** defined in the reference to produce a single
combined findings list for Phase 3.

### Path C — Agent Team Review (`AGENT_TEAM_MODE=true`, Codex runtime only; not available in bundle invocations)

> **MANDATORY — AGENT TEAMS REQUIRED**
>
> You MUST follow the agent-team lifecycle. Every `Agent` call MUST include
> `team_name=` AND `name=`. See
> `~/.codex/plugins/ycc/shared/references/agent-team-dispatch.md`.

Roster and category split identical to Path B.

#### C.1 Build the team name

Team name: `qrev-local-<YYYYMMDD-HHMMSS>`. Generate the timestamp once at the
start of Phase 2 and reuse it if the user later selects "Save to file" or
"Apply fixes" (for artifact filename consistency).

#### C.2 Create the team

```
create an agent group: team_name="qrev-local-<timestamp>", description="Quick review team for uncommitted local changes"
```

On failure, abort.

#### C.3 Register subtasks

Create 3 tasks in the shared task list (flat graph — reviewers are independent):

```
record the task: subject="correctness-reviewer: code-quality review of uncommitted changes", description="<full reviewer prompt>"
record the task: subject="security-reviewer: security review of uncommitted changes",        description="<full reviewer prompt>"
record the task: subject="quality-reviewer: best-practices review of uncommitted changes",   description="<full reviewer prompt>"
```

If any `record the task` fails → `close the agent group`, abort.

#### C.4 Spawn the 3 reviewers

Single message, three `Agent` calls. Every call MUST include `team_name`, `name`
(matching the `record the task` subject prefix), `subagent_type="code-reviewer"`,
description, and a prompt equivalent to Path B's reviewer prompt plus a note
that the teammate shares a task list with two siblings (name them) and may
`send follow-up instructions` them on overlaps, and must call `update the task tracker` to mark its task
complete before returning.

#### C.5 Monitor and collect results

Use `the task tracker` until all 3 tasks are `completed`. Failure policy:

- All 3 error → `close the agent group`, abort with a clear error.
- 1 or 2 error → record "partial review — {role} did not complete" and proceed
  with the remaining findings. Note the gap when printing inline.

#### C.6 Shutdown and cleanup

```
send follow-up instructions(to="correctness-reviewer", message={type:"shutdown_request"})
send follow-up instructions(to="security-reviewer",    message={type:"shutdown_request"})
send follow-up instructions(to="quality-reviewer",     message={type:"shutdown_request"})
close the agent group
```

Always `close the agent group` — even on abort or partial failure.

#### C.7 Merge findings

Apply the reference's Merge Procedure and pass the combined findings to Phase 3.

---

## Phase 3 — REPORT (inline)

Assign sequential finding IDs (`F001`, `F002`, …) ordered by severity
(CRITICAL first) then by file path. Every finding gets `Status: Open`.

Compute the finding counts by severity: `C`, `H`, `M`, `L`.

**Print** the review to stdout in the Review Artifact Format, **without**
writing a file. The printed block looks like:

```markdown
# Quick Review — Uncommitted Changes

**Reviewed**: <ISO date>
**Mode**: Quick (inline)
**Author**: local
**Branch**: <current-branch>
**Decision**: (pending user confirmation)

## Summary

<1–2 sentence overall assessment>

## Findings

### CRITICAL

- **[F001]** `file:line` — <description>
  - **Status**: Open
  - **Category**: <Security | Correctness | Code Quality | Best Practices>
  - **Suggested fix**: <concrete fix>

### HIGH

- **[F002]** ...
  - **Status**: Open
  - ...

### MEDIUM

- **[F003]** ...
  - **Status**: Open
  - ...

### LOW

- **[F004]** ...
  - **Status**: Open
  - ...

## Files Reviewed

- `file1.ts` (Modified)
- `file2.ts` (Added)
```

**Omissions** (vs. the standard Review Artifact Format): no
`## Worktree Setup` section (quick mode never creates a worktree) and no
`## Validation Results` section (quick mode does not run toolchain checks).

After the artifact block, print a one-line summary:

```
Findings: [C] {critical_count}  [H] {high_count}  [M] {medium_count}  [L] {low_count}
```

If the count is zero across all severities, skip Phase 4 entirely. Print
`No findings. Nothing to do.` and exit.

Otherwise continue to Phase 4.

---

## Phase 4 — DECIDE (confirmation)

If `AUTO_YES=true` → skip this phase, proceed directly to Phase 5 as if the
user selected "Apply fixes".

If `AUTO_SAVE=true` → skip this phase, proceed directly to Phase 5 as if the
user selected "Save to file".

Otherwise, ask the user with `ask the user`:

```
question: "What should I do with this review?"
header:   "Review action"
options:
  - label: "Apply fixes"
    description: "Write the review artifact to docs/prps/reviews/ and hand off to $review-fix (recommended)"
  - label: "Save to file"
    description: "Write the review artifact to docs/prps/reviews/ and stop — you can run $review-fix later"
  - label: "Discard"
    description: "Write nothing, exit"
```

Mark "Apply fixes" with `(Recommended)` in its label when
`critical_count + high_count > 0`; otherwise leave it unmarked.

**Text-mode fallback** (if `ask the user` is unavailable — Cursor/Codex
bundles without that tool): print the three choices explicitly and WAIT for
the user's next message. Parse their reply case-insensitively:

- `yes` / `apply` / `apply fixes` / `fix` → "Apply fixes"
- `save` / `save to file` / `write` / `file` → "Save to file"
- `no` / `discard` / `cancel` / `skip` → "Discard"
- Anything else → re-prompt once, then default to `Discard` if still ambiguous.

---

## Phase 5 — HAND-OFF

Branch on the user's selection (or the auto-confirm flag).

### Selection: "Discard"

Print `Discarded. No artifact written.` and exit. Do NOT write any file.

### Selection: "Save to file"

Write the artifact to disk using the Phase 3 content plus the canonical
header block:

```bash
mkdir -p docs/prps/reviews
TIMESTAMP=$(date +%Y%m%d-%H%M%S)    # reuse the Path C timestamp if set
REVIEW_FILE="docs/prps/reviews/quick-${TIMESTAMP}-review.md"
```

Write the same artifact content that was printed in Phase 3, but set
`**Decision**: COMMENT` in the header (since a review was produced but no
GitHub decision is being posted).

Print the Next steps block to stdout:

```
Quick review written to: docs/prps/reviews/quick-<TIMESTAMP>-review.md
Findings: [C] {critical_count}  [H] {high_count}  [M] {medium_count}  [L] {low_count}

Next steps:
  $review-fix docs/prps/reviews/quick-<TIMESTAMP>-review.md              # apply fixes {recommended_single if 1-2 Open findings}
  $review-fix docs/prps/reviews/quick-<TIMESTAMP>-review.md --parallel   # fan out fixes {recommended_parallel if 3+ Open across 2+ files}
```

Annotate ONE of the two commands with `# ← recommended`:

- 1–2 Open findings → recommend the single-pass form.
- 3+ Open findings spanning 2+ files → recommend the `--parallel` form.
- Otherwise default to the single-pass form.

Exit.

### Selection: "Apply fixes"

Step 1 — write the artifact to disk (same as "Save to file" above) so
`$review-fix` can parse and update it in place.

Step 2 — invoke the `review-fix` skill inline via the `Skill` tool:

- `skill`: `"review-fix"`
- `args`: `"<REVIEW_FILE> [--parallel] [--severity <level>]"` — always pass the
  explicit review path. Forward `--parallel` if `PARALLEL_MODE=true`. Forward
  `--severity <level>` when `MIN_SEVERITY != HIGH` (HIGH is the default on
  review-fix so omitting it produces the same behavior).

Step 3 — after the Skill call returns, print a one-line confirmation:

```
Fixes complete. Review artifact updated in place: docs/prps/reviews/quick-<TIMESTAMP>-review.md
```

Step 4 — exit.

**Note**: `--team` from quick-review is NOT forwarded to `$review-fix`
automatically. The review-phase fan-out is about finding issues quickly;
the fix phase has its own decision. If the user wants team-mode fixes they
can re-run `$review-fix <path> --team` themselves.

---

## Important Notes

- **No artifact until confirmation**: "Discard" MUST write nothing. "Save to
  file" and "Apply fixes" both write once, to the same canonical path.
- **Idempotent filename**: the `quick-{YYYYMMDD-HHMMSS}-review.md` pattern
  produces a new file per invocation — no overwrites.
- **Parity with `$code-review`**: the artifact format and finding schema
  are identical, so `$review-fix` consumes it unchanged.
- **Not a replacement for `$code-review`**: if you need toolchain
  validation (typecheck/lint/test/build), a `## Validation Results` block,
  worktree isolation, or a GitHub review posted, use `$code-review`
  without `--quick`.

---

## Integration with ycc

- `$code-review --quick` delegates to this skill.
- `$review-fix` consumes the written artifact.
- `$prp-commit` or `$git-workflow` can commit the fixes afterward.
