---
description: 'Orchestrate parallel cleanup agents to find and remove unnecessary project
  files Usage: [target-directory] [--dry-run] [--report-only] [--safe-mode] [--include-git]'
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
- `--include-git`: Analyze git artifacts (large files, stale branches)

Examples:

```
/clean                           # Clean current directory
/clean /path/to/project          # Clean specific directory
/clean --dry-run                 # Preview cleanup
/clean --report-only             # Report only, no deletions
/clean --safe-mode --include-git # Thorough with confirmations
```
