---
description: Orchestrate parallel cleanup agents to find and remove unnecessary project files
argument-hint: '[target-directory] [--dry-run] [--report-only] [--safe-mode]'
---

Clean unnecessary files from a project directory using parallel analysis agents.

Invoke the **clean** skill to:

1. Detect project type and load safety configuration
2. Deploy 6 parallel cleanup agents (code files, binaries, assets, docs, config, Docker)
3. Consolidate findings, calculate space savings, and validate safety
4. Present findings for user review with risk assessment
5. Execute safe removal with user confirmation

Pass `$ARGUMENTS` through to the skill. Supported flags:

- `--dry-run`: Preview analysis plan without executing
- `--report-only`: Generate detailed report without any deletions
- `--safe-mode`: Extra confirmation prompts for each category

Note: `--include-git` is deprecated and ignored. The clean skill shows a one-time
notice and continues with files-only cleanup. Git resources (branches, worktrees,
remotes, stashes, tags, PRs, issues) belong to `/ycc:git-cleanup`, which this
command never invokes automatically.

Examples:

```
/ycc:clean                           # Clean current directory
/ycc:clean /path/to/project          # Clean specific directory
/ycc:clean --dry-run                 # Preview cleanup
/ycc:clean --report-only             # Report only, no deletions
/ycc:clean --safe-mode               # Thorough with confirmations
```
