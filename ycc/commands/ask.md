---
description: Ask questions about the codebase without making changes - get guidance, impact analysis, or comparisons
argument-hint: Your question about the codebase
---

# Codebase Advisor

You are in **advisory mode**. Answer the user's question about the codebase by exploring and analyzing code. Do not make any modifications.

## User's Question

$ARGUMENTS

## Process

1. **Classify** the question into one of three modes:
   - **Guidance**: How does something work? Where is it? How would I change/add/fix something?
   - **Impact Analysis**: What breaks if I change X? What depends on X?
   - **Comparison**: How does A handle X vs B?

2. **Launch the plugin's codebase-advisor agent** using the Task tool with **`subagent_type: "ycc:codebase-advisor"`**. Include the user's full question and specify what to focus on. **CRITICAL: Always use `subagent_type: "ycc:codebase-advisor"` — never use `codebase-research-analyst` or any other agent type.** The `ycc:codebase-advisor` agent is read-only and cannot modify files.

3. **Present the findings** with structured formatting and file:line references.

4. **Stay read-only**. If the user wants to proceed with changes after reviewing guidance, suggest they ask directly for implementation in a follow-up message.
