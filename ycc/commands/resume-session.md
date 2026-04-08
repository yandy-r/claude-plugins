---
description: Load the most recent session file from ~/.claude/session-data/ and resume work with full context. Counterpart to /ycc:save-session.
argument-hint: '[YYYY-MM-DD | path/to/session.tmp] (blank = most recent)'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(find:*)
  - Bash(git:*)
---

# Resume Session Command

Load a saved session and produce a structured briefing. Does not start working — waits for user direction.

**Load and follow the `ycc:resume-session` skill, passing through `$ARGUMENTS`.**

```
Usage: /ycc:resume-session [YYYY-MM-DD | path/to/session.tmp]

Examples:
  /ycc:resume-session
  /ycc:resume-session 2024-01-15
  /ycc:resume-session ~/.claude/session-data/2024-01-15-abc123de-session.tmp
```
