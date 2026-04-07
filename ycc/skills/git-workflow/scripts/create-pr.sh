#!/usr/bin/env bash
set -euo pipefail

# create-pr.sh
# Analyzes git repository and helps create pull requests
# Usage: create-pr.sh [--analyze | --create [--draft]]

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Parse arguments
MODE="analyze"
DRAFT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --analyze)
            MODE="analyze"
            shift
            ;;
        --create)
            MODE="create"
            shift
            ;;
        --draft)
            DRAFT=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            echo "Usage: $0 [--analyze | --create [--draft]]" >&2
            exit 1
            ;;
    esac
done

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}" >&2
    exit 1
fi

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}" >&2
    echo "" >&2
    echo "Install with:" >&2
    echo "  macOS:   brew install gh" >&2
    echo "  Linux:   See https://github.com/cli/cli/blob/trunk/docs/install_linux.md" >&2
    exit 1
fi

# Check if authenticated with gh
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}" >&2
    echo "" >&2
    echo "Authenticate with:" >&2
    echo "  gh auth login" >&2
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" = "HEAD" ]; then
    echo -e "${RED}Error: Not on a branch (detached HEAD)${NC}" >&2
    exit 1
fi

# Get default branch (usually main or master)
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || echo "main")

# Check if branch exists on remote
if ! git ls-remote --exit-code --heads origin "$CURRENT_BRANCH" &> /dev/null; then
    echo -e "${YELLOW}⚠ Branch not pushed to remote${NC}" >&2
    echo "Push with: git push -u origin $CURRENT_BRANCH" >&2
    exit 1
fi

echo -e "${BLUE}=== Pull Request Analysis ===${NC}\n"

# Display branch information
echo -e "${GREEN}Branch Information:${NC}"
echo "  Current branch:  $CURRENT_BRANCH"
echo "  Base branch:     $DEFAULT_BRANCH"
echo ""

# Get commits since divergence from base
MERGE_BASE=$(git merge-base HEAD "origin/$DEFAULT_BRANCH" 2>/dev/null || echo "")

if [ -z "$MERGE_BASE" ]; then
    echo -e "${RED}Error: Cannot find common ancestor with $DEFAULT_BRANCH${NC}" >&2
    exit 1
fi

# Count commits
COMMIT_COUNT=$(git rev-list --count "$MERGE_BASE..HEAD")

echo -e "${GREEN}Commits in this Branch:${NC}"
echo "  Total commits: $COMMIT_COUNT"
echo ""

if [ "$COMMIT_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}No new commits on this branch${NC}"
    echo "Nothing to create PR for."
    exit 0
fi

# Display commit history
echo -e "${GREEN}Commit History:${NC}"
git log --oneline --no-merges "$MERGE_BASE..HEAD" | while IFS= read -r line; do
    echo "  - $line"
done
echo ""

# Analyze changed files
CHANGED_FILES=$(git diff --name-only "$MERGE_BASE..HEAD" | wc -l | tr -d ' ')
SOURCE_FILES=$(git diff --name-only "$MERGE_BASE..HEAD" | grep -vE '(test|spec|__tests__|\.test\.|\.spec\.|\.md$|^docs/)' | wc -l | tr -d ' ')
TEST_FILES=$(git diff --name-only "$MERGE_BASE..HEAD" | grep -E '(test|spec|__tests__|\.test\.|\.spec\.)' | wc -l | tr -d ' ')
DOC_FILES=$(git diff --name-only "$MERGE_BASE..HEAD" | grep -E '(\.md$|^docs/)' | wc -l | tr -d ' ')

echo -e "${GREEN}Files Changed:${NC}"
echo "  Total files:   $CHANGED_FILES"
echo "  Source files:  $SOURCE_FILES"
echo "  Test files:    $TEST_FILES"
echo "  Doc files:     $DOC_FILES"
echo ""

# Get change statistics
STATS=$(git diff --stat "$MERGE_BASE..HEAD" | tail -n1)
echo -e "${GREEN}Change Statistics:${NC}"
echo "  $STATS"
echo ""

# Suggest PR title based on commits
echo -e "${GREEN}Suggested PR Title:${NC}"

if [ "$COMMIT_COUNT" -eq 1 ]; then
    # Single commit - use commit message
    SUGGESTED_TITLE=$(git log --format=%s -n1 HEAD)
    echo "  $SUGGESTED_TITLE"
    echo "  (from single commit)"
else
    # Multiple commits - analyze for common theme
    # Try to extract type and scope from first commit
    FIRST_COMMIT=$(git log --format=%s -n1 HEAD)
    
    if echo "$FIRST_COMMIT" | grep -qE '^[a-z]+(\([a-z0-9-]+\))?:'; then
        TYPE=$(echo "$FIRST_COMMIT" | grep -oE '^[a-z]+')
        SCOPE=$(echo "$FIRST_COMMIT" | grep -oE '\([a-z0-9-]+\)' | tr -d '()' || echo "")
        
        if [ -n "$SCOPE" ]; then
            SUGGESTED_TITLE="${TYPE}(${SCOPE}): [describe overall changes]"
            echo "  $SUGGESTED_TITLE"
        else
            SUGGESTED_TITLE="${TYPE}: [describe overall changes]"
            echo "  $SUGGESTED_TITLE"
        fi
        echo "  (based on commit pattern)"
    else
        # No conventional commit pattern detected
        SUGGESTED_TITLE=""
        echo "  [type](scope): [describe changes]"
        echo "  (no clear pattern detected)"
    fi
fi
echo ""

# Check for documentation
echo -e "${GREEN}Documentation Status:${NC}"
if [ "$DOC_FILES" -gt 0 ]; then
    echo "  ✓ Documentation changes detected ($DOC_FILES files)"
    git diff --name-only "$MERGE_BASE..HEAD" | grep -E '(\.md$|^docs/)' | while IFS= read -r file; do
        echo "    - $file"
    done
else
    echo "  ⚠ No documentation files changed"
    if [ "$SOURCE_FILES" -ge 3 ]; then
        echo "    Consider if documentation is needed for these changes"
    fi
fi
echo ""

# Check for breaking changes in commits
echo -e "${GREEN}Breaking Changes:${NC}"
if git log --format=%B "$MERGE_BASE..HEAD" | grep -qE 'BREAKING CHANGE:|^[a-z]+(\([a-z0-9-]+\))?!:'; then
    echo "  ⚠ Breaking changes detected in commits"
    git log --format=%s "$MERGE_BASE..HEAD" | grep -E '^[a-z]+(\([a-z0-9-]+\))?!:' | while IFS= read -r line; do
        echo "    - $line"
    done
    git log --format=%B "$MERGE_BASE..HEAD" | grep -A2 'BREAKING CHANGE:' | while IFS= read -r line; do
        [ -n "$line" ] && echo "    $line"
    done
else
    echo "  ✓ No breaking changes detected"
fi
echo ""

# Recommend PR type
echo -e "${YELLOW}Recommended PR Type:${NC}"
if [ "$TEST_FILES" -eq 0 ] || [ "$SOURCE_FILES" -ge 10 ]; then
    echo "  Draft PR (use --draft flag)"
    echo "  Reasoning:"
    [ "$TEST_FILES" -eq 0 ] && echo "    - No test files changed (tests may be incomplete)"
    [ "$SOURCE_FILES" -ge 10 ] && echo "    - Large change ($SOURCE_FILES source files)"
else
    echo "  Regular PR (ready for review)"
    echo "  Reasoning:"
    echo "    - Tests included ($TEST_FILES test files)"
    echo "    - Reasonable size ($SOURCE_FILES source files)"
fi
echo ""

# If analyze mode, stop here
if [ "$MODE" = "analyze" ]; then
    echo -e "${BLUE}=== Analysis Complete ===${NC}\n"
    echo "To create PR:"
    echo "  Regular: gh pr create --web"
    echo "  Draft:   gh pr create --draft --web"
    exit 0
fi

# Create PR mode
echo -e "${BLUE}=== Creating Pull Request ===${NC}\n"

# Check if PR already exists
EXISTING_PR=$(gh pr list --head "$CURRENT_BRANCH" --json number --jq '.[0].number' 2>/dev/null || echo "")

if [ -n "$EXISTING_PR" ]; then
    echo -e "${YELLOW}⚠ PR already exists for this branch: #$EXISTING_PR${NC}"
    echo ""
    echo "View PR: gh pr view $EXISTING_PR"
    echo "Edit PR: gh pr edit $EXISTING_PR"
    exit 1
fi

# Generate PR description template
# Set PR_TITLE with fallback if SUGGESTED_TITLE is empty
if [ -n "$SUGGESTED_TITLE" ]; then
    PR_TITLE="$SUGGESTED_TITLE"
else
    # Fall back to most recent commit subject
    PR_TITLE=$(git log -1 --pretty=%s)
    echo -e "${YELLOW}⚠ Using most recent commit message as PR title${NC}"
    echo "  Title: $PR_TITLE"
    echo ""
fi

# Create description based on commits
PR_DESCRIPTION="## Summary

[Describe what this PR does and why]

## Changes

"

# Add commits to changes section
while IFS= read -r line; do
    PR_DESCRIPTION="${PR_DESCRIPTION}${line}\n"
done < <(git log --format="- %s" --no-merges "$MERGE_BASE..HEAD")

PR_DESCRIPTION="${PR_DESCRIPTION}
## Documentation

"

if [ "$DOC_FILES" -gt 0 ]; then
    PR_DESCRIPTION="${PR_DESCRIPTION}### Updated
"
    while IFS= read -r file; do
        PR_DESCRIPTION="${PR_DESCRIPTION}- ${file}\n"
    done < <(git diff --name-only "$MERGE_BASE..HEAD" | grep -E '(\.md$|^docs/)')
else
    PR_DESCRIPTION="${PR_DESCRIPTION}- No documentation changes
"
fi

PR_DESCRIPTION="${PR_DESCRIPTION}
## Testing

### How to test:
1. [Step one]
2. [Step two]
3. [Expected result]

## Related Issues

Closes #

## Breaking Changes

- No breaking changes

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] All tests passing
"

# Create the PR
echo "Creating PR..."
echo ""

if [ "$DRAFT" = true ]; then
    set +e
    gh pr create \
        --title "$PR_TITLE" \
        --body "$PR_DESCRIPTION" \
        --draft \
        --web
    rc=$?
    set -e
    
    if [ $rc -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Draft PR created successfully${NC}"
        echo ""
        echo "Mark ready when complete: gh pr ready"
    else
        echo ""
        echo -e "${RED}✗ Failed to create PR${NC}"
        exit 1
    fi
else
    set +e
    gh pr create \
        --title "$PR_TITLE" \
        --body "$PR_DESCRIPTION" \
        --web
    rc=$?
    set -e
    
    if [ $rc -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ PR created successfully${NC}"
    else
        echo ""
        echo -e "${RED}✗ Failed to create PR${NC}"
        exit 1
    fi
fi

exit 0
