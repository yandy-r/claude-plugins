---
name: git-workflow
description: Git commit and documentation workflow manager. Analyzes changes, determines commit strategy (direct vs agents), writes conventional commit messages, coordinates documentation updates, and creates pull requests. Use when completing features, making commits, pushing changes, creating PRs, or when the user says "It's time to push commits."
---

# Git Workflow Manager

Intelligent git commit and documentation workflow orchestration. Analyzes changes, writes conventional commit messages, and coordinates documentation updates through parallel agent deployment when needed.

## Current Task

**Managing git workflow for**: `$ARGUMENTS`

Parse arguments:

- **--dry-run**: Show analysis and plan without making changes
- **--no-docs**: Skip documentation updates (commits only)
- **--push**: Automatically push after committing
- **--pr**: Create pull request after pushing (implies --push)
- **--draft**: Create PR as draft (requires --pr)

If no arguments needed, proceed with analysis.

---

## Tool Preference Strategy

Before beginning Phase 0, determine which tools are available for GitHub operations.

### Step 0: Detect GitHub MCP Server

Check if GitHub MCP tools are available in your current tool list by looking for tools matching the pattern `mcp__github__*` (e.g., `mcp__github__create_pull_request`, `mcp__github__get_pull_request`).

**Set your tool preference for this session:**

| MCP Tools Available?                  | GitHub Operations Strategy                                              |
| ------------------------------------- | ----------------------------------------------------------------------- |
| Yes (`mcp__github__*` tools found)    | **Use MCP tools** for all GitHub operations (PR creation, PR viewing)   |
| No (no `mcp__github__*` tools found)  | **Use `gh` CLI** via Bash for all GitHub operations (current behavior)  |

**What stays as CLI regardless:**

- All `git` operations (status, diff, add, commit, push) — always use Bash `git` commands
- All bash scripts (analyze-changes.sh, create-pr.sh, validate-commit.sh) — always run via Bash
- File reading and analysis — always use Read/Grep/Glob tools

**Important**: Lack of MCP tools must NEVER block the workflow. If MCP tools are detected but a specific MCP call fails, fall back to the equivalent `gh` CLI command for that operation.

---

## Conventional Commits Requirement

**ALL commits produced by this workflow MUST use the Conventional Commits format.** This is a hard requirement, not a suggestion.

**Format**: `<type>(<scope>): <subject>`

**Valid types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`, `revert`

**Rules** (enforced by `validate-commit.sh`):

- Subject line: imperative mood, lowercase start, no trailing period, ≤50 chars (≤72 max)
- Scope: optional, lowercase alphanumeric with hyphens
- Breaking changes: use `!` suffix and/or `BREAKING CHANGE:` footer
- Body: optional, wrap at 72 chars

**This applies to:**

- Direct commits (Phase 3a) — validated before committing
- Agent commits (Phase 3b) — validated after agents complete, amended if non-conformant
- PR titles (Phase 5) — must follow `<type>(<scope>): <description>` format

Load the full reference before crafting any commit message:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/templates/commit-types.md
```

---

## Phase 0: Analyze Changes

### Step 1: Check Git Status

Run git commands to analyze current state:

```bash
git status --porcelain
git diff --stat
git diff --cached --stat
```

Determine:

- Staged changes vs unstaged changes
- Total files modified
- Types of files changed (source, test, docs, config)
- Lines added/removed

### Step 2: Automated Analysis

Run the analysis script for structured output:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/scripts/analyze-changes.sh
```

This provides:

- Change categorization (source, test, docs, config)
- File count and change metrics
- Recommended strategy (direct vs agents)
- Scope suggestions for commit messages

### Step 3: Review Changed Files

For each modified file, understand:

- What feature or fix is this related to?
- Are changes part of single feature or multiple?
- Do changes warrant documentation updates?

Group related changes together for commit organization.

---

## Phase 1: Determine Strategy

### Step 4: Apply Decision Tree

Use this decision tree to determine approach:

```
Is this a small change?
├─ YES (1-3 files, single feature, minor changes)
│  └─> Use Direct Commit (Phase 3a)
│     - Write commit message yourself
│     - Stage and commit in one operation
│     - Skip agent deployment
│
└─ NO (4+ files, multiple features, substantial changes)
   └─> Use Agent Deployment (Phase 3b)
      - Deploy parallel docs-git-committer agents
      - One agent per feature/significant change
      - Each agent handles docs + commit for its scope
```

**Small Change Criteria:**

- Single feature implementation
- Fewer than 4 files changed
- Clear, focused scope
- Minimal documentation needs
- Bug fix or minor improvement

**Large Change Criteria:**

- Multiple features or significant changes
- 4+ files with substantial modifications
- Cross-cutting changes affecting multiple areas
- New features requiring documentation
- Breaking changes or API modifications

### Step 5: Check for Dry Run Mode

If `--dry-run` is present in `$ARGUMENTS`:

Display the analysis and proposed strategy:

```markdown
# Dry Run: Git Workflow Analysis

## Changes Detected

**Files Changed**: [count]
**Insertions**: [count]
**Deletions**: [count]

### By Type

- Source files: [count]
- Test files: [count]
- Documentation: [count]
- Configuration: [count]

## Recommended Strategy

**Approach**: [Direct Commit / Agent Deployment]

**Reasoning**: [why this strategy was chosen]

## Proposed Actions

[For Direct Commit]

- Commit message: [proposed message]
- Documentation: [yes/no] - [reasoning]

[For Agent Deployment]

- Agent 1: [feature/scope] - docs + commit
- Agent 2: [feature/scope] - docs + commit
- Total agents: [count]

## Next Steps

Remove --dry-run flag to execute the workflow.
```

**STOP HERE** - do not make changes.

---

## Phase 2: Documentation Decision

### Step 6: Load Documentation Decision Tree

Read the documentation decision template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/templates/documentation-decision.md
```

This provides guidance on:

- When feature documentation is needed
- When CLAUDE.md updates are appropriate (rarely)
- When architecture/API docs should be updated
- What NOT to document

### Step 7: Determine Documentation Needs

For each changed file or feature, decide:

**Feature Documentation** (docs/features/):

- New user-facing features
- Significant API changes
- Complex data flows
- Breaking changes
- NOT internal refactoring
- NOT bug fixes (unless behavior changes)
- NOT style/formatting changes
- NOT minor performance improvements

**CLAUDE.md Updates** (RARELY NEEDED):

- New critical patterns specific to a directory
- Security boundary changes within a directory
- Major architectural decisions affecting a directory
- NOT root CLAUDE.md (NEVER update root)
- NOT feature-specific details (put in feature docs)
- NOT most changes (don't need CLAUDE.md updates)

**Skip Documentation If**:

- `--no-docs` flag is present
- Changes are purely internal refactoring
- Only test files were modified
- Only documentation files were modified
- Changes are trivial or obvious

---

## Phase 3a: Direct Commit (Small Changes)

### Step 8: Load Commit Message Template

Read the conventional commits reference:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/templates/commit-types.md
```

### Step 9: Craft Commit Message

Write a conventional commit message:

**Format**: `<type>(<scope>): <subject>`

**Guidelines**:

- Type: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
- Scope: Optional, indicates area of change
- Subject: Imperative mood, no period, max 50 chars
- Body: Optional, wrap at 72 chars, explain what and why
- Footer: Optional, breaking changes or issue references

**Example**:

```
feat(auth): implement JWT-based authentication

Add login endpoint with JWT token generation and validation
middleware for protected routes.

BREAKING CHANGE: Session-based auth is no longer supported.
Existing sessions will be invalidated.
```

### Step 10: Validate Commit Message

Run validation script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/scripts/validate-commit.sh "<commit-message>"
```

If validation fails, revise the message and re-validate.

### Step 11: Stage and Commit

Execute the commit:

```bash
git add [files...]
git commit -m "$(cat <<'EOF'
<commit-message>
EOF
)"
```

**CRITICAL**: Stage and commit in single operation to avoid race conditions.

### Step 12: Optional Push

If `--push` flag is present:

```bash
git push
```

Skip to Phase 4 (Summary).

---

## Phase 3b: Agent Deployment (Large Changes)

### Step 13: Identify Feature Scopes

Break changes into logical feature scopes:

- Group files by feature or area
- Each scope should be independently committable
- Identify relationships between scopes

Example scopes:

- "User authentication system"
- "Payment integration"
- "API documentation updates"
- "Test infrastructure improvements"

### Step 14: Load Agent Prompt Template

Read the docs-git-committer prompt template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/templates/agent-prompts.md
```

### Step 15: Deploy Agents in Parallel

**CRITICAL**: Deploy all agents in a **SINGLE message** with **MULTIPLE Task tool calls**.

For each feature scope, deploy a `docs-git-committer` agent:

| Field         | Value                                                             |
| ------------- | ----------------------------------------------------------------- |
| subagent_type | `docs-git-committer`                                              |
| description   | "Commit [feature-name] with docs"                                 |
| prompt        | Complete instructions including scope, files, documentation needs |

**Agent Instructions Template**:

```
You are handling the git commit and documentation for: [FEATURE SCOPE]

## Changed Files in Your Scope

[List of files related to this feature]

## Context

[Brief description of what changed and why]

## Your Tasks

1. Review the changes in your assigned files
2. Determine if documentation updates are needed (see templates)
3. Update or create documentation if appropriate:
   - Feature docs: docs/features/[name].doc.md
   - CLAUDE.md: Only if critically needed in specific directory
   - Architecture docs: docs/architecture/ if system-wide changes
4. Stage all files (source + docs) and commit with conventional message
5. Return summary of what you committed

## Important

- Use conventional commit format
- Combine source + docs in ONE commit
- Use git add + commit in single command
- Do NOT push (main skill handles that)
- Focus ONLY on your assigned scope
```

### Step 16: Track Agent Progress

Create todos for each agent:

```
- agent-1: "[Feature 1] - docs-git-committer - status: in_progress"
- agent-2: "[Feature 2] - docs-git-committer - status: in_progress"
```

### Step 17: Wait for Agents to Complete

Monitor agent execution:

- All agents run in parallel
- Each handles its own scope
- Each creates its own commit
- Wait for all to finish before proceeding

### Step 18: Review and Validate Agent Results

After agents complete:

- Update todos to "completed"
- **Validate each agent's commit message** against conventional commit format:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/scripts/validate-commit.sh "$(git log -1 --format=%s <commit-hash>)"
```

- If any commit message fails validation, amend it:

```bash
git rebase -x '${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/scripts/validate-commit.sh "$(git log -1 --format=%s HEAD)" || echo "NEEDS FIX"' <merge-base>..HEAD
```

  Or for a single commit, use `git commit --amend -m "<corrected-message>"` to fix it.

- Check for conflicts or issues
- Verify documentation quality

**CRITICAL**: Do not proceed to Phase 4 until all agent commits pass conventional commit validation.

---

## Phase 4: Summary and Push

### Step 19: Consolidate Results

Gather information about what was committed:

For direct commits:

- Commit hash and message
- Files changed
- Documentation updates (if any)

For agent deployment:

- List of commits made
- Agents deployed and their results
- Documentation files created/updated
- Any issues encountered

### Step 20: Display Summary

Provide comprehensive completion summary:

```markdown
# Git Workflow Complete

## Commits Made

### Commit 1: [hash]

**Message**: [subject line]
**Files**: [count] files changed
**Changes**: +[insertions] -[deletions]

[If multiple commits, repeat above]

## Documentation Updates

[If docs were updated]

- Created: docs/features/[name].doc.md
- Updated: [other docs]

[If no docs]

- No documentation updates needed (minor changes)

## Summary

- **Total Commits**: [count]
- **Files Changed**: [count]
- **Documentation**: [yes/no]
- **Pushed**: [yes/no]

## Next Steps

[If not pushed]

1. Review the commits: `git log --oneline -[count]`
2. View changes: `git show HEAD`
3. Push when ready: `git push`

[If pushed]
Changes have been pushed to remote
```

### Step 21: Optional Push

If `--push` flag is present and not already pushed:

```bash
git push
```

Display push result.

---

## Phase 5: Pull Request Creation (Optional)

### Step 22: Check for PR Flag

If `--pr` flag is present in `$ARGUMENTS`:

**Prerequisites**:

- Branch must be pushed to remote
- GitHub MCP server OR GitHub CLI (`gh`) must be available:
  - If MCP tools available (`mcp__github__*`): no additional prerequisites
  - If using CLI fallback: `gh` must be installed and authenticated
- If `--pr` but not pushed, automatically push first

### Step 23: Load PR Template

Read the PR template:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/templates/pr-template.md
```

This provides:

- PR title guidelines (based on commits)
- Description structure
- Review checklist
- Testing guidance
- When to use draft PRs

### Step 24: Gather PR Context

Run the PR creation script to gather information:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/scripts/create-pr.sh --analyze
```

This provides:

- Current branch name
- Base branch (typically main/master)
- Commit history since divergence
- Changed files summary
- Documentation changes
- Suggested PR title and scope

### Step 25: Generate PR Title

PR titles **MUST** follow the conventional commit format: `<type>(<scope>): <description>`

Based on commits made, create a PR title:

**Single commit**: Use the commit subject line directly (already validated)

**Multiple related commits**: Create a descriptive title that follows the same conventional format

Validate the PR title with the same rules as commit messages:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/git-workflow/scripts/validate-commit.sh "<pr-title>"
```

If validation fails, revise the title until it passes.

**Examples**:

```
feat(auth): implement JWT authentication system
fix(api): resolve multiple payment processing issues
docs: update API documentation and examples
refactor(database): migrate to new query builder pattern
```

### Step 26: Generate PR Description

Create comprehensive PR description following this structure:

```markdown
## Summary

[2-4 sentence overview of what this PR does and why]

## Changes

- [Key change 1 with context]
- [Key change 2 with context]
- [Key change 3 with context]

## Documentation

[If docs were created/updated]

- Feature docs: docs/features/[name].doc.md
- API docs: docs/api/[endpoint].md
- Architecture docs: docs/architecture/[topic].md

[If no docs]

- No documentation changes needed

## Testing

[For each feature/change]

### [Feature Name]

**How to test:**

1. Step one
2. Step two
3. Expected result

**Edge cases:**

- Edge case 1 to verify
- Edge case 2 to verify

## Related Issues

[If applicable]
Closes #123
Fixes #456
Related to #789

## Breaking Changes

[If any]
BREAKING CHANGE: [Description]

**Migration steps:**

1. Step one
2. Step two

[If none]

- No breaking changes

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests passing
- [ ] No new warnings
```

### Step 27: Determine PR Type

Decide between regular PR and draft PR:

**Use draft PR** (`--draft` flag) when:

- Work is not fully complete
- Seeking early feedback
- Tests are not passing yet
- Documentation is incomplete
- Breaking changes need discussion

**Use regular PR** when:

- Work is complete and tested
- Ready for immediate review
- All checks passing
- Documentation is complete

### Step 28: Create Pull Request

#### If GitHub MCP tools are available (preferred)

Use `mcp__github__create_pull_request` with:

- `owner`: Repository owner (extract from `git remote get-url origin`)
- `repo`: Repository name (extract from `git remote get-url origin`)
- `title`: PR title from Step 25
- `body`: PR description from Step 26
- `head`: Current branch name
- `base`: Default branch (main/master)
- `draft`: `true` if `--draft` flag is set, `false` otherwise

The MCP tool returns the PR number and URL in structured data.

#### If MCP is unavailable or fails — fall back to GitHub CLI

**For regular PR**:

```bash
gh pr create \
  --title "[PR Title]" \
  --body "$(cat <<'EOF'
[PR Description from Step 26]
EOF
)" \
  --web
```

**For draft PR**:

```bash
gh pr create \
  --title "[PR Title]" \
  --body "$(cat <<'EOF'
[PR Description from Step 26]
EOF
)" \
  --draft \
  --web
```

The `--web` flag opens the PR in browser for final review.

### Step 29: Handle PR Creation Results

After PR creation:

**Success**:

- Capture PR number and URL
- Display PR link to user
- Note if draft or ready for review

**Failure scenarios**:

1. **No upstream branch**: Offer to push with `-u origin [branch]`
2. **Branch not pushed**: Automatically push and retry
3. **gh CLI not installed**: If MCP tools are available, use those instead; otherwise provide installation instructions
4. **Not authenticated**: If MCP tools are available, use those instead; otherwise guide to run `gh auth login`
5. **PR already exists**: Offer to update or view existing PR
6. **MCP tool failed**: Fall back to `gh` CLI and retry the operation

### Step 30: Post-PR Summary

Display comprehensive PR creation summary:

```markdown
# Pull Request Created

## PR Details

**Number**: #[number]
**Title**: [PR title]
**URL**: [GitHub URL]
**Status**: [Draft/Ready for Review]
**Base**: [base-branch] <- [current-branch]

## Commits Included

- [hash]: [commit message]
- [hash]: [commit message]

## Files Changed

**Total**: [count] files

- Source: [count]
- Tests: [count]
- Docs: [count]

## Next Steps

1. PR is ready for review
2. View PR: [URL]
3. Request reviewers in GitHub
4. Monitor CI/CD checks
5. Address review feedback

[If draft]

## Draft PR Status

This PR is marked as draft. To mark ready for review:

    gh pr ready [PR number]

Complete these before marking ready:

- [ ] All tests passing
- [ ] Documentation complete
- [ ] Self-review done
```

### Step 31: Optional PR Template Check

If repository has `.github/PULL_REQUEST_TEMPLATE.md`:

- Read the template
- Ensure generated description follows template structure
- Fill in any template-specific sections

---

## Quality Standards

### Commit Message Checklist

- [ ] Uses conventional commit format
- [ ] Type is appropriate (feat, fix, docs, etc.)
- [ ] Subject line is imperative mood
- [ ] Subject line is <=50 characters
- [ ] No period at end of subject
- [ ] Body explains what and why (if needed)
- [ ] Breaking changes noted in footer (if applicable)

### Documentation Checklist

- [ ] Feature docs created for new features
- [ ] CLAUDE.md updated ONLY if critical and directory-specific
- [ ] Architecture docs updated for system-wide changes
- [ ] API docs updated for public API changes
- [ ] Documentation is concise and actionable
- [ ] No documentation for trivial changes

### Agent Deployment Checklist

- [ ] All agents deployed in single message
- [ ] Each agent has clear, non-overlapping scope
- [ ] Agent instructions include file list
- [ ] Agents use conventional commits
- [ ] Each agent commits separately
- [ ] No agent pushes (main skill handles that)

### Pull Request Checklist

- [ ] PR title follows conventional commit format
- [ ] Description includes summary of changes
- [ ] Testing instructions are clear and complete
- [ ] Documentation changes are noted
- [ ] Breaking changes are clearly marked
- [ ] Related issues are referenced
- [ ] PR type is appropriate (draft vs ready)
- [ ] All commits follow conventional format

### Overall Quality Checklist

- [ ] All changes committed (nothing left unstaged)
- [ ] Commits are atomic and focused
- [ ] Documentation appropriate to change scope
- [ ] Push successful (if requested)
- [ ] Summary provided to user

---

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────┐
│ Phase 0: Analyze Changes                                │
│ - git status, git diff                                  │
│ - Categorize files                                      │
│ - Run analysis script                                   │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ Phase 1: Determine Strategy                             │
│ - Apply decision tree                                   │
│ - Small (1-3 files) vs Large (4+ files)                 │
└─────────────────┬───────────────────────────────────────┘
                  │
        ┌─────────┴────────────┐
        │                      │
        ▼                      ▼
┌──────────────────┐  ┌────────────────────────┐
│ Phase 3a:        │  │ Phase 3b:              │
│ Direct Commit    │  │ Agent Deployment       │
│                  │  │                        │
│ - Write message  │  │ - Deploy parallel      │
│ - Stage files    │  │   docs-git-committer   │
│ - Commit         │  │   agents               │
└────────┬─────────┘  │ - Each commits scope   │
         │            └──────────┬─────────────┘
         │                       │
         └─────────┬─────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│ Phase 4: Summary and Push                               │
│ - Consolidate results                                   │
│ - Display summary                                       │
│ - Optional push (--push flag)                           │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ Phase 5: Pull Request (Optional, --pr flag)             │
│ - Gather PR context                                     │
│ - Generate title and description                        │
│ - Create PR (draft or ready)                            │
│ - Display PR URL and next steps                         │
└─────────────────────────────────────────────────────────┘
```

---

## Important Notes

- **Small changes**: Handle directly for speed and simplicity
- **Large changes**: Use agents for parallel documentation + commits
- **Conventional commits**: Always use proper format for consistency
- **Documentation**: Only update when substantial changes warrant it
- **CLAUDE.md**: Rarely needed, only for critical directory-specific patterns
- **Atomic commits**: Stage and commit in single operation
- **No premature push**: Only push when explicitly requested or with `--push` flag
- **Pull requests**: Use `--pr` flag to automatically create PR after pushing
- **Draft PRs**: Use `--draft` with `--pr` for work-in-progress or early feedback
- **MCP-first**: GitHub operations prefer MCP tools (`mcp__github__*`) when available, with automatic `gh` CLI fallback
- **GitHub tools required**: PR creation requires GitHub MCP server or `gh` CLI tool installed and authenticated

---

## Examples

### Example 1: Small Change (Direct Commit)

**Scenario**: Fixed a bug in user validation

```bash
# Analysis shows: 1 file, 10 lines changed
# Strategy: Direct commit

# Crafted message:
fix(auth): prevent null email validation bypass

# Committed:
git add src/services/auth.ts
git commit -m "fix(auth): prevent null email validation bypass"
```

### Example 2: Large Change (Agent Deployment)

**Scenario**: Implemented user authentication system

```bash
# Analysis shows: 8 files, 450 lines changed
# Strategy: Agent deployment

# Deployed 3 agents:
# 1. docs-git-committer: Auth backend (models, services, middleware)
# 2. docs-git-committer: Auth frontend (components, hooks)
# 3. docs-git-committer: Auth tests (unit + integration)

# Result: 3 commits, feature docs created
```

### Example 3: Documentation-Only Change

**Scenario**: Updated API documentation

```bash
# Analysis shows: 2 doc files changed
# Strategy: Direct commit (no feature changes)

# Message:
docs(api): update authentication endpoint examples

# No documentation agents needed (already docs)
```

### Example 4: Complete Workflow with PR

**Scenario**: Implemented new payment feature, commit and create PR

```bash
# User runs with PR flag
/git-workflow --pr

# Workflow executes:
# 1. Analyzes changes (12 files)
# 2. Deploys agents (payment backend, frontend, tests)
# 3. Each agent commits with docs
# 4. Pushes to remote
# 5. Creates PR automatically

# Result:
# - 3 commits made
# - Feature docs created
# - PR #123 created and ready for review
# - PR URL displayed for user
```

### Example 5: Draft PR for Work-in-Progress

**Scenario**: New feature not fully complete, seeking early feedback

```bash
/git-workflow --pr --draft

# Workflow executes:
# 1. Commits current work
# 2. Pushes to remote
# 3. Creates draft PR
# 4. Marks as "not ready for review"

# Result:
# - Draft PR created
# - Reviewers can see progress
# - Can be marked ready later with: gh pr ready [number]
```

### Example 6: Commit Only (No PR)

**Scenario**: Feature complete but not ready to create PR yet

```bash
/git-workflow --push

# Workflow executes:
# 1. Commits and documents
# 2. Pushes to remote
# 3. Stops (no PR created)

# User can create PR later:
# /git-workflow --pr  (will use existing commits)
```

---

## Troubleshooting

### Issue: Validation script fails

**Solution**: Review commit message format, check type is valid, ensure subject <=50 chars

### Issue: Too many agents suggested

**Solution**: Group related changes, combine scopes, or use sequential commits

### Issue: Unclear what changed

**Solution**: Use `git diff` to review changes, `git log` for context, ask user for clarification

### Issue: Conflicts between agent commits

**Solution**: This shouldn't happen with proper scope isolation, but if it does, manually resolve and recommit

### Issue: Documentation decision unclear

**Solution**: When in doubt, skip documentation for minor changes, create it for substantial features

### Issue: MCP tools detected but GitHub operation fails via MCP

**Solution**: The workflow automatically falls back to `gh` CLI. If both fail, check:

- Repository permissions
- Authentication status (`gh auth status`)
- Branch is pushed to remote
- MCP server configuration is correct

### Issue: PR creation fails - gh CLI not installed

**Solution**: If GitHub MCP tools are available, the workflow will use those instead. Otherwise, install GitHub CLI:

```bash
# macOS
brew install gh

# Linux
# See: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
```

### Issue: PR creation fails - not authenticated

**Solution**: Authenticate with GitHub:

```bash
gh auth login
# Follow prompts to authenticate
```

### Issue: PR creation fails - no upstream branch

**Solution**: Push with upstream:

```bash
git push -u origin [branch-name]
# Then retry with --pr flag
```

### Issue: PR already exists for branch

**Solution**: View existing PR or update it:

```bash
# View PR
gh pr view

# Or create new branch for separate PR
git checkout -b [new-branch-name]
```

### Issue: Draft PR but want to mark ready

**Solution**: Mark PR as ready for review:

```bash
gh pr ready [PR-number]
```
