---
description: 'Quick natural-language git commit helper — describe what to commit in
  plain English (blob glob, filter phrase, or topic). Lightweight sibling of /git-workflow.
  Usage: [target description] (blank = all changes)'
---

# PRP Commit Command

Stage and commit changes with a natural-language target.

**Load and follow the `prp-commit` skill, passing through `$ARGUMENTS`.**

For full commit + documentation + agent orchestration, use `/git-workflow` instead.

```
Usage: /prp-commit [target description]

Examples:
  /prp-commit                              # stage all, auto message
  /prp-commit staged                       # commit what is already staged
  /prp-commit *.ts                         # only TypeScript files
  /prp-commit except tests                 # everything except test files
  /prp-commit the auth changes             # natural-language filter
  /prp-commit only new files               # untracked only
```
