---
description: 'Apply fixes from an inline /quick-review findings block without creating
  a review artifact. Use directly with pasted Quick Review findings, or indirectly
  from /quick-review "Apply fixes". Usage: [--parallel] [--severity <level>] <quick-review
  findings block>'
---

# Quick Fix Command

Apply fixes from inline Quick Review findings without writing
`docs/prps/reviews/*.md`.

**Load and follow the `quick-fix` skill, passing through `$ARGUMENTS`.**

Use this command when you have a Quick Review findings block and want the
low-friction fixer path. For artifact-backed fixing, use `/review-fix`.

**Flags**:

- `--parallel` — Dispatch independent same-file groups to `review-fixer`
  agents in parallel.
- `--severity <CRITICAL|HIGH|MEDIUM|LOW>` — Minimum severity threshold to fix.
  Default: `HIGH`.

```
Usage: /quick-fix [--parallel] [--severity <level>] <quick-review findings block>
```

`/quick-review` invokes this automatically when the user chooses
**Apply fixes**. It does not write or update a review artifact.
