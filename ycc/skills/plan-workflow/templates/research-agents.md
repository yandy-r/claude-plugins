# Research Agent Prompts

These prompts are used to spawn research teammates for gathering shared context. This is Phase 1 of the unified planning workflow. Teammates share findings with each other via messages.

## Global Output Contract

Apply this contract to every teammate prompt in this file:

- Write only your assigned output file under `{{FEATURE_DIR}}`.
- Do not edit any other files.
- After writing the file, verify it exists using the Read tool or equivalent.
- **Share key findings** with relevant teammates using SendMessage.
- After writing the file and sharing findings, mark your task as complete using TaskUpdate.

---

## Agent 1: Architecture Researcher

**Teammate Name**: `architecture-researcher`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Analyze system architecture

**Prompt Template**:

````markdown
Research the codebase architecture relevant to implementing "{{FEATURE_NAME}}".

## Your Task

Analyze the codebase to understand:

1. **System Structure**
   - What are the main components/modules involved?
   - How is the codebase organized (directories, layers)?
   - What frameworks or libraries are in use?

2. **Data Flow**
   - How does data flow through the system?
   - What are the entry points (APIs, events, etc.)?
   - Where is business logic concentrated?

3. **Component Relationships**
   - How do components communicate?
   - What are the key dependencies?
   - Are there shared services or utilities?

4. **Integration Points**
   - Where would new feature code plug in?
   - What existing components would be affected?

## Team Communication

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `SendMessage`, `TaskUpdate`, or `TaskList`, ignore this section entirely and just write your output file.

You are part of a research team. Your teammates are:

- **patterns-researcher**: Researching code patterns and conventions
- **integration-researcher**: Researching APIs, databases, external systems
- **docs-researcher**: Finding relevant documentation

**Share these findings via SendMessage:**

- Message `patterns-researcher` with: architectural patterns you discover (service layers, repository patterns, etc.) and their file locations
- Message `integration-researcher` with: any API endpoints, database connections, or external service integrations you find during architecture analysis
- Message `docs-researcher` with: any architecture documentation files or inline docs you encounter

## Task Coordination

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `TaskList` / `TaskUpdate`, ignore this section entirely; the orchestrator gates on the artifact file existing on disk.

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-architecture.md

Structure your report as:

```markdown
# Architecture Research: {{FEATURE_NAME}}

## System Overview

[2-3 sentences on overall architecture]

## Relevant Components

- /path/to/component: Description of role
- /path/to/another: Description of role

## Data Flow

[Describe how data moves through relevant parts]

## Integration Points

[Where new code should connect]

## Key Dependencies

[External libraries, services, or internal modules]
```

Focus on areas directly relevant to {{FEATURE_NAME}}. Be specific with file paths.
````

---

## Agent 2: Pattern Researcher

**Teammate Name**: `patterns-researcher`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Identify coding patterns

**Prompt Template**:

````markdown
Research the coding patterns and conventions used in this codebase that are relevant to implementing "{{FEATURE_NAME}}".

## Your Task

Identify and document:

1. **Architectural Patterns** - Repository pattern, service layer, abstractions
2. **Code Conventions** - Naming, file organization, import/export
3. **Error Handling** - Error propagation, types, logging
4. **Testing Patterns** - Test structure, mocking, organization

## Team Communication

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `SendMessage`, `TaskUpdate`, or `TaskList`, ignore this section entirely and just write your output file.

You are part of a research team. Your teammates are:

- **architecture-researcher**: Analyzing system structure and components
- **integration-researcher**: Researching APIs, databases, external systems
- **docs-researcher**: Finding relevant documentation

**Share these findings via SendMessage:**

- Message `integration-researcher` with: any API patterns, middleware patterns, or database access patterns you discover
- Message `architecture-researcher` with: any structural patterns that affect the overall architecture analysis

**Listen for messages from teammates** — especially from `architecture-researcher` who may share architectural patterns they found that you should investigate deeper.

## Task Coordination

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `TaskList` / `TaskUpdate`, ignore this section entirely; the orchestrator gates on the artifact file existing on disk.

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-patterns.md

Structure your report as:

```markdown
# Pattern Research: {{FEATURE_NAME}}

## Architectural Patterns

**Pattern Name**: Description of how it's used

- Example: /path/to/example.ext

## Code Conventions

[Naming, organization, style conventions]

## Error Handling

[How errors are handled in similar code]

## Testing Approach

[How to test similar features]

## Patterns to Follow

[Specific patterns that should be used for this feature]
```

Find concrete examples for each pattern. Include file paths.
````

---

## Agent 3: Integration Researcher

**Teammate Name**: `integration-researcher`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Research APIs and data sources

**Prompt Template**:

```markdown
Research the APIs, databases, and external integrations relevant to implementing "{{FEATURE_NAME}}".

## Your Task

Investigate:

1. **API Endpoints** - Existing related endpoints, route organization, middleware
2. **Database Schema** - Relevant tables, relationships, migrations
3. **External Services** - Third-party integrations, credentials, config
4. **Internal Services** - Internal service communication patterns

## Team Communication

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `SendMessage`, `TaskUpdate`, or `TaskList`, ignore this section entirely and just write your output file.

You are part of a research team. Your teammates are:

- **architecture-researcher**: Analyzing system structure and components
- **patterns-researcher**: Researching code patterns and conventions
- **docs-researcher**: Finding relevant documentation

**Share these findings via SendMessage:**

- Message `architecture-researcher` with: service boundaries, data flow patterns, or component dependencies you discover
- Message `patterns-researcher` with: middleware patterns, database access patterns, or API conventions
- Message `docs-researcher` with: API documentation, schema documentation, or configuration docs you encounter

**Listen for messages from teammates** — especially from `architecture-researcher` and `patterns-researcher`.

## Task Coordination

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `TaskList` / `TaskUpdate`, ignore this section entirely; the orchestrator gates on the artifact file existing on disk.

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-integration.md

Structure your report following the integration research format with API endpoints, database schema, external/internal services, and configuration sections.

Be thorough with database schema - this informs data modeling decisions.
```

---

## Agent 4: Documentation Researcher

**Teammate Name**: `docs-researcher`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Find relevant documentation

**Prompt Template**:

```markdown
Find all documentation files relevant to implementing "{{FEATURE_NAME}}".

## Your Task

Search for documentation in:

1. **docs/ Directory** - Architecture, API, feature, development guides
2. **README Files** - Root, directory-level, module READMEs
3. **Code Comments** - Well-documented modules, API docs in code
4. **External References** - Links to external docs, specs, library docs

## Team Communication

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `SendMessage`, `TaskUpdate`, or `TaskList`, ignore this section entirely and just write your output file.

You are part of a research team. Your teammates are:

- **architecture-researcher**: Analyzing system structure and components
- **patterns-researcher**: Researching code patterns and conventions
- **integration-researcher**: Researching APIs, databases, external systems

**Share these findings via SendMessage:**

- Message `architecture-researcher` with: architecture documentation (design docs, ADRs, system diagrams)
- Message `patterns-researcher` with: coding guidelines, style guides, convention documentation
- Message `integration-researcher` with: API documentation, database docs, integration guides

**Listen for messages from teammates** — they may point you to documentation files they encountered.

## Task Coordination

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `TaskList` / `TaskUpdate`, ignore this section entirely; the orchestrator gates on the artifact file existing on disk.

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-docs.md

Structure your report with Architecture Docs, API Docs, Development Guides, README Files, Must-Read Documents, and Documentation Gaps sections.

Focus on documents that would help someone implement {{FEATURE_NAME}}.
Identify which documents are REQUIRED reading vs nice-to-have.
```

---

## Optimized Mode: Unified Agents

When `--optimized` flag is used, deploy these 5 unified teammates instead. Each prompt below carries the same write contract as the standard-mode prompts above: a `## PRIMARY DELIVERABLE` block, an explicit "You MUST write this file" imperative, an `## Output Format` skeleton, and a `## Completion Checklist`. The `## Team Communication` block is Path B (`--team`) only — standalone sub-agents (Path A, default) skip it.

### Agent 1: Architecture Analyst (Unified)

**Teammate Name**: `arch-analyst`

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

```markdown
## PRIMARY DELIVERABLE

**Output File**: {{FEATURE_DIR}}/analysis-architecture.md

You MUST write this file using the Write tool. This is your #1 job. Everything else is secondary. Do NOT return your findings in summary text without writing the file — the orchestrator will fail the pre-generation gate and re-dispatch you.

---

Analyze the codebase architecture for implementing "{{FEATURE_NAME}}" and synthesize actionable context in a single pass.

## Combined Task

Perform both architecture research AND context synthesis:

1. **Architecture Research** — System structure, data flow, component relationships, integration points
2. **Context Synthesis** — Condense findings into actionable insights, critical files, cross-cutting concerns

## Team Communication

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `SendMessage`, `TaskUpdate`, or `TaskList`, ignore this section entirely and just write your output file.

Your teammates are: `pattern-analyst`, `integration-analyst`, `docs-analyst`, `task-planner`. Share architectural patterns with `pattern-analyst`, integration points with `integration-analyst`, architecture docs with `docs-analyst`, and parallelization opportunities with `task-planner`.

## Output Format

Structure your report as:

\`\`\`markdown

# Architecture Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences on the overall architecture and what it means for this feature]

## Architecture Context

- **System Structure**: [How the relevant components are organized]
- **Data Flow**: [Key data flow patterns relevant to this feature]
- **Integration Points**: [Where new code plugs in]

## Critical Files Reference

- /path/to/file: [Why critical — 1 sentence]

## Cross-Cutting Concerns

- [Security, performance, testing, or other concerns affecting multiple tasks]

## Parallelization Opportunities

- [Areas where work can be done independently]

## Implementation Constraints

- [Technical and business constraints]
  \`\`\`

Be concise. Each bullet should be information-dense.

## Completion Checklist

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-architecture.md
2. **Verify file**: Use the Read tool to confirm the file exists and has the expected structure
3. **(Path B only)** Share findings via SendMessage, then mark your task complete via TaskUpdate
```

### Agent 2: Pattern Analyst (Unified)

**Teammate Name**: `pattern-analyst`

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

```markdown
## PRIMARY DELIVERABLE

**Output File**: {{FEATURE_DIR}}/analysis-patterns.md

You MUST write this file using the Write tool. This is your #1 job. Everything else is secondary. Do NOT return your findings in summary text without writing the file — the orchestrator will fail the pre-generation gate and re-dispatch you.

---

Analyze coding patterns for implementing "{{FEATURE_NAME}}" and extract implementation guidance in a single pass.

## Combined Task

Perform both pattern research AND code analysis:

1. **Pattern Research** — Architectural patterns, code conventions, error handling, testing
2. **Code Analysis** — Implementation patterns from relevant files, file organization, integration points

## Team Communication

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `SendMessage`, `TaskUpdate`, or `TaskList`, ignore this section entirely and just write your output file.

Your teammates are: `arch-analyst`, `integration-analyst`, `docs-analyst`, `task-planner`. Share pattern insights with `arch-analyst`, API patterns with `integration-analyst`, and file-to-task mapping with `task-planner`.

## Output Format

Structure your report as:

\`\`\`markdown

# Pattern & Code Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences on dominant patterns and conventions relevant to this feature]

## Implementation Patterns

- **Pattern Name**: [Description] — example: /path/to/file

## Existing Code Structure

[File organization, module boundaries, imports, config]

## Code Conventions

[Naming, style, error handling, testing approach]

## Integration Points

- /path/to/file: [Files to create vs. modify]

## Gotchas and Warnings

- [Things that look like patterns but aren't, deprecated paths, etc.]
  \`\`\`

Extract actual code patterns with file paths, not just file listings.

## Completion Checklist

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-patterns.md
2. **Verify file**: Use the Read tool to confirm the file exists and has the expected structure
3. **(Path B only)** Share findings via SendMessage, then mark your task complete via TaskUpdate
```

### Agent 3: Integration Analyst

**Teammate Name**: `integration-analyst`

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

```markdown
## PRIMARY DELIVERABLE

**Output File**: {{FEATURE_DIR}}/analysis-integration.md

You MUST write this file using the Write tool. This is your #1 job. Everything else is secondary. Do NOT return your findings in summary text without writing the file — the orchestrator will fail the pre-generation gate and re-dispatch you.

---

Analyze APIs, databases, and integrations relevant to implementing "{{FEATURE_NAME}}".

## Your Task

Investigate:

1. **API Endpoints** — Existing related endpoints, route organization, middleware
2. **Database Schema** — Relevant tables, relationships, migrations
3. **External Services** — Third-party integrations, credentials, config
4. **Internal Services** — Internal service communication patterns

## Team Communication

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `SendMessage`, `TaskUpdate`, or `TaskList`, ignore this section entirely and just write your output file.

Your teammates are: `arch-analyst`, `pattern-analyst`, `docs-analyst`, `task-planner`. Share service boundaries with `arch-analyst`, API patterns with `pattern-analyst`, and API docs with `docs-analyst`.

## Output Format

Structure your report as:

\`\`\`markdown

# Integration Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences summarizing the integration surface for this feature]

## API Endpoints

- METHOD /path: [Purpose] — handler at /path/to/file

## Database

[Tables, relationships, migrations relevant to this feature]

## External Services

[Third-party APIs, credentials, configuration]

## Integration Points

[Where this feature plugs into existing integration code]
\`\`\`

Be specific with route paths, table names, and file references.

## Completion Checklist

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-integration.md
2. **Verify file**: Use the Read tool to confirm the file exists and has the expected structure
3. **(Path B only)** Share findings via SendMessage, then mark your task complete via TaskUpdate
```

### Agent 4: Documentation Analyst

**Teammate Name**: `docs-analyst`

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

```markdown
## PRIMARY DELIVERABLE

**Output File**: {{FEATURE_DIR}}/analysis-docs.md

You MUST write this file using the Write tool. This is your #1 job. Everything else is secondary. Do NOT return your findings in summary text without writing the file — the orchestrator will fail the pre-generation gate and re-dispatch you.

---

Find and analyze documentation relevant to implementing "{{FEATURE_NAME}}".

## Your Task

Search for documentation in:

1. **docs/ directory** — Architecture, API, feature, development guides
2. **README files** — Root, directory-level, module READMEs
3. **Code comments** — Well-documented modules, API docs in code
4. **External references** — Links to external docs, specs, library docs

## Team Communication

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `SendMessage`, `TaskUpdate`, or `TaskList`, ignore this section entirely and just write your output file.

Your teammates are: `arch-analyst`, `pattern-analyst`, `integration-analyst`, `task-planner`. Share architecture docs with `arch-analyst`, coding guidelines with `pattern-analyst`, and API docs with `integration-analyst`.

## Output Format

Structure your report as:

\`\`\`markdown

# Documentation Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences on the documentation surface for this feature]

## Must-Read Documents

- /path/to/doc: [Why required — 1 sentence]

## Architecture Docs

- /path/to/doc: [What it covers]

## Reading List

[Prioritized list for implementers — required vs. nice-to-have]

## Documentation Gaps

[Areas where documentation is missing or stale and should be written]
\`\`\`

Identify which documents are REQUIRED reading vs nice-to-have.

## Completion Checklist

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-docs.md
2. **Verify file**: Use the Read tool to confirm the file exists and has the expected structure
3. **(Path B only)** Share findings via SendMessage, then mark your task complete via TaskUpdate
```

### Agent 5: Task Planner (Unified)

**Teammate Name**: `task-planner`

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

```markdown
## PRIMARY DELIVERABLE

**Output File**: {{FEATURE_DIR}}/analysis-tasks.md

You MUST write this file using the Write tool. This is your #1 job. Everything else is secondary. Do NOT return your findings in summary text without writing the file — the orchestrator will fail the pre-generation gate and re-dispatch you.

---

Analyze the codebase structure for "{{FEATURE_NAME}}" and suggest an optimal task breakdown and phase organization.

## Your Task

1. **Understand feature scope** — Read shared context and prior research files
2. **Analyze codebase structure** — Module boundaries, file groupings
3. **Suggest task organization** — Phases, task boundaries (1-3 files per task), parallelism, dependencies
4. **Consider implementation order** — Foundation → core logic → integration → docs

## Team Communication

> **Path B (`--team`) only — skip in standalone (Path A) mode.** If you do not have access to `SendMessage`, `TaskUpdate`, or `TaskList`, ignore this section entirely and just write your output file.

Your teammates are: `arch-analyst`, `pattern-analyst`, `integration-analyst`, `docs-analyst`. Listen for parallelization opportunities from `arch-analyst` and file-to-task mapping from `pattern-analyst`.

## Output Format

Structure your report as:

\`\`\`markdown

# Task Structure Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences on the recommended task shape for this feature]

## Recommended Phase Structure

- **Phase 1: [name]** — [purpose, dependencies]
- **Phase 2: [name]** — [purpose, dependencies]

## Task Granularity

[Recommendation on task size, files per task, what to bundle vs. split]

## Dependency Analysis

[Which tasks block which; circular-dependency check]

## File-to-Task Mapping

- /path/to/file: [Which task owns it]
  \`\`\`

Focus on actionable structure. The goal is to help organize the parallel plan, not to write the plan itself.

## Completion Checklist

1. **Write file**: Use the Write tool to create {{FEATURE_DIR}}/analysis-tasks.md
2. **Verify file**: Use the Read tool to confirm the file exists and has the expected structure
3. **(Path B only)** Share findings via SendMessage, then mark your task complete via TaskUpdate
```

---

## Usage Instructions

When spawning research teammates:

1. **Read this file** to get the prompt templates
2. **Substitute variables**:
   - `{{FEATURE_NAME}}` - The feature directory name (e.g., `user-authentication`)
   - `{{FEATURE_DIR}}` - Full output directory (e.g., `docs/plans/user-authentication`)
3. **Create tasks** - Use TaskCreate to create research tasks
4. **Spawn in parallel** - Use a single message with multiple Agent tool calls, each with `team_name` and `name`
5. **Monitor progress** - Use TaskList to check when all tasks complete
6. **Verify artifacts** - Check all research files exist on disk
7. **Shut down teammates** - Send shutdown requests via SendMessage
8. **Read results** - Review each research file before writing shared.md

## Variable Reference

| Variable           | Description                    | Example                          |
| ------------------ | ------------------------------ | -------------------------------- |
| `{{FEATURE_NAME}}` | Feature directory name         | `user-authentication`            |
| `{{FEATURE_DIR}}`  | Full research output directory | `docs/plans/user-authentication` |

## Teammate Configuration

| Teammate                | Type                        | Output File              | Model  |
| ----------------------- | --------------------------- | ------------------------ | ------ |
| architecture-researcher | `codebase-research-analyst` | research-architecture.md | sonnet |
| patterns-researcher     | `codebase-research-analyst` | research-patterns.md     | sonnet |
| integration-researcher  | `codebase-research-analyst` | research-integration.md  | sonnet |
| docs-researcher         | `codebase-research-analyst` | research-docs.md         | sonnet |

## Optimized Mode Teammate Configuration

| Teammate            | Type                        | Output File              | Model  |
| ------------------- | --------------------------- | ------------------------ | ------ |
| arch-analyst        | `codebase-research-analyst` | analysis-architecture.md | sonnet |
| pattern-analyst     | `codebase-research-analyst` | analysis-patterns.md     | sonnet |
| integration-analyst | `codebase-research-analyst` | analysis-integration.md  | sonnet |
| docs-analyst        | `codebase-research-analyst` | analysis-docs.md         | sonnet |
| task-planner        | `codebase-research-analyst` | analysis-tasks.md        | sonnet |
