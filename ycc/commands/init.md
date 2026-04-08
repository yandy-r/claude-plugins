---
description: Initialize Claude CLI workspace with agents and MCPs based on project analysis
argument-hint: '[--dry-run]'
---

Initialize the current workspace with the optimal Claude CLI configuration.

Invoke the **init** skill to:

1. Analyze the project type, language, and development needs
2. Generate catalogs of available agents and MCP servers
3. Present a selection list with pre-checked recommendations
4. Apply the selected configuration (`.mcp.json` and `.claude/agents/`)

Pass `$ARGUMENTS` through to the skill (supports `--dry-run` to preview without changes).
