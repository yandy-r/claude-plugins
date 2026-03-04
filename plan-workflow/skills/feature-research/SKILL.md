---
name: feature-research
description: >
  This skill should be used when the user asks to "research a feature", "create a feature spec",
  "analyze external APIs for a feature", "plan feature research", "generate a feature-spec.md",
  or mentions needing comprehensive research before implementing a new feature. Also triggered
  by the /feature-research command. Creates feature-spec.md ready for plan-workflow.
argument-hint: '[feature-name] [--description "..."] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
  - TodoWrite
  - WebSearch
  - WebFetch
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/feature-research/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
---

# Feature Research

Deep research skill for application features. Goes beyond codebase analysis to research external APIs, business logic, technical specifications, UX considerations, and generate actionable recommendations.

## Workflow Integration

```
feature-research  -->  plan-workflow  -->  implement-plan
(this skill)           (Step 2)            (Step 3)
Creates:               Uses:               Executes:
feature-spec.md        feature-spec.md     parallel-plan.md
```

**Key Distinction**:

- `shared-context`: Codebase-focused research (files, patterns, tables, internal docs)
- `feature-research`: Comprehensive research (external APIs, business logic, UX, technical specs, recommendations)

## Arguments

**Target**: `$ARGUMENTS`

Parse arguments:

- **feature-name**: Required. Directory name in `docs/plans/`
- **--description "..."**: Brief description of the feature (guides research agents)
- **--dry-run**: Show execution plan without running

If no feature name provided, abort with usage instructions:

```
Usage: /feature-research [feature-name] [--description "..."] [--dry-run]

Examples:
  /feature-research plex-integration --description "Advanced Plex media library integration with filters and playlists"
  /feature-research payment-system --description "Stripe payment integration for subscriptions"
  /feature-research user-dashboard --dry-run
```

---

## Phase 0: Initialize

### Step 1: Parse Arguments

Extract from `$ARGUMENTS`:

1. **feature-name**: First non-flag argument (required)
2. **--description**: Quoted string after flag (optional but recommended)
3. **--dry-run**: Boolean flag

Validate the feature name: must be kebab-case, no special characters except hyphens.

### Step 2: Create Directory

```bash
test -d "docs/plans/[feature-name]" && echo "exists" || mkdir -p "docs/plans/[feature-name]"
```

### Step 3: Check Existing Research

List any existing files. If `feature-spec.md` exists, read it and ask user if they want to regenerate or enhance.

### Step 4: Handle Dry Run

If `--dry-run` is present, display the execution plan (agents, output files, directory) and **STOP** without creating files or deploying agents.

---

## Phase 1: Research (Parallel Deployment)

### Step 5: Read Research Prompts

Read the research prompts template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/feature-research/templates/research-agents.md
```

### Step 6: Deploy Research Agents

**CRITICAL**: Deploy all 5 agents in a **SINGLE message** with **MULTIPLE Task tool calls**.

| Agent                   | Subagent Type               | Output File                   | Focus                                                         |
| ----------------------- | --------------------------- | ----------------------------- | ------------------------------------------------------------- |
| External API Researcher | `research-specialist`       | `research-external.md`        | External APIs, libraries, documentation, integration patterns |
| Business Logic Analyzer | `codebase-research-analyst` | `research-business.md`        | Requirements, user stories, business rules, domain logic      |
| Technical Spec Designer | `codebase-research-analyst` | `research-technical.md`       | Architecture, data models, API design, system constraints     |
| UX Researcher           | `research-specialist`       | `research-ux.md`              | User experience, workflows, best practices, accessibility     |
| Recommendations Agent   | `codebase-research-analyst` | `research-recommendations.md` | Ideas, improvements, related features, risks                  |

Use the prompts from `research-agents.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`docs/plans/[feature-name]`)
- `{{FEATURE_DESCRIPTION}}` - The description provided (or feature name if none)

---

## Phase 2: Consolidate Research

### Step 7: Validate Research Artifacts

After agents complete, validate all `research-*.md` files:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/feature-research/scripts/validate-research.sh docs/plans/[feature-name]
```

If validation fails: identify failed workstream files, send targeted corrective follow-up only to owning agents, wait for corrected outputs, rerun validation until pass.

### Step 8: Read Research Results

Read all 5 research files from `docs/plans/[feature-name]/`.

### Step 9: Read Spec Template

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/feature-research/templates/spec-structure.md
```

### Step 10: Generate feature-spec.md

Create `docs/plans/[feature-name]/feature-spec.md` following the template.

**Key Consolidation Principles**:

1. Organize by section, not by agent - Synthesize related findings
2. Be information-dense - Every sentence should add value
3. Include actionable details - Links, code examples, specific APIs
4. Highlight decisions needed - Call out areas requiring user input
5. Preserve source references - Link to original research files for details

---

## Phase 3: Validate and Complete

### Step 11: Validate Spec

```bash
${CLAUDE_PLUGIN_ROOT}/skills/feature-research/scripts/validate-spec.sh docs/plans/[feature-name]/feature-spec.md
```

Fix any issues reported (missing sections, empty content, formatting).

### Step 12: Display Summary

Provide completion summary with: feature name, description, files created, research summary counts, key findings, decisions needed, and next steps (review spec, proceed to `/plan-workflow`, or add requirements).

---

## Quality Standards

### feature-spec.md Quality Checklist

- Executive summary is information-dense (3-5 sentences)
- External dependencies include documentation links
- Business requirements are specific and testable
- Technical specs include data models/schemas
- UX considerations address error states
- Recommendations are actionable
- Task breakdown preview is realistic

### Research Quality Checklist

Each research file should: focus on its specific domain, include concrete examples and links, identify gaps and uncertainties, provide actionable recommendations, and avoid duplication with other research files.

## Important Notes

- Deploy agents in parallel - single message with multiple Task calls
- Use single-owner research files - each agent writes only its assigned artifact
- Gate synthesis with research validation - do not generate `feature-spec.md` before validator pass
- Use web search - external APIs require current documentation
- Be thorough but focused - quality over quantity
- Enable plan-workflow - this spec is the foundation for implementation planning
- Preserve uncertainty - mark areas needing clarification rather than guessing
