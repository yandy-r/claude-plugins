---
description: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.
argument-hint: '[optional: topic override]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - Bash(date:*)
  - Bash(git:*)
---

# Save Session Command

Persist the current session's work, decisions, failures, and next steps.

**Load and follow the `ycc:save-session` skill, passing through `$ARGUMENTS`.**

The skill writes to `~/.claude/session-data/YYYY-MM-DD-{shortid}-session.tmp`. The file is read by `/ycc:resume-session` at the start of the next session.

```
Usage: /ycc:save-session [optional topic]

Examples:
  /ycc:save-session
  /ycc:save-session "JWT cookie auth refactor"

Paired command:
  /ycc:resume-session   # load the most recent session at the start of the next one
```
