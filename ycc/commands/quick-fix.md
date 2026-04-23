---
description: Apply fixes from an inline /ycc:quick-review findings block without creating a review artifact. Use directly with pasted Quick Review findings, or indirectly from /ycc:quick-review "Apply fixes".
argument-hint: '[--parallel] [--severity <level>] <quick-review findings block>'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - MultiEdit
  - Agent
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(git:*)
  - Bash(npm:*)
  - Bash(pnpm:*)
  - Bash(yarn:*)
  - Bash(bun:*)
  - Bash(npx:*)
  - Bash(cargo:*)
  - Bash(go:*)
  - Bash(pytest:*)
  - Bash(python:*)
  - Bash(python3:*)
  - Bash(make:*)
---

# Quick Fix Command

Apply fixes from inline Quick Review findings without writing
`docs/prps/reviews/*.md`.

**Load and follow the `ycc:quick-fix` skill, passing through `$ARGUMENTS`.**

Use this command when you have a Quick Review findings block and want the
low-friction fixer path. For artifact-backed fixing, use `/ycc:review-fix`.

**Flags**:

- `--parallel` — Dispatch independent same-file groups to `ycc:review-fixer`
  agents in parallel.
- `--severity <CRITICAL|HIGH|MEDIUM|LOW>` — Minimum severity threshold to fix.
  Default: `HIGH`.

```
Usage: /ycc:quick-fix [--parallel] [--severity <level>] <quick-review findings block>
```

`/ycc:quick-review` invokes this automatically when the user chooses
**Apply fixes**. It does not write or update a review artifact.
