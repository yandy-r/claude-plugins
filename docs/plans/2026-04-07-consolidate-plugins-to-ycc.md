# Plan: Consolidate all plugins into a single `ycc` plugin

**Date:** 2026-04-07
**Status:** Draft — awaiting user approval before execution
**Scope:** Repository-wide refactor of `yandy-r/claude-plugins`
**Complexity:** MEDIUM (mechanical moves + text rewrites + registry rewrite)
**Type:** BREAKING CHANGE (marketplace 1.0.0 → 2.0.0)

---

## 1. Goal

All plugin skills in this repo must be accessible via the single namespace prefix
`ycc:{skill}` instead of `{plugin-name}:{skill-name}`.

| Before                               | After                    |
| ------------------------------------ | ------------------------ |
| `git-workflow:git-workflow`          | `ycc:git-workflow`       |
| `git-workflow:research-to-issues`    | `ycc:research-to-issues` |
| `plan-workflow:plan-workflow`        | `ycc:plan-workflow`      |
| `plan-workflow:feature-research`     | `ycc:feature-research`   |
| `plan-workflow:parallel-plan`        | `ycc:parallel-plan`      |
| `plan-workflow:shared-context`       | `ycc:shared-context`     |
| `implement-plan:implement-plan`      | `ycc:implement-plan`     |
| `code-report:code-report`            | `ycc:code-report`        |
| `deep-research:deep-research`        | `ycc:deep-research`      |
| `orchestrate:orchestrate`            | `ycc:orchestrate`        |
| `write-docs:write-docs`              | `ycc:write-docs`         |
| `ask:ask-codebase` / `/ask`          | `ycc:ask-codebase`       |
| `project:init-workspace` / `/init`   | `ycc:init-workspace`     |
| `project:project-cleaner` / `/clean` | `ycc:project-cleaner`    |

## 2. Core Design Decision

**Claude Code ties the namespace prefix directly to the plugin's `name` field.**
There is no aliasing mechanism. To get `ycc:{skill}`, the skills must literally
live inside a plugin named `ycc`.

**Therefore:** collapse all 9 current plugin directories into one `ycc/` plugin
directory. This is the only viable approach.

### Confirmed trade-offs

- ✅ Single bundled plugin — no per-plugin à-la-carte install (user confirmed OK)
- ✅ Breaking change for marketplace consumers, marketplace bumps `1.0.0` → `2.0.0`
- ✅ Merge the two `_shared/` skill directories into one `ycc/skills/_shared/`

## 3. Preconditions / What I verified

1. **No name collisions** across skills (12), commands (9), or agents (9). Clean consolidation is possible without renaming anything below the plugin level.
2. **`_shared/` collision** exists between `plan-workflow/skills/_shared/` and `implement-plan/skills/_shared/`. Diff shows **only comment-level differences** in `resolve-plans-dir.sh` — trivial reconcile. The documented version wins.
3. **`${CLAUDE_PLUGIN_ROOT}` references** (~30 occurrences) are all of the form `${CLAUDE_PLUGIN_ROOT}/skills/{skill-name}/...`. These stay valid post-move because the skill subdirectory names are preserved — only the plugin directory wrapper changes.
4. **Shell scripts:** 33 total, **all 33 already executable**. `git mv` preserves the executable bit.
5. **Hardcoded prefix strings** for rewrite: 16 occurrences across user-facing docs. Full list in §6.
6. **Cross-plugin references:** none. No skill calls another plugin's skill by its prefix. (Only `ask.md` hardcodes `ask:codebase-advisor` as a subagent_type — see §6.)

## 4. Target repository layout

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json          # rewritten: 9 entries → 1 entry
├── ycc/                          # NEW: single consolidated plugin
│   ├── .claude-plugin/
│   │   └── plugin.json           # name: "ycc", version: "2.0.0"
│   ├── commands/                 # 9 files (flat, no collisions)
│   │   ├── ask.md
│   │   ├── clean.md
│   │   ├── code-report.md
│   │   ├── deep-research.md
│   │   ├── git-workflow.md
│   │   ├── implement-plan.md
│   │   ├── init.md
│   │   ├── research-to-issues.md
│   │   └── write-docs.md
│   ├── agents/                   # 9 files (flat, no collisions)
│   │   ├── api-documenter.md
│   │   ├── architecture-analyst.md
│   │   ├── code-documenter.md
│   │   ├── codebase-advisor.md
│   │   ├── feature-researcher.md
│   │   ├── feature-writer.md
│   │   ├── practices-researcher.md
│   │   ├── project-file-cleaner.md
│   │   └── readme-generator.md
│   └── skills/                   # 12 skill subdirs
│       ├── _shared/              # merged from plan-workflow + implement-plan
│       ├── ask-codebase/
│       ├── code-report/
│       ├── deep-research/
│       ├── feature-research/
│       ├── git-workflow/
│       ├── implement-plan/
│       ├── init-workspace/
│       ├── orchestrate/
│       ├── parallel-plan/
│       ├── plan-workflow/
│       ├── project-cleaner/
│       ├── research-to-issues/
│       ├── shared-context/
│       └── write-docs/
├── docs/plans/
│   └── 2026-04-07-consolidate-plugins-to-ycc.md   # this file
├── CLAUDE.md
├── CONTRIBUTING.md
├── README.md
└── LICENSE
```

**Deleted:** the 9 old plugin directories (`ask/`, `plan-workflow/`, `implement-plan/`, `git-workflow/`, `code-report/`, `deep-research/`, `orchestrate/`, `write-docs/`, `project/`).

## 5. Implementation phases

### Phase 0 — Safety net (before any mutation)

- Create a safety branch: `git checkout -b feat/consolidate-to-ycc`
- Confirm the working tree is clean.
- Run a sanity inventory: record current skill, command, and agent counts so we can verify the post-move totals match.

**Exit criteria:** Branch created, clean tree, inventory recorded.

### Phase 1 — Scaffold the `ycc/` skeleton

- Create `ycc/.claude-plugin/plugin.json` with:

  ```json
  {
    "name": "ycc",
    "version": "2.0.0",
    "description": "Yandy's Claude Code plugin bundle: planning, implementation, git workflow, research, docs, orchestration, ask, and project utilities — all under the ycc: namespace.",
    "author": { "name": "yandy-r" }
  }
  ```

- Create empty directories: `ycc/commands/`, `ycc/agents/`, `ycc/skills/`.

**Exit criteria:** `ycc/` exists, `plugin.json` is valid JSON (verified by `python -m json.tool`).

### Phase 2 — Move skill directories

Use `git mv` for each so history follows:

```
git mv ask/skills/ask-codebase                    ycc/skills/ask-codebase
git mv code-report/skills/code-report             ycc/skills/code-report
git mv deep-research/skills/deep-research         ycc/skills/deep-research
git mv git-workflow/skills/git-workflow           ycc/skills/git-workflow
git mv git-workflow/skills/research-to-issues    ycc/skills/research-to-issues
git mv implement-plan/skills/implement-plan       ycc/skills/implement-plan
git mv orchestrate/skills/orchestrate             ycc/skills/orchestrate
git mv plan-workflow/skills/plan-workflow         ycc/skills/plan-workflow
git mv plan-workflow/skills/parallel-plan         ycc/skills/parallel-plan
git mv plan-workflow/skills/shared-context        ycc/skills/shared-context
git mv plan-workflow/skills/feature-research      ycc/skills/feature-research
git mv project/skills/init-workspace              ycc/skills/init-workspace
git mv project/skills/project-cleaner             ycc/skills/project-cleaner
git mv write-docs/skills/write-docs               ycc/skills/write-docs
```

**`_shared/` reconciliation** (done separately to avoid a merge conflict):

1. `git mv plan-workflow/skills/_shared ycc/skills/_shared` (this wins — better comments per the diff)
2. `diff -rq implement-plan/skills/_shared ycc/skills/_shared` to confirm no other divergent files
3. `git rm -r implement-plan/skills/_shared`

**Exit criteria:** `ls ycc/skills/` shows all 14 subdirs (12 skill + 1 `_shared`), each containing its original contents.

### Phase 3 — Move agents

```
git mv ask/agents/codebase-advisor.md             ycc/agents/
git mv plan-workflow/agents/feature-researcher.md ycc/agents/
git mv plan-workflow/agents/practices-researcher.md ycc/agents/
git mv project/agents/project-file-cleaner.md    ycc/agents/
git mv write-docs/agents/api-documenter.md        ycc/agents/
git mv write-docs/agents/architecture-analyst.md  ycc/agents/
git mv write-docs/agents/code-documenter.md       ycc/agents/
git mv write-docs/agents/feature-writer.md        ycc/agents/
git mv write-docs/agents/readme-generator.md      ycc/agents/
```

**Exit criteria:** 9 agents under `ycc/agents/`.

### Phase 4 — Move commands

```
git mv ask/commands/ask.md                        ycc/commands/
git mv code-report/commands/code-report.md        ycc/commands/
git mv deep-research/commands/deep-research.md    ycc/commands/
git mv git-workflow/commands/git-workflow.md      ycc/commands/
git mv git-workflow/commands/research-to-issues.md ycc/commands/
git mv implement-plan/commands/implement-plan.md  ycc/commands/
git mv project/commands/clean.md                  ycc/commands/
git mv project/commands/init.md                   ycc/commands/
git mv write-docs/commands/write-docs.md          ycc/commands/
```

**Exit criteria:** 9 commands under `ycc/commands/`.

### Phase 5 — Delete old plugin directories

After each phase-2..4 move, the old `{plugin}/skills/`, `{plugin}/agents/`, `{plugin}/commands/` dirs are empty. The only remaining file is each plugin's `.claude-plugin/plugin.json`.

```
git rm -r ask code-report deep-research git-workflow implement-plan \
          orchestrate plan-workflow project write-docs
```

**Exit criteria:** `ls` at repo root shows no old plugin directories; only `ycc/`, `docs/`, `.claude-plugin/`, and top-level files remain.

### Phase 6 — Rewrite the marketplace manifest

Replace `.claude-plugin/marketplace.json` with a single `ycc` entry. Bump marketplace metadata version to `2.0.0`:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "ycc",
  "description": "Yandy's Claude Code plugin bundle, consolidated under the ycc: namespace.",
  "owner": { "name": "yandy-r" },
  "metadata": {
    "version": "2.0.0",
    "repository": "https://github.com/yandy-r/claude-plugins"
  },
  "plugins": [
    {
      "name": "ycc",
      "description": "Yandy's Claude Code plugin bundle: planning, implementation, git workflow, research, docs, orchestration, ask, and project utilities — all under the ycc: namespace.",
      "version": "2.0.0",
      "author": { "name": "yandy-r" },
      "source": "./ycc"
    }
  ]
}
```

**Exit criteria:** `python -m json.tool .claude-plugin/marketplace.json` exits 0.

### Phase 7 — Text rewrites in user-facing docs

Rewrite all 16 occurrences. See §6 for the exact sed/Edit operations. Every one of these is either:

- `/old-prefix:skill-or-command` → `/ycc:skill-or-command`, or
- `"old-prefix:agent-name"` → `"ycc:agent-name"`, or
- `` `old-prefix:skill` `` → `` `ycc:skill` `` (for cross-references in prose)

Also rewrite any `${CLAUDE_PLUGIN_ROOT}` path that (if any) refers to a skill by a former sibling plugin. **Verified: none exist** — every `${CLAUDE_PLUGIN_ROOT}/skills/X/...` reference already points to a skill that used to be in the SAME plugin, so they all resolve correctly after consolidation without changes.

**Exit criteria:** `grep -rE "(ask|plan-workflow|implement-plan|git-workflow|code-report|deep-research|orchestrate|write-docs|project):" ycc/ .claude-plugin/` returns zero matches (excluding the `_shared` dir, template strings that happen to contain `Task:`, etc.).

### Phase 8 — Update `README.md` and `CLAUDE.md`

- `README.md`: rewrite the plugin list to describe the single `ycc` plugin and the new `ycc:{skill}` invocation pattern. Remove the per-plugin marketing blocks.
- `CLAUDE.md`: update the "Directory Structure" and "Naming" sections that currently describe per-plugin layout — reflect that this repo now ships one plugin.

**Exit criteria:** Both files accurately describe the consolidated structure; no stale references to the 9 old plugin names as installable units.

### Phase 9 — Validation

Run this validation script (hand-executed, not committed):

```bash
# 1. JSON validity
python -m json.tool .claude-plugin/marketplace.json > /dev/null
python -m json.tool ycc/.claude-plugin/plugin.json > /dev/null

# 2. Count consistency
test $(find ycc/skills -mindepth 1 -maxdepth 1 -type d | wc -l) -eq 14  # 12 skills + _shared + (any)
test $(find ycc/commands -name "*.md" | wc -l) -eq 9
test $(find ycc/agents -name "*.md" | wc -l) -eq 9

# 3. No stray old-prefix references
! grep -rE "(ask|plan-workflow|implement-plan|git-workflow|code-report|deep-research|orchestrate|write-docs|project):[a-z]" ycc/ .claude-plugin/ README.md CLAUDE.md 2>/dev/null | grep -vE "(Your Task|Task:|_shared)"

# 4. Executable bits preserved
find ycc/skills -name "*.sh" -not -executable   # should output nothing

# 5. No broken ${CLAUDE_PLUGIN_ROOT} references
# (manual spot-check: grep for ${CLAUDE_PLUGIN_ROOT} and verify each path resolves)

# 6. No dangling old plugin directories
! test -d ask && ! test -d plan-workflow && ! test -d implement-plan && \
! test -d git-workflow && ! test -d code-report && ! test -d deep-research && \
! test -d orchestrate && ! test -d write-docs && ! test -d project
```

**Exit criteria:** All checks pass.

### Phase 10 — Commit strategy

Split into logical commits for an auditable history:

1. `refactor(ycc): scaffold consolidated ycc plugin skeleton`
2. `refactor(ycc): move all skills under ycc/skills/` (largest diff, pure `git mv`)
3. `refactor(ycc): merge plan-workflow and implement-plan _shared dirs`
4. `refactor(ycc): move all agents under ycc/agents/`
5. `refactor(ycc): move all commands under ycc/commands/`
6. `refactor(ycc): remove obsolete per-plugin directories`
7. `refactor(ycc): rewrite marketplace.json for single ycc plugin`
8. `refactor(ycc): rewrite namespace prefixes in docs to ycc:`
9. `docs(ycc): update README and CLAUDE.md for consolidated layout`

`git mv` in separate commits keeps rename detection clean so `git log --follow` still works on individual files.

**Exit criteria:** All 9 commits exist, each passes `git show --stat` inspection, and the branch builds a coherent story.

### Phase 11 — Smoke test in a Claude Code session

- Run Claude Code against the worktree and verify at least these skills resolve by the new prefix:
  - `ycc:git-workflow`
  - `ycc:feature-research`
  - `ycc:plan-workflow`
  - `ycc:implement-plan`
  - `ycc:ask-codebase` (and the corresponding `subagent_type: "ycc:codebase-advisor"`)
- Verify at least one slash command still works: `/ycc:git-workflow` or similar.
- Verify `${CLAUDE_PLUGIN_ROOT}` resolves by invoking a skill that uses it (e.g., `ycc:git-workflow` runs `analyze-changes.sh`).

**Exit criteria:** All three probes return expected behavior. If any fail, STOP and re-plan.

## 6. Exact text-rewrite targets

These are the 16 lines that must be rewritten in Phase 7. Each is listed as `file:line — before → after`.

### ask plugin (3 references)

1. `ycc/commands/ask.md:21` (was `ask/commands/ask.md:21`)
   - `subagent_type: "ask:codebase-advisor"` → `subagent_type: "ycc:codebase-advisor"` (3 occurrences on this line)
2. `ycc/skills/ask-codebase/SKILL.md:37`
   - `subagent_type: "ask:codebase-advisor"` → `subagent_type: "ycc:codebase-advisor"`
3. `ycc/skills/ask-codebase/SKILL.md:39`
   - `subagent_type: "ask:codebase-advisor"` → `subagent_type: "ycc:codebase-advisor"`

### git-workflow plugin (6 references)

4. `ycc/commands/research-to-issues.md:53`
   - `/git-workflow:research-to-issues` → `/ycc:research-to-issues`
5. `ycc/commands/research-to-issues.md:56`
   - `/git-workflow:research-to-issues --dry-run` → `/ycc:research-to-issues --dry-run`
6. `ycc/commands/research-to-issues.md:57`
   - `/git-workflow:research-to-issues` → `/ycc:research-to-issues`
7. `ycc/commands/research-to-issues.md:58`
   - `/git-workflow:research-to-issues --research-dir ./docs/research` → `/ycc:research-to-issues --research-dir ./docs/research`
8. `ycc/commands/research-to-issues.md:59`
   - `/git-workflow:research-to-issues --skip-anti-scope --skip-gaps` → `/ycc:research-to-issues --skip-anti-scope --skip-gaps`
9. `ycc/commands/research-to-issues.md:60`
   - `/git-workflow:research-to-issues --dry-run --skip-gaps` → `/ycc:research-to-issues --dry-run --skip-gaps`

### project plugin (6 references)

10. `ycc/commands/clean.md:27` — `/project:clean` → `/ycc:clean`\*
11. `ycc/commands/clean.md:28` — `/project:clean /path/to/project` → `/ycc:clean /path/to/project`
12. `ycc/commands/clean.md:29` — `/project:clean --dry-run` → `/ycc:clean --dry-run`
13. `ycc/commands/clean.md:30` — `/project:clean --report-only` → `/ycc:clean --report-only`
14. `ycc/commands/clean.md:31` — `/project:clean --safe-mode --include-git` → `/ycc:clean --safe-mode --include-git`
15. `ycc/skills/init-workspace/templates/workspace-report.md:3`
    - `` Generated by `/project:init` `` → `` Generated by `/ycc:init` ``

> **\*Naming consideration for `/clean` and `/init`:** these command filenames stay as-is (`clean.md`, `init.md`), because the file basename determines the slash command name. So post-consolidation they become `/ycc:clean` and `/ycc:init`. If you'd rather rename them to `/ycc:project-clean` and `/ycc:project-init` for clarity, say so and I'll add a `git mv` step. Default: keep as `/ycc:clean` and `/ycc:init`.

### write-docs plugin (1 reference)

16. `ycc/commands/write-docs.md:33`
    - ``Invoke the `write-docs:write-docs` skill`` → ``Invoke the `ycc:write-docs` skill``

### Strings that look like prefixes but are NOT (must NOT be rewritten)

These false positives showed up in grep but are prose/templates, not prefix references:

- `deep-research/skills/deep-research/templates/analysis-prompts.md`: `## Your Task: ...` (English prose)
- `orchestrate/skills/orchestrate/references/task-breakdown.md`: `Check each subtask:` (English prose)
- `plan-workflow/skills/*/templates/*`: `Task: [Description]`, `Before completing this task:` (English prose)
- `write-docs/skills/write-docs/references/agent-task-prompts.md:136`: `Your task:` (English prose)

The rewrite tool must be surgical — use exact `old_string`/`new_string` on the lines listed above, not a blind `sed`.

## 7. Risk register

| Risk                                                                                                                                | Severity | Likelihood      | Mitigation                                                                                                                                |
| ----------------------------------------------------------------------------------------------------------------------------------- | -------- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Breaking change silently breaks existing installs of the old plugin names                                                           | HIGH     | CERTAIN         | Bump marketplace to 2.0.0, document the breaking change in README and release notes. Users re-install under `ycc`. This is user-accepted. |
| `_shared/` merge loses the more-documented version                                                                                  | MEDIUM   | LOW             | Step 2.`_shared` explicitly keeps the better-commented version; step includes a `diff -rq` safety check                                   |
| `${CLAUDE_PLUGIN_ROOT}` paths silently break because a skill referenced another plugin's file                                       | HIGH     | LOW             | Verified in §3.3 — zero such cross-plugin references exist. Re-verify in Phase 9 with grep-based check.                                   |
| Text rewrite accidentally mangles English prose that contains strings like "Task:"                                                  | MEDIUM   | LOW             | §6 uses exact-line Edit operations, not blind sed. False-positive list is enumerated.                                                     |
| Executable bit dropped on shell scripts during move                                                                                 | MEDIUM   | LOW             | `git mv` preserves mode. Phase 9 check 4 catches any regressions.                                                                         |
| `/clean` and `/init` become too-generic slash commands under `ycc:`                                                                 | LOW      | MEDIUM          | Flagged in §6 as a naming consideration for user input. Default is to keep them as-is.                                                    |
| `plan-workflow` currently has a stray `version: 2.0.0` in its `plugin.json` while marketplace says `2.0.0` — internal inconsistency | LOW      | N/A             | Becomes moot; old `plugin.json` files are deleted in Phase 5.                                                                             |
| Running hook or CI that matches `{plugin-name}/` in this repo                                                                       | LOW      | UNKNOWN         | Pre-flight `grep` in Phase 0 to find any lingering references in `.claude/`, `.github/`, or config files. If found, rewrite or update.    |
| Plugin cache (`~/.claude/plugins/cache/`) keeps stale copies of old plugin dirs                                                     | LOW      | CERTAIN locally | User clears cache or reloads marketplace after merge. Document in commit message / PR description.                                        |

## 8. Out of scope

- Changing any skill's internal logic, prompts, or scripts. This is a pure move + prefix rewrite.
- Renaming commands or skills below the plugin level. Only the wrapping plugin name changes.
- Publishing to a central marketplace or updating anything outside this repo.
- Providing backward-compatibility shims (user confirmed breaking change is OK).
- Anything in `~/.claude/` or `.claude-plugin/cache/` on the user's machine.

## 9. Estimated effort

| Phase                                      | Effort                       |
| ------------------------------------------ | ---------------------------- |
| 0. Safety net                              | trivial                      |
| 1. Scaffold                                | trivial                      |
| 2. Move skills (14 dirs + `_shared` merge) | small                        |
| 3. Move agents (9 files)                   | trivial                      |
| 4. Move commands (9 files)                 | trivial                      |
| 5. Delete old plugin dirs                  | trivial                      |
| 6. Rewrite marketplace.json                | small                        |
| 7. Text rewrites (16 lines)                | small                        |
| 8. Update README + CLAUDE.md               | small                        |
| 9. Validation                              | small                        |
| 10. Commit strategy (9 commits)            | small                        |
| 11. Smoke test in Claude Code session      | small, but blocks completion |

Total: a single focused work session. No code needs to be written — only files moved and strings edited.

## 10. Rollback plan

Everything happens on a branch (`feat/consolidate-to-ycc`). If anything goes wrong:

- **Before merge:** `git checkout main && git branch -D feat/consolidate-to-ycc`. Zero impact.
- **After merge but before any consumer updates:** `git revert` the merge commit. Marketplace consumers reload and get the 1.x state back.
- **After merge and consumers have updated:** users re-install by subscribing to the old marketplace version tag if available, or pin to the last commit on `main` before the merge. Document the rollback commit SHA in the PR description.

## 11. Acceptance criteria

This refactor is DONE when all of the following hold:

1. `ls` at repo root shows exactly: `.claude-plugin/`, `ycc/`, `docs/`, `CLAUDE.md`, `CONTRIBUTING.md`, `LICENSE`, `README.md`, and the repo dotfiles.
2. `ycc/skills/` contains exactly 12 skill subdirs + 1 `_shared` dir.
3. `ycc/commands/` contains exactly 9 `.md` files.
4. `ycc/agents/` contains exactly 9 `.md` files.
5. `marketplace.json` is valid JSON with exactly one entry named `ycc` at version `2.0.0`.
6. `plugin.json` at `ycc/.claude-plugin/plugin.json` is valid JSON with `name: "ycc"`.
7. The acceptance grep from Phase 9 check 3 returns zero matches.
8. All 33 shell scripts remain executable.
9. At least 3 skills invoked via the new `ycc:{skill}` prefix work in a live Claude Code session (Phase 11).
10. `README.md` and `CLAUDE.md` accurately describe the consolidated layout.

## 12. Explicit user-approval gate

> **DO NOT begin execution of Phases 1–11 until the user reviews this document and says "approved" / "proceed" / "go".**

If the user wants changes, revise this document first, re-request approval, and only then proceed.

---

_Plan author: planner agent via `/ecc:plan` command_
_Plan location: `docs/plans/2026-04-07-consolidate-plugins-to-ycc.md`_
