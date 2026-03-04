# Research Agent Prompts

These prompts deploy parallel research agents for comprehensive feature research including external APIs, business logic, technical specifications, UX analysis, and recommendations.

## Global Output Contract

Apply this contract to every agent prompt in this file:

- Write only your assigned output file under `{{FEATURE_DIR}}`.
- Do not edit any other files.
- Use an atomic write pattern: write complete content to a temporary path, then rename to the final `research-*.md` path.
- After writing the file, return a short completion signal:
  - `STATUS: COMPLETE` or `STATUS: BLOCKED`
  - `OUTPUT: <path>`
  - `SECTIONS: <comma-separated headings>`

---

## Agent 1: External API Researcher

**Subagent Type**: `research-specialist`

**Task Description**: Research external APIs and integrations

**Prompt Template**:

````
Research external APIs, libraries, and integration patterns for implementing "{{FEATURE_NAME}}".

## Feature Description
{{FEATURE_DESCRIPTION}}

## Your Task

Use web search and documentation to research:

1. **Primary APIs**
   - Official API documentation
   - Authentication methods (OAuth, API keys, tokens)
   - Available endpoints relevant to the feature
   - Rate limits and quotas
   - Pricing considerations

2. **Libraries and SDKs**
   - Official SDKs for relevant languages
   - Popular third-party libraries
   - Version compatibility
   - Installation requirements

3. **Integration Patterns**
   - Common integration approaches
   - Best practices from official docs
   - Example implementations
   - Webhook/event patterns if applicable

4. **Constraints and Limitations**
   - API restrictions
   - Data format requirements
   - Pagination patterns
   - Error response formats

## Output Format

Write your findings to: {{FEATURE_DIR}}/research-external.md

Structure your report as:

```markdown
# External API Research: {{FEATURE_NAME}}

## Executive Summary
[2-3 sentences: Key APIs needed and integration approach]

## Primary APIs

### [API Name]
- **Documentation**: [URL]
- **Authentication**: [Method and requirements]
- **Key Endpoints**:
  - `GET /endpoint`: Description
  - `POST /endpoint`: Description
- **Rate Limits**: [Limits and quotas]
- **Pricing**: [Free tier, paid tiers]

### [Another API if needed]
[Same structure]

## Libraries and SDKs

### Recommended Libraries
- **[Language]**: [Library name] - [Why recommended]
  - Install: `command`
  - Docs: [URL]

### Alternative Options
- [Library]: [Pros/cons]

## Integration Patterns

### Recommended Approach
[Description of best integration pattern]

### Authentication Flow
[Step-by-step auth process]

### Data Synchronization
[How to keep data in sync if applicable]

## Constraints and Gotchas

- [Constraint 1]: Impact and workaround
- [Constraint 2]: Impact and workaround

## Code Examples

### Basic Integration
```[language]
[Minimal working example]
````

## Open Questions

- [Question needing clarification]
- [Decision point for user]

```

**Critical**: Include actual documentation URLs and working code examples where possible.
```

---

## Agent 2: Business Logic Analyzer

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Analyze business requirements and logic

**Prompt Template**:

````
Analyze the business logic and requirements for implementing "{{FEATURE_NAME}}".

## Feature Description
{{FEATURE_DESCRIPTION}}

## Your Task

Research and document:

1. **User Stories**
   - Who are the users?
   - What do they want to accomplish?
   - What problems does this solve?

2. **Business Rules**
   - Core logic rules
   - Validation requirements
   - Edge cases and exceptions
   - Data integrity constraints

3. **Workflows**
   - Step-by-step user workflows
   - Decision points
   - Error recovery paths
   - Success criteria

4. **Domain Concepts**
   - Key entities and their relationships
   - Business terminology
   - State transitions
   - Lifecycle events

5. **Existing Codebase Analysis**
   - Related existing features
   - Patterns already in use
   - Shared components to leverage
   - Data models to extend

## Output Format

Write your findings to: {{FEATURE_DIR}}/research-business.md

Structure your report as:

```markdown
# Business Logic Research: {{FEATURE_NAME}}

## Executive Summary
[2-3 sentences: Core business value and key requirements]

## User Stories

### Primary User: [Role]
- As a [role], I want to [action] so that [benefit]
- As a [role], I want to [action] so that [benefit]

### Secondary User: [Role]
- As a [role], I want to [action] so that [benefit]

## Business Rules

### Core Rules
1. **[Rule Name]**: [Description]
   - Validation: [How to validate]
   - Exception: [When rule doesn't apply]

2. **[Another Rule]**: [Description]

### Edge Cases
- **[Scenario]**: [How to handle]
- **[Scenario]**: [How to handle]

## Workflows

### Primary Workflow: [Name]
1. User [action]
2. System [response]
3. User [action]
4. System [response]
5. Success: [Outcome]

### Error Recovery
- **[Error condition]**: [Recovery steps]

## Domain Model

### Key Entities
- **[Entity]**: [Description and key attributes]
- **[Entity]**: [Description and relationships]

### State Transitions
- [State A] → [State B]: [Trigger]
- [State B] → [State C]: [Trigger]

## Existing Codebase Integration

### Related Features
- /path/to/related: [How it relates]

### Patterns to Follow
- [Pattern]: [Where used]

### Components to Leverage
- [Component]: [How to use]

## Success Criteria
- [ ] [Measurable criterion]
- [ ] [Measurable criterion]

## Open Questions
- [Business decision needed]
- [Clarification required]
````

**Critical**: Focus on business value and user needs, not implementation details.

```

---

## Agent 3: Technical Spec Designer

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Design technical specifications

**Prompt Template**:

```

Design technical specifications for implementing "{{FEATURE_NAME}}".

## Feature Description

{{FEATURE_DESCRIPTION}}

## Your Task

Research and design:

1. **Architecture Design**
   - Component structure
   - Service boundaries
   - Integration points with existing system
   - Data flow

2. **Data Models**
   - Database schema changes
   - New entities/tables
   - Relationships and indexes
   - Migration considerations

3. **API Design**
   - New endpoints needed
   - Request/response formats
   - Error handling
   - Authentication requirements

4. **System Constraints**
   - Performance requirements
   - Scalability considerations
   - Security requirements
   - Compatibility constraints

5. **Codebase Analysis**
   - Existing architecture patterns
   - Files to modify
   - New files to create
   - Dependencies to add

## Output Format

Write your findings to: {{FEATURE_DIR}}/research-technical.md

Structure your report as:

```markdown
# Technical Specifications: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences: Technical approach and key architectural decisions]

## Architecture Design

### Component Diagram
```

[Component A] ──▶ [Component B] ──▶ [External API]
│ │
▼ ▼
[Database] [Cache/Queue]

````

### New Components
- **[Component]**: [Purpose and responsibilities]

### Integration Points
- [Existing system] ←→ [New component]: [Integration method]

## Data Models

### New Tables/Collections

#### [table_name]
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | Primary key |
| [column] | [type] | [constraints] | [description] |

#### Indexes
- `idx_[name]` on ([columns]): [Purpose]

### Schema Migrations
- Migration 1: [Description]
- Migration 2: [Description]

## API Design

### New Endpoints

#### `POST /api/[resource]`
**Purpose**: [Description]
**Auth**: [Required/Optional]

Request:
```json
{
  "field": "type - description"
}
````

Response:

```json
{
  "field": "type - description"
}
```

Errors:

- `400`: [Condition]
- `401`: [Condition]
- `404`: [Condition]

### Modified Endpoints

- `GET /api/[existing]`: [Changes needed]

## System Constraints

### Performance

- [Requirement]: [Target metric]

### Security

- [Requirement]: [Implementation approach]

### Scalability

- [Consideration]: [Design decision]

## Codebase Changes

### Files to Create

- /path/to/new/file.ext: [Purpose]

### Files to Modify

- /path/to/existing.ext: [Changes needed]

### Dependencies

- [Package]: [Version] - [Purpose]

## Technical Decisions

### [Decision 1]

- **Options**: [A, B, C]
- **Recommendation**: [Choice]
- **Rationale**: [Why]

## Open Questions

- [Technical decision needed]
- [Architecture question]

```

**Critical**: Be specific about data models and API contracts. Include actual schemas and examples.
```

---

## Agent 4: UX Researcher

**Subagent Type**: `research-specialist`

**Task Description**: Research user experience patterns

**Prompt Template**:

````
Research user experience patterns and best practices for "{{FEATURE_NAME}}".

## Feature Description
{{FEATURE_DESCRIPTION}}

## Your Task

Research and document:

1. **User Workflows**
   - Optimal user journeys
   - Common interaction patterns
   - Step-by-step flows
   - Decision points

2. **UI/UX Best Practices**
   - Industry standards for similar features
   - Accessibility requirements
   - Mobile/responsive considerations
   - Loading states and feedback

3. **Error Handling UX**
   - Error message patterns
   - Recovery flows
   - Validation feedback
   - Edge case handling

4. **Performance UX**
   - Loading indicators
   - Optimistic updates
   - Offline handling
   - Progress feedback

5. **Competitive Analysis**
   - How similar products handle this
   - Best-in-class examples
   - Patterns to adopt or avoid

## Output Format

Write your findings to: {{FEATURE_DIR}}/research-ux.md

Structure your report as:

```markdown
# UX Research: {{FEATURE_NAME}}

## Executive Summary
[2-3 sentences: Key UX considerations and recommended approach]

## User Workflows

### Primary Flow: [Name]
1. **[Step]**: [User action] → [System response]
2. **[Step]**: [User action] → [System response]
3. **[Success state]**: [Feedback to user]

### Alternative Flows
- **[Scenario]**: [Different path]

## UI/UX Best Practices

### Industry Standards
- [Standard]: [How to implement]
- [Standard]: [How to implement]

### Accessibility (WCAG)
- [Requirement]: [Implementation]
- [Requirement]: [Implementation]

### Responsive Design
- **Desktop**: [Considerations]
- **Tablet**: [Considerations]
- **Mobile**: [Considerations]

## Error Handling

### Error States
| Error | User Message | Recovery Action |
|-------|--------------|-----------------|
| [Error] | "[Message]" | [Action] |

### Validation Patterns
- **[Field]**: [Validation UX]

## Performance UX

### Loading States
- **Initial load**: [Pattern]
- **Action pending**: [Pattern]
- **Background refresh**: [Pattern]

### Optimistic Updates
- [Action]: [Optimistic behavior]

### Offline Handling
- [Scenario]: [Graceful degradation]

## Competitive Analysis

### [Competitor/Product]
- **Approach**: [How they handle it]
- **Strengths**: [What works well]
- **Weaknesses**: [What to avoid]

### Best Practices to Adopt
- [Practice]: [From where]

## Recommendations

### Must Have
- [Critical UX requirement]

### Should Have
- [Important but not blocking]

### Nice to Have
- [Enhancement opportunity]

## Open Questions
- [UX decision needed]
- [User research question]
````

**Critical**: Include specific, actionable UX patterns. Reference industry standards and real examples.

```

---

## Agent 5: Recommendations Agent

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Generate recommendations and ideas

**Prompt Template**:

```

Generate recommendations, improvement ideas, and identify risks for "{{FEATURE_NAME}}".

## Feature Description

{{FEATURE_DESCRIPTION}}

## Your Task

Explore the codebase and generate:

1. **Implementation Recommendations**
   - Suggested technical approach
   - Technology choices
   - Phasing strategy
   - Quick wins vs long-term investments

2. **Improvement Ideas**
   - Related features to consider
   - Future enhancements
   - Optimization opportunities
   - Integration possibilities

3. **Risk Assessment**
   - Technical risks
   - Integration challenges
   - Performance concerns
   - Security considerations

4. **Alternative Approaches**
   - Different ways to solve the problem
   - Trade-offs of each approach
   - Recommendation with rationale

5. **Task Breakdown Preview**
   - High-level phases
   - Suggested task groupings
   - Dependency hints
   - Parallelization opportunities

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-recommendations.md

Before completing this task:

1. Create the output file using the Write tool
2. Verify the file was created successfully
3. Report completion status

Structure your report as:

```markdown
# Recommendations: {{FEATURE_NAME}}

## Executive Summary

[2-3 sentences: Top recommendations and key risks]

## Implementation Recommendations

### Recommended Approach

[Description of suggested implementation strategy]

### Technology Choices

| Component   | Recommendation | Rationale |
| ----------- | -------------- | --------- |
| [Component] | [Choice]       | [Why]     |

### Phasing Strategy

1. **Phase 1 - MVP**: [Scope]
2. **Phase 2 - Enhancement**: [Scope]
3. **Phase 3 - Polish**: [Scope]

### Quick Wins

- [Quick win]: [Impact]
- [Quick win]: [Impact]

## Improvement Ideas

### Related Features

- **[Feature]**: [How it relates and value add]

### Future Enhancements

- [Enhancement]: [Value and complexity]

### Integration Opportunities

- [Integration]: [Potential value]

## Risk Assessment

### Technical Risks

| Risk   | Likelihood   | Impact       | Mitigation |
| ------ | ------------ | ------------ | ---------- |
| [Risk] | High/Med/Low | High/Med/Low | [Strategy] |

### Integration Challenges

- [Challenge]: [Mitigation approach]

### Performance Concerns

- [Concern]: [Monitoring/mitigation]

### Security Considerations

- [Consideration]: [Approach]

## Alternative Approaches

### Option A: [Name]

- **Pros**: [Benefits]
- **Cons**: [Drawbacks]
- **Effort**: [Estimate]

### Option B: [Name]

- **Pros**: [Benefits]
- **Cons**: [Drawbacks]
- **Effort**: [Estimate]

### Recommendation

[Which option and why]

## Task Breakdown Preview

### Phase 1: Foundation

- Task group: [Description]
- Parallel opportunities: [What can run together]

### Phase 2: Core Implementation

- Task group: [Description]
- Dependencies: [What must complete first]

### Phase 3: Integration & Testing

- Task group: [Description]

### Estimated Complexity

- **Total tasks**: [Rough estimate]
- **Critical path**: [Key dependencies]

## Key Decisions Needed

- [Decision 1]: [Options and impact]
- [Decision 2]: [Options and impact]

## Open Questions

- [Question requiring user input]
```

**Critical**: Be creative but realistic. Ground recommendations in codebase analysis and practical constraints.

```

---

## Usage Instructions

When deploying research agents:

1. **Read this file** to get the prompt templates
2. **Substitute variables**:
   - `{{FEATURE_NAME}}` - The feature directory name (e.g., `plex-integration`)
   - `{{FEATURE_DIR}}` - Full output directory (e.g., `docs/plans/plex-integration`)
   - `{{FEATURE_DESCRIPTION}}` - Description provided by user (or feature name if none)
3. **Deploy in parallel** - Use a single message with 5 Task tool calls
4. **Wait for completion** - All agents must finish before consolidation
5. **Validate results** - Run research validator before synthesis
6. **Read results** - Review each research file before writing feature-spec.md

## Variable Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `{{FEATURE_NAME}}` | Feature directory name | `plex-integration` |
| `{{FEATURE_DIR}}` | Full research output directory | `docs/plans/plex-integration` |
| `{{FEATURE_DESCRIPTION}}` | User-provided description | `Advanced Plex media library integration with filters and playlists` |

## Agent Configuration

| Agent | Type | Can Write | Output File | Model |
|-------|------|-----------|-------------|-------|
| External API | `research-specialist` | Yes | research-external.md | Default |
| Business Logic | `codebase-research-analyst` | Yes | research-business.md | Default |
| Technical Spec | `codebase-research-analyst` | Yes | research-technical.md | Default |
| UX Research | `research-specialist` | Yes | research-ux.md | Default |
| Recommendations | `codebase-research-analyst` | Yes | research-recommendations.md | Default |

## Expected Output

Each research file should be:
- **Comprehensive**: Cover all aspects of its domain
- **Actionable**: Include specific recommendations
- **Referenced**: Link to sources and documentation
- **Structured**: Follow the output format exactly
```
