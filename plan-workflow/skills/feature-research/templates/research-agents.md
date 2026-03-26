# Research Agent Prompts

These prompts deploy research teammates for comprehensive feature research including external APIs, business logic, technical specifications, UX analysis, and recommendations. Teammates share findings with each other via messages.

## Global Output Contract

Apply this contract to every teammate prompt in this file:

- Write only your assigned output file under `{{FEATURE_DIR}}`.
- Do not edit any other files.
- **Share key findings** with relevant teammates using SendMessage.
- After writing the file and sharing findings, mark your task as complete using TaskUpdate.

---

## Agent 1: External API Researcher

**Teammate Name**: `api-researcher`

**Subagent Type**: `research-specialist`

**Task Description**: Research external APIs and integrations

**Prompt Template**:

````
Research external APIs, libraries, and integration patterns for implementing "{{FEATURE_NAME}}".

## Feature Description
{{FEATURE_DESCRIPTION}}

## Your Task

Use web search and documentation to research:

1. **Primary APIs** - Official docs, auth methods, endpoints, rate limits, pricing
2. **Libraries and SDKs** - Official SDKs, third-party libraries, version compatibility
3. **Integration Patterns** - Common approaches, best practices, examples, webhooks
4. **Constraints and Limitations** - API restrictions, data formats, pagination, errors

## Team Communication

You are part of a research team. Your teammates are:

- **business-analyzer**: Analyzing business requirements and logic
- **tech-designer**: Designing technical specifications
- **ux-researcher**: Researching user experience patterns
- **recommendations-agent**: Generating recommendations and risk assessment

**Share these findings via SendMessage:**

- Message `tech-designer` with: discovered API endpoints, authentication flows, data formats, and SDK recommendations — these directly inform the technical architecture
- Message `business-analyzer` with: API pricing tiers, rate limits, and feature availability that affect business requirements
- Message `ux-researcher` with: any API-provided UI components, widgets, or UX patterns from the service
- Message `recommendations-agent` with: alternative APIs or libraries you evaluated, with pros/cons

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Format

Write your findings to: {{FEATURE_DIR}}/research-external.md

Structure with: Executive Summary, Primary APIs (with docs URLs, auth, endpoints, rate limits, pricing), Libraries and SDKs, Integration Patterns, Constraints and Gotchas, Code Examples, Open Questions.

**Critical**: Include actual documentation URLs and working code examples where possible.
````

---

## Agent 2: Business Logic Analyzer

**Teammate Name**: `business-analyzer`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Analyze business requirements and logic

**Prompt Template**:

````
Analyze the business logic and requirements for implementing "{{FEATURE_NAME}}".

## Feature Description
{{FEATURE_DESCRIPTION}}

## Your Task

Research and document:

1. **User Stories** - Who uses it, what they want, what problems it solves
2. **Business Rules** - Core logic, validation, edge cases, data integrity
3. **Workflows** - Step-by-step flows, decision points, error recovery
4. **Domain Concepts** - Key entities, relationships, state transitions
5. **Existing Codebase Analysis** - Related features, patterns, shared components

## Team Communication

You are part of a research team. Your teammates are:

- **api-researcher**: Researching external APIs and libraries
- **tech-designer**: Designing technical specifications
- **ux-researcher**: Researching user experience patterns
- **recommendations-agent**: Generating recommendations and risk assessment

**Share these findings via SendMessage:**

- Message `tech-designer` with: key business rules and validation requirements that affect data model design
- Message `ux-researcher` with: user workflows and decision points that need UI representation
- Message `recommendations-agent` with: domain complexity insights and potential business risks

**Listen for messages from teammates** — `api-researcher` may share pricing/feature constraints that affect requirements, and `ux-researcher` may share workflow patterns that influence business rules.

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Format

Write your findings to: {{FEATURE_DIR}}/research-business.md

Structure with: Executive Summary, User Stories, Business Rules (core rules + edge cases), Workflows (primary + error recovery), Domain Model (entities + state transitions), Existing Codebase Integration, Success Criteria, Open Questions.

**Critical**: Focus on business value and user needs, not implementation details.
````

---

## Agent 3: Technical Spec Designer

**Teammate Name**: `tech-designer`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Design technical specifications

**Prompt Template**:

````
Design technical specifications for implementing "{{FEATURE_NAME}}".

## Feature Description
{{FEATURE_DESCRIPTION}}

## Your Task

Research and design:

1. **Architecture Design** - Component structure, service boundaries, data flow
2. **Data Models** - Database schema, entities, relationships, migrations
3. **API Design** - New endpoints, request/response formats, error handling
4. **System Constraints** - Performance, scalability, security, compatibility
5. **Codebase Analysis** - Existing patterns, files to modify/create, dependencies

## Team Communication

You are part of a research team. Your teammates are:

- **api-researcher**: Researching external APIs and libraries
- **business-analyzer**: Analyzing business requirements and logic
- **ux-researcher**: Researching user experience patterns
- **recommendations-agent**: Generating recommendations and risk assessment

**Share these findings via SendMessage:**

- Message `business-analyzer` with: data model constraints and API limitations that affect business rules
- Message `ux-researcher` with: API response formats and loading patterns that affect UX design
- Message `recommendations-agent` with: architectural trade-offs and technical decision points
- Message `api-researcher` with: specific technical requirements that may need additional API research

**Listen for messages from teammates** — `api-researcher` will share discovered API endpoints and auth flows, and `business-analyzer` will share validation requirements affecting your data model.

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Format

Write your findings to: {{FEATURE_DIR}}/research-technical.md

Structure with: Executive Summary, Architecture Design (component diagram, new components, integration points), Data Models (tables with columns/types/constraints, indexes, migrations), API Design (endpoints with request/response/errors), System Constraints (performance, security, scalability), Codebase Changes (files to create/modify, dependencies), Technical Decisions (options + recommendation + rationale), Open Questions.

**Critical**: Be specific about data models and API contracts. Include actual schemas and examples.
````

---

## Agent 4: UX Researcher

**Teammate Name**: `ux-researcher`

**Subagent Type**: `research-specialist`

**Task Description**: Research user experience patterns

**Prompt Template**:

````
Research user experience patterns and best practices for "{{FEATURE_NAME}}".

## Feature Description
{{FEATURE_DESCRIPTION}}

## Your Task

Research and document:

1. **User Workflows** - Optimal journeys, interaction patterns, decision points
2. **UI/UX Best Practices** - Industry standards, accessibility, responsive design, loading states
3. **Error Handling UX** - Error messages, recovery flows, validation feedback
4. **Performance UX** - Loading indicators, optimistic updates, offline handling
5. **Competitive Analysis** - How similar products handle this, best-in-class examples

## Team Communication

You are part of a research team. Your teammates are:

- **api-researcher**: Researching external APIs and libraries
- **business-analyzer**: Analyzing business requirements and logic
- **tech-designer**: Designing technical specifications
- **recommendations-agent**: Generating recommendations and risk assessment

**Share these findings via SendMessage:**

- Message `business-analyzer` with: user workflow patterns and decision points that should map to business rules
- Message `tech-designer` with: loading state requirements, real-time update needs, and data display patterns that affect API design
- Message `recommendations-agent` with: competitive analysis highlights and UX best practices worth adopting

**Listen for messages from teammates** — `business-analyzer` may share workflow requirements, `tech-designer` may share API response formats, and `api-researcher` may share UI components provided by the service.

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your research
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Format

Write your findings to: {{FEATURE_DIR}}/research-ux.md

Structure with: Executive Summary, User Workflows (primary + alternative flows), UI/UX Best Practices (industry standards, accessibility, responsive), Error Handling (error states table, validation patterns), Performance UX (loading states, optimistic updates, offline), Competitive Analysis, Recommendations (must have, should have, nice to have), Open Questions.

**Critical**: Include specific, actionable UX patterns. Reference industry standards and real examples.
````

---

## Agent 5: Recommendations Agent

**Teammate Name**: `recommendations-agent`

**Subagent Type**: `codebase-research-analyst`

**Task Description**: Generate recommendations and ideas

**Prompt Template**:

````
Generate recommendations, improvement ideas, and identify risks for "{{FEATURE_NAME}}".

## Feature Description
{{FEATURE_DESCRIPTION}}

## Your Task

Explore the codebase and generate:

1. **Implementation Recommendations** - Technical approach, technology choices, phasing, quick wins
2. **Improvement Ideas** - Related features, future enhancements, optimization opportunities
3. **Risk Assessment** - Technical risks, integration challenges, performance, security
4. **Alternative Approaches** - Different solutions, trade-offs, recommendation with rationale
5. **Task Breakdown Preview** - High-level phases, task groupings, dependencies

## Team Communication

You are part of a research team. Your teammates are:

- **api-researcher**: Researching external APIs and libraries
- **business-analyzer**: Analyzing business requirements and logic
- **tech-designer**: Designing technical specifications
- **ux-researcher**: Researching user experience patterns

**This is a synthesis role** — you should actively listen for messages from all teammates and incorporate their findings into your recommendations.

**Share these findings via SendMessage:**

- Message `tech-designer` with: alternative architectural approaches you identify that they should consider
- Message `business-analyzer` with: risk factors that may require business rule adjustments

**Listen for messages from ALL teammates** — incorporate API evaluation results from `api-researcher`, domain complexity from `business-analyzer`, architectural trade-offs from `tech-designer`, and competitive insights from `ux-researcher` into your recommendations.

## Task Coordination

1. Check TaskList for your assigned task
2. Claim your task with TaskUpdate (set status to in_progress, owner to your name)
3. Do your research (consider waiting briefly for teammate messages before finalizing)
4. Share findings with teammates
5. Write your output file
6. Mark your task complete with TaskUpdate

## Output Requirements

**CRITICAL**: You MUST write your findings to the specified file. This is not optional.

**Output File**: {{FEATURE_DIR}}/research-recommendations.md

Structure with: Executive Summary, Implementation Recommendations (approach, technology choices, phasing, quick wins), Improvement Ideas (related features, enhancements, integrations), Risk Assessment (technical risks table, integration challenges, performance, security), Alternative Approaches (options with pros/cons/effort, recommendation), Task Breakdown Preview (phases with task groups, estimated complexity), Key Decisions Needed, Open Questions.

**Critical**: Be creative but realistic. Ground recommendations in codebase analysis and practical constraints.
````

---

## Usage Instructions

When spawning research teammates:

1. **Read this file** to get the prompt templates
2. **Substitute variables**:
   - `{{FEATURE_NAME}}` - The feature directory name (e.g., `plex-integration`)
   - `{{FEATURE_DIR}}` - Full output directory (e.g., `docs/plans/plex-integration`)
   - `{{FEATURE_DESCRIPTION}}` - Description provided by user (or feature name if none)
3. **Create team** - Use TeamCreate with name `fr-[feature-name]`
4. **Create tasks** - Use TaskCreate to create 5 research tasks
5. **Spawn in parallel** - Use a single message with 5 Agent tool calls, each with `team_name` and `name`
6. **Monitor progress** - Use TaskList to check when all tasks complete
7. **Validate results** - Run research validator before synthesis
8. **Shut down teammates** - Send shutdown requests via SendMessage
9. **Read results** - Review each research file before writing feature-spec.md
10. **Clean up team** - Use TeamDelete

## Variable Reference

| Variable                 | Description                          | Example                                                                 |
| ------------------------ | ------------------------------------ | ----------------------------------------------------------------------- |
| `{{FEATURE_NAME}}`       | Feature directory name               | `plex-integration`                                                      |
| `{{FEATURE_DIR}}`        | Full research output directory       | `docs/plans/plex-integration`                                           |
| `{{FEATURE_DESCRIPTION}}`| User-provided description            | `Advanced Plex media library integration with filters and playlists`    |

## Teammate Configuration

| Teammate              | Type                        | Can Write | Output File                   | Model   |
| --------------------- | --------------------------- | --------- | ----------------------------- | ------- |
| api-researcher        | `research-specialist`       | Yes       | research-external.md          | Default |
| business-analyzer     | `codebase-research-analyst` | Yes       | research-business.md          | Default |
| tech-designer         | `codebase-research-analyst` | Yes       | research-technical.md         | Default |
| ux-researcher         | `research-specialist`       | Yes       | research-ux.md                | Default |
| recommendations-agent | `codebase-research-analyst` | Yes       | research-recommendations.md   | Default |

## Expected Output

Each research file should be:
- **Comprehensive**: Cover all aspects of its domain
- **Actionable**: Include specific recommendations
- **Referenced**: Link to sources and documentation
- **Structured**: Follow the output format exactly
