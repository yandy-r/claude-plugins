---
description: 'Save current session state to a dated file in ~/.config/opencode/session-data/
  so work can be resumed in a future session with full context. Usage: [optional:
  topic override]'
---

# Save Session Command

Persist the current session's work, decisions, failures, and next steps.

**Load and follow the `save-session` skill, passing through `$ARGUMENTS`.**

The skill writes to `~/.config/opencode/session-data/YYYY-MM-DD-{shortid}-session.tmp`. The file is read by `/resume-session` at the start of the next session.

```
Usage: /save-session [optional topic]

Examples:
  /save-session
  /save-session "JWT cookie auth refactor"

Paired command:
  /resume-session   # load the most recent session at the start of the next one
```
