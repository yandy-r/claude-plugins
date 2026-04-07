# Tracking Issue Template

Use this template for phase-level tracking issues that group related feature issues.

## Template

```markdown
## Overview

{phase_description}

**Duration**: {duration}
**Team**: {team_size}
**Risk Level**: {risk_level}
**Prerequisites**: {prerequisites}

## Features / Deliverables

{checkbox_list}

## Success Criteria

{success_criteria}

## Notes

- This is a tracking issue. Individual features are linked above.
- Check off items as their linked issues are completed.
```

## Field Descriptions

| Field             | Source                                   | Example                               |
| ----------------- | ---------------------------------------- | ------------------------------------- |
| phase_description | Implementation roadmap phase objective   | "Establish project infrastructure..." |
| duration          | Implementation roadmap duration estimate | "3-4 weeks"                           |
| team_size         | Implementation roadmap team field        | "1-2 developers"                      |
| risk_level        | Implementation roadmap risk level        | "Low", "Medium", "High"               |
| prerequisites     | Implementation roadmap prerequisite      | "Phase 0 complete"                    |
| checkbox_list     | Generated from child issues              | "- [ ] #12 Multi-Tenant Data Model"   |
| success_criteria  | Implementation roadmap success criteria  | Bulleted list of criteria             |

## Label Assignment

Tracking issues receive:

- `tracking` — identifies this as a parent tracking issue
- `phase:{phase-number}` — e.g., `phase:0`, `phase:1`
- `priority:high` — tracking issues are always high priority
