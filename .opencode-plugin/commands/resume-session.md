---
description: 'Load the most recent session file from ~/.config/opencode/session-data/
  and resume work with full context. Counterpart to /save-session. Usage: [YYYY-MM-DD
  | path/to/session.tmp] (blank = most recent)'
---

# Resume Session Command

Load a saved session and produce a structured briefing. Does not start working — waits for user direction.

**Load and follow the `resume-session` skill, passing through `$ARGUMENTS`.**

```
Usage: /resume-session [YYYY-MM-DD | path/to/session.tmp]

Examples:
  /resume-session
  /resume-session 2024-01-15
  /resume-session ~/.config/opencode/session-data/2024-01-15-abc123de-session.tmp
```
