---
name: shared-context
description: Create shared context documentation for a feature by orchestrating parallel research agents, writing research artifacts, and synthesizing verified architecture, patterns, integrations, and docs into shared.md. Use as Step 1 before parallel-plan when preparing implementation context.
argument-hint: '[feature-name] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
  - TodoWrite
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

Create planning context for a feature by orchestrating parallel research agents, persisting workstream reports, and synthesizing `shared.md`.

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

## Research Agents That Would Run

1. Architecture Researcher - System structure and components
2. Pattern Researcher - Existing patterns to follow
3. Integration Researcher - APIs, databases, external systems
4. Documentation Researcher - Relevant docs and guides

## Files That Would Be Created

- ${PLANS_DIR}/[feature-name]/research-architecture.md
- ${PLANS_DIR}/[feature-name]/research-patterns.md
- ${PLANS_DIR}/[feature-name]/research-integration.md
- ${PLANS_DIR}/[feature-name]/research-docs.md
- ${PLANS_DIR}/[feature-name]/shared.md

## Execution Model

- Deploy one `codebase-research-analyst` agent per workstream
- Wait for all workstreams to complete
- Persist each workstream as a research artifact
- Synthesize results into shared.md
- Validate shared.md

## Next Steps

Remove --dry-run flag to execute research.
```

**STOP HERE** - do not create files or deploy agents.

---

## Phase 2: Parallel Research Deployment

### Step 6: Read Research Prompts

Read the research prompts template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/shared-context/templates/research-prompts.md
```

### Step 7: Deploy Research Agents

**CRITICAL**: Deploy all 4 agents in a **SINGLE message** with **MULTIPLE Task tool calls**.

Each agent MUST write its findings to the specified output file. The orchestrator MUST verify file persistence after agents complete.

| Agent                    | Subagent Type               | Output File                | Focus                                    |
| ------------------------ | --------------------------- | -------------------------- | ---------------------------------------- |
| Architecture Researcher  | `codebase-research-analyst` | `research-architecture.md` | System structure, components, data flow  |
| Pattern Researcher       | `codebase-research-analyst` | `research-patterns.md`     | Existing patterns, conventions, examples |
| Integration Researcher   | `codebase-research-analyst` | `research-integration.md`  | APIs, databases, external systems        |
| Documentation Researcher | `codebase-research-analyst` | `research-docs.md`         | Relevant documentation files             |

Each agent writes findings to `${feature_dir}/[output-file]`.

Use the prompts from `research-prompts.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 2)

---

## Phase 3: Validate Research Artifacts

### Step 8: Validate Research Artifacts

After agents complete, validate all research files:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/shared-context/scripts/validate-research-artifacts.sh "${feature_dir}"
```

If validation fails: identify which files are missing or invalid from the script output, re-deploy ONLY the failed agents with their original prompts, wait for corrected outputs, then rerun validation until pass.

**Do not proceed to synthesis until validation passes.**

---

## Phase 4: Consolidate Research

### Step 9: Read Research Reports

Read all research files:

1. `${feature_dir}/research-architecture.md`
2. `${feature_dir}/research-patterns.md`
3. `${feature_dir}/research-integration.md`
4. `${feature_dir}/research-docs.md`

### Step 10: Generate shared.md

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

### Step 11: Validate shared.md

Run the validation script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/shared-context/scripts/validate-shared.sh "${feature_dir}/shared.md"
```

Fix any issues reported, then re-run until validation passes or only warnings remain.

### Step 12: Display Summary

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

## Output Contract

All files are written to `${feature_dir}/` (resolved via `resolve-plans-dir.sh`).

| File                       | Producer                       | Required Before     |
| -------------------------- | ------------------------------ | ------------------- |
| `research-architecture.md` | Architecture Researcher agent  | shared.md synthesis |
| `research-patterns.md`     | Pattern Researcher agent       | shared.md synthesis |
| `research-integration.md`  | Integration Researcher agent   | shared.md synthesis |
| `research-docs.md`         | Documentation Researcher agent | shared.md synthesis |
| `shared.md`                | Orchestrator (this skill)      | Skill completion    |

**Contract Rules**:

1. Each agent MUST write its own output file using the Write tool
2. The orchestrator MUST run `validate-research-artifacts.sh` before generating shared.md
3. If validation fails, the orchestrator MUST re-deploy the failed agents
4. No file may be skipped or deferred

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

- **You are the researcher** - gather comprehensive context
- **Deploy agents in parallel** - single message with multiple Task calls
- **Validate with script** - run `validate-research-artifacts.sh` after agents complete
- **Re-deploy on failure** - if validation fails, re-deploy only the failed agents
- **Be thorough but concise** - quality over quantity
- **Verify file paths** - all referenced files must exist
- **Foundation for planning** - this document will be used by parallel-plan (run separately by user)
- **Monorepo aware** - automatically resolves correct plans directory
