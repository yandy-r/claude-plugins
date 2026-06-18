---
description: 'Turn an existing text plan into a rich, interactive visual plan — diagrams,
  file maps, annotated code, open questions, and an optional UI/prototype review surface.
  Reads the plan (never edits it) and writes plan.mdx + canvas.mdx into a sibling
  visual/ directory. Hosted sharing is consent-gated behind --share; default is a
  local-files localhost preview. Usage: [--share] <path/to/plan.md>'
---

# Visual Plan Command

Render an existing plan as a structured, reviewable visual plan.

**Load and follow the `visual-plan` skill, passing through `$ARGUMENTS`.**

The skill reads the plan at the given path (read-only), auto-selects a review
mode from its content (UI-first / prototype-first / design-first / visual-intake,
or document-only), resolves the live block catalog at use time, and emits
`plan.mdx` (plus `canvas.mdx` when a canvas is used) into a `visual/` sibling of
the input plan. It prints exactly one link: a localhost preview by default, or a
hosted shareable URL when `--share` is passed.

**Flags**:

- `--share` — Opt in to hosted egress (destination `plan.agent-native.com`).
  Hosted upload is OFF by default and consent-gated: without `--share` the skill
  runs in local-files mode and nothing leaves the machine. Egress is routed
  through the shared `visual-egress-guard.sh`, which scans for secrets, refuses
  non-public remotes, and requires a consent token naming the destination.

```
Usage: /visual-plan [--share] <path/to/plan.md>

Examples:
  /visual-plan docs/prps/plans/notifications.plan.md          # local-files preview (default)
  /visual-plan --share docs/prps/plans/notifications.plan.md  # hosted shareable URL (consent-gated)
  /visual-plan .work/feature-x/parallel-plan.md               # any plan path; visual/ derived from it

Output (exactly one of):
  https://plan.agent-native.com/...   # hosted shareable URL (only with --share)
  http://127.0.0.1:PORT/...           # localhost preview (default)
  local files only                    # when no server/host is available
```

Invoked automatically as the hand-off target of the shared `--visual` decorator
on `/prp-plan`, `/plan`, `/parallel-plan`, and `/plan-workflow`.
The decorator runs only after a plan is written and validated, then calls
`visual-plan <absolute-plan-path>`.
