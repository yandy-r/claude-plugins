---
description: 'Interactive PRD generator — problem-first, hypothesis-driven product
  spec built through iterative questioning and dual-mode grounding research. Writes
  to docs/prps/prds/. Usage: [feature/product idea] (blank = start with questions)'
---

# PRP PRD Command

Run the interactive PRD generation workflow.

**Load and follow the `prp-prd` skill, passing through `$ARGUMENTS`.**

The skill runs an 8-phase interactive flow: Initiate → Foundation → Market Grounding → Deep Dive → Technical Grounding → Decisions → Generate → Output. It dispatches the `prp-researcher` agent during grounding phases and writes the final PRD to `docs/prps/prds/{kebab-name}.prd.md`.

```
Usage: /prp-prd [feature idea]

Examples:
  /prp-prd                                    # Start from scratch with questions
  /prp-prd real-time market resolution alerts # Start from a one-line idea

Next step after PRD is written:
  /prp-plan docs/prps/prds/{name}.prd.md      # Generate the next phase plan
```
