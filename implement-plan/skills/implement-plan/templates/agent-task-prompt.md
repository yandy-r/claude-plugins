# Implementor Agent Task Prompt

This template is used to spawn implementor teammates for each task in the parallel plan. Teammates work as a coordinated team within each batch, sharing findings with each other via messages.

---

## Prompt Template

````
Implement Task {{TASK_ID}}: {{TASK_TITLE}}

## Context

You are implementing one task from a larger feature plan as part of an implementation team. Read the context documents first to understand the overall architecture and patterns.

### Required Reading

1. **Plan Document**: docs/plans/{{FEATURE_NAME}}/parallel-plan.md
   - Read the full plan to understand the feature
   - Focus on Task {{TASK_ID}} for your specific instructions

2. **Shared Context**: docs/plans/{{FEATURE_NAME}}/shared.md
   - Understand the architecture and patterns
   - Note the relevant files and their purposes

3. **Task-Specific Files**:
{{FILES_TO_READ}}

## Your Task

**Task {{TASK_ID}}: {{TASK_TITLE}}**

### Files to Create
{{FILES_TO_CREATE}}

### Files to Modify
{{FILES_TO_MODIFY}}

### Instructions
{{TASK_INSTRUCTIONS}}

## Requirements

1. **Read First**: Read all required files before making changes
2. **Implement Only This Task**: Do not implement other tasks
3. **Follow Existing Patterns**: Match the codebase style and conventions
4. **Validate Changes**: Check for linting errors after modifications
5. **Share Findings**: Message teammates with relevant discoveries
6. **Report Results**: Mark your task complete when done

## Team Communication

You are part of implementation batch {{BATCH_NUMBER}} for "{{FEATURE_NAME}}".

### Your Teammates (This Batch)

{{BATCH_TEAMMATES}}

### What to Share (via SendMessage)

After completing your implementation, share relevant findings with teammates:

- **New utility functions or helpers** you created that teammates might need
- **API patterns or interfaces** you established that dependent tasks will consume
- **Unexpected findings** — files in a different state than expected, breaking changes
- **Shared constants, types, or configuration** you added

Only share findings that are genuinely useful to specific teammates. Use targeted messages (SendMessage to a specific teammate name), not broadcasts.

### What to Listen For

Your teammates may message you with:

- Utility functions or shared code they created
- Interface contracts they established
- Warnings about unexpected codebase state

Integrate any relevant information from teammate messages into your implementation.

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Read all required context files
4. Implement your task
5. Share key findings with relevant teammates via SendMessage
6. Validate your changes
7. Mark your task complete with TaskUpdate (set status to completed)

## Output Format

After completing the task, provide:

```markdown
## Task {{TASK_ID}} Complete

### Files Created
- /path/to/file.ext

### Files Modified
- /path/to/file.ext: Description of changes

### Validation
- Linting: [Pass/Fail]
- Issues: [None or list issues]

### Notes
[Any important observations or warnings]
````

```

---

## Variable Reference

| Variable               | Description                              | Example                              |
| ---------------------- | ---------------------------------------- | ------------------------------------ |
| `{{FEATURE_NAME}}`     | Feature directory name                   | `user-authentication`                |
| `{{TASK_ID}}`          | Task identifier                          | `1.1`, `2.3` or `T0`, `T1`          |
| `{{TASK_TITLE}}`       | Task title from plan                     | `Create user model`                  |
| `{{FILES_TO_READ}}`    | Files from "READ THESE BEFORE TASK"      | `- /src/models/base.ts`             |
| `{{FILES_TO_CREATE}}`  | Files from "Files to Create"             | `- /src/models/user.ts`             |
| `{{FILES_TO_MODIFY}}`  | Files from "Files to Modify"             | `- /src/index.ts`                   |
| `{{TASK_INSTRUCTIONS}}`| Implementation instructions              | Detailed task steps                  |
| `{{BATCH_NUMBER}}`     | Current execution batch number           | `1`, `2`, `3`                        |
| `{{BATCH_TEAMMATES}}`  | List of other teammates in this batch    | `- **task-1-3**: Setup routes`      |

---

## Usage Instructions

When spawning an implementor teammate:

1. **Read the task** from parallel-plan.md
2. **Extract all variables** from the task section
3. **Build batch teammate list** from other tasks in the same batch
4. **Substitute variables** in this template
5. **Deploy teammate** with:
   - `team_name`: `ip-[feature-name]`
   - `name`: `task-[task-id]` (e.g., `task-1-1`)
   - `subagent_type`: `implementor`
   - `description`: "Implement {{TASK_ID}}: {{TASK_TITLE}}"
   - `prompt`: The substituted template

---

## Example Populated Prompt

```

Implement Task 1.1: Create user model

## Context

You are implementing one task from a larger feature plan as part of an implementation team. Read the context documents first to understand the overall architecture and patterns.

### Required Reading

1. **Plan Document**: docs/plans/user-authentication/parallel-plan.md
   - Read the full plan to understand the feature
   - Focus on Task 1.1 for your specific instructions

2. **Shared Context**: docs/plans/user-authentication/shared.md
   - Understand the architecture and patterns
   - Note the relevant files and their purposes

3. **Task-Specific Files**:
   - /src/models/base-model.ts
   - /src/types/user.ts
   - /docs/architecture/models.md

## Your Task

**Task 1.1: Create user model**

### Files to Create

- /src/models/user.ts

### Files to Modify

- /src/models/index.ts

### Instructions

Create a new User model following the BaseModel pattern:

1. Create /src/models/user.ts with:
   - User class extending BaseModel
   - Fields: id, email, passwordHash, createdAt, updatedAt
   - Methods: validateEmail(), hashPassword()

2. Update /src/models/index.ts:
   - Export the new User model

Follow the pattern in /src/models/base-model.ts for consistency.

## Requirements

1. **Read First**: Read all required files before making changes
2. **Implement Only This Task**: Do not implement other tasks
3. **Follow Existing Patterns**: Match the codebase style and conventions
4. **Validate Changes**: Check for linting errors after modifications
5. **Share Findings**: Message teammates with relevant discoveries
6. **Report Results**: Mark your task complete when done

## Team Communication

You are part of implementation batch 1 for "user-authentication".

### Your Teammates (This Batch)

- **task-1-3**: Setup API routes
- **task-2-2**: Create validation middleware

### What to Share (via SendMessage)

After completing your implementation, share relevant findings with teammates:

- **New utility functions or helpers** you created that teammates might need
- **API patterns or interfaces** you established that dependent tasks will consume
- **Unexpected findings** — files in a different state than expected, breaking changes
- **Shared constants, types, or configuration** you added

### What to Listen For

Your teammates may message you with utility functions, interface contracts, or warnings.

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Read all required context files
4. Implement your task
5. Share key findings with relevant teammates via SendMessage
6. Validate your changes
7. Mark your task complete with TaskUpdate (set status to completed)

## Output Format

After completing the task, provide:

```markdown
## Task 1.1 Complete

### Files Created

- /src/models/user.ts

### Files Modified

- /src/models/index.ts: Added User export

### Validation

- Linting: Pass
- Issues: None

### Notes

Followed BaseModel pattern exactly. User model ready for validation task 1.2.
```

```

---

## Teammate Configuration

| Setting       | Value                                         |
| ------------- | --------------------------------------------- |
| team_name     | `ip-[feature-name]`                           |
| name          | `task-[task-id]` (e.g., `task-1-1`)           |
| Subagent Type | `implementor`                                 |
| Readonly      | No (must modify files)                        |
| Model         | Default                                       |

## Best Practices

1. **One Task Per Teammate**: Each teammate implements exactly one task
2. **Include All Context**: Provide complete file paths and instructions
3. **Clear Boundaries**: Make it obvious what is in scope vs out of scope
4. **Validation Required**: Teammates must check their work before completing
5. **Targeted Sharing**: Message specific teammates with relevant findings, not all
6. **Self-Report**: Teammates claim tasks and mark them complete via TaskUpdate
