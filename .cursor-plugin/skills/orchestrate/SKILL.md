---
name: orchestrate
description: Orchestrate multiple specialized agents to accomplish complex tasks efficiently through intelligent task decomposition, parallel execution, and result synthesis.
argument-hint: '[task-description] [--dry-run] [--plan-only] [--sequential]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
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
  - Bash(mkdir:*)
  - 'Bash(${CURSOR_PLUGIN_ROOT}/skills/orchestrate/scripts/*.sh:*)'
---

## MANDATORY — AGENT TEAMS REQUIRED

**You MUST use agent teams for this skill. Do NOT use standalone sub-agents.**

1. **TeamCreate** FIRST — before spawning any agents
2. **TaskCreate** — register all subtasks in the shared task list
3. **Agent with `team_name`** — every agent spawn MUST include the `team_name` parameter
4. **SendMessage** — shut down teammates between batches
5. **TeamDelete** — clean up when done

If you spawn an agent WITHOUT `team_name`, you are doing it wrong. Stop and fix it.

---

# Multi-Agent Orchestration Skill

You are an orchestration expert coordinating multiple specialized agents to accomplish complex tasks. **Your role is to coordinate agents, not do the work yourself.**

## Current Task

**Orchestrating**: `$ARGUMENTS`

Parse the arguments:

- **task-description**: The complex task to orchestrate (required, can be multi-word)
- **--dry-run**: Show orchestration plan without deploying agents
- **--plan-only**: Create orchestration plan file without execution
- **--sequential**: Force sequential execution (for tightly dependent tasks)

If no task description provided, abort with usage instructions:

```
Usage: /orchestrate [task-description] [--dry-run] [--plan-only] [--sequential]

Examples:
  /orchestrate "Implement user authentication with tests and docs"
  /orchestrate "Debug payment processing failure" --dry-run
  /orchestrate "Refactor database layer" --plan-only
  /orchestrate "Update API documentation across all services"
```

---

## Phase 0: Task Analysis

### Step 1: Parse Task Description

Extract the task description from `$ARGUMENTS` (everything before any flags).

Run the task analysis script:

```bash
${CURSOR_PLUGIN_ROOT}/skills/orchestrate/scripts/analyze-task.sh "$TASK_DESCRIPTION"
```

The script provides:

- Task complexity estimate
- Suggested decomposition approach
- Potential agent types needed
- Recommended execution mode (parallel vs sequential)

### Step 2: Load Agent Catalog

Read the complete agent catalog:

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/orchestrate/references/agent-catalog.md
```

This provides the complete reference of available agents organized by category, capabilities, and use cases.

### Step 3: Initial Assessment

Analyze the task to determine:

- **Scope**: Is this a feature, bug, refactor, documentation, or infrastructure task?
- **Components**: Which parts of the system are involved?
- **Complexity**: Simple (1-2 agents), Medium (3-5 agents), Complex (6+ agents)
- **Dependencies**: Are subtasks independent or sequential?

---

## Phase 1: Task Decomposition & Team Creation

### Step 4: Read Decomposition Template

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/orchestrate/references/task-breakdown.md
```

This template provides patterns for breaking down tasks by feature area, technical layer, cross-cutting concerns, and dependencies.

### Step 5: Create Team and Register Subtasks

**5a: Create the orchestration team:**

Sanitize the task description to create a team name (lowercase, hyphens, max 20 chars):

```
TeamCreate: team_name="orch-[sanitized-task]", description="Orchestration team for: [task description]"
```

**5b: Create subtasks in the shared task list:**

Using **TaskCreate**, register each subtask:

```
TaskCreate: subject="[subtask-N]: [Description]", description="Agent: [agent-type]. Dependencies: [none/list]. Scope: [details]. Expected output: [deliverables]."
```

**5c: Set up dependencies:**

For subtasks with dependencies, use **TaskUpdate** with `addBlockedBy`:

```
TaskUpdate: taskId="[subtask-2-id]", addBlockedBy=["[subtask-1-id]"]
```

### Step 6: Validate Task Decomposition

Ensure each subtask meets quality standards:

- [ ] Clear, specific scope (not too broad)
- [ ] Single responsibility (doesn't overlap with others)
- [ ] Appropriate size (completable in one focused session)
- [ ] Dependencies explicitly stated
- [ ] Success criteria clear
- [ ] Agent type assignment justified

Optionally run validation script:

```bash
if [[ -f "${CURSOR_PLUGIN_ROOT}/skills/orchestrate/scripts/validate-agents.sh" ]]; then
  ${CURSOR_PLUGIN_ROOT}/skills/orchestrate/scripts/validate-agents.sh
fi
```

---

## Phase 2: Agent Assignment

### Step 7: Map Subtasks to Agents

For each subtask, determine the optimal agent type based on:

| Task Type                | Recommended Agent                                         |
| ------------------------ | --------------------------------------------------------- |
| Code exploration/finding | `explore`, `code-finder`                                  |
| Architecture research    | `codebase-research-analyst`                               |
| Frontend UI work         | `frontend-ui-developer`, `nextjs-ux-ui-expert`            |
| Backend API work         | `nodejs-backend-architect`, `go-api-architect`            |
| Database changes         | `db-modifier`, `sql-database-architect`                   |
| Documentation            | `documentation-writer`, `api-docs-expert`                 |
| Testing strategy         | `test-strategy-planner`                                   |
| Bug diagnosis            | `root-cause-analyzer`                                     |
| Infrastructure           | `terraform-architect`, `cloudflare-architect`             |
| DevOps/automation        | `ansible-automation-expert`, `systems-engineering-expert` |

### Step 8: Read Agent Prompt Templates

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/orchestrate/references/agent-prompts.md
```

Use standard prompts for common orchestration patterns to ensure consistency.

### Step 9: Prepare Agent Instructions

For each subtask, prepare:

1. **Context**: What the agent needs to know
2. **Scope**: Specific files/areas to focus on
3. **Deliverables**: Expected outputs
4. **Constraints**: What NOT to do (avoid overlap)

---

## Phase 3: Dry Run Check

### Step 10: Check for Dry Run or Plan-Only Mode

If `--dry-run` is present in `$ARGUMENTS`:

Display:

```markdown
# Dry Run: Orchestration Plan for [Task]

## Team

- Name: orch-[sanitized-task]
- Teammates share findings within each batch

## Task Analysis

- Complexity: [Simple/Medium/Complex]
- Execution Mode: [Parallel/Sequential]
- Total Subtasks: [count]

## Subtask Breakdown

### Batch 1 (Independent Tasks)

1. **[Subtask 1]**
   - Agent: [agent-type]
   - Focus: [brief description]
   - Output: [expected deliverable]

2. **[Subtask 2]**
   - Agent: [agent-type]
   - Focus: [brief description]
   - Output: [expected deliverable]

### Batch 2 (After Batch 1)

1. **[Subtask 3]**
   - Agent: [agent-type]
   - Dependencies: [subtask-1]
   - Focus: [brief description]
   - Output: [expected deliverable]

## Agent Deployment Summary

- Total Agents: [count]
- Parallel Batches: [count]
- Max Parallelism: [largest batch size]

## Next Steps

Remove --dry-run flag to execute the orchestration.
```

Clean up the team with `TeamDelete`, then **STOP HERE** — do not deploy agents.

If `--plan-only` is present:

- Create the plan as `docs/orchestration/[sanitized-task-name].md`
- Save the complete orchestration plan for later execution
- Display the plan location and summary
- Clean up the team with `TeamDelete`
- **STOP HERE** — do not deploy agents

---

## Phase 4: Parallel Agent Deployment

### Step 11: Organize into Execution Batches

Group subtasks by dependencies:

**Batch 1**: All subtasks with no dependencies (fully independent)
**Batch 2**: Subtasks depending only on Batch 1
**Batch 3**: Subtasks depending on Batch 1 and/or 2
...and so on

If `--sequential` flag is present, create single-task batches.

### Step 12: Deploy Batch

For each batch, do the following **in order**:

**1. Build the teammate list** for this batch — list each subtask's name and description so teammates know who else is working in parallel. Substitute into `{{BATCH_TEAMMATES}}`.

**2. Spawn ALL batch teammates in a SINGLE message** using MULTIPLE Agent tool calls. Every call MUST include `team_name`:

```
Agent(
  team_name = "orch-[sanitized-task]",
  name = "subtask-1",
  subagent_type = "nodejs-backend-architect",
  description = "Implement auth system",
  prompt = [substituted template with team communication section]
)
Agent(
  team_name = "orch-[sanitized-task]",
  name = "subtask-2",
  subagent_type = "test-strategy-planner",
  description = "Create auth test plan",
  prompt = [substituted template with team communication section]
)
Agent(
  team_name = "orch-[sanitized-task]",
  name = "subtask-3",
  subagent_type = "documentation-writer",
  description = "Document auth API",
  prompt = [substituted template with team communication section]
)
```

Each agent's prompt MUST include the Team Communication section from the agent-prompts.md templates, with `{{BATCH_NUMBER}}` and `{{BATCH_TEAMMATES}}` substituted.

**3. Monitor progress** — use `TaskList` to check when all batch tasks are complete. If a teammate messages you with an issue, respond with guidance.

**4. Handle failures** — if a subtask fails, note the failure, determine if dependent subtasks can proceed, and continue with independent subtasks.

**5. Shut down batch teammates** — send `SendMessage(to="subtask-[N]", message={type: "shutdown_request"})` to each teammate. Wait for shutdowns before next batch.

**6. Identify next batch** — check `TaskList` for pending tasks with all blockers completed. If tasks remain but none are unblocked, report deadlock and stop.

### Step 13: Repeat Until Complete

Repeat Step 12 for each subsequent batch until all subtasks are completed or no more can be unblocked.

---

## Phase 5: Result Synthesis & Summary

### Step 14: Consolidate Agent Outputs

Run the summarization script:

```bash
${CURSOR_PLUGIN_ROOT}/skills/orchestrate/scripts/summarize-results.sh
```

Collect outputs from all agents and organize by:

- Files created
- Files modified
- Documentation added
- Tests created
- Issues encountered

### Step 15: Integration Check

Verify that agent outputs work together:

- [ ] No conflicting changes between agents
- [ ] All dependencies properly integrated
- [ ] Cross-references between components valid
- [ ] Consistent patterns and conventions used

### Step 16: Clean Up Team

Delete the team and its resources:

```
TeamDelete
```

### Step 17: Final Summary

Provide comprehensive completion summary:

```markdown
# Orchestration Complete: [Task]

## Team Summary

- Team: orch-[sanitized-task]
- Total teammates spawned: [count across all batches]
- Batches executed: [count]
- Inter-agent sharing: Enabled (teammates shared findings within batches)

## Execution Summary

- **Total Subtasks**: [count]
- **Completed**: [count]
- **Failed**: [count]
- **Execution Batches**: [count]

## Results by Agent

### [Agent Type 1] - [Subtask 1]

**Status**: Success
**Outputs**:

- Created: [files]
- Modified: [files]
- Notes: [key points]

### [Agent Type 2] - [Subtask 2]

**Status**: Success
**Outputs**:

- Created: [files]
- Modified: [files]
- Notes: [key points]

## Files Changed

### Created

- /path/to/new/file1.ext
- /path/to/new/file2.ext

### Modified

- /path/to/modified/file1.ext
- /path/to/modified/file2.ext

## Integration Status

- [x] All agent outputs integrated successfully
- [x] No conflicting changes detected
- [x] Cross-references validated
- [ ] Manual review needed for: [items]

## Issues Encountered

[List any problems, warnings, or areas needing attention]

## Next Steps

1. Review the changes in your editor
2. Test the integrated functionality
3. Address any failed subtasks if needed
4. Commit the changes when satisfied
```

---

## Quality Standards

### Task Decomposition Checklist

Each subtask must have:

- [ ] Clear, specific scope (not too broad or vague)
- [ ] Single responsibility (no overlapping work)
- [ ] Appropriate size (completable in one session)
- [ ] Explicit dependencies stated
- [ ] Clear success criteria
- [ ] Agent type assignment justified

### Agent Assignment Checklist

Each agent assignment must have:

- [ ] Agent type matches subtask requirements
- [ ] No duplicate work between agents
- [ ] Context files identified for agent
- [ ] Expected output format specified
- [ ] Non-overlapping scope with other agents
- [ ] Clear boundaries defined

### Execution Checklist

The orchestration must:

- [ ] Create team before spawning any agents
- [ ] Register all subtasks in shared task list
- [ ] Deploy independent tasks as teammates (single message, multiple Agent calls with team_name)
- [ ] Respect dependency ordering between batches
- [ ] Track progress via TaskList
- [ ] Shut down teammates between batches via SendMessage
- [ ] Handle failures gracefully
- [ ] Synthesize results on completion
- [ ] Verify integration between agent outputs
- [ ] Clean up team with TeamDelete

### Result Quality Checklist

The final result must have:

- [ ] All subtasks attempted
- [ ] Clear status for each subtask (success/fail)
- [ ] Complete list of files changed
- [ ] Integration issues identified
- [ ] Failed subtasks documented
- [ ] Next steps provided

---

## Best Practices

### Coordination Principles

1. **Delegate Everything**: Only coordinate; don't implement yourself
2. **Create Team First**: Always TeamCreate before spawning agents
3. **Maximize Parallelism**: Run independent tasks simultaneously
4. **Clear Boundaries**: Ensure no overlap between agents
5. **Single Goal**: Keep all agents aligned to the main objective
6. **Monitor via TaskList**: Track progress through the shared task list
7. **Shut Down Between Batches**: Clean up teammates before spawning new ones
8. **Synthesize Results**: Integrate outputs into coherent whole
9. **Clean Up Team**: Always TeamDelete before completing

### When to Use Sequential Mode

Use `--sequential` flag when:

- Subtasks have tight coupling
- Each step informs the next
- Risk of conflicts is high
- Debugging or exploratory work

### When to Use Plan-Only Mode

Use `--plan-only` flag when:

- Need approval before execution
- Task is very large or risky
- Want to review approach first
- Building reusable orchestration pattern

### Common Orchestration Patterns

**Feature Implementation**:

- Research agent -> multiple implementation agents -> test agent -> docs agent

**Bug Investigation**:

- Root cause analyzer -> fix implementor -> test verifier -> docs updater

**Refactoring**:

- Architecture analyst -> multiple refactor agents -> test updater -> docs updater

**Documentation Update**:

- Code analyzer -> multiple doc writers -> cross-link validator

---

## Important Notes

- **You are the orchestrator** — coordinate agents, don't implement
- **Create team first** — TeamCreate before spawning any agents
- **Deploy as teammates** — single message with multiple Agent calls, each with team_name
- **Teammates share findings** — they communicate within batches via SendMessage
- **Respect dependencies** — never start a subtask before its dependencies complete
- **Maximize parallelism** — run all independent subtasks simultaneously
- **Shut down between batches** — shut down teammates before spawning next batch
- **Handle failures** — continue with independent subtasks if one fails
- **Track via TaskList** — monitor teammate progress through shared task list
- **Clean up team** — always TeamDelete before completing
- **Quality over speed** — ensure proper coordination and integration

---

## Troubleshooting

### Issue: Agents producing conflicting changes

**Solution**: Review subtask boundaries, ensure non-overlapping scopes, redeploy with clearer instructions

### Issue: Dependencies not properly sequenced

**Solution**: Review dependency graph, adjust batch organization, ensure proper ordering

### Issue: Agent outputs don't integrate

**Solution**: Add integration subtask, deploy agent to resolve conflicts, update instructions for clarity

### Issue: Too many agents for single batch

**Solution**: Break into smaller batches, stagger deployment, or use sequential mode

### Issue: Unclear what to orchestrate

**Solution**: Ask clarifying questions before decomposition, use dry-run to preview, iterate on plan
