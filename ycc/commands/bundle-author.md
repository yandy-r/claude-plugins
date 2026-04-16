---
description: Scaffold new source-of-truth content in the ycc bundle (skill, optional matching command and agent)
argument-hint: '<skill-name> [--with-command] [--with-agent] [--dry-run]'
---

Scaffold a new skill (and optionally a matching command and/or agent) in the `ycc/` source-of-truth tree.

Invoke the **bundle-author** skill to:

1. Validate kebab-case name and refuse collisions with existing skills, commands, or agents
2. Preview the files that will be created
3. Scaffold from templates under `ycc/skills/bundle-author/references/templates/`
4. Emit the exact follow-up commands (sync, validate, chmod) needed after scaffolding

Pass `$ARGUMENTS` through to the skill. Supported flags:

- `--with-command`: Also scaffold `ycc/commands/<skill-name>.md`
- `--with-agent`: Also scaffold `ycc/agents/<skill-name>.md`
- `--dry-run`: Preview only, write nothing

Examples:

```
/ycc:bundle-author my-new-skill                          # skill only
/ycc:bundle-author my-new-skill --with-command           # skill + command
/ycc:bundle-author my-new-skill --with-command --with-agent
/ycc:bundle-author my-new-skill --dry-run                # preview only
```

Refuses generic scaffolding for external repos — see `ycc/skills/bundle-author/references/when-not-to-scaffold.md` for anti-patterns.
