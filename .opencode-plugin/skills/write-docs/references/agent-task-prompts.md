# Agent Task Prompts Reference

This file contains the standard prompts for each documentation agent.
These are used by the write-docs skill when deploying agents.

---

## Architecture Analyst

**Plugin Agent**: `architecture-analyst`

**Prompt Template**:

```
Analyze the codebase architecture and create documentation in docs/architecture/.

Context: Read docs/plans/documentation-strategy.md first.

Your deliverables:
1. docs/architecture/overview.md - High-level system overview
   - System purpose and goals
   - Major components and their responsibilities
   - Mermaid diagram showing component relationships

2. docs/architecture/components.md - Detailed component documentation
   - Each major module/service
   - Dependencies and interfaces
   - Configuration options

3. docs/architecture/data-flow.md - Data flow documentation
   - Request/response flows (Mermaid sequence diagrams)
   - Data transformation pipelines
   - State management patterns

Style requirements:
- Use Mermaid syntax for ALL diagrams
- Keep explanations concise but complete
- Include code references (file:line format)
- Cross-reference related documentation

Scope: [SCOPE]
Mode: [update|fresh]
```

---

## API Documenter

**Plugin Agent**: `api-documenter`

**Prompt Template**:

```
Create comprehensive API documentation in docs/api/.

Context: Read docs/plans/documentation-strategy.md first.

Your deliverables:
1. docs/api/README.md - API overview
   - Available endpoints summary
   - Authentication requirements
   - Base URL and versioning

2. docs/api/endpoints.md - Detailed endpoint documentation
   - Each endpoint with method, path, description
   - Request parameters (path, query, body)
   - Response format with examples
   - Error responses

3. docs/api/authentication.md - Authentication guide
   - Auth methods supported
   - Token acquisition flow
   - Example requests with auth

4. docs/api/errors.md - Error handling
   - Error code reference
   - Common error scenarios
   - Troubleshooting tips

Requirements:
- Include realistic request/response examples
- Use consistent formatting
- Document all parameters with types
- Show error responses for each endpoint

Scope: [SCOPE]
Mode: [update|fresh]
```

---

## Feature Writer

**Plugin Agent**: `feature-writer`

**Prompt Template**:

```
Create user-facing feature documentation in docs/features/.

Context: Read docs/plans/documentation-strategy.md first.

For each major feature, create a guide with:
1. Overview - What the feature does and why
2. Getting Started - Quick start example
3. Detailed Usage - All options and configurations
4. Examples - Real-world use cases
5. Troubleshooting - Common issues and solutions

Requirements:
- Write for end-users, not developers
- Include working code examples
- Use clear, simple language
- Add screenshots or diagrams where helpful
- Cross-reference related features

Output: docs/features/[feature-name].md for each feature

Scope: [SCOPE]
Mode: [update|fresh]
```

---

## Code Documenter

**Plugin Agent**: `code-documenter`

**Prompt Template**:

```
Add inline documentation to source files.

Context: Read docs/plans/documentation-strategy.md first.

Your task:
1. Add JSDoc/docstrings to exported functions and classes
2. Document complex type definitions
3. Add inline comments for non-obvious logic
4. Create module-level documentation headers

Guidelines:
- Document the "why", not the "what"
- Focus on public APIs and exported items
- Don't over-document obvious code
- Use standard formats (JSDoc, Python docstrings, Go doc comments)
- Include parameter types, return types, and examples

Priority files:
[PRIORITY_FILES]

Scope: [SCOPE]
Mode: [update|fresh]
```

---

## README Generator

**Plugin Agent**: `readme-generator`

**Prompt Template**:

```
Create and update README.md files throughout the project.

Context: Read docs/plans/documentation-strategy.md first.

Your deliverables:
1. Root README.md (create or enhance)
   - Project title and description
   - Badges (if applicable)
   - Quick start guide
   - Installation instructions
   - Basic usage examples
   - Links to detailed documentation
   - Contributing section
   - License

2. Directory READMEs
   - For each major directory without a README
   - Explain the purpose of the directory
   - List key files with descriptions
   - Link to related documentation

Requirements:
- Keep READMEs concise and scannable
- Include working examples
- Link to detailed docs for more info
- Use consistent formatting

Scope: [SCOPE]
Mode: [update|fresh]
```

---

## Variable Reference

| Variable           | Description                                                         |
| ------------------ | ------------------------------------------------------------------- |
| `[SCOPE]`          | User-provided scope (feature name, module, etc.) or "full codebase" |
| `[update\|fresh]`  | `update` (enhance existing) or `fresh` (create new)                 |
| `[PRIORITY_FILES]` | Files identified as high-priority for documentation                 |

---

_These prompts are templates - the orchestrator fills in variables before deployment._
