# Agent Prompt Templates

Standard prompt templates for common orchestration patterns. Use these to ensure consistent, high-quality agent instructions.

---

## Template Variables

All templates support these variables:

| Variable            | Description                      | Example                                    |
| ------------------- | -------------------------------- | ------------------------------------------ |
| `{{TASK}}`          | The main task being orchestrated | "Implement user authentication"            |
| `{{SUBTASK}}`       | Specific subtask for this agent  | "Create user model and schema"             |
| `{{CONTEXT_FILES}}` | Files agent should read first    | "src/models/base.ts, docs/architecture.md" |
| `{{OUTPUT_FILES}}`  | Files agent should create/modify | "src/models/user.ts"                       |
| `{{CONSTRAINTS}}`   | What agent should NOT do         | "Don't modify authentication middleware"   |
| `{{DEPENDENCIES}}`  | What must be complete first      | "User model (Task 1.1)"                    |

---

## Pattern 1: Feature Implementation

### Use Case

Implementing a new feature across multiple components (frontend, backend, database).

### Agent Prompt Template

```markdown
You are implementing part of the "{{TASK}}" feature.

## Your Specific Task

{{SUBTASK}}

## Context

This is part of a larger orchestrated effort. Other agents are handling:

- [List other subtasks being handled in parallel]

Your work will be used by: [Agents depending on this work]

## Required Reading

Before starting, read these files to understand existing patterns:
{{CONTEXT_FILES}}

## Your Deliverables

Create/modify these files:
{{OUTPUT_FILES}}

## Implementation Requirements

1. **Follow Existing Patterns**: Match the style and conventions in the codebase
2. **Stay in Scope**: Only implement {{SUBTASK}}, nothing more
3. **Integration Points**: Ensure your code integrates with [related components]
4. **Error Handling**: Include appropriate error handling and validation
5. **Code Quality**: Write clean, maintainable, well-documented code

## Constraints

{{CONSTRAINTS}}

## Success Criteria

Your implementation is complete when:

- [Specific criterion 1]
- [Specific criterion 2]
- [Specific criterion 3]

## Output Format

After completing the task, provide:

- List of files created
- List of files modified
- Brief description of changes
- Any issues or concerns
- Integration notes for dependent tasks
```

---

## Pattern 2: Bug Investigation & Fix

### Use Case

Investigating and fixing a bug through root cause analysis and implementation.

### Phase 1: Root Cause Analysis Agent

```markdown
Investigate the following bug: {{TASK}}

## Bug Description

{{BUG_DESCRIPTION}}

## Your Task

Perform systematic root cause analysis to identify WHY this bug is occurring.

## Investigation Approach

1. **Reproduce the Issue**: Understand the exact conditions
2. **Generate Hypotheses**: Create 3-5 possible root causes
3. **Gather Evidence**: Find code, logs, or data supporting each hypothesis
4. **Identify Root Cause**: Determine the most likely explanation

## Files to Investigate

{{CONTEXT_FILES}}

## Output Format

Provide a diagnostic report:

### Bug Summary

[Concise description of the issue]

### Reproduction Steps

[How to reproduce the bug]

### Root Cause Analysis

#### Hypothesis 1: [Name]

- **Evidence**: [Supporting evidence]
- **Likelihood**: High/Medium/Low

#### Hypothesis 2: [Name]

- **Evidence**: [Supporting evidence]
- **Likelihood**: High/Medium/Low

### Conclusion

The root cause is: [Most likely cause]

### Recommended Fix

[High-level approach to fixing, but DO NOT implement]

### Files That Need Changes

[List files that would need modification]
```

### Phase 2: Fix Implementation Agent

```markdown
Implement a fix for: {{TASK}}

## Root Cause

[Insert findings from root-cause-analyzer]

## Your Task

{{SUBTASK}}

## Context

The root cause analysis identified: [summary]

Read the diagnostic report: {{DIAGNOSTIC_REPORT_PATH}}

## Files to Modify

{{OUTPUT_FILES}}

## Fix Requirements

1. **Address Root Cause**: Fix the underlying issue, not symptoms
2. **Avoid Regressions**: Ensure fix doesn't break other functionality
3. **Add Safety**: Include validation or checks to prevent recurrence
4. **Follow Patterns**: Match existing error handling patterns

## Testing Considerations

After implementing the fix:

- [Test case 1 to verify fix]
- [Test case 2 to ensure no regression]

## Output Format

Provide:

- Files modified
- Description of fix
- How it addresses the root cause
- Regression test suggestions
```

---

## Pattern 3: Refactoring

### Use Case

Refactoring code to improve structure, performance, or maintainability.

### Phase 1: Analysis Agent

```markdown
Analyze the current implementation for refactoring: {{TASK}}

## Your Task

{{SUBTASK}} - Analyze current architecture and recommend refactoring approach

## Analysis Scope

{{CONTEXT_FILES}}

## Analysis Objectives

1. **Current State**: Document existing architecture and patterns
2. **Issues**: Identify problems, code smells, technical debt
3. **Opportunities**: Find areas for improvement
4. **Risks**: Identify risks in refactoring
5. **Approach**: Recommend refactoring strategy

## Output Format

Create analysis document: {{OUTPUT_PATH}}

### Current Architecture

[Describe how it currently works]

### Issues Identified

1. [Issue 1]
2. [Issue 2]
3. [Issue 3]

### Recommended Refactoring Approach

[Step-by-step refactoring strategy]

### Risks & Mitigation

- **Risk 1**: [Description] - Mitigation: [Strategy]
- **Risk 2**: [Description] - Mitigation: [Strategy]

### Files to Refactor

[Prioritized list with rationale]
```

### Phase 2: Refactoring Implementation Agent

```markdown
Refactor code as part of: {{TASK}}

## Your Task

{{SUBTASK}}

## Refactoring Context

Read the analysis: {{ANALYSIS_PATH}}

The recommended approach is: [Summary from analysis]

## Files to Refactor

{{OUTPUT_FILES}}

## Refactoring Requirements

1. **Preserve Behavior**: Functionality must remain identical
2. **Improve Structure**: Follow the recommended patterns
3. **Maintain Tests**: Ensure existing tests still pass
4. **Incremental Changes**: Make focused, reviewable changes
5. **Document Changes**: Update comments and documentation

## Constraints

{{CONSTRAINTS}}

## Success Criteria

- Improved code structure
- All existing tests pass
- No behavior changes
- Better maintainability

## Output Format

Provide:

- Files refactored
- Key changes made
- Any test updates needed
- Before/after comparison for complex changes
```

---

## Pattern 4: Documentation Update

### Use Case

Creating or updating comprehensive documentation.

### Agent Prompt Template

```markdown
Create/update documentation for: {{TASK}}

## Your Task

{{SUBTASK}}

## Documentation Scope

Document the following aspects:

- [Aspect 1]
- [Aspect 2]
- [Aspect 3]

## Source Files to Document

Read and understand these files:
{{CONTEXT_FILES}}

## Output Files

Create/update:
{{OUTPUT_FILES}}

## Documentation Requirements

1. **Accuracy**: Documentation must match actual code behavior
2. **Completeness**: Cover all public APIs and features
3. **Examples**: Include working code examples
4. **Structure**: Use clear headings and organization
5. **Cross-References**: Link to related documentation

## Style Guidelines

- Use clear, concise language
- Include code examples from the actual codebase
- Use Mermaid syntax for diagrams
- Provide both quick-start and detailed sections
- Add troubleshooting tips where relevant

## Documentation Structure

### Overview

[What this component/feature does]

### Getting Started

[Quick start example]

### Detailed Usage

[Comprehensive usage guide]

### API Reference

[If applicable - detailed API documentation]

### Examples

[Real-world use cases]

### Troubleshooting

[Common issues and solutions]

## Output Format

After completing documentation:

- Files created/updated
- Sections added
- Examples included
- Cross-references made
```

---

## Pattern 5: Testing Strategy

### Use Case

Creating comprehensive test plans and strategies.

### Agent Prompt Template

```markdown
Create a testing strategy for: {{TASK}}

## Your Task

{{SUBTASK}}

## Code to Test

Analyze these files:
{{CONTEXT_FILES}}

## Testing Objectives

Create a comprehensive test plan covering:

1. **Unit Tests**: Individual functions and components
2. **Integration Tests**: Component interactions
3. **End-to-End Tests**: Full user workflows
4. **Edge Cases**: Boundary conditions and error scenarios
5. **Performance Tests**: If applicable

## Test Plan Requirements

For each test category, provide:

- What needs testing
- Test cases (specific scenarios)
- Expected behavior
- Test data requirements
- Priority (High/Medium/Low)

## Output File

Create test plan: {{OUTPUT_PATH}}

## Test Plan Structure

### Unit Tests

#### Component/Function 1

- Test case 1: [Description]
  - Input: [Test input]
  - Expected: [Expected output]
  - Priority: [H/M/L]

### Integration Tests

#### Integration Point 1

- Test case 1: [Description]
  - Setup: [Test setup]
  - Action: [What to test]
  - Expected: [Expected result]

### End-to-End Tests

#### User Flow 1

- Scenario: [Description]
- Steps: [User actions]
- Expected: [End result]

### Edge Cases & Error Scenarios

[List critical edge cases to test]

### Performance Tests

[If applicable]

### Test Data Requirements

[Data needed for testing]

## Output Format

Provide:

- Complete test plan document
- Total test cases by category
- Priority breakdown
- Estimated effort
```

---

## Pattern 6: API Development

### Use Case

Designing and implementing RESTful API endpoints.

### Agent Prompt Template

```markdown
Implement API endpoints for: {{TASK}}

## Your Task

{{SUBTASK}}

## API Scope

Create the following endpoints:

- [Endpoint 1: Method + Path]
- [Endpoint 2: Method + Path]
- [Endpoint 3: Method + Path]

## Context

Read existing API patterns:
{{CONTEXT_FILES}}

## Files to Create/Modify

{{OUTPUT_FILES}}

## API Requirements

For each endpoint:

1. **Route Definition**: Clear path and HTTP method
2. **Request Validation**: Validate all inputs
3. **Authentication**: Apply appropriate auth middleware
4. **Error Handling**: Return proper error responses
5. **Response Format**: Consistent JSON structure
6. **Status Codes**: Use appropriate HTTP status codes

## API Conventions

Follow these patterns from existing code:

- [Convention 1]
- [Convention 2]
- [Convention 3]

## Example Request/Response

For each endpoint, document:
```

POST /api/resource
Content-Type: application/json

{
"field": "value"
}

Response 201:
{
"data": {...},
"message": "Success"
}

Response 400:
{
"error": "Error description"
}

```

## Constraints
{{CONSTRAINTS}}

## Output Format
After implementation:
- Endpoints implemented
- Request/response examples
- Authentication requirements
- Error scenarios handled
```

---

## Pattern 7: Database Schema Changes

### Use Case

Creating or modifying database schemas and migrations.

### Agent Prompt Template

````markdown
Implement database changes for: {{TASK}}

## Your Task

{{SUBTASK}}

## Database Changes Required

- [Change 1: Create table / Alter table / Add column]
- [Change 2: Add index / Foreign key]
- [Change 3: Migration script]

## Context

Review existing schema:
{{CONTEXT_FILES}}

## Files to Create

{{OUTPUT_FILES}}

## Schema Requirements

1. **Data Integrity**: Proper constraints and foreign keys
2. **Performance**: Appropriate indexes
3. **Migration Safety**: Reversible migrations
4. **Naming Conventions**: Follow existing patterns
5. **Documentation**: Comment complex schemas

## Migration Structure

```sql
-- Migration Up
-- [Create tables, add columns, create indexes]

-- Migration Down
-- [Rollback changes]
```
````

## Constraints

{{CONSTRAINTS}}

## Success Criteria

- Schema changes implemented
- Migration script created (up and down)
- Indexes added for performance
- Foreign keys maintain referential integrity

## Output Format

Provide:

- Migration file created
- Tables/columns added
- Indexes created
- Rollback script included

```

---

## Best Practices for Using Templates

1. **Always fill all variables**: Don't leave placeholders like {{TASK}} in the actual prompt
2. **Add specific context**: Templates are starting points - add project-specific details
3. **Adjust scope**: Narrow or expand based on subtask complexity
4. **Include examples**: Reference actual files from the codebase
5. **Set clear boundaries**: Explicitly state what NOT to do
6. **Specify output format**: Be clear about expected deliverables
7. **Link related work**: Help agents understand their place in the bigger picture

---

## Customizing Templates

When adapting templates:

1. **Add technology-specific details**: Framework, libraries, tools being used
2. **Include architectural constraints**: Design patterns, conventions, restrictions
3. **Reference style guides**: Code style, naming conventions, formatting
4. **Specify integration points**: How this connects to other components
5. **Add validation criteria**: How to verify the work is complete and correct

---

*These templates should be customized for your specific project, technology stack, and team conventions.*
```
