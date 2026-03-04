# Validation Agent Prompts

These prompts are used to deploy parallel validation agents after creating a parallel plan. This is Phase 5 of the unified planning workflow.

---

## Standard Mode: 3 Validation Agents

### Agent 1: File Path Validator

**Subagent Type**: `explore`

**Task Description**: Verify file path references

**Prompt Template**:

```
Verify all file paths referenced in the parallel implementation plan exist in the codebase.

## Context

Read: {{FEATURE_DIR}}/parallel-plan.md

## Your Task

Scan the plan and check:

1. **Critically Relevant Files section**
   - Verify each listed file path exists
   - Check if paths are relative to project root

2. **Task Instructions**
   - Verify files in "READ THESE BEFORE TASK" sections
   - Check "Files to Create" for conflicts with existing files
   - Verify "Files to Modify" exist

3. **Documentation References**
   - Check any /docs/ references are valid

## Output Format

Provide a report with:

**Valid Paths** (checkmark)
- /path/to/file.ext
- /path/to/another.ext

**Missing Paths** (X)
- /path/to/nonexistent.ext - File not found
- /path/to/missing.ext - File not found

**Potential Issues** (warning)
- /path/to/file.ext - Listed in "Files to Create" but already exists
- /path/to/ambiguous - Multiple files match pattern

**Suggestions**
- Correct path for /wrong/path.ext might be /correct/path.ext
- Consider adding missing file references

Focus on accuracy - verify each path exists before marking valid.
```

---

### Agent 2: Dependency Graph Validator

**Subagent Type**: `explore`

**Task Description**: Analyze task dependencies

**Prompt Template**:

```
Analyze the task dependency graph in the parallel implementation plan for issues.

## Context

Read: {{FEATURE_DIR}}/parallel-plan.md

## Your Task

Extract all tasks and their dependencies, then check for:

1. **Circular Dependencies**
   - Tasks that depend on each other (directly or indirectly)
   - Example: Task 2.1 depends on 3.1, and 3.1 depends on 2.1

2. **Missing Dependencies**
   - Tasks that reference or modify files created by prior tasks
   - Tasks that should depend on each other but don't

3. **Orphaned Tasks**
   - Tasks that nothing depends on and don't contribute to later work

4. **Parallelization Opportunities**
   - Tasks marked as dependent that could actually run in parallel
   - Tasks that share no file modifications or data dependencies

## Output Format

**Dependency Graph** (text visualization)
```

Phase 1:
1.1 [none] ----+
1.2 [none] ----+--> Phase 2
1.3 [1.1] ----+

Phase 2:
2.1 [1.1, 1.2] ---> 2.3
2.2 [none] ---> 2.3
2.3 [2.1, 2.2]

```

**Issues Found**

Circular Dependencies: [count]
- Task 2.1 -> 3.1 -> 2.1 (circular)

Missing Dependencies: [count]
- Task 3.1 modifies file created in 2.2 but doesn't depend on it

Orphaned Tasks: [count]
- Task 1.3 creates file never used

**Parallelization Analysis**

Current parallelizable tasks: [count]
Potential additional parallel tasks: [count]
- Tasks 2.1 and 2.2 could run in parallel (no shared dependencies)

**Recommendations**
- Add dependency: 3.1 depends on [2.2]
- Consider removing orphaned task 1.3 or clarify its purpose
- Tasks 2.1 and 2.2 can be marked [none] to increase parallelism
```

---

### Agent 3: Task Completeness Validator

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

For each task, evaluate:

1. **Clear Purpose**
   - Is it obvious what this task accomplishes?
   - Is the task title descriptive?

2. **Specific File Changes**
   - Are file paths specific (not placeholders)?
   - Are both creation and modification clear?

3. **Actionable Instructions**
   - Can a developer implement without guessing?
   - Are integration points clear?
   - Are patterns to follow specified?

4. **Gotchas Documented**
   - Are non-obvious issues mentioned?
   - Are dependencies on existing code noted?
   - Are edge cases addressed?

5. **Appropriate Scope**
   - Is the task small enough (1-3 files)?
   - Should it be broken into subtasks?

## Output Format

**Task Quality Summary**

Total Tasks: [count]
High Quality: [count] (checkmark)
Needs Minor Improvements: [count] (warning)
Needs Significant Work: [count] (X)

**Detailed Findings**

(checkmark) Task 1.1: [Title] - Well-defined and actionable
(checkmark) Task 1.2: [Title] - Clear purpose and instructions

(warning) Task 2.1: [Title]
  - Missing: Gotchas or edge cases
  - Suggestion: Mention how this integrates with existing auth system

(warning) Task 2.3: [Title]
  - Issue: Scope too large (modifies 5 files)
  - Suggestion: Split into 2.3a and 2.3b

(X) Task 3.1: [Title]
  - Missing: Specific file paths (uses placeholders)
  - Missing: Clear instructions for implementation
  - Missing: Pattern to follow
  - Needs: Complete rewrite with specific details

**Recommendations**

Priority Improvements:
1. Task 3.1 - Add specific file paths and detailed instructions
2. Task 2.3 - Split into smaller tasks
3. Task 2.1 - Document integration gotchas

Overall Assessment:
[Summary of plan quality and readiness for implementation]
```

---

## Optimized Mode: 2 Validation Agents

When `--optimized` flag is used, deploy 2 agents instead of 3:

### Agent 1: Path and Dependency Validator (Combined)

**Subagent Type**: `explore`

**Task Description**: Verify paths and dependencies

**Prompt Template**:

```
Verify all file paths and analyze the dependency graph in the parallel implementation plan.

## Context

Read: {{FEATURE_DIR}}/parallel-plan.md

## Your Task

### Part 1: File Path Validation

1. Verify all file paths in:
   - Critically Relevant Files section
   - READ THESE BEFORE TASK sections
   - Files to Create and Files to Modify lists
   - Documentation references

2. Check for conflicts:
   - Files marked for creation that already exist
   - Ambiguous paths matching multiple files

### Part 2: Dependency Analysis

1. Extract all tasks and dependencies
2. Check for:
   - Circular dependencies
   - Missing dependencies (file-based)
   - Orphaned tasks
   - Parallelization opportunities

## Output Format

**File Path Validation**

Valid: [count]
Missing: [count]
Conflicts: [count]

[List any issues with specific paths]

**Dependency Graph**

[Text visualization of dependency relationships]

**Issues Found**

[Combined list of path and dependency issues]

**Recommendations**

[Prioritized list of fixes needed]
```

---

### Agent 2: Task Quality Validator

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

For each task, evaluate:

1. **Clear Purpose** - Is the goal obvious?
2. **Specific Files** - Are paths specific (not placeholders)?
3. **Actionable Instructions** - Can it be implemented without guessing?
4. **Gotchas Documented** - Are non-obvious issues mentioned?
5. **Appropriate Scope** - Is it 1-3 files maximum?

## Output Format

**Task Quality Summary**

Total Tasks: [count]
High Quality: [count]
Needs Improvement: [count]
Needs Rewrite: [count]

**Detailed Findings**

[Per-task evaluation with specific issues and suggestions]

**Priority Improvements**

[Ordered list of most important fixes]

**Overall Assessment**

[Summary of plan quality and implementation readiness]
```

---

## Usage Instructions

When deploying validation agents:

1. **Read this file** to get the prompt templates
2. **Substitute variables**:
   - `{{FEATURE_NAME}}` - The feature directory name
   - `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 2)
3. **Deploy in parallel** - Use a single message with 3 Task tool calls (or 2 in optimized mode)
4. **Review results** - Address issues found before finalizing plan

## Variable Reference

| Variable           | Description                | Example                          |
| ------------------ | -------------------------- | -------------------------------- |
| `{{FEATURE_NAME}}` | Feature directory name     | `user-authentication`            |
| `{{FEATURE_DIR}}`  | Full output directory path | `docs/plans/user-authentication` |

## Agent Configuration

### Standard Mode

| Agent                | Type                        | Focus             | Model   |
| -------------------- | --------------------------- | ----------------- | ------- |
| File Path Validator  | `explore`                   | Path verification | haiku   |
| Dependency Validator | `explore`                   | Dependency graph  | haiku   |
| Task Completeness    | `codebase-research-analyst` | Task quality      | Default |

### Optimized Mode

| Agent             | Type                        | Focus                  | Model   |
| ----------------- | --------------------------- | ---------------------- | ------- |
| Path + Dependency | `explore`                   | Paths and dependencies | haiku   |
| Task Quality      | `codebase-research-analyst` | Completeness           | Default |
