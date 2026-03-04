# Research Agent Prompts

These prompts are used to deploy parallel research agents for gathering shared context. This is Phase 1 of the unified planning workflow.

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

## Agent 1: Architecture Researcher

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

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-architecture.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

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

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-patterns.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

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

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-integration.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

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

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-docs.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

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

When `--optimized` flag is used, deploy these 5 unified agents instead:

### Agent 1: Architecture Analyst (Unified)

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

````markdown
Analyze the codebase architecture for implementing "{{FEATURE_NAME}}" and synthesize actionable context.

## Combined Task

Perform both architecture research AND context synthesis in one pass:

1. **Architecture Research**
   - System structure and component organization
   - Data flow and entry points
   - Component relationships and dependencies
   - Integration points for new code

2. **Context Synthesis**
   - Condense architecture findings into actionable insights
   - Identify critical files that must be referenced
   - Document cross-cutting concerns
   - Highlight parallelization opportunities

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/analysis-architecture.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

Structure your report as:

```markdown
# Architecture Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences: System structure and how new feature fits]

## System Architecture

- **Structure**: [Organization and layers]
- **Data Flow**: [Key data flow patterns]
- **Integration Points**: [Where new code connects]

## Critical Components

- /path/to/file: [Why critical - 1 sentence]
- /path/to/another: [Why critical - 1 sentence]

## Dependencies

- [External and internal dependencies]

## Cross-Cutting Concerns

- [Security, performance, testing concerns]

## Recommendations

- [Architectural decisions to make]
- [Patterns to follow]
```

Be concise but comprehensive. Focus on actionable insights.
````

### Agent 2: Pattern Analyst (Unified)

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

````markdown
Analyze coding patterns for implementing "{{FEATURE_NAME}}" and extract implementation guidance.

## Combined Task

Perform both pattern research AND code analysis in one pass:

1. **Pattern Research**
   - Architectural patterns in use
   - Code conventions and naming
   - Error handling approaches
   - Testing patterns

2. **Code Analysis**
   - Extract implementation patterns from relevant files
   - Document file organization
   - Identify integration points
   - Note gotchas and warnings

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/analysis-patterns.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

Structure your report as:

```markdown
# Pattern Analysis: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences: Key patterns and how to apply them]

## Implementation Patterns

### Pattern: [Name]

**Description**: [1-2 sentences]
**Example**: /path/to/example.ext lines X-Y
**Apply to**: [Which tasks use this]

## Code Conventions

- **Naming**: [Conventions to follow]
- **Organization**: [File structure pattern]
- **Error Handling**: [How to handle errors]

## Files to Create

- /path/to/new/file: [Purpose]

## Files to Modify

- /path/to/existing: [What changes needed]

## Gotchas

- [Non-obvious issues to avoid]
```
````

### Agent 3: Integration Analyst

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

```markdown
Analyze APIs, databases, and integrations for implementing "{{FEATURE_NAME}}".

## Task

Research and document:

- API endpoints and route organization
- Database schema and relationships
- External service integrations
- Internal service communication
- Configuration requirements

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/analysis-integration.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

Follow the integration research format with actionable synthesis.
```

### Agent 4: Documentation Analyst

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

```markdown
Find and analyze documentation for implementing "{{FEATURE_NAME}}".

## Task

Search for and categorize:

- Architecture and API documentation
- Development guides and READMEs
- Code documentation and comments
- External references

Identify MUST-READ documents and gaps.

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/analysis-docs.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

Include a prioritized reading list for implementers.
```

### Agent 5: Task Planner (Unified)

**Subagent Type**: `codebase-research-analyst`

**Prompt Template**:

```markdown
Analyze the codebase structure for "{{FEATURE_NAME}}" and suggest task breakdown.

## Task

Based on codebase structure:

- Identify natural module boundaries
- Find similar features for reference
- Suggest task organization and phases
- Determine parallelization opportunities
- Map files to tasks

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/analysis-tasks.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

Include phase structure, task granularity recommendations, and dependency analysis.
```

---

## Usage Instructions

When deploying research agents:

1. **Read this file** to get the prompt templates
2. **Substitute variables**:
   - `{{FEATURE_NAME}}` - The feature directory name (e.g., `user-authentication`)
   - `{{FEATURE_DIR}}` - Full output directory (e.g., `docs/plans/user-authentication`)
3. **Deploy in parallel** - Use a single message with 4 Task tool calls (or 5 in optimized mode)
4. **Wait for completion** - All agents must finish before consolidation
5. **Verify artifacts** - Check all research files exist on disk before proceeding
6. **Read results** - Review each research file before writing shared.md

## Variable Reference

| Variable           | Description                    | Example                          |
| ------------------ | ------------------------------ | -------------------------------- |
| `{{FEATURE_NAME}}` | Feature directory name         | `user-authentication`            |
| `{{FEATURE_DIR}}`  | Full research output directory | `docs/plans/user-authentication` |

## Agent Configuration

| Agent         | Type                        | Output File              | Model   |
| ------------- | --------------------------- | ------------------------ | ------- |
| Architecture  | `codebase-research-analyst` | research-architecture.md | Default |
| Pattern       | `codebase-research-analyst` | research-patterns.md     | Default |
| Integration   | `codebase-research-analyst` | research-integration.md  | Default |
| Documentation | `codebase-research-analyst` | research-docs.md         | Default |
