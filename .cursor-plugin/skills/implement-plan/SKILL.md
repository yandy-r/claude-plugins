---
name: implement-plan
description: Execute a parallel implementation plan by deploying implementor agents in dependency-resolved batches. Defaults to standalone sub-agents; pass --team (Claude Code only) to dispatch via an agent team with shared TaskList and up-front dependency wiring. Use as Step 3 after parallel-plan.
argument-hint: '[--team] [--dry-run] <feature-name>'
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
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - SendMessage
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(grep:*)
  - 'Bash(${CURSOR_PLUGIN_ROOT}/skills/implement-plan/scripts/*.sh:*)'
  - 'Bash(${CURSOR_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
---

# Parallel Plan Executor

Execute a parallel implementation plan by deploying implementor agents in dependency-resolved batches. This is **Step 3** of the planning workflow, transforming the plan into working code.

Parallelism is the baseline of this skill — every batch's tasks dispatch concurrently. The only choice is **how** the implementor agents are dispatched:

- **Standalone sub-agents** (default) — plain `Agent` calls per batch, no shared task list. Works in Claude Code, Cursor, and Codex.
- **Agent team** (`--team`, Claude Code only) — single `TeamCreate` with all tasks registered up front (`TaskCreate` + `addBlockedBy` for dependency wiring), per-batch teammate spawn, coordinated inter-batch shutdown via `SendMessage`, and `TeamDelete` at the end. Adds shared task-graph observability across all batches.

## Workflow Integration

This skill is the final step of the planning workflow. It requires `parallel-plan.md` from the parallel-plan skill.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ shared-context  │ ──▶ │  parallel-plan  │ ──▶ │  implement-plan │
│  (Step 1)       │     │  (Step 2)       │     │  (this skill)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
     Creates:                Creates:               Executes:
     shared.md              parallel-plan.md      parallel-plan.md
```

**If parallel-plan.md doesn't exist**, run `/parallel-plan [feature-name]` first.

## Arguments

**Target**: `$ARGUMENTS`

Parse flags first, then treat the remainder as the feature name:

- `--team` — (Claude Code only) Dispatch each batch's implementor agents under a shared `TeamCreate` with up-front `TaskCreate` + `addBlockedBy` dependency wiring and per-batch shutdown via `SendMessage`. Aborts if invoked from a Cursor or Codex bundle (team tools are absent there).
- `--dry-run` — Show the execution plan without deploying agents. With `--team`, also prints the team name and per-batch teammate roster.
- `<feature-name>` — The name of the feature to implement (matches directory name in `docs/plans/`).

Strip the flags from `$ARGUMENTS` and set `TEAM_FLAG=true|false`, `DRY_RUN=true|false`. The remaining non-flag token is the feature name.

If no feature name is provided after stripping flags, abort with usage instructions:

```
Usage: /implement-plan [--team] [--dry-run] <feature-name>

Examples:
  /implement-plan user-authentication
  /implement-plan --team user-authentication
  /implement-plan --dry-run payment-integration
  /implement-plan --team --dry-run payment-integration
```

**Compatibility note**: When this skill is invoked from a Cursor or Codex bundle, `--team` must abort with a clear message. Those bundles ship without team tools (`TeamCreate`, `TaskCreate`, `SendMessage`, etc.). The default standalone sub-agent path is the only execution mode available there.

---

## Phase 0: Prerequisites Check

### Step 1: Validate Prerequisites

After flag parsing, extract the feature name (first non-flag argument).

Run the prerequisites check script:

```bash
${CURSOR_PLUGIN_ROOT}/skills/implement-plan/scripts/check-prerequisites.sh [feature-name]
```

If the script exits with error:

- Display the error message
- Instruct user to run `/parallel-plan` first to create the implementation plan
- **STOP HERE** - do not proceed

### Step 2: Read Planning Documents

Read the essential planning documents:

1. `docs/plans/[feature-name]/parallel-plan.md` - The implementation plan
2. `docs/plans/[feature-name]/shared.md` - Architecture context

Also read files listed in the "Critically Relevant Files" section of parallel-plan.md.

---

## Phase 1: Parse Plan & Build Dependency Graph

### Step 3: Extract Tasks

Parse `parallel-plan.md` to extract all tasks:

```bash
${CURSOR_PLUGIN_ROOT}/skills/implement-plan/scripts/parse-dependencies.sh docs/plans/[feature-name]/parallel-plan.md
```

For each task, extract:

- **Task ID**: e.g., 1.1, 2.3, 3.1 (or T0, T1, T2)
- **Task Title**: Descriptive name
- **Dependencies**: List from `Depends on [...]` or `- **Dependencies**: ...`
- **Files to Read**: From "READ THESE BEFORE TASK"
- **Files to Create**: From "Files to Create"
- **Files to Modify**: From "Files to Modify"
- **Instructions**: Implementation details

### Step 4: Build Dependency Graph

Create a dependency graph structure:

```
Independent Tasks (Depends on [none]):
  - Task 1.1
  - Task 1.3
  - Task 2.2

Dependent Tasks:
  - Task 1.2 → depends on [1.1]
  - Task 2.1 → depends on [1.1, 1.2]
  - Task 2.3 → depends on [2.1, 2.2]
  - Task 3.1 → depends on [2.1]
```

Keep this graph available for both Path A (ordering) and Path B (`addBlockedBy` wiring).

---

## Phase 2: Create Todo List

### Step 5: Generate Comprehensive Todos

Using **TodoWrite**, create a todo item for each task in the plan:

Format each todo as:

- `id`: Task ID (e.g., "task-1-1")
- `content`: "[Task ID] [Task Title] - Depends on: [dependencies]"
- `status`: "pending"

Example:

```
- task-1-1: "1.1 Create user model - Depends on: none"
- task-1-2: "1.2 Add validation - Depends on: 1.1"
- task-1-3: "1.3 Setup routes - Depends on: none"
```

### Step 6: Identify First Batch

Identify all tasks with `Depends on [none]` - these form the first batch.

Mark these as ready for execution.

---

## Phase 3: Execute in Batches

### Step 7: Dry Run Gate

If `--dry-run` is present:

**Default dry-run (no `--team`)** — display the batch roster only:

```markdown
# Dry Run: Implementation Plan for [feature-name]

## Execution Batches

### Batch 1 (Independent Tasks)

- Task 1.1: [Title]
- Task 1.3: [Title]
- Task 2.2: [Title]

### Batch 2 (After Batch 1)

- Task 1.2: [Title] (depends on 1.1)
- Task 2.1: [Title] (depends on 1.1, 1.2)

### Batch 3 (After Batch 2)

- Task 2.3: [Title] (depends on 2.1, 2.2)
- Task 3.1: [Title] (depends on 2.1)

## Summary

- Total Tasks: [count]
- Total Batches: [count]
- Max Parallelism: [largest batch size]

## Next Steps

Remove --dry-run flag to execute the plan.
```

**`--team --dry-run`** — also print the team name and per-batch teammate roster:

```
Team name:    impl-<sanitized-feature-name>
Total tasks:  <N>  (across <M> batches, max parallel width <X>)
Dependencies: <K edges>  (from the parsed Depends on annotations)

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

Do **not** call `TeamCreate`, `TaskCreate`, `Agent`, `SendMessage`, or `TeamDelete` in dry-run mode. **STOP HERE**.

### Step 8: Branch on `TEAM_FLAG`

- `TEAM_FLAG=false` → **Path A — Standalone sub-agent batches** (default).
- `TEAM_FLAG=true` → **Path B — Agent team batches**.

---

### Path A — Standalone Sub-Agent Batches (default)

Read the agent task prompt template once before the loop:

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/implement-plan/templates/agent-task-prompt.md
```

For each batch of ready tasks, in order:

**CRITICAL**: Deploy all agents in the batch in a **SINGLE message** with **MULTIPLE `Agent` tool calls**.

For each task in the batch, deploy an implementor with:

| Field         | Value                                      |
| ------------- | ------------------------------------------ |
| subagent_type | `implementor`                              |
| description   | "Implement [Task ID]: [Title]"             |
| prompt        | Use template with task details substituted |

No `team_name`, no `name`, no `TaskCreate` — standalone sub-agent semantics.

#### Agent Task Requirements (Path A)

Each implementor agent must:

1. **Read context first**:
   - `docs/plans/[feature-name]/parallel-plan.md`
   - `docs/plans/[feature-name]/shared.md`
   - Files listed in "READ THESE BEFORE TASK"

2. **Implement the specific task**:
   - Create files listed in "Files to Create"
   - Modify files listed in "Files to Modify"
   - Follow the instructions exactly

3. **Validate changes**:
   - Check for linting errors on modified files
   - Ensure code compiles/parses correctly

4. **Return summary**:
   - List of files created
   - List of files modified
   - Any issues encountered

#### Process Batch Results (Path A)

After each batch completes:

1. **Update todos**: Mark completed tasks as `completed`
2. **Review agent outputs**: Check for errors or issues
3. **Identify next batch**: Find tasks whose dependencies are now satisfied
4. **Handle failures**: If a task failed, note it and continue with independent tasks

#### Repeat Until Complete (Path A)

```
While tasks remain:
  1. Find tasks where all dependencies are completed
  2. Deploy agents for those tasks in parallel (single message, multiple Agent calls)
  3. Wait for batch to complete
  4. Update task status
  5. Identify next batch
```

---

### Path B — Agent Team Batches (`--team`)

> **MANDATORY — AGENT TEAMS REQUIRED**
>
> In Path B you MUST follow the agent-team lifecycle. Do NOT mix standalone sub-agents
> with team dispatch. Every `Agent` call below MUST include `team_name=` AND `name=`.
>
> 1. `TeamCreate` ONCE at the start (single team across all batches)
> 2. `TaskCreate` for **every task across all batches** up front, with `addBlockedBy`
>    wiring the dependency graph from the plan's `Depends on` annotations
> 3. Per batch: spawn teammates (single message, multiple `Agent` calls with
>    `team_name=` + `name=`)
> 4. `TaskList` to monitor batch completion
> 5. `SendMessage({type:"shutdown_request"})` to all teammates of completed batch
>    BEFORE spawning next batch
> 6. `TeamDelete` ONCE after final batch (or on abort)
>
> If `TeamCreate` or up-front `TaskCreate` fails, abort the skill. Refer to
> `${CURSOR_PLUGIN_ROOT}/skills/_shared/references/agent-team-dispatch.md`
> for the full lifecycle contract.

#### B.1 Build the team name

Sanitize the feature name (lowercase, replace non-alphanumeric with `-`, collapse runs, trim, cap at **20 chars**, fall back to `untitled` if empty). Team name: `impl-<sanitized-feature-name>`.

#### B.2 Create the team

```
TeamCreate: team_name="impl-<sanitized-feature-name>", description="implement-plan team for: <feature-name>"
```

On failure, abort.

#### B.3 Register ALL tasks up front with the dependency graph

For **every task across all batches** in the parsed task list:

```
TaskCreate: subject="<task-id>: <task title>", description="<full spec — files to read, files to create, files to modify, instructions>"
```

Then wire dependencies from the Phase 1 Step 4 graph — for each task `T` with `Depends on [X, Y, Z]`:

```
TaskUpdate: taskId="<T-id>", addBlockedBy=["<X-id>", "<Y-id>", "<Z-id>"]
```

This populates the shared task graph **once**, not per batch. Subsequent batches can read `TaskList` to confirm prerequisites are complete.

If any `TaskCreate` or `TaskUpdate` fails → `TeamDelete`, then abort.

#### B.4 Per-batch loop

Read the agent task prompt template once:

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/implement-plan/templates/agent-task-prompt.md
```

For each batch `B1, B2, ... BN` in dependency order:

1. **Identify batch tasks** — All tasks whose dependencies are now satisfied and whose `TaskList` status is still pending.

2. **Spawn batch teammates** — Single message, multiple `Agent` tool calls, one per task in the batch. Every call MUST include:
   - `team_name`: `"impl-<sanitized-feature-name>"`
   - `name`: the task ID (e.g., `"1.1"`, `"2.3"`) — must match the `TaskCreate` subject prefix
   - `subagent_type`: `"implementor"`
   - `description`: `"Implement [Task ID]: [Title]"`
   - `prompt`: template-filled task spec. Include a directive that the agent must read the files listed in "READ THESE BEFORE TASK" before writing code, must validate its own modified files, and must call `TaskUpdate` to mark its task complete.

3. **Wait for batch completion via `TaskList`** — poll until all tasks in this batch are `completed`. If a teammate messages with an issue, respond via `SendMessage` with guidance.

4. **Shut down completed-batch teammates** — Send to every teammate of the just-completed batch:

   ```
   SendMessage(to="<task-id>", message={type:"shutdown_request"})
   ```

   Wait for shutdowns to complete before spawning the next batch's teammates.

5. **Track progress** — Log: `[done] Batch BN: K tasks — complete`

#### B.5 Failure handling

If a teammate fails:

- **Do NOT auto-retry** — parallel failures often indicate file conflicts or missing dependencies between supposedly-independent tasks.
- **Do NOT skip the failing batch** — tasks in later batches may depend on it.
- Use `AskUserQuestion` to ask the user: _"Batch {BN} had failures. Choose: (1) fix manually and resume, (2) switch to sequential standalone sub-agents for remaining batches, (3) abort."_
- If the user chooses (2) or (3), send `SendMessage(shutdown)` to all active teammates, then `TeamDelete` before proceeding.

#### B.6 After all batches complete

`TeamDelete` once. Proceed to Phase 4.

---

## Phase 4: Final Verification & Summary

### Step 9: Verify Implementation

After all tasks complete:

1. **Check for lint errors**: Run linting on all modified files
2. **Verify file creation**: Ensure all "Files to Create" exist
3. **Review changes**: Quick sanity check of modifications

### Step 10: Display Summary

Provide completion summary:

```markdown
# Implementation Complete

## Feature

[feature-name]

## Execution Mode

[Standalone sub-agents | Agent team (team: impl-<name>)]

## Execution Summary

- **Total Tasks**: [count]
- **Completed**: [count]
- **Failed**: [count]
- **Batches Executed**: [count]

## Files Changed

### Created

- /path/to/new/file.ext
- /path/to/another/file.ext

### Modified

- /path/to/existing/file.ext
- /path/to/another/existing/file.ext

## Task Results

### Batch 1

- [x] Task 1.1: [Title] - Success
- [x] Task 1.3: [Title] - Success

### Batch 2

- [x] Task 1.2: [Title] - Success
- [x] Task 2.1: [Title] - Success

## Issues Encountered

[List any problems or warnings]

## Next Steps

1. Review the changes in your editor
2. Run tests to verify functionality
3. Commit the changes when satisfied
4. **Optional**: Generate implementation report:

/code-report [feature-name]
```

---

## Quality Standards

### Batch Execution Checklist

Each batch must:

- [ ] Deploy all ready tasks in parallel (single message, multiple `Agent` calls)
- [ ] Wait for all agents to complete before next batch
- [ ] Update todo (and in Path B, TaskList) status after completion
- [ ] Handle failures gracefully
- [ ] In Path B: shut down completed-batch teammates before spawning the next batch

### Agent Quality Checklist

Each agent must:

- [ ] Read all required context files first
- [ ] Implement only the assigned task
- [ ] Validate changes before returning
- [ ] Return clear summary of changes
- [ ] In Path B: call `TaskUpdate` to mark its own task complete

### Overall Quality Checklist

The implementation must:

- [ ] Complete all tasks in the plan
- [ ] Respect dependency ordering
- [ ] Maximize parallel execution
- [ ] Report any failures clearly

---

## Monorepo Support

The skill automatically detects and uses the correct plans directory in monorepo setups.

### Default Behavior

- Plans are read from the **git repository root** in `docs/plans/`
- Running the skill from any subdirectory (e.g., `packages/app1/`) will still read plans from the root

### Configuration

Create a `.plans-config` file to customize behavior:

**Repository Root** (centralized plans):

```yaml
# .plans-config at repo root
plans_dir: docs/plans
```

**Package-Level Plans** (optional):

```yaml
# .plans-config in packages/app1/
plans_dir: docs/plans
scope: local
```

With `scope: local`, plans are read from the local `docs/plans/` instead of the root.

### Example: Monorepo Structure

```
monorepo/
  .plans-config          # plans_dir: docs/plans
  docs/plans/            # Centralized plans (default)
    feature-a/
      shared.md
      parallel-plan.md   # Read by this skill
  packages/
    app1/
    app2/
```

Running `/implement-plan feature-a` from anywhere executes `monorepo/docs/plans/feature-a/parallel-plan.md`.

---

## Important Notes

- **You are the orchestrator** — coordinate agents, don't implement yourself
- **Parallelism is the baseline** — every batch dispatches concurrently regardless of path
- **Default dispatch is standalone sub-agents** — `--team` is an opt-in for shared task-graph observability in Claude Code
- **Deploy in batches** — single message with multiple `Agent` calls per batch
- **Respect dependencies** — never start a task before its dependencies complete
- **Track progress** — update todos (and in Path B, `TaskList`) as tasks complete
- **Handle failures** — continue with independent tasks if one fails (Path A); escalate to the user via `AskUserQuestion` (Path B)
- **Monorepo aware** — automatically resolves correct plans directory

---

## Agent Team Lifecycle Reference

For Path B's team lifecycle contract (sanitization, shutdown sequence, failure policy,
multi-batch reuse pattern), refer to:

```
${CURSOR_PLUGIN_ROOT}/skills/_shared/references/agent-team-dispatch.md
```
