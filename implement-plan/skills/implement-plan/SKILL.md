---
name: implement-plan
description: Execute a parallel implementation plan by deploying implementor agent teams in dependency-resolved batches. Use as Step 3 after parallel-plan to implement features from the generated plan.
argument-hint: '[feature-name] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Agent
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
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/implement-plan/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
---

# Parallel Plan Executor

Execute a parallel implementation plan by deploying implementor agent teams in dependency-resolved batches. This is **Step 3** of the planning workflow, transforming the plan into working code.

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

Parse arguments:

- **feature-name**: The name of the feature to implement (matches directory name in `docs/plans/`)
- **--dry-run**: Show execution plan without deploying agents

If no feature name provided, abort with usage instructions:

```
Usage: /implement-plan [feature-name] [--dry-run]

Examples:
  /implement-plan user-authentication
  /implement-plan payment-integration --dry-run
```

---

## Phase 0: Prerequisites Check

### Step 1: Validate Prerequisites

Extract the feature name from `$ARGUMENTS` (first non-flag argument).

Run the prerequisites check script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/implement-plan/scripts/check-prerequisites.sh [feature-name]
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
${CLAUDE_PLUGIN_ROOT}/skills/implement-plan/scripts/parse-dependencies.sh docs/plans/[feature-name]/parallel-plan.md
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

---

## Phase 2: Create Team and Tasks

### Step 5: Create Implementation Team

Create an agent team for the implementation:

```
TeamCreate: team_name="ip-[feature-name]", description="Implementation team for [feature-name]"
```

### Step 6: Create Shared Task List

Using **TaskCreate**, create a task for each implementation task in the plan:

Format each task as:

- **subject**: `"[Task ID]: [Task Title]"`
- **description**: Include dependencies, files to read/create/modify, and instructions

Example:

```
TaskCreate: subject="1.1: Create user model", description="Depends on: none. Files to create: /src/models/user.ts. Files to modify: /src/models/index.ts."
TaskCreate: subject="1.2: Add validation", description="Depends on: 1.1. Files to modify: /src/models/user.ts."
```

### Step 7: Set Up Dependency Relationships

For each task with dependencies, use **TaskUpdate** with `addBlockedBy` to encode the dependency graph:

```
TaskUpdate: taskId="[task-1-2-id]", addBlockedBy=["[task-1-1-id]"]
TaskUpdate: taskId="[task-2-1-id]", addBlockedBy=["[task-1-1-id]", "[task-1-2-id]"]
```

This ensures the shared task list itself tracks which tasks are ready (unblocked) vs waiting.

### Step 8: Identify First Batch

Identify all tasks with no `blockedBy` dependencies — these form the first batch.

---

## Phase 3: Execute in Batches

### Step 9: Check for Dry Run Mode

If `--dry-run` is present in `$ARGUMENTS`:

Display:

```markdown
# Dry Run: Implementation Plan for [feature-name]

## Team

- Name: ip-[feature-name]
- Teammates share findings within each batch

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

**STOP HERE** - do not deploy agents. Clean up the team with `TeamDelete`.

### Step 10: Execute Batch Loop

For each batch of ready tasks, repeat the following cycle:

#### 10a: Read Agent Prompt Template

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/implement-plan/templates/agent-task-prompt.md
```

#### 10b: Build Batch Teammate List

For the current batch, build a teammate list showing all tasks being worked on in parallel. This is substituted into `{{BATCH_TEAMMATES}}` so each teammate knows who else is in their batch.

Example for batch 1 with tasks 1.1, 1.3, 2.2:

```
- **task-1-1**: Create user model
- **task-1-3**: Setup routes
- **task-2-2**: Create middleware
```

#### 10c: Spawn Batch Teammates

**CRITICAL**: Deploy all teammates in the batch in a **SINGLE message** with **MULTIPLE Agent tool calls**, each with `team_name="ip-[feature-name]"`.

For each task in the batch:

| Field         | Value                                              |
| ------------- | -------------------------------------------------- |
| team_name     | `ip-[feature-name]`                                |
| name          | `task-[task-id]` (e.g., `task-1-1`, `task-T0`)    |
| subagent_type | `implementor`                                      |
| description   | `"Implement [Task ID]: [Title]"`                   |
| prompt        | Template with task details + batch info substituted |

Substitute these variables in the template:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{TASK_ID}}` - Task identifier
- `{{TASK_TITLE}}` - Task name
- `{{FILES_TO_READ}}` - Files from "READ THESE BEFORE TASK"
- `{{FILES_TO_CREATE}}` - Files from "Files to Create"
- `{{FILES_TO_MODIFY}}` - Files from "Files to Modify"
- `{{TASK_INSTRUCTIONS}}` - Implementation details
- `{{BATCH_NUMBER}}` - Current batch number
- `{{BATCH_TEAMMATES}}` - List of other teammates in this batch

#### 10d: Monitor Batch Progress

Wait for all teammates in the batch to complete. Teammates will:

1. Claim their task from the shared list via TaskUpdate
2. Read all required context files
3. Implement their assigned task
4. Share key findings with batch teammates via SendMessage
5. Validate their changes
6. Mark their task complete via TaskUpdate
7. Go idle

Use **TaskList** to check progress. When all tasks in the batch are marked complete, proceed.

If a teammate reports an issue (via SendMessage), respond with corrective guidance.

#### 10e: Handle Failures

If a task fails:

1. Note the failure
2. Mark any tasks that depend on the failed task as skipped (they cannot proceed)
3. Continue with remaining independent tasks

#### 10f: Shut Down Batch Teammates

After all batch tasks are complete (or failed), send shutdown requests to each teammate:

```
SendMessage to each batch teammate: message={type: "shutdown_request"}
```

Wait for all shutdowns before proceeding to the next batch.

#### 10g: Identify Next Batch

Check **TaskList** for tasks that are:

- Status: `pending`
- No unresolved `blockedBy` dependencies (all blockers are `completed`)

These form the next batch. If tasks remain but none are unblocked, report a deadlock (likely circular dependency or cascading failure) and stop.

### Step 11: Repeat Until Complete

Continue the batch loop (Steps 10a-10g) until all tasks are completed or no more tasks can be unblocked.

```
While uncompleted tasks remain:
  1. Find tasks with no unresolved blockers
  2. If none found but tasks remain → deadlock, stop and report
  3. Spawn teammates for ready tasks (single message, multiple Agent calls)
  4. Monitor via TaskList until batch complete
  5. Handle failures, mark dependent tasks as skipped
  6. Shut down batch teammates
  7. Identify next batch
```

---

## Phase 4: Final Verification & Summary

### Step 12: Verify Implementation

After all tasks complete:

1. **Check for lint errors**: Run linting on all modified files
2. **Verify file creation**: Ensure all "Files to Create" exist
3. **Review changes**: Quick sanity check of modifications

### Step 13: Clean Up Team

Delete the team and its resources:

```
TeamDelete
```

### Step 14: Display Summary

Provide completion summary:

```markdown
# Implementation Complete

## Feature

[feature-name]

## Team Summary

- Team: ip-[feature-name]
- Total teammates spawned: [count across all batches]
- Batches executed: [count]
- Inter-agent sharing: Enabled (teammates shared findings within batches)

## Execution Summary

- **Total Tasks**: [count]
- **Completed**: [count]
- **Failed**: [count]
- **Skipped**: [count] (blocked by failed dependencies)

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

- [ ] Deploy all ready tasks as teammates in parallel (single message, multiple Agent calls)
- [ ] Wait for all teammates to complete before next batch
- [ ] Update task status via TaskList monitoring
- [ ] Handle failures gracefully (skip dependent tasks)
- [ ] Shut down batch teammates before spawning next batch

### Teammate Quality Checklist

Each teammate must:

- [ ] Read all required context files first
- [ ] Implement only the assigned task
- [ ] Share relevant findings with batch teammates
- [ ] Validate changes before completing
- [ ] Mark task complete via TaskUpdate

### Overall Quality Checklist

The implementation must:

- [ ] Complete all tasks in the plan (or report failures clearly)
- [ ] Respect dependency ordering
- [ ] Maximize parallel execution within batches
- [ ] Report any failures and skipped tasks clearly
- [ ] Clean up team before completing

---

## Monorepo Support

The skill automatically detects and uses the correct plans directory in monorepo setups.

### Default Behavior

- Plans are read from the **git repository root** in `docs/plans/`
- Running the skill from any subdirectory still reads plans from the root

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

---

## Important Notes

- **You are the team lead** - coordinate teammates, don't implement yourself
- **Create team first** - use TeamCreate before spawning any teammates
- **Spawn teammates in parallel** - single message with multiple Agent calls per batch
- **Teammates share findings** - they communicate within batches via SendMessage
- **Respect dependencies** - never start a task before its dependencies complete
- **Maximize parallelism** - run all independent tasks simultaneously in each batch
- **Shut down between batches** - shut down teammates before spawning next batch
- **Handle failures** - skip dependent tasks if a task fails, continue with independent ones
- **Detect deadlocks** - if no tasks can be unblocked, report and stop
- **Clean up team** - always TeamDelete before completing
- **Monorepo aware** - automatically resolves correct plans directory
