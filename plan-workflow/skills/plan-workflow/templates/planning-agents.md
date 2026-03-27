# Planning Agent Prompts

These prompts are used to spawn analysis teammates for condensing planning context before generating the parallel implementation plan. This is Phase 5 of the unified planning workflow (standard mode only). Teammates share findings with each other via messages.

## Global Output Contract

Apply this contract to every teammate prompt in this file:

- Write only your assigned output file under `{{FEATURE_DIR}}`.
- Do not edit any other files.
- After writing the file, verify it exists using the Read tool or equivalent.
- **Share key findings** with relevant teammates using SendMessage.
- After writing the file and sharing findings, mark your task as complete using TaskUpdate.

---

## Agent 1: Context Synthesizer

**Teammate Name**: `context-synthesizer`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Synthesize planning context

**Prompt Template**:

````markdown
## PRIMARY DELIVERABLE

**Output File**: {{FEATURE_DIR}}/analysis-context.md

You MUST write this file using the Write tool. This is your #1 job. Everything else is secondary.

---

Synthesize and condense all planning documentation for the "{{FEATURE_NAME}}" feature into an
actionable summary.

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

## Team Communication

You are part of an analysis team. Your teammates are:

- **code-analyzer**: Extracting code patterns from relevant files
- **task-structurer**: Suggesting task breakdown and phases

**Share these findings via SendMessage:**

- Message `code-analyzer` with: critical files to prioritize, architectural patterns affecting code analysis
- Message `task-structurer` with: cross-cutting concerns, parallelization opportunities, constraints

**Listen for messages from teammates** — `code-analyzer` may share patterns that affect your synthesis.

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your analysis
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

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

## Patterns to Follow

- **Pattern Name**: [Description with example file path]

## Cross-Cutting Concerns

- [Security, performance, testing, or other concerns that affect multiple tasks]

## Parallelization Opportunities

- [Areas where work can be done independently]

## Implementation Constraints

- [Technical and business constraints]

## Key Recommendations

- [Specific advice for task breakdown]
```

Be concise. Each bullet should be information-dense. Aim for 60-80% compression.

## Completion Checklist

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-context.md
2. **Verify file**: Use the Read tool to confirm the file exists
3. **Share findings**: Message teammates with key insights
4. **Mark complete**: Update your task status to completed
````

---

## Agent 2: Code Analyzer

**Teammate Name**: `code-analyzer`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Analyze relevant code files

**Prompt Template**:

```markdown
## PRIMARY DELIVERABLE

**Output File**: {{FEATURE_DIR}}/analysis-code.md

You MUST write this file using the Write tool. This is your #1 job. Everything else is secondary.

---

Analyze the critically relevant code files for implementing "{{FEATURE_NAME}}" and extract
actionable patterns and integration points.

## Your Task

1. **Read Source Files** - Read {{FEATURE_DIR}}/shared.md to find relevant files, then read each
2. **Extract Code Patterns** - Structure, naming, error handling, testing, dependency injection
3. **Identify Integration Points** - Interfaces, services, what to modify vs create
4. **Document Code Structure** - File organization, module boundaries, imports, config

## Team Communication

You are part of an analysis team. Your teammates are:

- **context-synthesizer**: Condensing planning documentation
- **task-structurer**: Suggesting task breakdown and phases

**Share these findings via SendMessage:**

- Message `context-synthesizer` with: patterns or architectural insights for context synthesis
- Message `task-structurer` with: file-to-task mapping, file groupings, dependency relationships

**Listen for messages from teammates** — especially from `context-synthesizer` who may point you to critical files.

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your analysis
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Format

Structure your report with: Executive Summary, Existing Code Structure, Implementation Patterns (with examples), Integration Points (files to create/modify), Code Conventions, Dependencies and Services, Gotchas and Warnings, Task-Specific Guidance.

Focus on patterns that inform implementation. Extract actual code patterns, not just file listings.

## Completion Checklist

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-code.md
2. **Verify file**: Use the Read tool to confirm the file exists
3. **Share findings**: Message teammates with key insights
4. **Mark complete**: Update your task status to completed
```

---

## Agent 3: Task Structure Agent

**Teammate Name**: `task-structurer`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Suggest task structure

**Prompt Template**:

```markdown
## PRIMARY DELIVERABLE

**Output File**: {{FEATURE_DIR}}/analysis-tasks.md

You MUST write this file using the Write tool. This is your #1 job. Everything else is secondary.

---

Analyze the codebase structure and planning documents for "{{FEATURE_NAME}}" to suggest an optimal
task breakdown and phase organization.

## Your Task

1. **Understand Feature Scope** - Read shared.md, requirements.md if exists
2. **Analyze Codebase Structure** - Explore relevant directories, find module boundaries
3. **Suggest Task Organization** - Phases, task boundaries (1-3 files per task), parallelism, dependencies
4. **Consider Implementation Order** - Foundation → core logic → integration → docs

## Team Communication

You are part of an analysis team. Your teammates are:

- **context-synthesizer**: Condensing planning documentation
- **code-analyzer**: Extracting code patterns from relevant files

**Share these findings via SendMessage:**

- Message `context-synthesizer` with: scope clarifications or missing context
- Message `code-analyzer` with: specific files important for pattern analysis

**Listen for messages from teammates** — especially from `code-analyzer` for file-to-task mapping insights, and `context-synthesizer` for parallelization opportunities.

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your analysis
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Format

Structure your report with: Executive Summary, Recommended Phase Structure, Task Granularity Recommendations, Dependency Analysis, File-to-Task Mapping, Optimization Opportunities, Implementation Strategy Recommendations.

Focus on actionable structure suggestions. The goal is to help organize the parallel plan, not to write the plan itself.

## Completion Checklist

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-tasks.md
2. **Verify file**: Use the Read tool to confirm the file exists
3. **Share findings**: Message teammates with key insights
4. **Mark complete**: Update your task status to completed
```

---

## Usage Instructions

When spawning analysis teammates:

1. **Read this file** to get the prompt templates
2. **Substitute variables**:
   - `{{FEATURE_NAME}}` - The feature directory name
   - `{{FEATURE_DIR}}` - Full output directory
3. **Create tasks** - Use TaskCreate to create 3 analysis tasks
4. **Spawn in parallel** - Use a single message with 3 Agent tool calls, each with `team_name` and `name`
5. **Monitor progress** - Use TaskList to check when all tasks complete
6. **Verify artifacts** - Check all analysis files exist on disk
7. **Shut down teammates** - Send shutdown requests via SendMessage
8. **Read condensed outputs** - Review the 3 analysis files before creating parallel-plan.md

## Teammate Configuration

| Teammate            | Type                        | Output File         | Model  |
| ------------------- | --------------------------- | ------------------- | ------ |
| context-synthesizer | `codebase-research-analyst` | analysis-context.md | sonnet |
| code-analyzer       | `codebase-research-analyst` | analysis-code.md    | sonnet |
| task-structurer     | `codebase-research-analyst` | analysis-tasks.md   | sonnet |

## Expected Output Size

Each analysis file should be:

- **Condensed**: 60-80% smaller than reading source files directly
- **Actionable**: Focus on what informs task breakdown
- **Structured**: Follow the output format exactly

Total context consumption: ~5-10K tokens (vs 50-100K+ reading files directly)
