---
name: shared-context
description: Create shared context documentation for a feature by orchestrating a research agent team, writing research artifacts, and synthesizing verified architecture, patterns, integrations, and docs into shared.md. Use as Step 1 before parallel-plan when preparing implementation context.
argument-hint: '[feature-name] [--dry-run]'
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
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/shared-context/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
---

## SCOPE LIMITATION - READ FIRST

**THIS SKILL ONLY CREATES RESEARCH CONTEXT FILES. IT NEVER PLANS OR IMPLEMENTS.**

- DO NOT run the parallel-plan skill
- DO NOT run the implement-plan skill
- DO NOT execute implementation tasks
- DO NOT modify application source files

**Outputs**:

- `${PLANS_DIR}/[feature-name]/research-architecture.md`
- `${PLANS_DIR}/[feature-name]/research-patterns.md`
- `${PLANS_DIR}/[feature-name]/research-integration.md`
- `${PLANS_DIR}/[feature-name]/research-docs.md`
- `${PLANS_DIR}/[feature-name]/shared.md`

After creating the shared context files and displaying the summary, **STOP COMPLETELY**.

---

# Shared Context Creator

Create planning context for a feature by orchestrating a research agent team, persisting workstream reports, and synthesizing `shared.md`.

## Workflow Integration

```text
shared-context (this skill) -> parallel-plan -> implement-plan
```

This skill ends after research files and `shared.md` are created and validated.

## Arguments

**Target**: `$ARGUMENTS`

Parse arguments:

- **feature-name**: Name of the feature to research (directory name under `${PLANS_DIR}`)
- **--dry-run**: Show orchestration plan without creating files

If no feature name provided, abort with usage instructions:

```
Usage: /shared-context [feature-name] [--dry-run]

Examples:
  /shared-context user-authentication
  /shared-context payment-integration --dry-run
```

---

## Phase 0: Initialize Planning Directory

### Step 1: Extract Feature Name

Extract the feature name from `$ARGUMENTS` (first non-flag argument).

Validate the feature name:

- Must be provided
- Should use kebab-case (lowercase with hyphens)
- No special characters except hyphens

### Step 2: Resolve Plans Directory

Use the shared resolver to determine the correct plans directory:

```bash
source ${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/resolve-plans-dir.sh
feature_dir="$(get_feature_plan_dir "[feature-name]")"
```

This handles monorepo detection, `.plans-config` files, and git root resolution automatically.

### Step 3: Ensure Feature Directory Exists

```bash
mkdir -p "$feature_dir"
```

### Step 4: Load Existing Planning Context

If the directory already has `.md` files:

- Read them for prior context
- Reuse findings where valid
- Avoid duplicating existing analysis

---

## Phase 1: Dry Run Check

### Step 5: Handle `--dry-run`

If `--dry-run` is present in `$ARGUMENTS`:

Display:

```markdown
# Dry Run: Shared Context for [feature-name]

## Directory

- ${PLANS_DIR}/[feature-name]/

## Research Team

Team Name: sc-[feature-name]
Teammates: 4 research agents (can share findings with each other)

1. architecture-researcher - System structure and components
2. patterns-researcher - Existing patterns to follow
3. integration-researcher - APIs, databases, external systems
4. docs-researcher - Relevant docs and guides

## Files That Would Be Created

- ${PLANS_DIR}/[feature-name]/research-architecture.md
- ${PLANS_DIR}/[feature-name]/research-patterns.md
- ${PLANS_DIR}/[feature-name]/research-integration.md
- ${PLANS_DIR}/[feature-name]/research-docs.md
- ${PLANS_DIR}/[feature-name]/shared.md

## Execution Model

- Create agent team with 4 research teammates
- Teammates claim tasks from shared task list
- Teammates share findings with each other via messages
- Team lead validates research artifacts
- Team lead synthesizes results into shared.md
- Team cleanup

## Next Steps

Remove --dry-run flag to execute research.
```

**STOP HERE** - do not create files or deploy agents.

---

## Phase 2: Create Research Team

### Step 6: Create the Team

Create an agent team for the research phase:

```
TeamCreate: team_name="sc-[feature-name]", description="Research team for [feature-name] shared context"
```

### Step 7: Create Research Tasks

Create 4 tasks in the shared task list — one per research domain:

1. **"Research architecture for [feature-name]"** — System structure, components, data flow, integration points
2. **"Research patterns for [feature-name]"** — Architectural patterns, code conventions, error handling, testing
3. **"Research integrations for [feature-name]"** — APIs, databases, external services, configuration
4. **"Research documentation for [feature-name]"** — Docs, READMEs, code comments, external references

### Step 8: Read Research Prompts

Read the research prompts template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/shared-context/templates/research-prompts.md
```

### Step 9: Spawn Research Teammates

**CRITICAL**: Spawn all 4 teammates in a **SINGLE message** with **MULTIPLE Agent tool calls**, each with `team_name="sc-[feature-name]"`.

| Teammate Name             | Subagent Type               | Output File                | Model  | Focus                                    |
| ------------------------- | --------------------------- | -------------------------- | ------ | ---------------------------------------- |
| `architecture-researcher` | `codebase-research-analyst` | `research-architecture.md` | sonnet | System structure, components, data flow  |
| `patterns-researcher`     | `codebase-research-analyst` | `research-patterns.md`     | sonnet | Existing patterns, conventions, examples |
| `integration-researcher`  | `codebase-research-analyst` | `research-integration.md`  | sonnet | APIs, databases, external systems        |
| `docs-researcher`         | `codebase-research-analyst` | `research-docs.md`         | sonnet | Relevant documentation files             |

**Model Assignment**: Pass `model: "sonnet"` for all shared-context researchers.

Each teammate writes findings to `${feature_dir}/[output-file]`.

Use the prompts from `research-prompts.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 2)

### Step 10: Monitor Team Progress

Wait for teammates to complete their tasks. Teammates will:

1. Claim their task from the shared list
2. Research their domain
3. Share key findings with relevant teammates via SendMessage
4. Write their output file
5. Mark their task complete
6. Go idle

Use `TaskList` to check progress. When all 4 tasks are complete, proceed to validation.

If a teammate gets stuck, send them a message with guidance or additional context.

---

## Phase 3: Validate Research Artifacts

### Step 11: Validate Research Artifacts

After all teammates complete, validate all research files:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/shared-context/scripts/validate-research-artifacts.sh "${feature_dir}"
```

If validation fails: identify which files are missing or invalid from the script output, send a message to the relevant teammate asking them to fix their output, wait for correction, then rerun validation until pass.

**Do not proceed to synthesis until validation passes.**

### Step 12: Shut Down Research Teammates

Send shutdown requests to all teammates:

```
SendMessage to each teammate: message={type: "shutdown_request"}
```

Wait for all teammates to shut down before proceeding.

---

## Phase 4: Consolidate Research

### Step 13: Read Research Reports

Read all research files:

1. `${feature_dir}/research-architecture.md`
2. `${feature_dir}/research-patterns.md`
3. `${feature_dir}/research-integration.md`
4. `${feature_dir}/research-docs.md`

### Step 14: Generate shared.md

Read the shared structure template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/shared-context/templates/shared-structure.md
```

Create `${feature_dir}/shared.md` following the template exactly.

Quality rules:

- Include only verified paths
- Keep descriptions concise and implementation-relevant
- Link patterns to concrete examples
- Mark docs with explicit "must read" contexts

---

## Phase 5: Validation & Summary

### Step 15: Validate shared.md

Run the validation script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/shared-context/scripts/validate-shared.sh "${feature_dir}/shared.md"
```

Fix any issues reported, then re-run until validation passes or only warnings remain.

### Step 16: Clean Up Team

Delete the team and its resources:

```
TeamDelete
```

### Step 17: Display Summary

Provide completion summary:

```markdown
# Shared Context Created

## Location

${feature_dir}/shared.md

## Research Files

- ${feature_dir}/research-architecture.md
- ${feature_dir}/research-patterns.md
- ${feature_dir}/research-integration.md
- ${feature_dir}/research-docs.md

## Team Summary

- Team: sc-[feature-name]
- Teammates: 4 research agents
- Inter-agent sharing: Enabled (teammates shared findings with each other)

## Summary

- Relevant Files: [count]
- Relevant Tables: [count]
- Relevant Patterns: [count]
- Relevant Docs: [count]

## Next Step (User Triggered)

/parallel-plan [feature-name]
```

**STOP**: Do not execute parallel-plan. Do not write any more files. Do not modify any code. This skill is complete.

---

## Quality Standards

### shared.md Quality Checklist

- [ ] Clear, information-dense overview (3-4 sentences)
- [ ] All file paths verified to exist
- [ ] Brief but useful descriptions for each item
- [ ] Patterns linked to example files where possible
- [ ] Documentation marked with required reading topics

## CRITICAL CONSTRAINTS

- **RESEARCH ONLY** - This skill creates documentation, never plans or implements
- **NO CODE CHANGES** - Do not modify any application source files
- **NO PLANNING** - Do not run parallel-plan or create implementation plans
- **STOP AFTER SUMMARY** - After displaying the completion summary, stop completely
- **DO NOT CHAIN** - Do not automatically proceed to parallel-plan or implement-plan
- **PERSIST ARTIFACTS** - All 4 research files must exist before synthesis
- **CLEAN UP TEAM** - Always delete the team before completing

## Output Contract

All files are written to `${feature_dir}/` (resolved via `resolve-plans-dir.sh`).

| File                       | Producer                         | Required Before     |
| -------------------------- | -------------------------------- | ------------------- |
| `research-architecture.md` | architecture-researcher teammate | shared.md synthesis |
| `research-patterns.md`     | patterns-researcher teammate     | shared.md synthesis |
| `research-integration.md`  | integration-researcher teammate  | shared.md synthesis |
| `research-docs.md`         | docs-researcher teammate         | shared.md synthesis |
| `shared.md`                | Team lead (this skill)           | Skill completion    |

**Contract Rules**:

1. Each teammate MUST write its own output file using the Write tool
2. Each teammate MUST share key findings with relevant teammates via SendMessage
3. The team lead MUST run `validate-research-artifacts.sh` before generating shared.md
4. If validation fails, the team lead MUST message the failing teammate to fix their output
5. No file may be skipped or deferred
6. The team MUST be cleaned up (TeamDelete) before skill completion

## Monorepo Support

Use `.plans-config` via `resolve-plans-dir.sh`.

Default behavior:

- Plans resolve to repository root `docs/plans/`
- Running from subdirectories still writes to root plans unless local scope is configured

Optional local scope in `.plans-config`:

```yaml
plans_dir: docs/plans
scope: local
```

## Important Notes

- **You are the team lead** - coordinate the research team
- **Create team first** - use TeamCreate before spawning teammates
- **Spawn teammates in parallel** - single message with multiple Agent calls
- **Teammates share findings** - they communicate with each other via SendMessage
- **Validate with script** - run `validate-research-artifacts.sh` after teammates complete
- **Message on failure** - if validation fails, message the relevant teammate
- **Clean up team** - always TeamDelete before completing
- **Be thorough but concise** - quality over quantity
- **Verify file paths** - all referenced files must exist
- **Foundation for planning** - this document will be used by parallel-plan (run separately by user)
- **Monorepo aware** - automatically resolves correct plans directory
