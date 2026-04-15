---
name: prp-implement
description: Execute a PRP plan file with continuous validation loops. Detects package
  manager, prepares git branch, processes tasks with per-task validation, runs all
  5 validation levels (static, unit, build, integration, edge cases), writes an implementation
  report to docs/prps/reports/, and archives the plan. Auto-detects parallel-capable
  plans (those with a Batches section and Depends on annotations) and prompts the
  user to choose sequential or parallel execution. Pass `--parallel` to skip the prompt
  and run tasks in parallel via standalone implementor sub-agents. Pass `--team`
  (Codex only) to run the same per-batch implementor fan-out under a shared create
  an agent group/the task tracker with up-front dependency wiring (`addBlockedBy`)
  and coordinated per-batch shutdown via send follow-up instructions. `--parallel`
  and `--team` are mutually exclusive.
---

# PRP Implement

Execute a plan file step-by-step with continuous validation. Every change is verified immediately — never accumulate broken state.

> Adapted from PRPs-agentic-eng by Wirasm. Part of the PRP workflow series.

**Core Philosophy**: Validation loops catch mistakes early. Run checks after every change. Fix issues immediately.

**Golden Rule**: If a validation fails, fix it before moving on. Never accumulate broken state.

---

## Phase 0 — DETECT

### Flag Parsing

Extract flags from `$ARGUMENTS` before treating the remainder as a plan path:

| Flag         | Effect                                                                                                                                                                                                                                                                                                                                                            |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--parallel` | Force parallel execution via **standalone sub-agents** when the plan is parallel-capable. Skips the interactive prompt. Falls back to sequential with a warning if the plan has no `Batches` section. Works in Codex, Cursor, and Codex.                                                                                                                          |
| `--team`     | (Codex only) Force parallel execution via an **agent team** with up-front `record the task` + `addBlockedBy` dependency wiring, per-batch teammate spawn, and inter-batch shutdown via `send follow-up instructions`. Aborts (does NOT fall back) if the plan has no `Batches` section. Heavier dispatch with shared task-graph observability across all batches. |
| `--dry-run`  | Only valid with `--team`. Prints the team name, full task graph (with dependencies), and per-batch teammate roster, then exits without spawning any teammates.                                                                                                                                                                                                    |

Strip the flags from `$ARGUMENTS` and set `PARALLEL_FLAG=true|false`, `AGENT_TEAM_FLAG=true|false`, `DRY_RUN=true|false`. The remaining text is the plan file path.

**Validation**:

- `--parallel` and `--team` are **mutually exclusive**. If both are passed → abort with: `--parallel and --team are mutually exclusive. Pick one.`
- `--dry-run` requires `--team`. If `DRY_RUN=true` and `AGENT_TEAM_FLAG=false` → abort with: `--dry-run requires --team.`

**Compatibility note**: When this skill is invoked from a Cursor or Codex bundle, `--team` must not be used (those bundles ship without team tools). Use `--parallel` instead.

### Package Manager Detection

| File Exists                            | Package Manager | Runner                  |
| -------------------------------------- | --------------- | ----------------------- |
| `bun.lockb`                            | bun             | `bun run`               |
| `pnpm-lock.yaml`                       | pnpm            | `pnpm run`              |
| `yarn.lock`                            | yarn            | `yarn`                  |
| `package-lock.json`                    | npm             | `npm run`               |
| `pyproject.toml` or `requirements.txt` | uv / pip        | `uv run` or `python -m` |
| `Cargo.toml`                           | cargo           | `cargo`                 |
| `go.mod`                               | go              | `go`                    |

### Validation Scripts

Check `package.json` (or equivalent) for available scripts:

```bash
cat package.json | grep -A 20 '"scripts"'
```

Note available commands for: type-check, lint, test, build.

---

## Phase 1 — LOAD

Read the plan file:

```bash
cat "$ARGUMENTS"
```

Extract these sections from the plan:

- **Summary** — What is being built
- **Patterns to Mirror** — Code conventions to follow
- **Files to Change** — What to create or modify
- **Step-by-Step Tasks** — Implementation sequence
- **Validation Commands** — How to verify correctness
- **Acceptance Criteria** — Definition of done

If the file doesn't exist or isn't a valid plan:

```
Error: Plan file not found or invalid.
Run $prp-plan <feature-description> to create a plan first.
```

### Parallel-Capable Detection

After reading the plan, check whether it was written in parallel mode by looking for a `## Batches` section:

```bash
grep -c "^## Batches" "$PLAN_PATH" || echo 0
```

- **Count > 0** → Plan is **parallel-capable**. Parse the `Batches` table to extract batch ordering and `BATCH:` fields from tasks.
- **Count = 0** → Plan is **sequential only**.

### Execution Mode Decision

Decide between **Path A (Sequential)**, **Path B (Parallel sub-agents)**, and **Path C (Agent team)** based on the flags and plan capability:

| Flags        | Parallel-capable plan | Action                                                                                                                                                                                                                                                     |
| ------------ | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--team`     | Yes                   | Proceed with **Path C** (agent-team batch execution) — no prompt                                                                                                                                                                                           |
| `--team`     | No                    | **Abort** with: _"`--team` requires a parallel-capable plan (with `## Batches` section). This plan is sequential — re-run with `--parallel` to fall back to standalone sub-agents, or omit the flag for sequential execution."_ Do NOT silently fall back. |
| `--parallel` | Yes                   | Proceed with **Path B** (parallel sub-agent batch execution) — no prompt                                                                                                                                                                                   |
| `--parallel` | No                    | Warn: _"Plan has no `Batches` section — cannot run in parallel. Falling back to sequential execution."_ → **Path A**                                                                                                                                       |
| (none)       | Yes                   | Use `ask the user` to prompt: _"This plan is parallel-capable ({N} tasks in {M} batches, max width {X}). Run sequential / parallel sub-agents / agent team?"_. Accept user's choice → **Path A**, **Path B**, or **Path C**.                               |
| (none)       | No                    | Proceed with **Path A** (sequential) — default, no prompt                                                                                                                                                                                                  |

Record the chosen mode as `EXECUTION_MODE=sequential|parallel|agent_team` for use in Phase 3.

**CHECKPOINT**: Plan loaded. All sections identified. Tasks extracted. Parallel capability detected. Execution mode chosen.

---

## Phase 2 — PREPARE

### Git State

```bash
git branch --show-current
git status --porcelain
```

### Branch Decision

| Current State                      | Action                                                    |
| ---------------------------------- | --------------------------------------------------------- |
| On feature branch                  | Use current branch                                        |
| On main, clean working tree        | Create feature branch: `git checkout -b feat/{plan-name}` |
| On main, dirty working tree        | **STOP** — Ask user to stash or commit first              |
| In a git worktree for this feature | Use the worktree                                          |

### Sync Remote

```bash
git pull --rebase origin $(git branch --show-current) 2>/dev/null || true
```

**CHECKPOINT**: On correct branch. Working tree ready. Remote synced.

---

## Phase 3 — EXECUTE

Branch based on `EXECUTION_MODE` from Phase 1.

### Path A — Sequential Execution (`EXECUTION_MODE=sequential`)

Process each task from the plan sequentially.

#### Per-Task Loop

For each task in **Step-by-Step Tasks**:

1. **Read MIRROR reference** — Open the pattern file referenced in the task's MIRROR field. Understand the convention before writing code.
2. **Implement** — Write the code following the pattern exactly. Apply GOTCHA warnings. Use specified IMPORTS.
3. **Validate immediately** — After EVERY file change:

   ```bash
   # Run type-check (adjust command per project)
   [type-check command from Phase 0]
   ```

   If type-check fails → fix the error before moving to the next file.

4. **Track progress** — Log: `[done] Task N: [task name] — complete`

### Path B — Parallel Batch Execution (`EXECUTION_MODE=parallel`)

Process batches sequentially. Within each batch, dispatch one `implementor` agent per task in parallel.

#### Per-Batch Loop

For each batch `B1, B2, ... BN` in order (from the plan's `Batches` table):

1. **Identify batch tasks** — Extract all tasks with `BATCH: BN` from the Step-by-Step Tasks section.

2. **Dispatch implementor agents in parallel** — Use a **SINGLE message** with **MULTIPLE `Agent` tool calls**, one per task in the batch. Each call:
   - `subagent_type`: `"implementor"`
   - `description`: The task title (e.g., `"Task 1.1: add rate limiter middleware"`)
   - `prompt`: The complete task spec (ACTION, IMPLEMENT, MIRROR, IMPORTS, GOTCHA, VALIDATE) plus the relevant excerpt from the plan's **Patterns to Mirror** section. Include a directive that the agent must read the MIRROR source file before writing code and must run its own type-check on modified files before reporting complete.

3. **Wait for all agents in the batch to complete** before proceeding.

4. **Between-batch validation (Levels 1 + 2)** — After each batch (including between-batches, not just at the end), run:

   ```bash
   # Level 1: Type-check — zero errors required
   [type-check command from Phase 0]

   # Level 2: Unit tests — affected area must be green
   [test command from Phase 0]
   ```

   - **If either fails**: **STOP** the parallel pipeline. Do NOT dispatch the next batch.
   - Report which batch failed and which type errors / test failures occurred.
   - Use `ask the user` to ask the user: _"Batch {BN} validation failed. Choose: (1) fix manually and resume from batch {BN+1}, (2) switch to sequential mode for remaining batches, (3) abort."_
   - Apply the user's choice.

5. **Track progress** — Log: `[done] Batch BN: K tasks — complete (type-check + tests pass)`

#### Handling Parallel Failures

If a batch fails validation:

- **Do NOT auto-retry** — parallel failures are often file conflicts or missing dependencies between supposedly-independent tasks, which won't resolve by retrying
- **Do NOT skip the failing batch** — tasks in later batches may depend on it
- Preserve all completed work; git state reflects whatever was successfully committed
- The user decides whether to resume, switch modes, or abort

#### After All Batches Complete

Proceed to **Phase 4 — VALIDATE** and run the full 5-level validation as normal. Between-batch validation only covered Levels 1 + 2; Phase 4 still runs Levels 3 (build), 4 (integration), and 5 (edge cases).

### Path C — Agent Team Batch Execution (`EXECUTION_MODE=agent_team`)

> **MANDATORY — AGENT TEAMS REQUIRED**
>
> In Path C you MUST follow the agent-team lifecycle. Do NOT mix standalone sub-agents
> with team dispatch. Every `Agent` call below MUST include `name=` AND `name=`.
>
> 1. `create an agent group` ONCE at the start (single team across all batches)
> 2. `record the task` for **every task across all batches** up front, with `addBlockedBy`
>    wiring the dependency graph from the plan's `Depends on` annotations
> 3. Per batch: spawn teammates (single message, multiple `Agent` calls with
>    `name=` + `name=`)
> 4. `the task tracker` to monitor batch completion; run between-batch validation
> 5. `send follow-up instructions({type:"shutdown_request"})` to all teammates of completed batch
>    BEFORE spawning next batch
> 6. `close the agent group` ONCE after final batch (or on abort)
>
> If `create an agent group` or up-front `record the task` fails, abort the skill. Refer to
> `~/.codex/plugins/ycc/shared/references/agent-team-dispatch.md`
> for the full lifecycle contract.

Process batches sequentially under a single team, with per-batch teammate spawn and
inter-batch shutdown.

#### C.1 Build the team name

Sanitize the plan basename (strip `.plan.md`, lowercase, kebab, max **20 chars**, fall
back to `untitled`). Team name: `prpi-<sanitized-plan-basename>`.

#### C.2 Dry-run gate (if `DRY_RUN=true`)

Print:

```
Team name:    prpi-<sanitized-plan-basename>
Total tasks:  <N>  (across <M> batches, max parallel width <X>)
Dependencies: <K edges>  (from plan's `Depends on` annotations)

Batch 1: <comma-separated task IDs>
Batch 2: <comma-separated task IDs>  (depends on Batch 1)
...
Batch M: <comma-separated task IDs>  (depends on Batch M-1)

Per-batch teammate roster:
  Batch 1:
    - <task-id-1>  subagent_type=implementor  task=<short>
    - <task-id-2>  subagent_type=implementor  task=<short>
  ...
```

Do **not** call any team/task/agent tools. Exit the skill.

#### C.3 Create the team

```
create an agent group: name="prpi-<sanitized-plan-basename>", description="PRP-implement team for: <plan basename>"
```

On failure, abort.

#### C.4 Register ALL tasks up front with dependency graph

For **every task across all batches** in the plan's Step-by-Step Tasks section:

```
record the task: subject="<task-id>: <task title>", description="<full spec — ACTION, IMPLEMENT, MIRROR, IMPORTS, GOTCHA, VALIDATE>"
```

Then wire dependencies — for each task `T` with a `Depends on [X, Y, Z]` annotation:

```
update the task tracker: taskId="<T-id>", addBlockedBy=["<X-id>", "<Y-id>", "<Z-id>"]
```

This populates the shared task graph **once**, not per batch. Subsequent batches can
read `the task tracker` to confirm prerequisites are complete.

If any `record the task` or `update the task tracker` fails → `close the agent group`, then abort.

#### C.5 Per-batch loop

For each batch `B1, B2, ... BN` in order (from the plan's `Batches` table):

1. **Identify batch tasks** — Extract all tasks with `BATCH: BN` from the
   Step-by-Step Tasks section.

2. **Spawn batch teammates** — Single message, multiple `Agent` tool calls, one per
   task in the batch. Every call MUST include:
   - `team_name`: `"prpi-<sanitized-plan-basename>"`
   - `name`: the task ID (e.g., `"1.1"`, `"2.3"`) — must match the `record the task`
     subject prefix
   - `subagent_type`: `"implementor"`
   - `description`: The task title
   - `prompt`: The complete task spec (ACTION, IMPLEMENT, MIRROR, IMPORTS, GOTCHA,
     VALIDATE) plus the relevant excerpt from the plan's **Patterns to Mirror**
     section. Include a directive that the agent must read the MIRROR source file
     before writing code, must run its own type-check on modified files before
     reporting complete, and must call `update the task tracker` to mark its task complete.

3. **Wait for batch completion via `the task tracker`** — poll until all tasks in this batch
   are `completed`. If a teammate messages with an issue, respond via `send follow-up instructions`
   with guidance.

4. **Between-batch validation (Levels 1 + 2)** — Run the same type-check and unit-test
   commands as Path B. On failure, **STOP** the parallel pipeline and ask the user via
   `ask the user`: _"Batch {BN} validation failed. Choose: (1) fix manually and
   resume from batch {BN+1}, (2) switch to sequential mode for remaining batches,
   (3) abort."_
   - If user picks (2) **switch to sequential**: send `send follow-up instructions(shutdown)` to all
     teammates of the failed batch, `close the agent group`, then continue with Path A logic
     for remaining batches.
   - If user picks (3) **abort**: send `send follow-up instructions(shutdown)` to all teammates,
     `close the agent group`, then exit.
   - If user picks (1) **resume**: wait for the user to fix; on resume, send
     `send follow-up instructions(shutdown)` to current batch teammates and proceed to Step 5.

5. **Shut down completed-batch teammates** — Send to every teammate of the just-completed
   batch:

   ```
   send follow-up instructions(to="<task-id>", message={type:"shutdown_request"})
   ```

   Wait for shutdowns to complete before spawning the next batch's teammates.

6. **Track progress** — Log: `[done] Batch BN: K tasks — complete (type-check + tests pass)`

#### C.6 After all batches complete

`close the agent group` once. Then proceed to **Phase 4 — VALIDATE** and run the full 5-level
validation as normal. Between-batch validation only covered Levels 1 + 2; Phase 4 still
runs Levels 3 (build), 4 (integration), and 5 (edge cases).

#### Path C failure handling

Same principles as Path B: do NOT auto-retry, do NOT skip a failed batch. Always
shut down teammates and `close the agent group` before exiting, regardless of success or failure.

### Handling Deviations

If implementation must deviate from the plan:

- Note **WHAT** changed
- Note **WHY** it changed
- Continue with the corrected approach
- These deviations will be captured in the report
- In parallel and agent-team modes, deviations reported by individual implementor agents are collected and included verbatim in the final report

**CHECKPOINT**: All tasks executed. Deviations logged.

---

## Phase 4 — VALIDATE

Run all validation levels from the plan. Fix issues at each level before proceeding.

### Level 1: Static Analysis

```bash
# Type checking — zero errors required
[project type-check command]

# Linting — fix automatically where possible
[project lint command]
[project lint-fix command]
```

If lint errors remain after auto-fix, fix manually.

### Level 2: Unit Tests

Write tests for every new function (as specified in the plan's Testing Strategy).

```bash
[project test command for affected area]
```

- Every function needs at least one test
- Cover edge cases listed in the plan
- If a test fails → fix the implementation (not the test, unless the test is wrong)

### Level 3: Build Check

```bash
[project build command]
```

Build must succeed with zero errors.

### Level 4: Integration Testing (if applicable)

```bash
# Start server, run tests, stop server
[project dev server command] &
SERVER_PID=$!

# Wait for server to be ready (adjust port as needed)
SERVER_READY=0
for i in $(seq 1 30); do
  if curl -sf http://localhost:PORT/health >/dev/null 2>&1; then
    SERVER_READY=1
    break
  fi
  sleep 1
done

if [ "$SERVER_READY" -ne 1 ]; then
  kill "$SERVER_PID" 2>/dev/null || true
  echo "ERROR: Server failed to start within 30s" >&2
  exit 1
fi

[integration test command]
TEST_EXIT=$?

kill "$SERVER_PID" 2>/dev/null || true
wait "$SERVER_PID" 2>/dev/null || true

exit "$TEST_EXIT"
```

### Level 5: Edge Case Testing

Run through edge cases from the plan's Testing Strategy checklist.

**CHECKPOINT**: All 5 validation levels pass. Zero errors.

---

## Phase 5 — REPORT

### Create Implementation Report

```bash
mkdir -p docs/prps/reports
```

Write report to `docs/prps/reports/{plan-name}-report.md`:

```markdown
# Implementation Report: [Feature Name]

## Summary

[What was implemented]

## Assessment vs Reality

| Metric        | Predicted (Plan) | Actual         |
| ------------- | ---------------- | -------------- |
| Complexity    | [from plan]      | [actual]       |
| Confidence    | [from plan]      | [actual]       |
| Files Changed | [from plan]      | [actual count] |

## Tasks Completed

| #   | Task        | Status          | Notes               |
| --- | ----------- | --------------- | ------------------- |
| 1   | [task name] | [done] Complete |                     |
| 2   | [task name] | [done] Complete | Deviated — [reason] |

## Validation Results

| Level           | Status      | Notes           |
| --------------- | ----------- | --------------- |
| Static Analysis | [done] Pass |                 |
| Unit Tests      | [done] Pass | N tests written |
| Build           | [done] Pass |                 |
| Integration     | [done] Pass | or N/A          |
| Edge Cases      | [done] Pass |                 |

## Files Changed

| File           | Action  | Lines   |
| -------------- | ------- | ------- |
| `path/to/file` | CREATED | +N      |
| `path/to/file` | UPDATED | +N / -M |

## Deviations from Plan

[List any deviations with WHAT and WHY, or "None"]

## Issues Encountered

[List any problems and how they were resolved, or "None"]

## Tests Written

| Test File      | Tests   | Coverage       |
| -------------- | ------- | -------------- |
| `path/to/test` | N tests | [area covered] |

## Next Steps

- [ ] Code review via `$code-review`
- [ ] Create PR via `$prp-pr`
```

### Update PRD (if applicable)

If this implementation was for a PRD phase:

1. Update the phase status from `in-progress` to `complete`
2. Add report path as reference

### Archive Plan

```bash
mkdir -p docs/prps/plans/completed
mv "$ARGUMENTS" docs/prps/plans/completed/
```

**CHECKPOINT**: Report created. PRD updated. Plan archived.

---

## Phase 6 — OUTPUT

Report to user:

```
## Implementation Complete

- **Plan**: [plan file path] → archived to completed/
- **Branch**: [current branch name]
- **Mode**: [Sequential | Parallel sub-agents (N batches, max width X) | Agent team (N batches, max width X)]
- **Status**: [done] All tasks complete

### Validation Summary

| Check       | Status               |
| ----------- | -------------------- |
| Type Check  | [done]               |
| Lint        | [done]               |
| Tests       | [done] (N written)   |
| Build       | [done]               |
| Integration | [done] or N/A        |

### Files Changed

- [N] files created, [M] files updated

### Deviations

[Summary or "None — implemented exactly as planned"]

### Artifacts

- Report: `docs/prps/reports/{name}-report.md`
- Archived Plan: `docs/prps/plans/completed/{name}.plan.md`

### PRD Progress (if applicable)

| Phase   | Status         |
| ------- | -------------- |
| Phase 1 | [done] Complete |
| Phase 2 | [next]         |
| ...     | ...            |

> Next step: Run `$prp-pr` to create a pull request, or `$code-review` to review changes first.
```

---

## Handling Failures

### Type Check Fails

1. Read the error message carefully
2. Fix the type error in the source file
3. Re-run type-check
4. Continue only when clean

### Tests Fail

1. Identify whether the bug is in the implementation or the test
2. Fix the root cause (usually the implementation)
3. Re-run tests
4. Continue only when green

### Lint Fails

1. Run auto-fix first
2. If errors remain, fix manually
3. Re-run lint
4. Continue only when clean

### Build Fails

1. Usually a type or import issue — check error message
2. Fix the offending file
3. Re-run build
4. Continue only when successful

### Integration Test Fails

1. Check server started correctly
2. Verify endpoint/route exists
3. Check request format matches expected
4. Fix and re-run

---

## Success Criteria

- **TASKS_COMPLETE**: All tasks from the plan executed
- **TYPES_PASS**: Zero type errors
- **LINT_PASS**: Zero lint errors
- **TESTS_PASS**: All tests green, new tests written
- **BUILD_PASS**: Build succeeds
- **REPORT_CREATED**: Implementation report saved
- **PLAN_ARCHIVED**: Plan moved to `docs/prps/plans/completed/`

---

## Next Steps

- Run `$code-review` to review changes before committing
- Run `$prp-commit` to commit with a descriptive message
- Run `$prp-pr` to create a pull request
- Run `$prp-plan <next-phase>` if the PRD has more phases

---

## Agent Team Lifecycle Reference

For Path C's team lifecycle contract (sanitization, shutdown sequence, failure policy,
multi-batch reuse pattern), refer to:

```
~/.codex/plugins/ycc/shared/references/agent-team-dispatch.md
```
