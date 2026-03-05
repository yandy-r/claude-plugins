---
name: plan-workflow
description: Unified planning workflow - research, analyze, and generate parallel implementation plans in one command. Combines shared-context and parallel-plan with checkpoint support and optimized agent deployment.
argument-hint: '[feature-name] [--research-only] [--plan-only] [--no-checkpoint] [--optimized] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
  - TodoWrite
  - AskUserQuestion
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/**/*.sh:*)'
---

# Unified Planning Workflow

Single command to research, analyze, and plan feature implementation. This skill combines the functionality of `shared-context` and `parallel-plan` with optimizations and checkpoint support.

## Workflow Overview

```
+--------------------------------------------------------------+
|                    /plan-workflow feature                     |
+--------------------------------------------------------------+
|                                                               |
|  +-----------+   +----------+   +---------------------+      |
|  | Research  |-->|Checkpoint|-->| Planning + Validate |      |
|  | (Wave 1)  |   | (Review) |   | (Waves 2-3)         |      |
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
source ${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/resolve-plans-dir.sh
feature_dir="$(get_feature_plan_dir "[feature-name]")"
```

This handles monorepo detection, `.plans-config` files, and git root resolution automatically.

### Step 3: Run State Detection

Run the state detection script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/scripts/check-state.sh [feature-name]
```

This script reports:

- Whether `${feature_dir}/` exists
- Whether `shared.md` exists
- Whether `parallel-plan.md` exists
- Any existing research files

### Step 4: Determine Execution Mode

Based on flags and detected state:

| State                | --plan-only | --research-only | Action                         |
| -------------------- | ----------- | --------------- | ------------------------------ |
| No shared.md         | N/A         | N/A             | Full workflow from Phase 1; if --research-only, stop after Phase 4 |
| Has shared.md        | Yes         | N/A             | Skip to Phase 5 (Analysis)     |
| Has shared.md        | No          | Yes             | Skip (already done)            |
| Has shared.md        | No          | No              | Full workflow from Phase 1 (regenerates shared.md) |
| Has parallel-plan.md | Any         | Any             | Warn about overwrite           |

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
cat ${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/templates/checkpoint-messages.md
```

Display the "Dry Run" section from the template with appropriate values substituted, then **STOP**.

---

## Phase 1: Research (unless --plan-only)

### Step 7: Read Research Prompts

Read the research prompts template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/templates/research-agents.md
```

### Step 8: Deploy Research Agents

**CRITICAL**: Deploy all 4 agents in a **SINGLE message** with **MULTIPLE Task tool calls**.

Each agent MUST write its findings to the specified output file. The orchestrator MUST verify file persistence after agents complete.

| Agent                    | Subagent Type               | Output File                | Focus                                    |
| ------------------------ | --------------------------- | -------------------------- | ---------------------------------------- |
| Architecture Researcher  | `codebase-research-analyst` | `research-architecture.md` | System structure, components, data flow  |
| Pattern Researcher       | `codebase-research-analyst` | `research-patterns.md`     | Existing patterns, conventions, examples |
| Integration Researcher   | `codebase-research-analyst` | `research-integration.md`  | APIs, databases, external systems        |
| Documentation Researcher | `codebase-research-analyst` | `research-docs.md`         | Relevant documentation files             |

Each agent writes findings to `${feature_dir}/[output-file]`.

Use the prompts from `research-agents.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 2)

---

## Phase 2: Validate Research Artifacts

### Step 9: Validate Research Artifacts

After agents complete, validate all research files:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/shared-context/scripts/validate-research-artifacts.sh "${feature_dir}"
```

If validation fails: identify which files are missing or invalid from the script output, re-deploy ONLY the failed agents with their original prompts, wait for corrected outputs, then rerun validation until pass.

**Do not proceed to shared.md synthesis until validation passes.**

---

## Phase 3: Consolidate Research

### Step 10: Read Research Results

After verifying all files exist, read all research files:

1. `${feature_dir}/research-architecture.md`
2. `${feature_dir}/research-patterns.md`
3. `${feature_dir}/research-integration.md`
4. `${feature_dir}/research-docs.md`

### Step 11: Generate shared.md

Read the shared structure template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/templates/shared-structure.md
```

Create `${feature_dir}/shared.md` following the template exactly.

### Step 12: Validate shared.md

Run the validation script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/scripts/validate-shared.sh "${feature_dir}/shared.md"
```

Fix any errors before proceeding.

---

## Phase 4: Checkpoint (unless --no-checkpoint or --research-only)

### Step 13: Pause for User Review

If checkpoint is enabled, use **AskUserQuestion** with these options:

**Question**: "Research complete for [feature-name]. Review the shared context before planning?"

**Options**:

1. **Continue to planning** - Proceed to Phase 5
2. **Review shared.md first** - Display shared.md contents, then re-prompt
3. **Stop here** - End workflow, user will continue manually

Read checkpoint message format from:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/templates/checkpoint-messages.md
```

If user chooses "Review shared.md first":

- Read and display `${feature_dir}/shared.md`
- Re-prompt with same question

If user chooses "Stop here":

- Display completion summary for research phase only
- **STOP** - do not proceed to planning

---

## Phase 5: Analysis (unless --research-only or --optimized)

> **MANDATORY**: This phase MUST run in standard mode, including when `--plan-only` is used.
> The `--plan-only` flag skips Research (Phases 1-4), NOT Analysis. Analysis agents produce
> the `analysis-*.md` files required by Phase 8 (Plan Generation).

### Step 14: Read Analysis Prompts

In standard mode (not --optimized), read analysis prompts:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/templates/planning-agents.md
```

### Step 15: Deploy Analysis Agents

**CRITICAL**: Deploy all 3 agents in a **SINGLE message** with **MULTIPLE Task tool calls**.

Each agent MUST write its findings to the specified output file. The orchestrator MUST verify file persistence after agents complete.

| Agent                | Subagent Type               | Output File           | Focus                  |
| -------------------- | --------------------------- | --------------------- | ---------------------- |
| Context Synthesizer  | `codebase-research-analyst` | `analysis-context.md` | Condense planning docs |
| Code Analyzer        | `codebase-research-analyst` | `analysis-code.md`    | Extract code patterns  |
| Task Structure Agent | `codebase-research-analyst` | `analysis-tasks.md`   | Suggest task breakdown |

Each agent writes to `${feature_dir}/[output-file]`.

Use the prompts from `planning-agents.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 2)

---

## Phase 6: Validate and Persist Analysis Artifacts

### Step 16: First Validation Check

After agents complete, validate all analysis files:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/validate-analysis-artifacts.sh "${feature_dir}"
```

If validation passes → skip to Step 16b (Pre-Generation Gate).
If validation fails → proceed to Step 16a.

### Step 16a: Fallback Write (only if Step 16 failed)

For each missing file reported by the validation script:

1. Find the corresponding `<ANALYSIS_*>` tag content from the agent's response:
   - Missing `analysis-context.md` → look for `<ANALYSIS_CONTEXT>...</ANALYSIS_CONTEXT>` in Agent 1's response
   - Missing `analysis-code.md` → look for `<ANALYSIS_CODE>...</ANALYSIS_CODE>` in Agent 2's response
   - Missing `analysis-tasks.md` → look for `<ANALYSIS_TASKS>...</ANALYSIS_TASKS>` in Agent 3's response
2. Write the tagged content to `${feature_dir}/[filename]` using the Write tool
3. If no tagged content is available for a missing file, re-deploy ONLY that specific agent with its original prompt

After writing fallback files, re-run validation:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/validate-analysis-artifacts.sh "${feature_dir}"
```

### Step 16b: Pre-Generation Gate (MANDATORY — cannot be skipped)

Run the pre-generation gate script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/persist-or-fail.sh "${feature_dir}"
```

- **Exit 0** → proceed to Phase 7
- **Exit 1** → the script prints `MISSING_FILES` and `ACTION_REQUIRED`. Write the missing files NOW (from response tags or by re-deploying agents), then re-run this gate until it passes (exit 0)

**Do NOT proceed to plan generation until `persist-or-fail.sh` exits 0.**

---

## Phase 7: Read Analysis Results

> **PRE-CHECK**: If `analysis-context.md`, `analysis-code.md`, or `analysis-tasks.md` do not
> exist in `${feature_dir}/`, Phase 5 was skipped in error. Go back and run Phase 5 now.

### Step 17: Read Analysis Results

After verifying all files exist, read all analysis files:

1. `${feature_dir}/analysis-context.md`
2. `${feature_dir}/analysis-code.md`
3. `${feature_dir}/analysis-tasks.md`

---

## Phase 8: Plan Generation

### Step 18: Create Task List

Using **TodoWrite**, create a comprehensive task list tracking:

- Major tasks from the emerging plan
- Current progress through the workflow
- In_progress status for current work

### Step 19: Read Plan Template

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/templates/plan-structure.md
```

### Step 20: Generate parallel-plan.md

Create `${feature_dir}/parallel-plan.md` following the template exactly.

Required sections:

- Title & Overview (3-4 information-dense sentences)
- Critically Relevant Files and Documentation
- Implementation Plan with Phases and Tasks
- Advice section

### Step 21: Validate Plan Structure

Run the validation script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/scripts/validate-workflow-plan.sh "${feature_dir}/parallel-plan.md"
```

Fix any structural issues found.

---

## Phase 9: Validation

### Step 22: Read Validation Prompts

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/templates/validation-agents.md
```

### Step 23: Deploy Validation Agents

**Standard Mode**: Deploy 3 agents in parallel:

| Agent                       | Subagent Type               | Focus                                   |
| --------------------------- | --------------------------- | --------------------------------------- |
| File Path Validator         | `explore`                   | Verify all referenced files exist       |
| Dependency Validator        | `explore`                   | Check for circular/invalid dependencies |
| Task Completeness Validator | `codebase-research-analyst` | Ensure tasks are actionable             |

**Optimized Mode**: Deploy 2 agents in parallel:

| Agent                  | Subagent Type               | Focus                           |
| ---------------------- | --------------------------- | ------------------------------- |
| Path Validator         | `explore`                   | Verify paths + dependency graph |
| Completeness Validator | `codebase-research-analyst` | Task quality + completeness     |

### Step 24: Review and Fix Issues

After validators complete:

- Review findings from each validator
- Fix any issues identified:
  - Correct invalid file paths
  - Resolve circular dependencies
  - Add missing details to incomplete tasks
- Re-run validation if significant changes made

---

## Phase 10: Summary

### Step 25: Display Completion Summary

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

## Agent Deployment Summary

- Mode: [standard/optimized]
- Research agents: 4
- Analysis agents: [3/0 depending on mode]
- Validation agents: [3/2 depending on mode]
- Total agents: [10/7]

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

Instead of separate research (4) + analysis (3) agents, deploy 5 unified agents:

| Unified Agent         | Combines                            | Output                     |
| --------------------- | ----------------------------------- | -------------------------- |
| Architecture Analyst  | Arch Research + Context Synthesizer | `analysis-architecture.md` |
| Pattern Analyst       | Pattern Research + Code Analyzer    | `analysis-patterns.md`     |
| Integration Analyst   | Integration Research                | `analysis-integration.md`  |
| Documentation Analyst | Doc Research                        | `analysis-docs.md`         |
| Task Planner          | Task Structure Agent                | `analysis-tasks.md`        |

These agents produce combined research+analysis output, skipping Phase 5 entirely.

Validation uses 2 agents instead of 3 (Path + Completeness merged).

**Total**: 7 agents instead of 10, 2 waves instead of 3.

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

| File                       | Producer                       | Required Before     |
| -------------------------- | ------------------------------ | ------------------- |
| `research-architecture.md` | Architecture Researcher agent  | shared.md synthesis |
| `research-patterns.md`     | Pattern Researcher agent       | shared.md synthesis |
| `research-integration.md`  | Integration Researcher agent   | shared.md synthesis |
| `research-docs.md`         | Documentation Researcher agent | shared.md synthesis |
| `shared.md`                | Orchestrator (this skill)      | Analysis phase      |

### Analysis Phase Artifacts (Standard Mode)

| File                  | Producer                  | Required Before             |
| --------------------- | ------------------------- | --------------------------- |
| `analysis-context.md` | Context Synthesizer agent | parallel-plan.md generation |
| `analysis-code.md`    | Code Analyzer agent       | parallel-plan.md generation |
| `analysis-tasks.md`   | Task Structure Agent      | parallel-plan.md generation |

### Planning Phase Artifacts

| File               | Producer                  | Required Before  |
| ------------------ | ------------------------- | ---------------- |
| `parallel-plan.md` | Orchestrator (this skill) | Skill completion |

**Contract Rules**:

1. Each agent MUST write its own output file using the Write tool AND include content in its assigned response tag (research agents: no tags; analysis agents: `<ANALYSIS_*>` tags)
2. The orchestrator MUST run `validate-research-artifacts.sh` before generating shared.md (Step 9)
3. The orchestrator MUST run `validate-analysis-artifacts.sh` after analysis agents complete (Step 16)
4. If analysis validation fails, the orchestrator MUST write missing files from `<ANALYSIS_*>` response tags (Step 16a)
5. The orchestrator MUST run `persist-or-fail.sh` as a mandatory pre-generation gate (Step 16b)
6. No file may be skipped or deferred — `persist-or-fail.sh` must exit 0 before plan generation

---

## Monorepo Support

The skill automatically detects and uses the correct plans directory in monorepo setups.

### Default Behavior

- Plans are created at the **git repository root** in `docs/plans/`
- Running the skill from any subdirectory (e.g., `packages/app1/`) will still create plans at the root

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

With `scope: local`, plans created from that directory use the local `docs/plans/` instead of the root.

### Example: Monorepo Structure

```
monorepo/
  .plans-config          # plans_dir: docs/plans
  docs/plans/            # Centralized plans (default)
    feature-a/
    feature-b/
  packages/
    app1/
      .plans-config      # plans_dir: docs/plans, scope: local (optional)
      docs/plans/        # App1-specific plans (only if configured)
    app2/
```

---

## Important Notes

- **Unified workflow** - One command replaces two separate skills
- **Checkpoint by default** - Users review research before planning
- **Agent optimization available** - Use `--optimized` to reduce agent count
- **Backwards compatible** - Works alongside individual skills
- **Deploy agents in parallel** - Single message with multiple Task calls
- **Validate with scripts** - Run validation scripts after agents complete
- **Re-deploy on failure** - If validation fails, re-deploy only the failed agents
- **Preserve context** - Read condensed analysis, not raw files
- **Validate thoroughly** - Multiple validation passes ensure quality
- **Monorepo aware** - Automatically resolves correct plans directory via `resolve-plans-dir.sh`
