---
name: ask
description: This skill should be used when the user asks questions about the codebase
  without requesting changes, such as "how does X work?", "where is Y implemented?",
  "explain this code", "walk me through X", "what does this do?", "what would I need
  to change for X?", "if I change X what breaks?", "compare how A and B handle X",
  or any exploratory question about code structure, architecture, or implementation.
  Also triggered by the /ask command.
---

# Ask Codebase - Read-Only Codebase Advisor

## Purpose

Provide expert guidance about the current codebase without making any modifications. Act as a knowledgeable senior engineer who can answer questions about architecture, implementation, impact of changes, and comparisons between different parts of the codebase.

## When to Activate

Activate when the user's intent is to **understand** rather than **change**. Common triggers:

- Questions about how something works or where something is
- "I want to change X to do Y" (guide, don't implement)
- "I want to add feature X" or "fix bug Y" (analyze and advise)
- "What would break if I change X?" (impact analysis)
- "Compare how A and B handle X" (comparison)
- Explicit `/ask` command invocation

## Workflow

### 1. Classify the Query

Determine the operating mode based on the user's question:

| Mode                | Trigger Phrases                                     | Agent Focus                                             |
| ------------------- | --------------------------------------------------- | ------------------------------------------------------- |
| **Guidance**        | "how does", "where is", "I want to change/add/fix"  | Trace code, explain architecture, suggest approach      |
| **Impact Analysis** | "what breaks if", "what depends on", "blast radius" | Map dependencies, assess risk, provide change checklist |
| **Comparison**      | "compare", "difference between", "A vs B"           | Side-by-side analysis, trade-offs, consistency          |

### 2. Launch the Codebase Advisor Agent

Mention `@codebase-advisor` or invoke it via the built-in `task` tool. This is the plugin's read-only agent — it has no write tools and cannot modify files.

**CRITICAL: Always use `@codebase-advisor`. Never use `codebase-research-analyst`, `Explore`, or any other agent type.** Other agent types have write tools (Bash, Write, the todo tracker) and will attempt to create files and directories.

**For guidance questions**:

```
Investigate: [user's question]
Focus on: entry points, code flow, architecture patterns, and specific file:line references.
If this is about making a change, explain exactly what files need modification and what patterns to follow.
```

**For impact analysis**:

```
Analyze the impact of changing [target].
Map all direct dependents, transitive effects, test coverage, and risk levels.
Provide a safe change checklist.
```

**For comparison**:

```
Compare how [A] and [B] handle [X].
Provide structural comparison, key differences with file:line references, and trade-off analysis.
```

### 3. Present Results

Relay the agent's findings directly to the user. Maintain the structured format with file:line references. Do not add implementation steps unless the user explicitly requests them.

### 4. Respect the Read-Only Boundary

**Critical**: Do not transition into making changes based on the advisory output. The user must explicitly request changes before any implementation begins. At that point, suggest using the appropriate workflow (e.g., feature-dev, direct editing).

## Integration Notes

- The `codebase-advisor` agent has **no write tools** - it cannot accidentally modify files
- For follow-up questions, launch additional advisor agents as needed
- Multiple advisor agents can run in parallel for complex multi-part questions
- The advisor reads AGENTS.md and project conventions to provide context-aware guidance

## Additional Resources

### Reference Files

Load and follow the templates in:

- **`references/response-patterns.md`** - Structured response templates for each mode, including edge case handling
