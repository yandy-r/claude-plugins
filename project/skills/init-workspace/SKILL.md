---
name: init-workspace
description: This skill should be used when the user asks to "initialize workspace", "set up Claude CLI environment", "configure agents and MCPs for project", "init workspace", "set up project with Claude tools", or mentions workspace initialization. Analyzes project type and presents available agents/MCPs for selection.
argument-hint: '[--dry-run]'
disable-model-invocation: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(cp:*)
  - Bash(mkdir:*)
  - Bash(jq:*)
  - 'Bash(${HOME}/.claude/mcp-library/generate-mcp-config.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/init-workspace/scripts/*.sh:*)'
---

# Claude CLI Workspace Initialization

Initialize this workspace with the optimal Claude CLI configuration based on project analysis.

## Current Project Context

- **Working Directory**: !`pwd`
- **Project Files**: !`ls -la 2>/dev/null | head -25`
- **package.json exists**: !`test -f package.json && echo "yes" || echo "no"`
- **CLAUDE.md exists**: !`test -f CLAUDE.md && echo "yes" || echo "no"`
- **README.md exists**: !`test -f README.md && echo "yes" || echo "no"`
- **Go project**: !`test -f go.mod && echo "yes" || echo "no"`
- **Python project**: !`test -f requirements.txt -o -f pyproject.toml && echo "yes" || echo "no"`
- **Rust project**: !`test -f Cargo.toml && echo "yes" || echo "no"`
- **Terraform project**: !`ls *.tf 2>/dev/null | head -1 >/dev/null && echo "yes" || echo "no"`

## Arguments

- `$ARGUMENTS`: User-provided arguments (e.g., `--dry-run`)

---

## Task

Initialize this workspace with the optimal Claude CLI configuration.

### Phase 1: Project Discovery

Analyze the project context above and read key files to determine:

1. **Project Type**: Identify the domain (web app, CLI tool, library, API, infrastructure, etc.)
2. **Primary Language/Framework**: Detect from config files, file extensions, and imports
3. **Development Needs**: Testing, deployment, database, CI/CD, etc.
4. **Special Requirements**: Any unique tooling or workflows

Read these files if they exist: `README.md`, `CLAUDE.md`, `package.json`, `go.mod`, `requirements.txt` / `pyproject.toml`, `Cargo.toml`, `*.tf` files.

### Phase 2: Generate Available Options

Run the catalog generator scripts:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/init-workspace/scripts/generate-mcp-catalog.sh

${CLAUDE_PLUGIN_ROOT}/skills/init-workspace/scripts/generate-agent-catalog.sh
```

### Phase 3: Present Full Selection List

Present ALL available options to the user using checkboxes organized by category. Pre-check items that match detected project needs based on language/framework alignment, workflow requirements, and detected infrastructure patterns. Let the user freely select/deselect any items.

### Phase 4: Dry Run Check

If `--dry-run` was passed in `$ARGUMENTS`: display what would be configured, show the planned `.mcp.json` content, list agent files that would be copied, and **STOP** without making changes.

### Phase 5: Apply Configuration

For selected MCPs:

```bash
${HOME}/.claude/mcp-library/generate-mcp-config.sh <selected-mcps>
```

For selected agents: create `.claude/agents/` directory if needed and copy selected agent files from `${HOME}/.claude/agents/` to the project.

### Phase 6: Generate Summary Report

Output a summary using the template at `${CLAUDE_PLUGIN_ROOT}/skills/init-workspace/templates/workspace-report.md` with project analysis, configured MCPs/agents tables, and next steps.

---

## Important Notes

- Never add MCPs or agents that don't match project needs
- Prefer fewer, well-matched tools over many options
- Consider project maturity and team preferences
- Respect existing `.mcp.json` if present (offer to merge)
