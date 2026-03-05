# Analysis Agent Prompts

These prompts are used to deploy parallel analysis agents for condensing planning context before generating the parallel implementation plan.

## Global Output Contract

Apply this contract to every agent prompt in this file:

- Write only your assigned output file under `{{FEATURE_DIR}}`.
- Do not edit any other files.
- After writing the file, verify it exists using the Read tool or equivalent.
- After writing the file, return a short completion signal:
  - `STATUS: COMPLETE` or `STATUS: BLOCKED`
  - `OUTPUT: <path>`
  - `SECTIONS: <comma-separated headings>`

---

## Agent 1: Context Synthesizer

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Synthesize planning context

**Prompt Template**:

````markdown
## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: `{{FEATURE_DIR}}/analysis-context.md`

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

---

Synthesize and condense all planning documentation for the "{{FEATURE_NAME}}" feature into an actionable summary.

## Your Task

Read and analyze all planning documentation:

1. **Core Planning Documents**
   - {{FEATURE_DIR}}/shared.md
   - {{FEATURE_DIR}}/requirements.md (if exists)
   - All other .md files in {{FEATURE_DIR}}/

2. **Extract Key Information**
   - Architecture decisions relevant to implementation
   - Critical files that must be referenced
   - Existing patterns that must be followed
   - Integration points and dependencies
   - Constraints and gotchas

3. **Synthesize Don't Summarize**
   - Focus on information that directly informs task breakdown
   - Extract actionable insights, not just descriptions
   - Identify cross-cutting concerns
   - Highlight potential parallelization opportunities

## Output Format

Structure your report as:

```markdown
# Context Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences: What is being built and the core architectural approach]

## Architecture Context

- **System Structure**: [How the relevant components are organized]
- **Data Flow**: [Key data flow patterns relevant to this feature]
- **Integration Points**: [Where new code plugs into existing system]

## Critical Files Reference

- /path/to/file: [Why critical - 1 sentence]
- /path/to/another: [Why critical - 1 sentence]

## Patterns to Follow

- **Pattern Name**: [Description with example file path]
- **Another Pattern**: [Description with example file path]

## Cross-Cutting Concerns

- [Security, performance, testing, or other concerns that affect multiple tasks]

## Parallelization Opportunities

- [Areas where work can be done independently]
- [Shared files or components that need coordination]

## Implementation Constraints

- [Technical constraints (APIs, libraries, etc.)]
- [Business constraints (must maintain X, cannot break Y)]

## Key Recommendations

- [Specific advice for task breakdown]
- [Suggested phase organization]
- [Dependency management suggestions]
```

Be concise. Each bullet should be information-dense. Aim for 60-80% compression versus reading all source documents directly.

## Completion Checklist

You MUST complete ALL of these steps in order:

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-context.md
2. **Verify file**: Use the Read tool to confirm the file exists and has content
3. **Report status**: STATUS: COMPLETE, OUTPUT: {{FEATURE_DIR}}/analysis-context.md, SECTIONS: [headings]
````

---

## Agent 2: Code Analyzer

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Analyze relevant code files

**Prompt Template**:

````markdown
## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: `{{FEATURE_DIR}}/analysis-code.md`

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

---

Analyze the critically relevant code files for implementing "{{FEATURE_NAME}}" and extract actionable patterns and integration points.

## Your Task

Read and analyze code files identified in the planning documents:

1. **Read Source Files**
   - First, read {{FEATURE_DIR}}/shared.md to find "Critically Relevant Files"
   - Read each file listed in that section
   - Note: Focus on files that inform implementation patterns, not every possible file

2. **Extract Code Patterns**
   - How are similar features structured?
   - What are the naming conventions?
   - How is error handling done?
   - What testing patterns are used?
   - How are dependencies injected?

3. **Identify Integration Points**
   - Where will new code connect?
   - What interfaces exist?
   - What services/utilities are available?
   - What needs to be modified vs created?

4. **Document Code Structure**
   - File organization patterns
   - Module boundaries
   - Import/export patterns
   - Configuration patterns

## Output Format

Structure your report as:

```markdown
# Code Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences: Current code structure and how new feature fits]

## Existing Code Structure

### Related Components

- /path/to/component: [Role and relevance - 1 sentence]
- /path/to/another: [Role and relevance - 1 sentence]

### File Organization Pattern

[How similar features are organized in the codebase]

## Implementation Patterns

### Pattern: [Pattern Name]

**Description**: [How this pattern is used - 1-2 sentences]
**Example**: See `/path/to/example.ext` lines X-Y
**Apply to**: [Which tasks should use this pattern]

### Pattern: [Another Pattern]

**Description**: [How this pattern is used - 1-2 sentences]
**Example**: See `/path/to/example.ext` lines X-Y
**Apply to**: [Which tasks should use this pattern]

## Integration Points

### Files to Create

- /path/to/new/file: [Purpose and where it fits]

### Files to Modify

- /path/to/existing/file: [What kind of changes needed]
- /path/to/another/file: [What kind of changes needed]

## Code Conventions

### Naming

[File naming, function naming, class naming patterns]

### Error Handling

[How errors are handled in similar code]

### Testing

[Testing patterns and file organization]

## Dependencies and Services

### Available Utilities

- Utility/Service: [What it provides]

### Required Dependencies

- Package/module: [Why needed]

## Gotchas and Warnings

- [Non-obvious issues discovered in existing code]
- [Common pitfalls to avoid]
- [Breaking changes to watch for]

## Task-Specific Guidance

- **For database tasks**: [Specific patterns to follow]
- **For API tasks**: [Specific patterns to follow]
- **For UI tasks**: [Specific patterns to follow]
```

Focus on patterns that inform implementation. Extract actual code patterns, not just file listings.

## Completion Checklist

You MUST complete ALL of these steps in order:

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-code.md
2. **Verify file**: Use the Read tool to confirm the file exists and has content
3. **Report status**: STATUS: COMPLETE, OUTPUT: {{FEATURE_DIR}}/analysis-code.md, SECTIONS: [headings]
````

---

## Agent 3: Task Structure Agent

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Suggest task structure

**Prompt Template**:

````markdown
## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: `{{FEATURE_DIR}}/analysis-tasks.md`

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

---

Analyze the codebase structure and planning documents for "{{FEATURE_NAME}}" to suggest an optimal task breakdown and phase organization.

## Your Task

Based on the codebase structure and planning context:

1. **Understand Feature Scope**
   - Read {{FEATURE_DIR}}/shared.md
   - Read {{FEATURE_DIR}}/requirements.md (if exists)
   - Understand what components are affected

2. **Analyze Codebase Structure**
   - Explore directories relevant to the feature
   - Identify natural module boundaries
   - Find similar features for reference
   - Understand dependency relationships

3. **Suggest Task Organization**
   - Logical phases for implementation
   - Natural task boundaries (based on files/modules)
   - Which tasks can run in parallel
   - Which tasks have dependencies
   - Appropriate granularity (1-3 files per task)

4. **Consider Implementation Order**
   - Foundation tasks (models, schemas, types)
   - Core logic tasks (services, handlers)
   - Integration tasks (API, UI, tests)
   - Documentation tasks

## Output Format

Structure your report as:

```markdown
# Task Structure Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences: Suggested approach for breaking down implementation]

## Recommended Phase Structure

### Phase 1: [Foundation/Setup Phase Name]

**Purpose**: [What this phase establishes]
**Suggested Tasks**: [3-5 task descriptions at high level]
**Parallelization**: [How many can run in parallel]

### Phase 2: [Core Implementation Phase Name]

**Purpose**: [What this phase builds]
**Suggested Tasks**: [3-5 task descriptions at high level]
**Dependencies**: [What from Phase 1 is needed]
**Parallelization**: [How many can run in parallel]

### Phase 3: [Integration/Testing Phase Name]

**Purpose**: [What this phase completes]
**Suggested Tasks**: [3-5 task descriptions at high level]
**Dependencies**: [What from Phase 2 is needed]

## Task Granularity Recommendations

### Appropriate Task Sizes

- Example: "Create user model and validation" (1-2 files)
- Example: "Add authentication middleware" (1 file)
- Example: "Implement login endpoint" (1-2 files)

### Tasks to Split

- [If you see any task that's too large, suggest how to split it]

### Tasks to Combine

- [If you see any task that's too small, suggest combinations]

## Dependency Analysis

### Independent Tasks (Can Run in Parallel)

- Task: [Description] - File(s): [paths]
- Task: [Description] - File(s): [paths]

### Sequential Dependencies

- Task A must complete before Task B because: [reason]
- Task C must complete before Task D because: [reason]

### Potential Bottlenecks

- [Tasks that many others depend on]
- [Shared files that could create conflicts]

## File-to-Task Mapping

### Files to Create

| File              | Suggested Task   | Phase | Dependencies     |
| ----------------- | ---------------- | ----- | ---------------- |
| /path/to/new/file | Task description | 1     | none             |
| /path/to/another  | Task description | 2     | Phase 1 complete |

### Files to Modify

| File              | Suggested Task   | Phase | Dependencies |
| ----------------- | ---------------- | ----- | ------------ |
| /path/to/existing | Task description | 2     | Phase 1      |
| /path/to/another  | Task description | 3     | Phase 2      |

## Optimization Opportunities

### Maximize Parallelism

- [Suggestions for independent tasks]
- [Ways to reduce dependency chains]

### Minimize Risk

- [Critical path tasks that need extra attention]
- [High-risk changes that should be isolated]

## Implementation Strategy Recommendations

- [Advice on order: bottom-up vs top-down]
- [Testing strategy: when to write tests]
- [Integration approach: how to wire components together]
```

Focus on actionable structure suggestions. The goal is to help organize the parallel plan, not to write the plan itself.

## Completion Checklist

You MUST complete ALL of these steps in order:

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-tasks.md
2. **Verify file**: Use the Read tool to confirm the file exists and has content
3. **Report status**: STATUS: COMPLETE, OUTPUT: {{FEATURE_DIR}}/analysis-tasks.md, SECTIONS: [headings]
````

---

## Usage Instructions

When deploying analysis agents:

1. **Read this file** to get the prompt templates
2. **Substitute variables**:
   - `{{FEATURE_NAME}}` - The feature directory name (e.g., `user-authentication`)
   - `{{FEATURE_DIR}}` - Full output directory (e.g., `docs/plans/user-authentication`)
3. **Deploy in parallel** - Use a single message with 3 Task tool calls
4. **Wait for completion** - All agents must finish before generating the plan
5. **Verify artifacts** - Check all analysis files exist on disk before proceeding
6. **Read condensed outputs** - Review the 3 analysis files before creating parallel-plan.md

## Variable Reference

| Variable           | Description                    | Example                          |
| ------------------ | ------------------------------ | -------------------------------- |
| `{{FEATURE_NAME}}` | Feature directory name         | `user-authentication`            |
| `{{FEATURE_DIR}}`  | Full analysis output directory | `docs/plans/user-authentication` |

## Agent Configuration

| Agent                | Type                        | Output File         |
| -------------------- | --------------------------- | ------------------- |
| Context Synthesizer  | `codebase-research-analyst` | analysis-context.md |
| Code Analyzer        | `codebase-research-analyst` | analysis-code.md    |
| Task Structure Agent | `codebase-research-analyst` | analysis-tasks.md   |

## Expected Output Size

Each analysis file should be:

- **Condensed**: 60-80% smaller than reading source files directly
- **Actionable**: Focus on what informs task breakdown
- **Structured**: Follow the output format exactly for consistent consumption

Total context consumption: ~5-10K tokens (vs 50-100K+ reading files directly)
