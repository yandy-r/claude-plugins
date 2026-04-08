---
description: Quick natural-language git commit helper — describe what to commit in plain English (blob glob, filter phrase, or topic). Lightweight sibling of /ycc:git-workflow.
argument-hint: '[target description] (blank = all changes)'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(git:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
---

# PRP Commit Command

Stage and commit changes with a natural-language target.

**Load and follow the `ycc:prp-commit` skill, passing through `$ARGUMENTS`.**

For full commit + documentation + agent orchestration, use `/ycc:git-workflow` instead.

```
Usage: /ycc:prp-commit [target description]

Examples:
  /ycc:prp-commit                              # stage all, auto message
  /ycc:prp-commit staged                       # commit what is already staged
  /ycc:prp-commit *.ts                         # only TypeScript files
  /ycc:prp-commit except tests                 # everything except test files
  /ycc:prp-commit the auth changes             # natural-language filter
  /ycc:prp-commit only new files               # untracked only
```
