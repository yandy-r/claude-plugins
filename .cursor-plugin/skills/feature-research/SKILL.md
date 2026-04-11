---
name: feature-research
description: >
  Run the full 7-agent research pipeline for a new feature — deploys api-researcher,
  business-analyzer, tech-designer, ux-researcher, security-researcher, practices-researcher,
  and recommendations-agent in parallel to produce 7 research-*.md files and a consolidated
  feature-spec.md under docs/plans/[feature-name]/. This is the heavyweight multi-agent
  research track that outputs to docs/plans/, NOT docs/prps/. Use when the user asks to
  "research a feature", "run feature research", "deep-dive a feature before planning",
  or says "/feature-research". For lightweight single-pass specs in the PRP workflow,
  use prp-spec instead.
argument-hint: '[feature-name] [--description "..."] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Agent
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - SendMessage
  - WebSearch
  - WebFetch
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - 'Bash(${CURSOR_PLUGIN_ROOT}/skills/feature-research/scripts/*.sh:*)'
  - 'Bash(${CURSOR_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
---

# Feature Research

Deep research skill for application features. Goes beyond codebase analysis to research external APIs, business logic, technical specifications, UX considerations, and generate actionable recommendations. Uses a coordinated research team where agents share findings with each other.

## Workflow Integration

```
feature-research  -->  plan-workflow  -->  implement-plan
(this skill)           (Step 2)            (Step 3)
Creates:               Uses:               Executes:
feature-spec.md        feature-spec.md     parallel-plan.md
```

**Key Distinctions — This skill vs. other planning/research skills**:

| Skill                     | Agents                            | Output Dir           | Output Files                          | Use When                                       |
| ------------------------- | --------------------------------- | -------------------- | ------------------------------------- | ---------------------------------------------- |
| `feature-research` (THIS) | 7 parallel agents                 | `docs/plans/[name]/` | 7 `research-*.md` + `feature-spec.md` | Deep multi-agent research before plan-workflow |
| `shared-context`          | Agent team                        | `docs/plans/[name]/` | `shared.md`                           | Codebase-focused context for parallel-plan     |
| `prp-spec`                | Single pass (optional researcher) | `docs/prps/specs/`   | `{name}.spec.md`                      | Lightweight spec for PRP workflow              |
| `prp-prd`                 | Interactive + researcher          | `docs/prps/prds/`    | `{name}.prd.md`                       | Full PRD with hypothesis-driven questioning    |
| `prp-plan`                | Single pass + researcher          | `docs/prps/plans/`   | `{name}.plan.md`                      | Implementation plan from PRD or description    |

**This skill ALWAYS**:

- Deploys the full 7-agent research team (never skips agents)
- Creates 7 `research-*.md` files + 1 `feature-spec.md`
- Outputs ONLY to `docs/plans/[feature-name]/`
- Uses TeamCreate/TeamDelete for agent coordination

**This skill NEVER**:

- Writes to `docs/prps/` (that is the PRP workflow directory)
- Generates a single-file spec without the research pipeline
- Skips the multi-agent team to produce output directly
- Acts as a lightweight spec generator

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

**CRITICAL**: Output goes to `docs/plans/[feature-name]/` — NEVER to `docs/prps/` or any other directory, regardless of the user's current working directory. If the user invokes this skill from inside `docs/prps/` or any subdirectory, still resolve the output path from the repository root as `docs/plans/[feature-name]/`.

```bash
test -d "docs/plans/[feature-name]" && echo "exists" || mkdir -p "docs/plans/[feature-name]"
```

### Step 3: Check Existing Research

List any existing files. If `feature-spec.md` exists, read it and ask user if they want to regenerate or enhance.

### Step 4: Handle Dry Run

If `--dry-run` is present:

Display:

```markdown
# Dry Run: Feature Research for [feature-name]

## Research Team

Team Name: fr-[feature-name]
Teammates: 7 research agents (share findings with each other)

1. api-researcher - External APIs, libraries, integration patterns
2. business-analyzer - Requirements, user stories, business rules
3. tech-designer - Architecture, data models, API design
4. ux-researcher - User experience, workflows, best practices
5. security-researcher - Security analysis, dependency risks, secure coding (severity-leveled)
6. practices-researcher - Modularity, code reuse, KISS, engineering best practices
7. recommendations-agent - Ideas, improvements, risks

## Files That Would Be Created

- docs/plans/[feature-name]/research-external.md
- docs/plans/[feature-name]/research-business.md
- docs/plans/[feature-name]/research-technical.md
- docs/plans/[feature-name]/research-ux.md
- docs/plans/[feature-name]/research-security.md
- docs/plans/[feature-name]/research-practices.md
- docs/plans/[feature-name]/research-recommendations.md
- docs/plans/[feature-name]/feature-spec.md

## Execution Model

- Create agent team with 7 research teammates
- Teammates claim tasks and share findings with each other
- Team lead validates and synthesizes feature-spec.md
- Team cleanup
```

**STOP** without creating files or deploying agents.

---

## Phase 1: Research Team

### Step 5: Create the Team

Create an agent team for feature research:

```
TeamCreate: team_name="fr-[feature-name]", description="Feature research team for [feature-name]"
```

### Step 6: Create Research Tasks

Create 7 tasks in the shared task list:

1. **"Research external APIs for [feature-name]"** — APIs, libraries, integration patterns
2. **"Analyze business logic for [feature-name]"** — Requirements, user stories, business rules
3. **"Design technical specs for [feature-name]"** — Architecture, data models, API design
4. **"Research UX patterns for [feature-name]"** — User experience, workflows, accessibility
5. **"Evaluate security for [feature-name]"** — Security implications, dependency risks, secure coding
6. **"Evaluate engineering practices for [feature-name]"** — Modularity, code reuse, KISS, testability
7. **"Generate recommendations for [feature-name]"** — Ideas, improvements, risks

### Step 7: Read Research Prompts

Read the research prompts template:

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/feature-research/templates/research-agents.md
```

### Step 8: Spawn Research Teammates

**CRITICAL**: Spawn all 7 teammates in a **SINGLE message** with **MULTIPLE Agent tool calls**, each with `team_name="fr-[feature-name]"`.

| Teammate Name           | Subagent Type               | Output File                   | Model   | Focus                                                                 |
| ----------------------- | --------------------------- | ----------------------------- | ------- | --------------------------------------------------------------------- |
| `api-researcher`        | `research-specialist`       | `research-external.md`        | sonnet  | External APIs, libraries, documentation, integration patterns         |
| `business-analyzer`     | `codebase-research-analyst` | `research-business.md`        | sonnet  | Requirements, user stories, business rules, domain logic              |
| `tech-designer`         | `codebase-research-analyst` | `research-technical.md`       | Default | Architecture, data models, API design, system constraints             |
| `ux-researcher`         | `research-specialist`       | `research-ux.md`              | sonnet  | User experience, workflows, best practices, accessibility             |
| `security-researcher`   | `research-specialist`       | `research-security.md`        | sonnet  | Security analysis, dependency risks, secure coding (severity-leveled) |
| `practices-researcher`  | `codebase-research-analyst` | `research-practices.md`       | sonnet  | Modularity, code reuse, KISS, engineering best practices              |
| `recommendations-agent` | `codebase-research-analyst` | `research-recommendations.md` | Default | Ideas, improvements, related features, risks                          |

**Model Assignment**: Pass the `model` parameter when spawning each teammate. Use `model: "sonnet"` for api-researcher, business-analyzer, ux-researcher, security-researcher, practices-researcher. Omit model (inherit default) for tech-designer and recommendations-agent.

Use the prompts from `research-agents.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`docs/plans/[feature-name]`)
- `{{FEATURE_DESCRIPTION}}` - The description provided (or feature name if none)

### Step 9: Monitor Team Progress

Wait for all 7 teammates to complete their tasks. Use `TaskList` to check progress.

Teammates will share findings with each other:

- `api-researcher` tells `tech-designer` about discovered API endpoints and auth patterns
- `api-researcher` tells `security-researcher` about dependency versions and auth methods
- `api-researcher` tells `practices-researcher` about discovered libraries for build-vs-depend analysis
- `tech-designer` tells `business-analyzer` about data model constraints
- `tech-designer` tells `security-researcher` about proposed architecture for review
- `tech-designer` tells `practices-researcher` about proposed component structure for modularity review
- `ux-researcher` tells `business-analyzer` about user workflow requirements
- `security-researcher` tells `tech-designer` about security constraints (with severity levels)
- `security-researcher` tells `recommendations-agent` about full risk summary by severity
- `practices-researcher` tells `tech-designer` about reusable code discoveries and simplification opportunities
- `practices-researcher` tells `recommendations-agent` about modularity and reuse findings
- `recommendations-agent` synthesizes insights from all teammates including security and practices findings

If a teammate gets stuck, send them guidance via SendMessage.

---

## Phase 2: Consolidate Research

### Step 10: Validate Research Artifacts

After all 7 teammates complete, validate all `research-*.md` files:

```bash
${CURSOR_PLUGIN_ROOT}/skills/feature-research/scripts/validate-research.sh docs/plans/[feature-name]
```

If validation fails: message the relevant teammate to fix their output, wait for correction, rerun validation until pass.

### Step 11: Shut Down Research Teammates

Send shutdown requests to all teammates:

```
SendMessage to each teammate: message={type: "shutdown_request"}
```

### Step 12: Read Research Results

Read all 7 research files from `docs/plans/[feature-name]/`.

### Step 13: Read Spec Template

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/feature-research/templates/spec-structure.md
```

### Step 14: Generate feature-spec.md

Create `docs/plans/[feature-name]/feature-spec.md` following the template.

**Key Consolidation Principles**:

1. Organize by section, not by agent - Synthesize related findings
2. Be information-dense - Every sentence should add value
3. Include actionable details - Links, code examples, specific APIs
4. Highlight decisions needed - Call out areas requiring user input
5. Preserve source references - Link to original research files for details
6. Surface security findings by severity - CRITICAL items must appear in Risk Assessment; WARNING items in relevant technical sections; ADVISORY items in Recommendations

---

## Phase 3: Validate and Complete

### Step 15: Validate Spec

```bash
${CURSOR_PLUGIN_ROOT}/skills/feature-research/scripts/validate-spec.sh docs/plans/[feature-name]/feature-spec.md
```

Fix any issues reported (missing sections, empty content, formatting).

### Step 16: Clean Up Team

Delete the team and its resources:

```
TeamDelete
```

### Step 17: Display Summary

Provide completion summary with: feature name, description, files created, team summary, research summary counts, key findings, decisions needed, and next steps (review spec, proceed to `/plan-workflow`, or add requirements).

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

## Anti-patterns — Do NOT Do These

1. **Do NOT skip the multi-agent pipeline**: Never generate `feature-spec.md` directly without first deploying all 7 research teammates and collecting their `research-*.md` files. The spec is a synthesis of research, not a standalone generation. If about to write `feature-spec.md` without the 7 research files already on disk, STOP — the pipeline is off-rails.

2. **Do NOT output to `docs/prps/`**: This skill's output directory is `docs/plans/[feature-name]/`. The `docs/prps/` tree belongs to the PRP workflow (`prp-prd`, `prp-spec`, `prp-plan`, `prp-implement`). Even if the user's working directory is `docs/prps/` or any subdirectory, always create output under `docs/plans/`.

3. **Do NOT generate a single file**: The minimum correct output is 8 files (7 research + 1 spec). If about to write only one file, STOP — the user likely wants the lightweight PRP spec skill. Redirect them to `/prp-spec`.

4. **Do NOT conflate with PRP spec generation**: If the user wants a lightweight single-pass spec without a research team, they want `/prp-spec`, not this skill. This skill is the heavyweight multi-agent research track.

## Important Notes

- **You are the team lead** - coordinate the research team
- **Create team first** - use TeamCreate before spawning teammates
- **Spawn teammates in parallel** - single message with multiple Agent calls
- **Teammates share findings** - they communicate with each other via SendMessage
- **Use single-owner research files** - each teammate writes only its assigned artifact
- **Gate synthesis with validation** - do not generate `feature-spec.md` before validator pass
- **Use web search** - external APIs require current documentation
- **Be thorough but focused** - quality over quantity
- **Enable plan-workflow** - this spec is the foundation for implementation planning
- **Preserve uncertainty** - mark areas needing clarification rather than guessing
- **Clean up team** - always TeamDelete before completing
