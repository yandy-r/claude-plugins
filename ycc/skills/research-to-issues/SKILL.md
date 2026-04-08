---
name: research-to-issues
description: This skill should be used when the user asks to "create issues from research", "turn research into GitHub issues", "generate issues from deep-research output", "create tracking issues from research report", "parse research into actionable issues", or mentions converting documentation produced by the deep-research skill into structured GitHub issues with labels and tracking hierarchy.
---

# Research to GitHub Issues

Convert deep-research output into structured GitHub issues with tracking hierarchy, labels, and priority classification. Parse research documents to extract features, deliverables, anti-scope items, and research gaps, then create well-organized GitHub issues via GitHub MCP server (preferred) or `gh` CLI (fallback).

## Current Task

**Processing research for**: `$ARGUMENTS`

Parse arguments:

- **--dry-run**: Preview all issues that would be created without creating them
- **--research-dir PATH**: Path to the research output directory (default: `docs/research`)
- **--skip-anti-scope**: Skip creating issues for anti-scope items
- **--skip-gaps**: Skip creating issues for research gaps

---

## Tool Preference Strategy

Before beginning Phase 0, determine which tools are available for GitHub operations.

### Step 0: Detect GitHub MCP Server

Check if GitHub MCP tools are available in your current tool list by looking for tools matching the pattern `mcp__github__*` (e.g., `mcp__github__create_issue`, `mcp__github__create_label`).

**Set your tool preference for this session:**

| MCP Tools Available?                 | GitHub Operations Strategy                                                   |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| Yes (`mcp__github__*` tools found)   | **Use MCP tools** for issue creation, label creation, and repository queries |
| No (no `mcp__github__*` tools found) | **Use `gh` CLI** via Bash for all GitHub operations (current behavior)       |

**What stays as CLI regardless:**

- All `git` operations — always use Bash `git` commands
- Validation script (`validate-prerequisites.sh`) — always run via Bash
- File reading and analysis — always use Read/Grep/Glob tools

**Important**: Lack of MCP tools must NEVER block the workflow. If MCP tools are detected but a specific MCP call fails, fall back to the equivalent `gh` CLI command for that operation.

---

## Phase 0: Validate Prerequisites

**WARNING: This skill does NOT check for existing issues. Running it twice creates duplicates. Warn the user before proceeding if issues may have already been created from this research.**

### Step 1: Run Validation

```bash
${CLAUDE_PLUGIN_ROOT}/skills/research-to-issues/scripts/validate-prerequisites.sh "<research-dir>"
```

If validation fails, evaluate the failure:

- **If `gh` CLI is missing/unauthenticated BUT MCP tools are available**: Proceed — MCP tools will handle GitHub operations
- **If `gh` CLI fails AND no MCP tools available**: Display the error and stop
- **If research directory or git repo validation fails**: Display the error and stop regardless of MCP availability

Hard prerequisites (always required):

- A GitHub-connected git repository
- A valid research directory with expected structure

Soft prerequisites (one of these must be available):

- `gh` CLI installed and authenticated, OR
- GitHub MCP server (`mcp__github__*` tools)

### Step 2: Identify Research Directory

Determine the research directory:

1. If `--research-dir PATH` is specified, use that path
2. Otherwise, search for common locations: `docs/research/`, `research/`
3. If not found, ask the user to specify the path

Verify the directory contains at minimum `RESEARCH-REPORT.md`.

---

## Phase 1: Parse Research Documents

### Step 3: Read and Index Research Files

Read all markdown files in the research directory. Identify which documents contain extractable items:

| Document                                 | What to Extract                                                  |
| ---------------------------------------- | ---------------------------------------------------------------- |
| `RESEARCH-REPORT.md`                     | Research date, project name, key findings with confidence levels |
| `synthesis/strategic-recommendations.md` | MVP features (§4), anti-scope items (§7)                         |
| `synthesis/implementation-roadmap.md`    | Phase definitions, deliverables per phase, success criteria      |
| `analysis/convergence.md`                | Confidence levels for cross-cutting concerns                     |
| `analysis/gaps-and-risks.md`             | Research gaps with severity                                      |

Read each file and extract the structured data. Not all files may exist — adapt to whatever is present.

### Step 4: Extract Features and Deliverables

For each phase found in the implementation roadmap, extract:

- **Phase metadata**: name, duration, team size, risk level, prerequisites, objective
- **Deliverables**: name, description, effort estimate
- **Success criteria**: the definition-of-done checklist

For each feature in strategic recommendations (§4 "Must-Have Features for MVP" or equivalent), extract:

- **Feature name** and kebab-case slug
- **User story** (if present)
- **Acceptance criteria** (if present)
- **Technical complexity**
- **Dependencies**

Cross-reference features with convergence analysis to determine confidence levels.

### Step 5: Extract Anti-Scope and Research Gaps

Unless `--skip-anti-scope` is specified, extract from strategic recommendations (§7 or "What NOT to Build"):

- **Item name**
- **Why deferred** (reasoning)
- **When to revisit** (timeline/conditions)

Unless `--skip-gaps` is specified, extract from gaps-and-risks analysis (§1 "Research Gaps"):

- **Gap name**
- **Severity**
- **What was missed**
- **What needs further research**

### Step 6: Classify Priority

Apply priority mapping based on confidence:

| Confidence                       | Priority Label    | Extra Labels                   |
| -------------------------------- | ----------------- | ------------------------------ |
| High (7-8/8 personas, or "High") | `priority:high`   | —                              |
| Medium-High (5-6/8 personas)     | `priority:medium` | —                              |
| Medium or lower                  | `priority:low`    | `under-review`                 |
| Anti-scope items                 | `priority:low`    | `under-review`, `deferred`     |
| Research gaps                    | `priority:medium` | `under-review`, `research-gap` |

---

## Phase 2: Plan Issue Creation

### Step 7: Build Issue Plan

Construct a complete plan of all issues to create. Structure:

**For each phase** → 1 tracking issue containing:

- Phase title, description, metadata
- Checkbox list of child feature issues

**For each feature/deliverable** → 1 feature issue containing:

- Title, body from template, labels

**For anti-scope items** → 1 issue each (grouped under a "Deferred / Under Review" tracking issue)

**For research gaps** → 1 issue each (grouped under a "Research Gaps" tracking issue)

### Step 8: Compute Labels

Collect all unique labels that will be needed:

- `tracking` — for tracking issues
- `phase:0`, `phase:1`, etc. — per phase
- `feat:<name>` — per feature (kebab-case)
- `priority:high`, `priority:medium`, `priority:low`
- `under-review` — uncertain or deferred items
- `deferred` — anti-scope items
- `research-gap` — gap items

### Step 9: Display Plan (Always)

Before creating anything, display the full plan:

```markdown
# Research → Issues Plan

**Research directory**: {path}
**Project**: {project_name}
**Research date**: {date}

## Labels to Create

{list of labels that don't exist yet}

## Tracking Issues ({count})

### Phase 0: {title}

- Labels: tracking, phase:0, priority:high
- Child issues: {count}

### Phase 1: {title}

- Labels: tracking, phase:1, priority:high
- Child issues: {count}

{... more phases ...}

### Deferred / Under Review

- Labels: tracking, under-review
- Child issues: {count}

### Research Gaps

- Labels: tracking, research-gap
- Child issues: {count}

## Feature Issues ({total count})

| #   | Title                   | Phase | Labels                       | Priority |
| --- | ----------------------- | ----- | ---------------------------- | -------- |
| 1   | Multi-Tenant Data Model | 0-1   | feat:multi-tenant-data-model | high     |
| 2   | Credential Vault        | 1     | feat:credential-vault        | high     |
| ... | ...                     | ...   | ...                          | ...      |

## Anti-Scope Issues ({count})

| #   | Title         | Labels                 |
| --- | ------------- | ---------------------- |
| 1   | Path Analysis | under-review, deferred |
| ... | ...           | ...                    |

## Research Gap Issues ({count})

| #   | Title            | Severity | Labels                     |
| --- | ---------------- | -------- | -------------------------- |
| 1   | Testing Strategy | High     | under-review, research-gap |
| ... | ...              | ...      | ...                        |

**Total issues to create**: {total}
```

### Step 10: Check for Dry Run

If `--dry-run` is present in `$ARGUMENTS`:

Display the plan from Step 9 and **STOP**. Do not create any issues or labels.

Output: "Dry run complete. Remove --dry-run to create these issues."

---

## Phase 3: Create Issues

### Step 11: Create Missing Labels

For each label that does not already exist in the repo:

**If GitHub MCP tools are available (preferred)**, use `mcp__github__create_label` with:

- `owner`: Repository owner (extract from `git remote get-url origin`)
- `repo`: Repository name (extract from `git remote get-url origin`)
- `name`: Label name
- `color`: Hex color (without `#` prefix)
- `description`: Label description

**If MCP is unavailable or fails**, fall back to CLI:

```bash
gh label create "<label-name>" --description "<description>" --color "<hex-color>" --force
```

Label color scheme:

| Label Pattern     | Color                   | Description         |
| ----------------- | ----------------------- | ------------------- |
| `tracking`        | `0075ca` (blue)         | Tracking/epic issue |
| `phase:*`         | `6f42c1` (purple)       | Development phase   |
| `feat:*`          | `1d76db` (medium blue)  | Feature area        |
| `priority:high`   | `d73a4a` (red)          | High priority       |
| `priority:medium` | `fbca04` (yellow)       | Medium priority     |
| `priority:low`    | `0e8a16` (green)        | Low priority        |
| `under-review`    | `e4e669` (light yellow) | Needs decision      |
| `deferred`        | `d4c5f9` (light purple) | Explicitly deferred |
| `research-gap`    | `f9d0c4` (light orange) | Research gap        |

Use `--force` to avoid errors if a label already exists.

### Step 12: Create Feature Issues First

Create all feature issues before tracking issues (tracking issues need the child issue numbers for checkbox links).

For each feature issue, use the template from `${CLAUDE_PLUGIN_ROOT}/skills/research-to-issues/templates/feature-issue.md` to compose the body.

**If GitHub MCP tools are available (preferred)**, use `mcp__github__create_issue` with:

- `owner`: Repository owner
- `repo`: Repository name
- `title`: Issue title
- `body`: Composed body from template
- `labels`: Array of label name strings

The MCP tool returns the issue number in structured response data.

**If MCP is unavailable or fails**, fall back to CLI:

```bash
gh issue create \
  --title "<title>" \
  --body "$(cat <<'EOF'
<composed-body>
EOF
)" \
  --label "<label1>,<label2>,..."
```

Capture the issue number from each created issue. Map feature names to issue numbers.

### Step 13: Create Anti-Scope and Gap Issues

Same process as Step 12, using the anti-scope and research gap template variants from `${CLAUDE_PLUGIN_ROOT}/skills/research-to-issues/templates/feature-issue.md`.

### Step 14: Create Tracking Issues

For each phase tracking issue, compose the body using the template from `${CLAUDE_PLUGIN_ROOT}/skills/research-to-issues/templates/tracking-issue.md`. Populate the checkbox list with links to child issue numbers created in Steps 12-13 (e.g., `- [ ] #42 Multi-Tenant Data Model`).

Create the tracking issue:

**If GitHub MCP tools are available (preferred)**, use `mcp__github__create_issue` with:

- `owner`: Repository owner
- `repo`: Repository name
- `title`: `"Phase {N}: {phase_title}"`
- `body`: Composed body from template with child issue checkbox links
- `labels`: `["tracking", "phase:{N}", "priority:high"]`

**If MCP is unavailable or fails**, fall back to CLI:

```bash
gh issue create \
  --title "Phase {N}: {phase_title}" \
  --body "$(cat <<'EOF'
<composed-body>
EOF
)" \
  --label "tracking,phase:{N},priority:high"
```

Also create tracking issues for "Deferred / Under Review" and "Research Gaps" groups if those issues exist.

---

## Phase 4: Summary

### Step 15: Display Results

After all issues are created, display a summary:

```markdown
# Issues Created Successfully

**Repository**: {owner/repo}
**Total issues created**: {count}
**Labels created**: {count}

## Tracking Issues

| Phase | Title         | Issue | Child Issues |
| ----- | ------------- | ----- | ------------ |
| 0     | Foundation    | #XX   | {count}      |
| 1     | Core Platform | #XX   | {count}      |
| ...   | ...           | ...   | ...          |

## All Issues

| #   | Issue | Title                   | Labels                                               |
| --- | ----- | ----------------------- | ---------------------------------------------------- |
| 1   | #XX   | Multi-Tenant Data Model | feat:multi-tenant-data-model, phase:1, priority:high |
| ... | ...   | ...                     | ...                                                  |

## Next Steps

1. Review tracking issues for completeness
2. Assign issues to milestones if desired
3. Prioritize and assign to team members
4. Use `under-review` filter to find items needing decision
```

---

## Important Notes

- **Always show the plan first** — never create issues without displaying the plan (Step 9)
- **Dry-run is safe** — encourage using `--dry-run` on first invocation
- **Labels are created with --force** — safe to run multiple times
- **Issue order matters** — create child issues before tracking issues (need issue numbers)
- **MCP-first** — GitHub operations (issues, labels) prefer MCP tools (`mcp__github__*`) when available, with automatic `gh` CLI fallback
- **Validation adaptation** — if `gh` CLI is missing but MCP tools are available, the workflow can still proceed
- **No implementation** — this skill creates issues only. It does not write code or create plans.
- **Templates are guides** — adapt template fields to whatever is actually present in the research. Not all research output will have every field.

---

## Workflow Diagram

```
┌──────────────────────────────────────────┐
│ Phase 0: Validate Prerequisites          │
│ - gh CLI, git repo, research dir         │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│ Phase 1: Parse Research Documents        │
│ - Read all synthesis/analysis files      │
│ - Extract features, anti-scope, gaps     │
│ - Classify priority from confidence      │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│ Phase 2: Plan Issue Creation             │
│ - Build issue hierarchy                  │
│ - Compute labels                         │
│ - Display plan (ALWAYS)                  │
│ - STOP if --dry-run                      │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│ Phase 3: Create Issues                   │
│ - Create missing labels (gh label create)│
│ - Create feature issues first            │
│ - Create tracking issues with links      │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│ Phase 4: Summary                         │
│ - Display all created issues             │
│ - Show next steps                        │
└──────────────────────────────────────────┘
```

## Additional Resources

### Templates

Issue body templates for consistent formatting:

- **`templates/tracking-issue.md`** — Tracking issue body structure and field descriptions
- **`templates/feature-issue.md`** — Feature, anti-scope, and research gap issue templates with label assignment rules

### Scripts

- **`scripts/validate-prerequisites.sh`** — Validate gh CLI, git repo, and research directory
