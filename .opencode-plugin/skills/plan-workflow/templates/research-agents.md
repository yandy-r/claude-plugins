# Research Agent Prompts

These prompts are used to spawn research sub-agents for gathering shared context. This is Phase 1 of the unified planning workflow. Sub-agents share findings with each other via messages.

## Global Output Contract

Apply this contract to every sub-agent prompt in this file:

- Write only your assigned output file under `{{FEATURE_DIR}}`.
- Do not edit any other files.
- After writing the file, verify it exists using the Read tool or equivalent.
- **Share key findings** with relevant sub-agents using re-dispatch the affected sub-agent with the needed guidance.
- After writing the file and sharing findings, mark your task as complete using update the todo tracker.

---

## Agent 1: Architecture Researcher

**Sub-agent Role**: `architecture-researcher`

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

## Task Coordination


1. Check the todo tracker for your assigned task
2. Claim your task with update the todo tracker (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with sub-agents
5. Write your output file
6. Mark your task complete with update the todo tracker

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-architecture.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Share key findings with sub-agents
4. Mark your task as complete

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

**Sub-agent Role**: `patterns-researcher`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Identify coding patterns

**Prompt Template**:

````markdown
Research the coding patterns and conventions used in this codebase that are relevant to implementing "{{FEATURE_NAME}}".

## Your Task

Identify and document:

1. **Architectural Patterns**
   - Repository pattern, service layer, etc.
   - How are similar features structured?
   - What abstraction patterns are used?

2. **Code Conventions**
   - Naming conventions (files, functions, classes)
   - File organization within modules
   - Import/export patterns

3. **Error Handling**
   - How are errors propagated?
   - What error types are used?
   - Logging conventions

4. **Testing Patterns**
   - How are similar features tested?
   - Test file organization
   - Mocking patterns

## Task Coordination


1. Check the todo tracker for your assigned task
2. Claim your task with update the todo tracker (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with sub-agents
5. Write your output file
6. Mark your task complete with update the todo tracker

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-patterns.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Share key findings with sub-agents
4. Mark your task as complete

Structure your report as:

```markdown
# Pattern Research: {{FEATURE_NAME}}

## Architectural Patterns

**Pattern Name**: Description of how it's used

- Example: /path/to/example.ext

**Another Pattern**: Description

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

**Sub-agent Role**: `integration-researcher`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Research APIs and data sources

**Prompt Template**:

````markdown
Research the APIs, databases, and external integrations relevant to implementing "{{FEATURE_NAME}}".

## Your Task

Investigate:

1. **API Endpoints**
   - What existing endpoints are related?
   - How are routes organized?
   - What middleware is used?

2. **Database Schema**
   - What tables are involved?
   - What are the relationships?
   - Are there migrations to reference?

3. **External Services**
   - What third-party services are used?
   - How are they integrated?
   - What credentials/config is needed?

4. **Internal Services**
   - What internal services are called?
   - How is inter-service communication handled?

## Task Coordination


1. Check the todo tracker for your assigned task
2. Claim your task with update the todo tracker (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with sub-agents
5. Write your output file
6. Mark your task complete with update the todo tracker

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-integration.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Share key findings with sub-agents
4. Mark your task as complete

Structure your report as:

```markdown
# Integration Research: {{FEATURE_NAME}}

## API Endpoints

### Existing Related Endpoints

- GET /api/path: Description
- POST /api/path: Description

### Route Organization

[How routes are structured]

## Database

### Relevant Tables

- table_name: Description of data
- another_table: Description

### Schema Details

[Key columns, relationships, indexes]

## External Services

[Third-party integrations relevant to feature]

## Internal Services

[Internal services that may be called]

## Configuration

[Environment variables, config files needed]
```

Be thorough with database schema - this informs data modeling decisions.
````

---

## Agent 4: Documentation Researcher

**Sub-agent Role**: `docs-researcher`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Find relevant documentation

**Prompt Template**:

````markdown
Find all documentation files relevant to implementing "{{FEATURE_NAME}}".

## Your Task

Search for documentation in:

1. **docs/ Directory**
   - Architecture documentation
   - API documentation
   - Feature guides
   - Development guides

2. **README Files**
   - Root README.md
   - Directory-level READMEs
   - Module READMEs

3. **Code Comments**
   - Well-documented modules
   - API documentation in code
   - Configuration documentation

4. **External References**
   - Links to external docs in code
   - Referenced specifications
   - Library documentation needs

## Task Coordination


1. Check the todo tracker for your assigned task
2. Claim your task with update the todo tracker (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with sub-agents
5. Write your output file
6. Mark your task complete with update the todo tracker

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-docs.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Share key findings with sub-agents
4. Mark your task as complete

Structure your report as:

```markdown
# Documentation Research: {{FEATURE_NAME}}

## Architecture Docs

- /docs/path/file.md: What it covers

## API Docs

- /docs/api/file.md: What it covers

## Development Guides

- /docs/dev/file.md: What it covers

## README Files

- /path/README.md: What it covers

## Must-Read Documents

[List documents that implementers MUST read, with topics]

## Documentation Gaps

[Areas where documentation is missing or outdated]
```

Focus on documents that would help someone implement {{FEATURE_NAME}}.
Identify which documents are REQUIRED reading vs nice-to-have.
````

---

## Optimized Mode: Unified Agents


### Agent 1: Architecture Analyst (Unified)

**Sub-agent Role**: `arch-analyst`

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
3. **(Path B only)** Share findings via re-dispatch the affected sub-agent with the needed guidance, then mark your task complete via update the todo tracker
```

### Agent 2: Pattern Analyst (Unified)

**Sub-agent Role**: `pattern-analyst`

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
3. **(Path B only)** Share findings via re-dispatch the affected sub-agent with the needed guidance, then mark your task complete via update the todo tracker
```

### Agent 3: Integration Analyst

**Sub-agent Role**: `integration-analyst`

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
3. **(Path B only)** Share findings via re-dispatch the affected sub-agent with the needed guidance, then mark your task complete via update the todo tracker
```

### Agent 4: Documentation Analyst

**Sub-agent Role**: `docs-analyst`

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
3. **(Path B only)** Share findings via re-dispatch the affected sub-agent with the needed guidance, then mark your task complete via update the todo tracker
```

### Agent 5: Task Planner (Unified)

**Sub-agent Role**: `task-planner`

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
3. **(Path B only)** Share findings via re-dispatch the affected sub-agent with the needed guidance, then mark your task complete via update the todo tracker
```

---

## Usage Instructions

When spawning research sub-agents:

1. **Read this file** to get the prompt templates
2. **Substitute variables**:
   - `{{FEATURE_NAME}}` - The feature directory name (e.g., `user-authentication`)
   - `{{FEATURE_DIR}}` - Full output directory (e.g., `docs/plans/user-authentication`)
3. **Create tasks** - Use track the task to create research tasks
5. **Monitor progress** - Use the todo tracker to check when all tasks complete
6. **Verify artifacts** - Check all research files exist on disk
7. **Shut down sub-agents** - Send shutdown requests via re-dispatch the affected sub-agent with the needed guidance
8. **Read results** - Review each research file before writing shared.md

## Variable Reference

| Variable           | Description                    | Example                          |
| ------------------ | ------------------------------ | -------------------------------- |
| `{{FEATURE_NAME}}` | Feature directory name         | `user-authentication`            |
| `{{FEATURE_DIR}}`  | Full research output directory | `docs/plans/user-authentication` |
