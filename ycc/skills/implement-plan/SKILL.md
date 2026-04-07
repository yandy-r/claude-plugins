---
name: implement-plan
description: Execute a parallel implementation plan by deploying implementor agents in dependency-resolved batches. Use as Step 3 after parallel-plan to implement features from the generated plan.
---

# Parallel Plan Executor

Execute a parallel implementation plan by deploying implementor agents in dependency-resolved batches. This is **Step 3** of the planning workflow, transforming the plan into working code.

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

### Step 7: Check for Dry Run Mode

If `--dry-run` is present in `$ARGUMENTS`:

Display:

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

**STOP HERE** - do not deploy agents.

### Step 8: Execute Batch

For each batch of ready tasks:

**CRITICAL**: Deploy all agents in the batch in a **SINGLE message** with **MULTIPLE Task tool calls**.

Read the agent task prompt template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/implement-plan/templates/agent-task-prompt.md
```

For each task in the batch, deploy an `implementor` agent with:

| Field         | Value                                      |
| ------------- | ------------------------------------------ |
| subagent_type | `implementor`                              |
| description   | "Implement [Task ID]: [Title]"             |
| prompt        | Use template with task details substituted |

### Step 9: Agent Task Requirements

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

### Step 10: Process Batch Results

After batch completes:

1. **Update todos**: Mark completed tasks as `completed`
2. **Review agent outputs**: Check for errors or issues
3. **Identify next batch**: Find tasks whose dependencies are now satisfied
4. **Handle failures**: If a task failed, note it and continue with independent tasks

### Step 11: Repeat Until Complete

Continue executing batches until all tasks are completed:

```
While tasks remain:
  1. Find tasks where all dependencies are completed
  2. Deploy agents for those tasks in parallel
  3. Wait for batch to complete
  4. Update task status
  5. Identify next batch
```

---

## Phase 4: Final Verification & Summary

### Step 12: Verify Implementation

After all tasks complete:

1. **Check for lint errors**: Run linting on all modified files
2. **Verify file creation**: Ensure all "Files to Create" exist
3. **Review changes**: Quick sanity check of modifications

### Step 13: Display Summary

Provide completion summary:

```markdown
# Implementation Complete

## Feature

[feature-name]

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
```

/code-report [feature-name]

```

```

---

## Quality Standards

### Batch Execution Checklist

Each batch must:

- [ ] Deploy all ready tasks in parallel (single message, multiple Task calls)
- [ ] Wait for all agents to complete before next batch
- [ ] Update todo status after completion
- [ ] Handle failures gracefully

### Agent Quality Checklist

Each agent must:

- [ ] Read all required context files first
- [ ] Implement only the assigned task
- [ ] Validate changes before returning
- [ ] Return clear summary of changes

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

- **You are the orchestrator** - coordinate agents, don't implement yourself
- **Deploy in batches** - single message with multiple Task calls per batch
- **Respect dependencies** - never start a task before its dependencies complete
- **Maximize parallelism** - run all independent tasks simultaneously
- **Track progress** - update todos as tasks complete
- **Handle failures** - continue with independent tasks if one fails
- **Monorepo aware** - automatically resolves correct plans directory
