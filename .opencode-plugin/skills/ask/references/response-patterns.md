# Response Patterns Reference

Detailed response templates for each operating mode of the codebase-advisor agent.

## Guidance Mode Response Template

```
## [Direct Answer]

[1-3 sentence answer to the question]

## Relevant Code

- **Entry point**: `path/to/file.ts:42` - [brief description]
- **Core logic**: `path/to/logic.ts:15-78` - [brief description]
- **Configuration**: `path/to/config.ts:5` - [brief description]

## Architecture Context

[How the pieces fit together - data flow, abstraction layers, patterns used]

## Guidance

### To make this change:
1. **Modify** `path/to/file.ts:42` - [what to change and why]
2. **Update** `path/to/related.ts:10` - [what to change and why]
3. **Follow the pattern** in `path/to/example.ts:30` - [existing pattern to match]

### Watch out for:
- [Pitfall 1 with file reference]
- [Pitfall 2 with file reference]

### Tests to update:
- `path/to/test.ts` - [what test scenarios need adjustment]
```

## Impact Analysis Response Template

```
## Target

**[Element name]** at `path/to/file.ts:42`
[Brief description of what this element does]

## Direct Dependents

| File | Line | Usage | Risk |
|------|------|-------|------|
| `path/to/consumer1.ts` | 15 | Calls function directly | High |
| `path/to/consumer2.ts` | 88 | Imports type only | Low |

## Transitive Impact

- `consumer1.ts` is used by `handler.ts:20` which serves the `/api/users` endpoint
- Changing the return type would cascade through [N] files

## Risk Assessment

- **High risk**: [specific area] - [reason with file reference]
- **Medium risk**: [specific area] - [reason with file reference]
- **Low risk**: [specific area] - [reason with file reference]

## Test Coverage

- **Covered**: `path/to/test.ts` covers [scenarios]
- **Gap**: No tests for [scenario] - recommend adding coverage

## Safe Change Checklist

1. [ ] Update the target element at `file.ts:42`
2. [ ] Update direct consumer at `consumer1.ts:15`
3. [ ] Verify type compatibility in `consumer2.ts:88`
4. [ ] Run tests: `[test command]`
5. [ ] Check for runtime behavior changes in [area]
```

## Comparison Mode Response Template

```
## Overview

- **[A]** (`path/to/a.ts`): [1-2 sentence description]
- **[B]** (`path/to/b.ts`): [1-2 sentence description]

## Structural Comparison

| Aspect | [A] | [B] |
|--------|-----|-----|
| Pattern | [pattern name] | [pattern name] |
| Entry point | `a.ts:10` | `b.ts:25` |
| Error handling | [approach] | [approach] |
| State management | [approach] | [approach] |

## Key Differences

### 1. [Difference category]
- **[A]** at `a.ts:42`: [implementation detail]
- **[B]** at `b.ts:67`: [implementation detail]
- **Impact**: [why this difference matters]

### 2. [Difference category]
- **[A]** at `a.ts:100`: [implementation detail]
- **[B]** at `b.ts:55`: [implementation detail]
- **Impact**: [why this difference matters]

## Trade-offs

- **[A] is better when**: [scenario] because [reason]
- **[B] is better when**: [scenario] because [reason]

## Consistency Notes

[Whether the divergence is intentional or accidental, and whether
consolidation would be beneficial]
```

## Edge Case Handling

### Code Not Found

When the target code cannot be located:

- State clearly what was searched for and what patterns were tried
- Suggest alternative names, locations, or approaches to find it
- Check if the feature might be in a dependency, generated code, or external service
- Ask the user to clarify the name or provide a file hint

### Ambiguous Query

When the question could map to multiple modes or targets:

- Identify the ambiguity explicitly
- State the interpretation being used and why
- Offer to re-analyze under the alternative interpretation
- For multi-part questions, address each part in sequence

### Large Codebase / Incomplete Coverage

When the codebase is too large for comprehensive analysis:

- State the scope of what was analyzed and what was skipped
- Prioritize the most critical paths and direct dependencies
- Flag areas that warrant deeper investigation as follow-up questions
- Provide confidence levels for findings based on coverage depth

## General Response Guidelines

### File References

Always use the format `path/to/file.ts:42` for single lines or `path/to/file.ts:42-78` for ranges. These allow direct navigation in the editor.

### Confidence Indicators

When uncertain about findings, use explicit qualifiers:

- "Based on the code I've traced..." (high confidence)
- "This appears to be..." (medium confidence, pattern suggests but not confirmed)
- "I couldn't find direct evidence, but..." (low confidence, inference from context)

### Scope Management

For large codebases, prioritize depth over breadth:

- Focus on the 3-5 most relevant files rather than listing everything
- Trace the primary execution path before exploring edge cases
- Note areas that warrant deeper investigation without fully exploring them

### Follow-up Suggestions

End responses with actionable next steps:

- "To dig deeper into [area], ask about [specific question]"
- "Before making this change, check [specific concern]"
- "The impact analysis for [related element] would also be valuable"
