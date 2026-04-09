---
name: plan-workflow
description: Unified planning workflow - research, analyze, and generate parallel implementation plans in one command. Combines shared-context and parallel-plan with checkpoint support and agent team coordination.
argument-hint: '[feature-name] [--research-only] [--plan-only] [--no-checkpoint] [--optimized] [--dry-run]'
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
  - AskUserQuestion
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - 'Bash(${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/scripts/*.sh:*)'
  - 'Bash(${CURSOR_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
  - 'Bash(${CURSOR_PLUGIN_ROOT}/skills/**/*.sh:*)'
---

# Unified Planning Workflow

Single command to research, analyze, and plan feature implementation using coordinated agent teams. This skill combines the functionality of `shared-context` and `parallel-plan` with optimizations and checkpoint support.

## Workflow Overview

```
+--------------------------------------------------------------+
|                    /plan-workflow feature                     |
+--------------------------------------------------------------+
|                                                               |
|  +-----------+   +----------+   +---------------------+      |
|  | Research  |-->|Checkpoint|-->| Planning + Validate |      |
|  | Team      |   | (Review) |   | Team                |      |
|  +-----------+   +----------+   +---------------------+      |
|       |                                     |                 |
|   shared.md                         parallel-plan.md         |
|                                                               |
+--------------------------------------------------------------+
```

## Arguments

**Target**: `$ARGUMENTS`

Parse arguments:

- **feature-name**: Required. Directory name in `${PLANS_DIR}/`
- **--research-only**: Stop after research phase (creates shared.md only)
- **--plan-only**: Skip research, use existing shared.md
- **--no-checkpoint**: No pause between research and planning
- **--optimized**: Use 7-agent optimized deployment (default: 10-agent standard)
- **--dry-run**: Show execution plan without running

If no feature name provided, abort with usage instructions:

```
Usage: /plan-workflow [feature-name] [options]

Options:
  --research-only   Stop after research phase (creates shared.md only)
  --plan-only       Skip research, use existing shared.md
  --no-checkpoint   No pause between research and planning (default: checkpoint enabled)
  --optimized       Use 7-agent optimized deployment (default: 10-agent standard)
  --dry-run         Show execution plan without running

Examples:
  /plan-workflow user-authentication
  /plan-workflow payment-integration --no-checkpoint
  /plan-workflow api-refactor --research-only
  /plan-workflow user-auth --plan-only
  /plan-workflow new-feature --optimized --dry-run
```

---

## Phase 0: Initialize

### Step 1: Parse Arguments

Extract from `$ARGUMENTS`:

1. **feature-name**: First non-flag argument
2. **Flags**: Check for presence of each flag

Validate the feature name:

- Must be provided
- Should use kebab-case (lowercase with hyphens)
- No special characters except hyphens

### Step 2: Resolve Plans Directory

Use the shared resolver to determine the correct plans directory:

```bash
source ${CURSOR_PLUGIN_ROOT}/skills/_shared/scripts/resolve-plans-dir.sh
feature_dir="$(get_feature_plan_dir "[feature-name]")"
```

This handles monorepo detection, `.plans-config` files, and git root resolution automatically.

### Step 3: Run State Detection

Run the state detection script:

```bash
${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/scripts/check-state.sh [feature-name]
```

This script reports:

- Whether `${feature_dir}/` exists
- Whether `shared.md` exists
- Whether `parallel-plan.md` exists
- Any existing research files

### Step 4: Determine Execution Mode

Based on flags and detected state:

| State                | --plan-only | --research-only | Action                                                             |
| -------------------- | ----------- | --------------- | ------------------------------------------------------------------ |
| No shared.md         | N/A         | N/A             | Full workflow from Phase 1; if --research-only, stop after Phase 4 |
| Has shared.md        | Yes         | N/A             | Skip to Phase 5 (Analysis)                                         |
| Has shared.md        | No          | Yes             | Skip (already done)                                                |
| Has shared.md        | No          | No              | Full workflow from Phase 1 (regenerates shared.md)                 |
| Has parallel-plan.md | Any         | Any             | Warn about overwrite                                               |

**Note**: "Planning" in this workflow = Phase 8 (Plan Generation). "Analysis" = Phase 5.
The `--plan-only` flag skips Research + Checkpoint (Phases 1-4) but NOT Analysis (Phase 5).

### Step 5: Create Directory

If `${feature_dir}/` doesn't exist:

```bash
mkdir -p "${feature_dir}"
```

### Step 6: Handle Dry Run

If `--dry-run` is present, read and display dry run template:

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/templates/checkpoint-messages.md
```

Display the "Dry Run" section from the template with appropriate values substituted, then **STOP**.

---

## Phase 1: Create Team and Research (unless --plan-only)

### Step 7: Create the Team

Create an agent team for the entire workflow:

```
TeamCreate: team_name="pw-[feature-name]", description="Planning workflow team for [feature-name]"
```

### Step 8: Read Research Prompts

Read the research prompts template:

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/templates/research-agents.md
```

### Step 9: Create Research Tasks

Create 4 tasks in the shared task list:

1. **"Research architecture for [feature-name]"**
2. **"Research patterns for [feature-name]"**
3. **"Research integrations for [feature-name]"**
4. **"Research documentation for [feature-name]"**

### Step 10: Spawn Research Teammates

**CRITICAL**: Spawn all 4 teammates in a **SINGLE message** with **MULTIPLE Agent tool calls**, each with `team_name="pw-[feature-name]"`.

| Teammate Name             | Subagent Type               | Output File                | Model  | Focus                                    |
| ------------------------- | --------------------------- | -------------------------- | ------ | ---------------------------------------- |
| `architecture-researcher` | `codebase-research-analyst` | `research-architecture.md` | sonnet | System structure, components, data flow  |
| `patterns-researcher`     | `codebase-research-analyst` | `research-patterns.md`     | sonnet | Existing patterns, conventions, examples |
| `integration-researcher`  | `codebase-research-analyst` | `research-integration.md`  | sonnet | APIs, databases, external systems        |
| `docs-researcher`         | `codebase-research-analyst` | `research-docs.md`         | sonnet | Relevant documentation files             |

**Model Assignment**: Pass `model: "sonnet"` for all research teammates.

Each teammate writes findings to `${feature_dir}/[output-file]`.

Use the prompts from `research-agents.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 2)

---

## Phase 2: Validate Research Artifacts

### Step 11: Validate Research Artifacts

After all research teammates complete (check via TaskList), validate all research files:

```bash
${CURSOR_PLUGIN_ROOT}/skills/shared-context/scripts/validate-research-artifacts.sh "${feature_dir}"
```

If validation fails: message the relevant teammate to fix their output, wait for correction, rerun validation until pass.

**Do not proceed to shared.md synthesis until validation passes.**

### Step 12: Shut Down Research Teammates

Send shutdown requests to all research teammates:

```
SendMessage to each teammate: message={type: "shutdown_request"}
```

---

## Phase 3: Consolidate Research

### Step 13: Read Research Results

After verifying all files exist, read all research files:

1. `${feature_dir}/research-architecture.md`
2. `${feature_dir}/research-patterns.md`
3. `${feature_dir}/research-integration.md`
4. `${feature_dir}/research-docs.md`

### Step 14: Generate shared.md

Read the shared structure template:

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/templates/shared-structure.md
```

Create `${feature_dir}/shared.md` following the template exactly.

### Step 15: Validate shared.md

Run the validation script:

```bash
${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/scripts/validate-shared.sh "${feature_dir}/shared.md"
```

Fix any errors before proceeding.

---

## Phase 4: Checkpoint (unless --no-checkpoint or --research-only)

### Step 16: Pause for User Review

If checkpoint is enabled, use **AskUserQuestion** with these options:

**Question**: "Research complete for [feature-name]. Review the shared context before planning?"

**Options**:

1. **Continue to planning** - Proceed to Phase 5
2. **Review shared.md first** - Display shared.md contents, then re-prompt
3. **Stop here** - End workflow, user will continue manually

Read checkpoint message format from:

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/templates/checkpoint-messages.md
```

If user chooses "Review shared.md first":

- Read and display `${feature_dir}/shared.md`
- Re-prompt with same question

If user chooses "Stop here":

- Clean up team (TeamDelete)
- Display completion summary for research phase only
- **STOP** - do not proceed to planning

---

## Phase 5: Analysis Team (unless --research-only or --optimized)

> **MANDATORY**: This phase MUST run in standard mode, including when `--plan-only` is used.
> The `--plan-only` flag skips Research (Phases 1-4), NOT Analysis. Analysis teammates produce
> the `analysis-*.md` files required by Phase 8 (Plan Generation).

### Step 17: Create Team (if --plan-only)

If `--plan-only` was used (team doesn't exist yet):

```
TeamCreate: team_name="pw-[feature-name]", description="Planning workflow team for [feature-name]"
```

### Step 18: Read Analysis Prompts

In standard mode (not --optimized), read analysis prompts:

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/templates/planning-agents.md
```

### Step 19: Create Analysis Tasks

Create 3 analysis tasks in the shared task list:

1. **"Synthesize planning context for [feature-name]"**
2. **"Analyze code patterns for [feature-name]"**
3. **"Suggest task structure for [feature-name]"**

### Step 20: Spawn Analysis Teammates

**CRITICAL**: Spawn all 3 teammates in a **SINGLE message** with **MULTIPLE Agent tool calls**, each with `team_name="pw-[feature-name]"`.

| Teammate Name         | Subagent Type               | Output File           | Model  | Focus                  |
| --------------------- | --------------------------- | --------------------- | ------ | ---------------------- |
| `context-synthesizer` | `codebase-research-analyst` | `analysis-context.md` | sonnet | Condense planning docs |
| `code-analyzer`       | `codebase-research-analyst` | `analysis-code.md`    | sonnet | Extract code patterns  |
| `task-structurer`     | `codebase-research-analyst` | `analysis-tasks.md`   | sonnet | Suggest task breakdown |

**Model Assignment**: Pass `model: "sonnet"` for all analysis teammates.

Each teammate writes to `${feature_dir}/[output-file]`.

Use the prompts from `planning-agents.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 2)

---

## Phase 6: Validate and Persist Analysis Artifacts

### Step 21: First Validation Check

After analysis teammates complete (check via TaskList), validate all analysis files:

```bash
${CURSOR_PLUGIN_ROOT}/skills/parallel-plan/scripts/validate-analysis-artifacts.sh "${feature_dir}"
```

If validation passes → skip to Step 22 (Pre-Generation Gate).
If validation fails → message the relevant teammate to fix their output, wait, re-validate.

### Step 22: Pre-Generation Gate (MANDATORY — cannot be skipped)

Run the pre-generation gate script:

```bash
${CURSOR_PLUGIN_ROOT}/skills/parallel-plan/scripts/persist-or-fail.sh "${feature_dir}"
```

- **Exit 0** → proceed to Phase 7
- **Exit 1** → the script prints `MISSING_FILES` and `ACTION_REQUIRED`. Message the failing teammate to re-write, then re-run this gate until it passes (exit 0)

**Do NOT proceed to plan generation until `persist-or-fail.sh` exits 0.**

### Step 23: Shut Down Analysis Teammates

Send shutdown requests to all analysis teammates.

---

## Phase 7: Read Analysis Results

> **PRE-CHECK**: If `analysis-context.md`, `analysis-code.md`, or `analysis-tasks.md` do not
> exist in `${feature_dir}/`, Phase 5 was skipped in error. Go back and run Phase 5 now.

### Step 24: Read Analysis Results

After verifying all files exist, read all analysis files:

1. `${feature_dir}/analysis-context.md`
2. `${feature_dir}/analysis-code.md`
3. `${feature_dir}/analysis-tasks.md`

---

## Phase 8: Plan Generation

### Step 25: Read Plan Template

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/templates/plan-structure.md
```

### Step 26: Generate parallel-plan.md

Create `${feature_dir}/parallel-plan.md` following the template exactly.

Required sections:

- Title & Overview (3-4 information-dense sentences)
- Critically Relevant Files and Documentation
- Implementation Plan with Phases and Tasks
- Advice section

### Step 27: Validate Plan Structure

Run the validation script:

```bash
${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/scripts/validate-workflow-plan.sh "${feature_dir}/parallel-plan.md"
```

Fix any structural issues found.

---

## Phase 9: Validation Team

### Step 28: Read Validation Prompts

```bash
cat ${CURSOR_PLUGIN_ROOT}/skills/plan-workflow/templates/validation-agents.md
```

### Step 29: Create Validation Tasks

**Standard Mode**: Create 3 validation tasks:

1. **"Validate file paths in [feature-name] plan"**
2. **"Validate dependency graph in [feature-name] plan"**
3. **"Validate task completeness in [feature-name] plan"**

**Optimized Mode**: Create 2 validation tasks:

1. **"Validate paths and dependencies in [feature-name] plan"**
2. **"Validate task completeness in [feature-name] plan"**

### Step 30: Spawn Validation Teammates

**Standard Mode**: Spawn 3 teammates:

| Teammate Name            | Subagent Type               | Model  | Focus                                   |
| ------------------------ | --------------------------- | ------ | --------------------------------------- |
| `path-validator`         | `explore`                   | haiku  | Verify all referenced files exist       |
| `dependency-validator`   | `explore`                   | haiku  | Check for circular/invalid dependencies |
| `completeness-validator` | `codebase-research-analyst` | sonnet | Ensure tasks are actionable             |

**Optimized Mode**: Spawn 2 teammates:

| Teammate Name            | Subagent Type               | Model  | Focus                           |
| ------------------------ | --------------------------- | ------ | ------------------------------- |
| `path-dep-validator`     | `explore`                   | haiku  | Verify paths + dependency graph |
| `completeness-validator` | `codebase-research-analyst` | sonnet | Task quality + completeness     |

**Model Assignment**: Pass `model: "haiku"` for path/dependency validators, `model: "sonnet"` for completeness-validator.

### Step 31: Review and Fix Issues

After validators complete (check via TaskList):

- Review findings from each validator
- Fix any issues identified:
  - Correct invalid file paths
  - Resolve circular dependencies
  - Add missing details to incomplete tasks
- Re-run validation if significant changes made

### Step 32: Shut Down Validation Teammates

Send shutdown requests to all validation teammates.

---

## Phase 10: Summary

### Step 33: Clean Up Team

Delete the team and its resources:

```
TeamDelete
```

### Step 34: Display Completion Summary

Provide a comprehensive summary:

```markdown
# Plan Workflow Complete

## Feature

[feature-name]

## Files Created

### Research Phase

- ${feature_dir}/research-architecture.md
- ${feature_dir}/research-patterns.md
- ${feature_dir}/research-integration.md
- ${feature_dir}/research-docs.md
- ${feature_dir}/shared.md

### Analysis Phase

- ${feature_dir}/analysis-context.md
- ${feature_dir}/analysis-code.md
- ${feature_dir}/analysis-tasks.md

### Planning Phase

- ${feature_dir}/parallel-plan.md

## Team Summary

- Team: pw-[feature-name]
- Mode: [standard/optimized]
- Research teammates: 4
- Analysis teammates: [3/0 depending on mode]
- Validation teammates: [3/2 depending on mode]
- Total teammates: [10/7]
- Inter-agent sharing: Enabled (teammates shared findings within each phase)

## Plan Overview

- **Total Phases**: [count]
- **Total Tasks**: [count]
- **Independent Tasks**: [count that can run in parallel]
- **Max Dependency Depth**: [deepest chain]

## Validation Results

- File Path Validation: [passed/X issues]
- Dependency Graph: [valid/X issues]
- Task Completeness: [X high quality, Y needs work]

## Next Steps

The implementation plan is ready. Run:

/implement-plan [feature-name]

This will execute the plan with parallel agents where dependencies allow.
```

---

## Optimized Mode

When `--optimized` flag is used, the workflow changes:

### Optimized Agent Architecture

Instead of separate research (4) + analysis (3) teammates, deploy 5 unified teammates:

| Unified Teammate      | Combines                            | Output                     | Model  |
| --------------------- | ----------------------------------- | -------------------------- | ------ |
| `arch-analyst`        | Arch Research + Context Synthesizer | `analysis-architecture.md` | sonnet |
| `pattern-analyst`     | Pattern Research + Code Analyzer    | `analysis-patterns.md`     | sonnet |
| `integration-analyst` | Integration Research                | `analysis-integration.md`  | sonnet |
| `docs-analyst`        | Doc Research                        | `analysis-docs.md`         | sonnet |
| `task-planner`        | Task Structure Agent                | `analysis-tasks.md`        | sonnet |

**Model Assignment**: Pass `model: "sonnet"` for all unified teammates.

These teammates produce combined research+analysis output, skipping Phase 5 entirely.

Validation uses 2 teammates instead of 3 (Path + Dependency merged).

**Total**: 7 teammates instead of 10, 2 phases instead of 3.

---

## Quality Standards

### shared.md Quality Checklist

- [ ] Clear, information-dense overview (3-4 sentences)
- [ ] All file paths verified to exist
- [ ] Brief but useful descriptions for each item
- [ ] Patterns linked to example files where possible
- [ ] Documentation marked with required reading topics

### parallel-plan.md Quality Checklist

- [ ] Information-dense overview (3-4 sentences)
- [ ] Complete list of critically relevant files
- [ ] Tasks organized into logical phases
- [ ] At least one independent task per phase
- [ ] Advice section with implementation insights
- [ ] No circular dependencies
- [ ] All file paths verified

### Task Quality Checklist

Each task must have:

- [ ] Clear, descriptive title
- [ ] Explicit dependencies listed
- [ ] "READ THESE BEFORE TASK" section
- [ ] Files to Create list (if any)
- [ ] Files to Modify list
- [ ] Concise, actionable instructions

---

## Output Contract

All files are written to `${feature_dir}/` (resolved via `resolve-plans-dir.sh`).

### Research Phase Artifacts

| File                       | Producer                         | Required Before     |
| -------------------------- | -------------------------------- | ------------------- |
| `research-architecture.md` | architecture-researcher teammate | shared.md synthesis |
| `research-patterns.md`     | patterns-researcher teammate     | shared.md synthesis |
| `research-integration.md`  | integration-researcher teammate  | shared.md synthesis |
| `research-docs.md`         | docs-researcher teammate         | shared.md synthesis |
| `shared.md`                | Team lead (this skill)           | Analysis phase      |

### Analysis Phase Artifacts (Standard Mode)

| File                  | Producer                     | Required Before             |
| --------------------- | ---------------------------- | --------------------------- |
| `analysis-context.md` | context-synthesizer teammate | parallel-plan.md generation |
| `analysis-code.md`    | code-analyzer teammate       | parallel-plan.md generation |
| `analysis-tasks.md`   | task-structurer teammate     | parallel-plan.md generation |

### Planning Phase Artifacts

| File               | Producer               | Required Before  |
| ------------------ | ---------------------- | ---------------- |
| `parallel-plan.md` | Team lead (this skill) | Skill completion |

**Contract Rules**:

1. Each teammate MUST write its own output file using the Write tool
2. Each teammate MUST share key findings with relevant teammates via SendMessage
3. The team lead MUST run `validate-research-artifacts.sh` before generating shared.md (Step 11)
4. The team lead MUST run `validate-analysis-artifacts.sh` after analysis teammates complete (Step 21)
5. The team lead MUST run `persist-or-fail.sh` as a mandatory pre-generation gate (Step 22)
6. If validation fails, the team lead MUST message the failing teammate to fix their output
7. No file may be skipped or deferred — `persist-or-fail.sh` must exit 0 before plan generation
8. The team MUST be cleaned up (TeamDelete) before skill completion

---

## Monorepo Support

The skill automatically detects and uses the correct plans directory in monorepo setups.

### Default Behavior

- Plans are created at the **git repository root** in `docs/plans/`
- Running the skill from any subdirectory still creates plans at the root

### Configuration

Create a `.plans-config` file to customize behavior:

**Repository Root** (centralized plans):

```yaml
# .plans-config at repo root
plans_dir: docs/plans
```

**Package-Level Plans** (optional):

```yaml
# .plans-config in packages/app1/
plans_dir: docs/plans
scope: local
```

---

## Important Notes

- **You are the team lead** - coordinate all phases of the workflow
- **One team for entire workflow** - create once, use across all phases
- **Spawn teammates in parallel** - single message with multiple Agent calls per phase
- **Pass model parameters** - use `model: "sonnet"` for research/analysis agents, `model: "haiku"` for path/dependency validators, `model: "sonnet"` for completeness-validator
- **Teammates share findings** - they communicate with each other via SendMessage
- **Shut down between phases** - shut down teammates before spawning new ones for next phase
- **Validate with scripts** - run validation scripts after teammates complete
- **Message on failure** - if validation fails, message the relevant teammate
- **Preserve context** - read condensed analysis, not raw files
- **Validate thoroughly** - multiple validation passes ensure quality
- **Clean up team** - always TeamDelete before completing
- **Monorepo aware** - automatically resolves correct plans directory via `resolve-plans-dir.sh`
