# Cursor rules (`~/.cursor/rules`)

This directory contains **Cursor rule files** (`.mdc`) used by the editor’s AI features. Rules here
apply **globally** to all workspaces unless you override them with project-local rules under
`<project>/.cursor/rules/`.

## File types

| File        | Purpose                                         |
| ----------- | ----------------------------------------------- |
| `*.mdc`     | Active rules — read by Cursor                   |
| `README.md` | Human documentation only (not loaded as a rule) |

## Frontmatter (required)

Every rule file starts with YAML between `---` lines:

```yaml
---
description: 'Short human-readable summary of what this rule enforces'
alwaysApply: true
---
```

### Scoped rules (language / web)

When a rule should apply only to certain files, set `alwaysApply: false` and add **`globs`** (not
`paths`). Glob patterns **must be quoted** in YAML so `**` parses correctly:

```yaml
---
description: 'TypeScript coding conventions'
alwaysApply: false
globs:
  - '**/*.ts'
  - '**/*.tsx'
  - '**/*.js'
  - '**/*.jsx'
---
```

### Precedence

- **`alwaysApply: true`** — included in context broadly (use for language-agnostic standards: coding
  style, testing policy, git workflow, security baselines, etc.).
- **`alwaysApply: false` + `globs`** — applied when matching files are in scope (use for
  `typescript__*`, `python__*`, `web__*`, etc.).

Where a global rule and a scoped rule overlap, **the more specific scoped rule should win in
practice**; keep global rules generic and put language-specific detail in prefixed files.

## Naming convention

Files are **flattened** in this directory (no `common/` subfolders):

- **Global rules:** `coding-style.mdc`, `testing.mdc`, `security.mdc`, `git-workflow.mdc`, …
- **Language- or domain-prefixed rules:** `{prefix}__{topic}.mdc`  
  Examples: `typescript__coding-style.mdc`, `golang__testing.mdc`, `web__patterns.mdc`

Prefix examples: `typescript`, `python`, `golang`, `rust`, `java`, `kotlin`, `swift`, `php`, `perl`,
`dart`, `csharp`, `cpp`, `web`.

## Cross-references

Language-specific files reference the matching global file in the same directory, e.g.
`[coding-style.mdc](coding-style.mdc)`. Paths like `../common/` are **not** used in this layout.

## Content notes

- Some body text still mentions **Claude Code** paths (e.g. `~/.claude/agents/`, `settings.json`);
  update those to your harness if you use a different tool.
- Chinese duplicate rule files (`zh__*.md`) were removed; only English rules are kept here.

## Adding a new scoped rule

1. Create `mylang__topic.mdc` with `description`, `alwaysApply: false`, and `globs` for that
   language.
2. Optionally add a one-line “extends” note pointing at the global `topic.mdc` file.
3. Keep globs **double-quoted** in YAML.
