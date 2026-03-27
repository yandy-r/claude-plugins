# Validation Agent Prompts

These prompts are used to spawn validation teammates after creating a parallel plan. This is Phase 9 of the unified planning workflow. Validators cross-check each other's findings via messages.

---

## Standard Mode: 3 Validation Teammates

### Agent 1: File Path Validator

**Teammate Name**: `path-validator`

**Subagent Type**: `explore`

**Task Description**: Verify file path references

**Prompt Template**:

```
Verify all file paths referenced in the parallel implementation plan exist in the codebase.

## Context

Read: {{FEATURE_DIR}}/parallel-plan.md

## Your Task

Scan the plan and check:

1. **Critically Relevant Files section** - Verify paths exist, check relative to project root
2. **Task Instructions** - Verify "READ THESE BEFORE TASK", "Files to Create" (check conflicts), "Files to Modify" (must exist)
3. **Documentation References** - Check /docs/ references

## Team Communication

Your teammates are:
- **dependency-validator**: Checking the task dependency graph
- **completeness-validator**: Evaluating task quality

Share missing file info with `dependency-validator` (may indicate dependency issues) and placeholder paths with `completeness-validator`.

## Task Coordination

Claim your task, do validation, share findings, mark complete.

## Output Format

Report with: Valid Paths, Missing Paths, Potential Issues, Suggestions.
Focus on accuracy - verify each path exists before marking valid.
```

---

### Agent 2: Dependency Graph Validator

**Teammate Name**: `dependency-validator`

**Subagent Type**: `explore`

**Task Description**: Analyze task dependencies

**Prompt Template**:

```
Analyze the task dependency graph in the parallel implementation plan for issues.

## Context

Read: {{FEATURE_DIR}}/parallel-plan.md

## Your Task

Extract all tasks and dependencies, check for:

1. **Circular Dependencies** - Direct or indirect cycles
2. **Missing Dependencies** - Tasks modifying files created by prior tasks without declaring dependency
3. **Orphaned Tasks** - Tasks with no downstream consumers
4. **Parallelization Opportunities** - Falsely sequential tasks

## Team Communication

Your teammates are:
- **path-validator**: Verifying file paths
- **completeness-validator**: Evaluating task quality

Share file creation chains with `path-validator` and orphaned/bottleneck tasks with `completeness-validator`.
Listen for missing file reports from `path-validator`.

## Task Coordination

Claim your task, do validation, share findings, mark complete.

## Output Format

Dependency Graph (text visualization), Issues Found, Parallelization Analysis, Recommendations.
```

---

### Agent 3: Task Completeness Validator

**Teammate Name**: `completeness-validator`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Evaluate task quality

**Prompt Template**:

```
Evaluate whether each task in the parallel implementation plan is actionable and complete.

## Context

Read:
- {{FEATURE_DIR}}/parallel-plan.md
- {{FEATURE_DIR}}/shared.md

## Your Task

For each task, evaluate: Clear Purpose, Specific File Changes, Actionable Instructions, Gotchas Documented, Appropriate Scope (1-3 files).

## Team Communication

Your teammates are:
- **path-validator**: Verifying file paths
- **dependency-validator**: Checking dependency graph

Share suspicious file paths with `path-validator` and scope issues with `dependency-validator`.
Listen for missing files and orphaned tasks from teammates.

## Task Coordination

Claim your task, do validation, share findings, mark complete.

## Output Format

Task Quality Summary, Detailed Findings (per task), Recommendations, Overall Assessment.
```

---

## Optimized Mode: 2 Validation Teammates

### Agent 1: Path and Dependency Validator (Combined)

**Teammate Name**: `path-dep-validator`

**Subagent Type**: `explore`

**Task Description**: Verify paths and dependencies

**Prompt Template**:

```
Verify all file paths and analyze the dependency graph in the parallel implementation plan.

## Context

Read: {{FEATURE_DIR}}/parallel-plan.md

## Your Task

### Part 1: File Path Validation
Verify all paths in: Critically Relevant Files, READ THESE BEFORE TASK, Files to Create/Modify, docs references. Check for conflicts.

### Part 2: Dependency Analysis
Extract tasks and dependencies. Check for: circular dependencies, missing dependencies, orphaned tasks, parallelization opportunities.

## Team Communication

Your teammate is: **completeness-validator**

Share tasks with path issues or dependency problems for their quality assessment.

## Task Coordination

Claim your task, do validation, share findings, mark complete.

## Output Format

File Path Validation summary, Dependency Graph, Combined Issues, Recommendations.
```

---

### Agent 2: Task Quality Validator

**Teammate Name**: `completeness-validator`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Evaluate task completeness

**Prompt Template**:

```
Evaluate whether each task in the parallel implementation plan is actionable and complete.

## Context

Read:
- {{FEATURE_DIR}}/parallel-plan.md
- {{FEATURE_DIR}}/shared.md

## Your Task

For each task evaluate: Clear Purpose, Specific Files, Actionable Instructions, Gotchas Documented, Appropriate Scope (1-3 files).

## Team Communication

Your teammate is: **path-dep-validator**

Listen for path/dependency issues they find and factor into your quality assessment.

## Task Coordination

Claim your task, do validation, share findings, mark complete.

## Output Format

Task Quality Summary, Detailed Findings, Priority Improvements, Overall Assessment.
```

---

## Usage Instructions

When spawning validation teammates:

1. **Read this file** to get the prompt templates
2. **Substitute variables**:
   - `{{FEATURE_NAME}}` - The feature directory name
   - `{{FEATURE_DIR}}` - Full output directory path
3. **Create tasks** - Use TaskCreate for validation tasks
4. **Spawn in parallel** - Use a single message with Agent tool calls, each with `team_name` and `name`
5. **Monitor progress** - Use TaskList to check when all tasks complete
6. **Review results** - Address issues found before finalizing plan

## Teammate Configuration

### Standard Mode

| Teammate               | Type                        | Focus             | Model   |
| ---------------------- | --------------------------- | ----------------- | ------- |
| path-validator         | `explore`                   | Path verification | haiku   |
| dependency-validator   | `explore`                   | Dependency graph  | haiku   |
| completeness-validator | `codebase-research-analyst` | Task quality      | Default |

### Optimized Mode

| Teammate               | Type                        | Focus                  | Model   |
| ---------------------- | --------------------------- | ---------------------- | ------- |
| path-dep-validator     | `explore`                   | Paths and dependencies | haiku   |
| completeness-validator | `codebase-research-analyst` | Completeness           | Default |
