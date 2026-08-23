---
description: 'Turn a finished change (git range, branch, or tracked working-tree diff)
  into a LOCAL-ONLY interactive visual recap — annotated split diffs, file map, schema/API
  deltas, diagrams, and wireframes — written under docs/prps/reviews/visual/ and previewed
  in the browser via the 127.0.0.1 localhost bridge. Never uploads code; remote-agnostic
  across the public GitHub remote and the private Forgejo origin. Usage: [base..head
  | branch]'
---

# Visual Recap Command

Generate a LOCAL-ONLY visual recap of what a change touched.

**Load and follow the `visual-recap` skill, passing through `$ARGUMENTS`.**

The skill sources the diff through the remote-agnostic collector (local git refs only —
identical on the public `github` remote and the private Forgejo `origin`), fetches the
live block catalog, and authors MDX (`data-model`, `api-endpoint`, `file-tree`, split
`diff`, `diagram`, and mandatory `wireframe` blocks when UI changed) under
`docs/prps/reviews/visual/<slug>/`. The recap is previewed via the localhost bridge.

**LOCAL-ONLY — what this command will NOT do:**

- No hosted publish, no shareable hosted link, no Plan database write.
- No hosted recap-create / publish tool — `AGENT_NATIVE_PLANS_MODE=local-files` is always set.
- No PR comment and no GitHub/Forgejo Action.
- The only permitted Plan application request is the schema-only catalog lookup via
  `env AGENT_NATIVE_PLANS_MODE=local-files npx -y @agent-native/core@0.59.1 plan blocks --out <path>`.

**Arguments**:

- _(none)_ — Recap the tracked working-tree diff against `HEAD`.
- `<base>..<head>` — Recap an explicit two-endpoint range.
- `<branch>` — Treat `<branch>` as head; the base is computed via `git merge-base`
  against the tracked upstream (never a hardcoded trunk).

```
Usage: /visual-recap [base..head | branch]

Examples:
  /visual-recap                       # tracked working-tree diff vs HEAD
  /visual-recap feat/rate-limiting    # branch vs merge-base(upstream)
  /visual-recap main..HEAD            # explicit range
  /visual-recap v1.2.0..v1.3.0        # release-to-release recap

Output:
  docs/prps/reviews/visual/<slug>/        # local MDX recap + diff bundle
  http://127.0.0.1:<port>/...             # localhost-bridge preview (not shareable)
```

**Related**: `/visual-plan` renders a forward plan (hosted egress is consent-gated
there); `/visual-recap` is strictly local and emits no remote link.
