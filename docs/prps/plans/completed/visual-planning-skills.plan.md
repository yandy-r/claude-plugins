# Plan: Visual Planning Skills (visual-plan + visual-recap + `--visual` flag)

## Summary

Port the BuilderIO `visual-plan` and `visual-recap` skills (pinned upstream commit
`a0726717ab0402e85eadca46183d8be50bc3a102`) into the `ycc` bundle as `ycc:visual-plan`
and `ycc:visual-recap`, and add a `--visual` flag to four planning skills (`prp-plan`,
`plan`, `plan-workflow`, `parallel-plan`) that bootstraps the visual workflow after the
text plan is written. `ycc:visual-plan` keeps the faithful Agent-Native integration
(MDX, hosted shareable links, `npx @agent-native/*` tooling, localhost bridge) but gates
network egress behind explicit consent; `ycc:visual-recap` is local-only and
remote-agnostic (works against both the GitHub and private Forgejo remotes). No GitHub
Action is ported.

## User Story

As a developer running `/ycc:prp-plan`, `/ycc:plan`, `/ycc:plan-workflow`, or
`/ycc:parallel-plan`, I want a `--visual` flag that turns my finished plan into an
Agent-Native, browser-reviewable MDX document (hosted link or localhost preview), so that
I can review and share the plan visually before any code is written — instead of only a
static `.plan.md`.

As a developer who just finished an implementation, I want `/ycc:visual-recap` to generate
a **local-only** visual summary of what changed (annotated diffs, file map, schema/API
deltas), so that I can review the result in the browser without uploading private code to a
third-party service.

## Problem → Solution

Planning skills today emit only static Markdown (`docs/prps/plans/{name}.plan.md`,
feature-dir `parallel-plan.md`, or nothing for `/ycc:plan`) with no visual review surface,
and there is no post-implementation visual recap. → The `ycc/` bundle gains two new
source-of-truth skills (`ycc:visual-plan`, `ycc:visual-recap`) plus a `--visual`
decorator on the four planning skills, all conforming to repo conventions, with the
Cursor/Codex/opencode bundles regenerated and all validators green.

## Metadata

- **Complexity**: Large (10+ files: 2 new skills + 2 new commands + 4 skill edits + 4
  command edits + shared refs/scripts + bundle regeneration)
- **Source PRD**: N/A (free-form feature request)
- **PRD Phase**: N/A
- **Estimated Files**: ~22 source files touched/created (excluding regenerated bundles)
- **Upstream pin**: `BuilderIO/skills@a0726717ab0402e85eadca46183d8be50bc3a102`
- **Pinned dependency**: `@agent-native/core` / `@agent-native/skills` — pin an exact
  version (see Task 1.1); never `@latest` in committed content.

## Batches

Tasks grouped by dependency for parallel execution. Tasks within a batch run concurrently
(no two touch the same file); batches run in order.

| Batch | Tasks              | Depends On | Parallel Width |
| ----- | ------------------ | ---------- | -------------- |
| B1    | 1.1, 1.2, 1.3, 1.4 | —          | 4              |
| B2    | 2.1, 2.2           | B1         | 2              |
| B3    | 3.1, 3.2, 3.3, 3.4 | B2         | 4              |
| B4    | 4.1                | B1,B2,B3   | 1              |
| B5    | 5.1                | B4         | 1              |

- **Total tasks**: 12
- **Total batches**: 5
- **Max parallel width**: 4

---

## UX Design

### Before

- `/ycc:prp-plan <feature>` → one markdown plan at `docs/prps/plans/{name}.plan.md`
  (`ycc/skills/prp-plan/SKILL.md:327`) plus a text "Report to User" block
  (`SKILL.md:417-434`); the only artifact shown is a repo-relative path.
- Flags today: `--parallel | --team | --worktree | --no-worktree | --enhanced | --dry-run`
  (`ycc/commands/prp-plan.md:37-44`). No `--visual`; no visual artifact; no recap skill.

### After

- `/ycc:prp-plan --visual <feature>` writes the same `.plan.md`, then bootstraps
  `ycc:visual-plan` on that file → an MDX visual artifact under a sibling `visual/` dir and
  either a hosted shareable link (consent-gated) or a localhost preview URL.
- Report block gains two fields: `Visual Artifact:` and `Visual Link:`
  (`<hosted-url | http://127.0.0.1:PORT/... | "local files only">`).
- New `/ycc:visual-plan <plan-path>` (render an existing plan standalone) and
  `/ycc:visual-recap [base..head | branch]` (local-only recap → `docs/prps/reviews/visual/`).
- `--visual` is orthogonal — composes with `--parallel`/`--team`/`--enhanced`/`--no-worktree`;
  short-circuited by `--dry-run`; `/ycc:plan --visual` force-writes a plan file first.

### Interaction Changes

| Touchpoint                                                                                           | Before           | After                               | Notes                                   |
| ---------------------------------------------------------------------------------------------------- | ---------------- | ----------------------------------- | --------------------------------------- |
| 4 command flag tables (`prp-plan.md:37-44`, `plan.md:32-41`, `plan-workflow.md`, `parallel-plan.md`) | no `--visual`    | `--visual` row added                | Identical wording across all four       |
| 4 command Usage grammars                                                                             | no `[--visual]`  | `[--visual]` added                  | Keeps existing mutual-exclusion notes   |
| 4 SKILL flag-parse blocks                                                                            | no `VISUAL_MODE` | `VISUAL_MODE` boolean parsed        | Mirror the `--enhanced` case+strip pair |
| `prp-plan` Report block (`SKILL.md:417-434`)                                                         | 12 fields        | + `Visual Artifact` + `Visual Link` | Link value depends on consent/mode      |
| NEW `/ycc:visual-plan` help                                                                          | does not exist   | full Usage/Examples/Output          | hosted or localhost preview             |
| NEW `/ycc:visual-recap` help                                                                         | does not exist   | full Usage/Examples/Output          | local-only; no hosted link; no Action   |

**Forgejo / two-remote impact**: `origin` is the **private** Forgejo
(`git.azules-celsius.ts.net`); `github` is the public remote. Hosted links are generated
from local MDX and are remote-agnostic; in-artifact repo links must use
`git remote get-url <name>` (never hardcode `github.com`); recap is local-only so it emits
no remote-tied link. Report/artifact path fields stay repo-relative.

---

## Mandatory Reading

Files that MUST be read before implementing:

| Priority       | File                                                        | Lines                                                                                  | Why                                                                                                                     |
| -------------- | ----------------------------------------------------------- | -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| P0 (critical)  | `ycc/skills/prp-plan/SKILL.md`                              | 44-82, 323-371, 417-434                                                                | Canonical flag-parse block, validation gate, GENERATE chunking, Report block — the exact pattern `--visual` must mirror |
| P0 (critical)  | `ycc/skills/bundle-author/SKILL.md`                         | all                                                                                    | Sanctioned scaffolder for a new skill+command; encodes the source-of-truth split                                        |
| P0 (critical)  | `ycc/skills/bundle-author/references/surface-map.md`        | all                                                                                    | `${CLAUDE_PLUGIN_ROOT}` path conventions, skill/command surface layout                                                  |
| P0 (critical)  | `CLAUDE.md`                                                 | "Plugin Development Conventions", "Generated Compatibility Targets", "Testing Changes" | Naming, source-vs-generated split, regenerate+validate loop                                                             |
| P1 (important) | `ycc/skills/plan/SKILL.md`                                  | 81-102                                                                                 | Second instance of the flag-parse/validation pattern (no-artifact skill — force-write case)                             |
| P1 (important) | `ycc/skills/parallel-plan/SKILL.md`                         | 67-119                                                                                 | Arg-parse + dry-run roster pattern                                                                                      |
| P1 (important) | `ycc/skills/plan-workflow/SKILL.md`                         | 52-114                                                                                 | Arg-parse + usage block pattern                                                                                         |
| P1 (important) | `ycc/skills/_shared/references/target-capability-matrix.md` | 11-30                                                                                  | Confirms `--visual` must branch in the SKILL body (Codex has no command layer)                                          |
| P1 (important) | `ycc/skills/clean/scripts/validate-safety.sh`               | 8-14, 71-100, 238                                                                      | Protected-path/secret denylist + exit-code conventions to mirror in the egress guard                                    |
| P1 (important) | `ycc/skills/_shared/scripts/prepare-feature-branch.sh`      | 18-21, 69-92                                                                           | Strict flag parsing + stdout/stderr discipline for new scripts                                                          |
| P2 (reference) | `ycc/commands/prp-plan.md`                                  | 1-68                                                                                   | Thin command-doc shape (frontmatter + flag table + Usage/Examples)                                                      |
| P2 (reference) | `scripts/validate.sh` / `scripts/sync.sh`                   | headers, `:113-119`                                                                    | The regenerate + validate pipeline (CI loop), `--only` targets                                                          |
| P2 (reference) | `ycc/skills/_shared/references/goal-pairing.md`             | all                                                                                    | `/goal` pairing recipe — decide include/skip for new skills                                                             |

## External Documentation

| Topic                          | Source                                                 | Key Takeaway                                                                                                                                                                                                                                    |
| ------------------------------ | ------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| visual-plan skill body         | `BuilderIO/skills@a072671:skills/visual-plan/SKILL.md` | Entry `/visual-plan`; auto-selects mode (UI-first / prototype-first / design-first / visual-intake). Read-only. Flow: `get-plan-blocks` (block catalog) → mode create tool → surface link → `get-plan-feedback` → `update-visual-plan` patches. |
| visual-recap skill body        | `…:skills/visual-recap/SKILL.md`                       | `/visual-recap` turns diffs into a published Plan via `create-visual-recap`; upstream FORBIDS inline Markdown ("value is the hosted plan") — **this is the exact rule we invert for local-only**.                                               |
| npx installer                  | `…:README.md`                                          | `npx @agent-native/skills@latest add` picker (skills, storage hosted/local-files/self-hosted, client, scope, optional GitHub Action). We pin a version and skip the Action.                                                                     |
| Runtime CLI                    | upstream SKILL setup                                   | Install `npx @agent-native/core@latest skills add <skill>`; auth `npx -y @agent-native/core@latest reconnect https://plan.agent-native.com --client [codex\|claude-code\|all]` (one-time per client).                                           |
| Hosted Plans app               | upstream SKILL                                         | Origin `https://plan.agent-native.com`; create tools return an absolute shareable URL; private-repo plans are org-gated (viewer must sign in).                                                                                                  |
| Plan MCP connector             | `…:visual-recap/SKILL.md`                              | Connector `plan` (legacy alias `agent-native-plans`). `get-plan-blocks` is the ONLY tool callable in local mode (schema-only; offline fallback `plan blocks --out`).                                                                            |
| Localhost bridge (local-files) | upstream SKILL Local-Files                             | Write MDX → `plan local check --dir plans/<slug>` → `plan local serve --dir plans/<slug> --open`. Serves the hosted UI against local files; **no DB writes, nothing sent to servers**. Port is CLI-chosen.                                      |
| Local recap diff collection    | `…:visual-recap/SKILL.md`                              | `npx @agent-native/core@latest recap collect-diff` shells to local `git` → **remote-agnostic** (identical on GitHub or Forgejo; no vendor PR API).                                                                                              |
| MDX vocab — PLAN doc blocks    | `…:references/document-quality.md`, `exemplar.md`      | `rich-text`, `annotated-code`, `code`, `tabs`, `columns`, `diagram`, `table`, `checklist`, `callout` (`tone="decision"`), `question-form` (bottom only), `custom-html`.                                                                         |
| MDX vocab — PLAN canvas blocks | `…:references/canvas.md`                               | `<DesignBoard>`, `<Section>`, `<Artboard>`, `<Screen>`, `<Annotation>`, `<Connector>`. Files: `plan.mdx` + `canvas.mdx`; artboard size via `surface`; ≥96px spacing.                                                                            |
| MDX vocab — RECAP blocks       | `…:visual-recap/SKILL.md`                              | `data-model` (field `change` flags), `api-endpoint`, `file-tree`, `diff` (split default), `diagram`, `wireframe` (MANDATORY when UI affected).                                                                                                  |
| Wireframe classes/tokens       | `…:references/wireframe.md`                            | `.wf-*` classes, `[data-icon]` Tabler set, surfaces `browser/desktop/mobile/popover/panel`, colors via `--wf-*` tokens only (no hex). `data.skeleton:true` for loading.                                                                         |
| Diagram primitives             | `…:references/document-quality.md`                     | `.diagram-*` classes, `[data-rough]` sketchy mode; patch via `patch-diagram-html`.                                                                                                                                                              |
| Content patch ops              | `…:references/canvas.md`                               | `patch-wireframe-html`, `patch-diagram-html`, `update-block`, `replace-blocks`, `read/patch-visual-plan-source`, `update-rich-text` — inside `update-visual-plan` `contentPatches`.                                                             |
| Upstream packaging             | `…:.claude-plugin/plugin.json`                         | Single plugin `builder-skills`, `"skills": "./skills/"` glob, no per-skill registration → maps cleanly onto `ycc/skills/<name>/`.                                                                                                               |
| GitHub Action (SKIPPED)        | `…:README.md`                                          | The PR-automation Action is GENERATED by `--with-github-action`, NOT committed at this commit. Skipping = simply not emitting it. Nothing to port-and-delete.                                                                                   |
| Forgejo Actions                | Forgejo convention                                     | GitHub-Actions-compatible YAML under `.forgejo/workflows/*.yml`. Recap is local-only (`git diff`/`collect-diff`) so no PR API and no Action is needed; documented for the record only.                                                          |

---

## Patterns to Mirror

Code patterns discovered in the codebase. Follow these exactly.

### NAMING_CONVENTION

```
// SOURCE: CLAUDE.md "Naming" + ycc/skills/bundle-author/references/surface-map.md:28-33
ycc/skills/visual-plan/        -> skill id ycc:visual-plan   (kebab-case dir)
ycc/commands/visual-plan.md    -> slash command /ycc:visual-plan
// in-body self-refs:
${CLAUDE_PLUGIN_ROOT}/skills/visual-plan/references/<name>.md
${CLAUDE_PLUGIN_ROOT}/skills/visual-plan/scripts/<name>.sh
```

### FLAG_PARSE (the exact model for `--visual` — copy `--enhanced`)

```
// SOURCE: ycc/skills/prp-plan/SKILL.md:70-74
ENHANCED_MODE=false
case " $ARGUMENTS " in
  *" --enhanced "*) ENHANCED_MODE=true ;;
esac
ARGUMENTS="${ARGUMENTS//--enhanced/}"
// → add one analogous VISUAL_MODE case+strip pair per skill
```

### FLAG_VALIDATION / COMMAND_FLAG_TABLE

```
// SOURCE: ycc/skills/prp-plan/SKILL.md:77-82 (prose Validation bullets)
- --parallel and --team are **mutually exclusive**. ...
// SOURCE: ycc/commands/plan.md:32-41 (command-doc flag table)
**Flags**:
- --parallel — Instruct the ycc:planner agent ...
- --no-worktree — Opt out ...
```

### SKILL_FRONTMATTER (mirror prp-plan; allowed-tools lists the script glob)

```yaml
# SOURCE: ycc/skills/prp-plan/SKILL.md:1-30
---
name: visual-plan
description: <triggering description>
argument-hint: '[--share] <path/to/plan.md>'
allowed-tools:
  - Read
  - Bash(${CLAUDE_PLUGIN_ROOT}/skills/visual-plan/scripts/*.sh:*)
---
```

### COMMAND_FRONTMATTER (thin body — logic lives in the skill)

```
// SOURCE: ycc/commands/prp-plan.md:1-27
---
description: <one line>
argument-hint: '...'
---
Load and follow the ycc:visual-plan skill, passing through $ARGUMENTS.
```

### ERROR_HANDLING (new scripts mirror these exactly)

```bash
# SOURCE: ycc/skills/git-workflow/scripts/create-pr.sh:1-2
#!/usr/bin/env bash
set -euo pipefail
# SOURCE: ycc/skills/clean/scripts/validate-safety.sh:29-38 (arg present + exists, errors→stderr)
if [[ -z "$ARG" ]]; then echo "ERROR: ... required" >&2; exit 1; fi
if [[ ! -f "$ARG" ]]; then echo "ERROR: ... not found" >&2; exit 1; fi
```

### PROTECTED_PATH_DENYLIST (egress guard mirrors clean/validate-safety.sh)

```bash
# SOURCE: ycc/skills/clean/scripts/validate-safety.sh:71-72,98-100,238
declare -a PROTECTED=( ".git" ".env" ".env.*" "*.pem" "*.key" )
if [[ -L "$full_path" ]]; then ((symlink_violations+=1)); fi
# distinct exit codes per failure class (header :8-14)
```

### TEST_STRUCTURE (the project's verification loop)

```bash
# SOURCE: CLAUDE.md "Testing Changes" + scripts/validate.sh:113-119
./scripts/sync.sh        # regenerate every bundle (accepts --only inventory,cursor,codex,opencode,json)
./scripts/validate.sh    # run every validator (CI loop); includes python3 -m json.tool on both manifests
find ycc/skills -name "*.sh" -not -executable   # must output nothing
```

---

## Files to Change

| File                                                                                  | Action             | Justification                                                                                                                                                                                                    |
| ------------------------------------------------------------------------------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ycc/skills/_shared/references/agent-native-setup.md`                                 | CREATE             | DRY runtime contract: pinned `@agent-native/*` install/reconnect, MCP `plan` connector (alias `agent-native-plans`), `local-files` mode, localhost-bridge commands, hosted-egress policy. Shared by both skills. |
| `ycc/skills/_shared/references/visual-mode.md`                                        | CREATE             | Canonical `--visual` decorator contract referenced by all four planning skills (post-generation, orthogonal, `--dry-run` short-circuit, plan-path hand-off, `/ycc:plan` force-write).                            |
| `ycc/skills/_shared/scripts/visual-recap-collect.sh`                                  | CREATE             | Remote-agnostic local diff collector (`git merge-base` + `git diff <base>...<head>`, `git remote get-url`); writes under `docs/prps/reviews/visual/<slug>/`.                                                     |
| `ycc/skills/_shared/scripts/visual-egress-guard.sh`                                   | CREATE             | Pre-upload secret/denylist scan + non-public-remote refusal + consent gate; single shared guard reused by hosted paths (mirrors `clean/validate-safety.sh`).                                                     |
| `ycc/skills/visual-plan/SKILL.md`                                                     | CREATE             | Ported visual-plan body; faithful hosted+local MDX workflow; egress consent-gated; `${CLAUDE_PLUGIN_ROOT}`-relative refs.                                                                                        |
| `ycc/skills/visual-plan/references/{canvas,wireframe,document-quality,exemplar}.md`   | CREATE             | Quality references the skill mandates reading before authoring (provider-neutral port).                                                                                                                          |
| `ycc/skills/visual-plan/scripts/*.sh`                                                 | CREATE (if needed) | Thin wrappers over shared `_shared/scripts` helpers; executable, strict-mode.                                                                                                                                    |
| `ycc/commands/visual-plan.md`                                                         | CREATE             | Pairing policy: every skill needs a matching command (or `command: false`).                                                                                                                                      |
| `ycc/skills/visual-recap/SKILL.md`                                                    | CREATE             | Ported recap body, **rewritten local-only**: deliverable under `docs/prps/reviews/visual/`, served via `plan local serve`; hosted `create-visual-recap` disabled; inverts the upstream "always hosted" mandate.  |
| `ycc/skills/visual-recap/references/wireframe.md`                                     | CREATE             | Wireframe quality ref required by recap.                                                                                                                                                                         |
| `ycc/commands/visual-recap.md`                                                        | CREATE             | Pairing policy; local-only help doc.                                                                                                                                                                             |
| `docs/prps/reviews/visual/.gitkeep`                                                   | CREATE             | Establish the local-only recap output location.                                                                                                                                                                  |
| `.gitignore`                                                                          | UPDATE             | Ignore local-serve scratch (`plan-blocks.md`, served-plan temp dirs) so runs don't dirty the tree.                                                                                                               |
| `ycc/skills/prp-plan/SKILL.md`                                                        | UPDATE             | `--visual` case+strip (near :70-74), flag table (:50-57), validation bullet (:77-82), Worktree/Visual block, post-Phase-6 bootstrap, Report fields (:417-434).                                                   |
| `ycc/commands/prp-plan.md`                                                            | UPDATE             | `--visual` flag row + Usage grammar + one example.                                                                                                                                                               |
| `ycc/skills/plan/SKILL.md`                                                            | UPDATE             | `--visual` parse (:90-94), table (:43-50), validation (:97-102), **force-write artifact** + post-confirmation bootstrap.                                                                                         |
| `ycc/commands/plan.md`                                                                | UPDATE             | `--visual` flag row + Usage + example.                                                                                                                                                                           |
| `ycc/skills/plan-workflow/SKILL.md`                                                   | UPDATE             | `--visual` arg parse (:96-114), arg list (:52-64), usage, post-final-phase bootstrap.                                                                                                                            |
| `ycc/commands/plan-workflow.md`                                                       | UPDATE             | `--visual` flag docs/usage.                                                                                                                                                                                      |
| `ycc/skills/parallel-plan/SKILL.md`                                                   | UPDATE             | `--visual` arg parse (:104-119), arg list (:67-73), dry-run roster/usage, post-final-phase bootstrap.                                                                                                            |
| `ycc/commands/parallel-plan.md`                                                       | UPDATE             | `--visual` flag docs/usage.                                                                                                                                                                                      |
| `mcp-configs/mcp.json`                                                                | UPDATE             | Register the `plan` Agent-Native MCP connector (accept legacy alias `agent-native-plans`) so opencode `opencode.json` MCP translation picks it up for the hosted path.                                           |
| `.cursor-plugin/**`, `.codex-plugin/**`, `.opencode-plugin/**`, `docs/inventory.json` | REGENERATE         | Produced by `./scripts/sync.sh` from `ycc/` — never hand-edit.                                                                                                                                                   |
| `.claude-plugin/marketplace.json`, `ycc/.claude-plugin/plugin.json`                   | NO EDIT            | Discovery is directory-based (`source: ./ycc`); no per-skill manifest entry. Version bumps are owned by `bundle-release`, not this plan.                                                                         |

## NOT Building

- **No GitHub Action / no `.github/workflows/visual-*.yml`** — explicitly out of scope; the
  upstream Action is installer-generated, not committed, so there is nothing to port.
- **No second marketplace plugin** — both skills ship inside the existing single `ycc`
  bundle; a second `.claude-plugin/marketplace.json` entry is forbidden by repo policy.
- **No custom MDX/HTML renderer, browser, or screenshot engine** — rely on the upstream
  `@agent-native` hosted UI + localhost bridge as-is; ported skills are prompt + reference
  content only.
- **No `--visual` on non-planning skills** — scope is exactly the four named skills; do not
  retrofit `implement-plan`, `prp-implement`, etc.
- **visual-recap is NOT wired into the four planning skills** — it pairs with review flows,
  local-only.
- **No changes to existing research/dispatch logic** of the four skills — `--visual` adds a
  terminal decorator step only.
- **No auto-publish / auto-commit** of generated MDX or hosted links (matches repo posture).
- **No new validators** — reuse the existing `--check`-gated generator/validator pipeline.
- **No upstream npm/`package.json` runtime deps vendored** — repo uses npm for lint/format
  only; the Agent-Native tooling runs via pinned `npx` at use time.
- **`/goal` pairing deferred (decide explicitly)** — see Notes; not added to the new skills
  in this pass unless the user opts in.

---

## Step-by-Step Tasks

> Hierarchical IDs map to the Batches table. No two tasks in the same batch touch the same
> file. `--visual` is added by **copying** the `--enhanced` flag-parse pattern verbatim and
> a single shared `## Visual mode` block into each of the four skills.

### Task 1.1: Shared Agent-Native setup reference — Depends on [none]

- **BATCH**: B1
- **ACTION**: Create `ycc/skills/_shared/references/agent-native-setup.md`.
- **IMPLEMENT**: Document the runtime contract once: pinned install (`npx -y @agent-native/core@<PINNED_VERSION> skills add <skill>`), `reconnect https://plan.agent-native.com --client [claude-code|codex|all]`, the `plan` MCP connector (legacy alias `agent-native-plans`), `AGENT_NATIVE_PLANS_MODE=local-files`, the localhost-bridge commands (`plan local check`, `plan local serve --open`), and the egress policy (hosted OFF by default, consent-gated). Resolve and record the exact `@agent-native/core` version to pin (check `npm view @agent-native/core version`); never write `@latest` into committed content.
- **MIRROR**: NAMING_CONVENTION; `_shared/references/*.md` style (e.g. `target-capability-matrix.md`).
- **GOTCHA**: Block vocabulary drifts upstream — the doc must instruct the runtime author step to call `get-plan-blocks` (or offline `plan blocks --out`) at use time rather than trusting the hardcoded component list.
- **VALIDATE**: File exists; no `@latest` token (`! grep -q '@latest' ycc/skills/_shared/references/agent-native-setup.md`); referenced by both new skills.

### Task 1.2: Shared visual-mode contract reference — Depends on [none]

- **BATCH**: B1
- **ACTION**: Create `ycc/skills/_shared/references/visual-mode.md`.
- **IMPLEMENT**: Define the canonical `--visual` decorator contract used by all four planning skills: runs AFTER the plan is written + validated; orthogonal to `--parallel`/`--team`/`--enhanced`/`--no-worktree`; **short-circuited by `--dry-run`** (print "visual generation would run"); hand-off = invoke `ycc:visual-plan <absolute-plan-path>`, which derives a sibling `visual/` output dir and prints the link to stdout; visual-plan never re-runs research/dispatch and never edits the plan; `/ycc:plan --visual` must force a plan-file write first (nothing to visualize otherwise).
- **MIRROR**: The shared worktree-strategy reference pattern (one canonical block reused across skills).
- **GOTCHA**: The four skills write plans to different paths (`docs/prps/plans/*.plan.md`, feature-dir `parallel-plan.md`, or none) — the contract must instruct visual-plan to accept ANY plan path and derive `visual/` relative to it.
- **VALIDATE**: File exists; all four skills reference it after Batch 3.

### Task 1.3: Shared remote-agnostic recap collector + egress guard — Depends on [none]

- **BATCH**: B1
- **ACTION**: Create `ycc/skills/_shared/scripts/visual-recap-collect.sh` and `ycc/skills/_shared/scripts/visual-egress-guard.sh`; `chmod +x` both.
- **IMPLEMENT**: `visual-recap-collect.sh` — strict-mode bash; arg = `<base..head | branch>` (default working-tree diff); compute base via `git merge-base` against the tracked upstream, NEVER hardcode `origin/main`; resolve remote URL via `git remote get-url <name>`; write diff bundle under `docs/prps/reviews/visual/<slug>/`; results→stdout, errors→stderr. `visual-egress-guard.sh` — pre-upload secret/denylist scan (mirror `clean/validate-safety.sh` PROTECTED list: `.env*`, `*.pem`, `*.key`), refuse when the resolved remote is the private Forgejo `origin` (non-public), require explicit consent token; distinct exit codes per failure class.
- **MIRROR**: ERROR_HANDLING + PROTECTED_PATH_DENYLIST; `_shared/scripts/prepare-feature-branch.sh:69-92` strict flag parsing.
- **IMPORTS**: source nothing external; reuse `_shared/scripts` conventions.
- **GOTCHA**: `collect-diff` must use local git refs only (`git diff <base>...<head>`) — never a vendor PR API — so it is identical on GitHub and Forgejo.
- **VALIDATE**: `bash -n` both scripts; `find ycc/skills -name "*.sh" -not -executable` empty; pinned `shellcheck` clean.

### Task 1.4: Create `docs/prps/reviews/visual/` + `.gitignore` scratch ignores — Depends on [none]

- **BATCH**: B1
- **ACTION**: Create `docs/prps/reviews/visual/.gitkeep`; append local-serve scratch ignores to `.gitignore`.
- **IMPLEMENT**: Add ignore entries for `plan-blocks.md` and served-plan temp dirs so visual runs don't dirty the working tree. Keep `.gitkeep` so the local-only recap output dir exists.
- **MIRROR**: Existing `.gitignore` grouping.
- **VALIDATE**: `git check-ignore` matches the scratch patterns; `.gitkeep` tracked.

### Task 2.1: Port `ycc:visual-plan` (skill + references + command) — Depends on [1.1, 1.2]

- **BATCH**: B2
- **ACTION**: Scaffold via `ycc:bundle-author`, then port content. Create `ycc/skills/visual-plan/{SKILL.md,references/{canvas,wireframe,document-quality,exemplar}.md}`, optional `scripts/`, and `ycc/commands/visual-plan.md`.
- **IMPLEMENT**: Port BuilderIO visual-plan @ `a072671` faithfully — keep MDX vocab, hosted Agent-Native app, localhost bridge, mode auto-selection, `get-plan-blocks`→create→feedback→`update-visual-plan` flow. Rewrite all paths to `${CLAUDE_PLUGIN_ROOT}/skills/visual-plan/...`; reference `_shared/references/agent-native-setup.md` for runtime + the egress guard; make hosted/shareable egress consent-gated (default local-files). Drop the GitHub Action entirely.
- **MIRROR**: SKILL_FRONTMATTER, COMMAND_FRONTMATTER, NAMING_CONVENTION.
- **GOTCHA**: Hosted create tools upload MDX (real paths/symbols/snippets) to `plan.agent-native.com`; SKILL must make hosted-vs-local an explicit defaulted choice (local default) and route egress through `visual-egress-guard.sh`.
- **VALIDATE**: `python3 -m json.tool` n/a; `head -1` frontmatter valid; `ycc/skills/_shared/scripts/validate-file-paths.sh` resolves `${CLAUDE_PLUGIN_ROOT}` refs; command/skill pairing present.

### Task 2.2: Port `ycc:visual-recap` (local-only) (skill + references + command) — Depends on [1.1, 1.3]

- **BATCH**: B2
- **ACTION**: Scaffold via `ycc:bundle-author`, then port. Create `ycc/skills/visual-recap/{SKILL.md,references/wireframe.md}`, optional `scripts/`, and `ycc/commands/visual-recap.md`.
- **IMPLEMENT**: Port recap body but **invert the hosted mandate**: set `AGENT_NATIVE_PLANS_MODE=local-files`, never call `create-visual-recap`/hosted Plan MCP; deliverable is local MDX under `docs/prps/reviews/visual/<slug>/`, served via `plan local serve --open`. Source diffs through `_shared/scripts/visual-recap-collect.sh` (remote-agnostic). `get-plan-blocks` (schema-only, offline fallback) is the only permitted network call.
- **MIRROR**: SKILL_FRONTMATTER, ERROR_HANDLING; visual-plan reference layout.
- **GOTCHA**: Upstream forbids inline Markdown and forces hosting — the ported skill must explicitly state local-only and must not regress to hosted create tools.
- **VALIDATE**: `grep -q 'local-files' ycc/skills/visual-recap/SKILL.md`; `! grep -q 'create-visual-recap' ycc/skills/visual-recap/SKILL.md`; pairing present.

### Task 3.1: Add `--visual` to `prp-plan` — Depends on [2.1]

- **BATCH**: B3
- **ACTION**: Edit `ycc/skills/prp-plan/SKILL.md` and `ycc/commands/prp-plan.md`.
- **IMPLEMENT**: Add a `VISUAL_MODE` case+strip pair to the Phase-0 flag-parse block (copy `--enhanced` at :70-74); add a `--visual` flag-table row (:50-57) and a validation bullet (`--visual` orthogonal; `--dry-run` short-circuits) at :77-82; add a `## Visual mode` block that references `_shared/references/visual-mode.md`; add a post-Phase-6 step "if `VISUAL_MODE` and not `--dry-run`, invoke `ycc:visual-plan <plan-path>`"; add `Visual Artifact`/`Visual Link` fields to the Report block (:417-434). Update command flag row + Usage + one example.
- **MIRROR**: FLAG_PARSE, FLAG_VALIDATION / COMMAND_FLAG_TABLE.
- **GOTCHA**: `--visual` runs after plan write regardless of `--parallel`/`--team` dispatch — keep it dispatch-agnostic.
- **VALIDATE**: `grep -q 'VISUAL_MODE' ycc/skills/prp-plan/SKILL.md`; `grep -q -- '--visual' ycc/commands/prp-plan.md`.

### Task 3.2: Add `--visual` to `plan` (force-write artifact) — Depends on [2.1]

- **BATCH**: B3
- **ACTION**: Edit `ycc/skills/plan/SKILL.md` and `ycc/commands/plan.md`.
- **IMPLEMENT**: Same flag-parse/table/validation pattern (parse near :90-94, table :43-50, validation :97-102). Because `/ycc:plan` writes no artifact by default, `--visual` must **force a plan-file write first**, then invoke `ycc:visual-plan` on it (post-confirmation). Reference `_shared/references/visual-mode.md`.
- **MIRROR**: FLAG_PARSE; Task 3.1 wording (identical canonical block).
- **GOTCHA**: Do not visualize an unwritten plan — the force-write is mandatory for this skill only.
- **VALIDATE**: `grep -q 'VISUAL_MODE' ycc/skills/plan/SKILL.md`; force-write path documented; `grep -q -- '--visual' ycc/commands/plan.md`.

### Task 3.3: Add `--visual` to `plan-workflow` — Depends on [2.1]

- **BATCH**: B3
- **ACTION**: Edit `ycc/skills/plan-workflow/SKILL.md` and `ycc/commands/plan-workflow.md`.
- **IMPLEMENT**: Add `--visual` to the arg-parse step (:96-114), the arg list (:52-64), and the usage block; add the post-final-phase bootstrap invoking `ycc:visual-plan` on the produced plan (feature-dir `parallel-plan.md`). Reference `_shared/references/visual-mode.md`.
- **MIRROR**: FLAG_PARSE; Task 3.1 canonical block.
- **GOTCHA**: Hand off the actual written plan path (feature-dir), not a fixed `docs/prps/plans` path.
- **VALIDATE**: `grep -q -- '--visual' ycc/skills/plan-workflow/SKILL.md ycc/commands/plan-workflow.md`.

### Task 3.4: Add `--visual` to `parallel-plan` — Depends on [2.1]

- **BATCH**: B3
- **ACTION**: Edit `ycc/skills/parallel-plan/SKILL.md` and `ycc/commands/parallel-plan.md`.
- **IMPLEMENT**: Add `--visual` to the arg-parse step (:104-119), arg list (:67-73), dry-run roster/usage; add the post-final-phase bootstrap. Ensure `--visual --dry-run` only prints intent. Reference `_shared/references/visual-mode.md`.
- **MIRROR**: FLAG_PARSE; Task 3.1 canonical block.
- **GOTCHA**: Respect the existing `--dry-run` semantics — short-circuit visual generation in dry-run.
- **VALIDATE**: `grep -q -- '--visual' ycc/skills/parallel-plan/SKILL.md ycc/commands/parallel-plan.md`.

### Task 4.1: Register `plan` MCP connector + regenerate all bundles — Depends on [1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 3.1, 3.2, 3.3, 3.4]

- **BATCH**: B4
- **ACTION**: Edit `mcp-configs/mcp.json` to register the `plan` Agent-Native connector (accept legacy alias `agent-native-plans`), then run `./scripts/sync.sh`.
- **IMPLEMENT**: Add the MCP entry so opencode `opencode.json` translation exposes the hosted path. Run `./scripts/sync.sh` to regenerate inventory + Cursor + Codex + opencode (new skills propagate to all three; new commands propagate to opencode only). Do NOT hand-edit generated files.
- **MIRROR**: Existing `mcp-configs/mcp.json` entry shape.
- **GOTCHA**: This task is the single point where same-file generated bundles are written — it must run after all source edits (hence B4).
- **VALIDATE**: `python3 -m json.tool mcp-configs/mcp.json`; `git status` shows regenerated `.cursor-plugin/`, `.codex-plugin/`, `.opencode-plugin/`, `docs/inventory.json` containing both new skills.

### Task 5.1: Validate (CI loop) — Depends on [4.1]

- **BATCH**: B5
- **ACTION**: Run `./scripts/validate.sh` and the JSON manifest checks.
- **IMPLEMENT**: `./scripts/validate.sh` runs inventory (skill↔command pairing — confirms both new skills have matching commands), cursor/codex/opencode `--check` validators (drift = fail), and JSON manifest checks. Also run `python3 -m json.tool` on `.claude-plugin/marketplace.json` and `ycc/.claude-plugin/plugin.json`, and `find ycc/skills -name "*.sh" -not -executable`.
- **MIRROR**: TEST_STRUCTURE.
- **GOTCHA**: Any drift means Batch 4 regeneration was skipped/partial — re-run `./scripts/sync.sh` then re-validate.
- **VALIDATE**: `./scripts/validate.sh` exits 0; both manifests parse; no non-executable scripts.

---

## Testing Strategy

This repo's verification is structural (no unit-test runner). "Tests" = the validator
pipeline plus targeted greps.

### Validator / Integration

| Check                 | Command                                             | Expected                                  |
| --------------------- | --------------------------------------------------- | ----------------------------------------- |
| Skill↔command pairing | `./scripts/validate.sh --only inventory`            | both new skills paired; no orphan command |
| Cursor bundle drift   | `./scripts/validate.sh --only cursor`               | no drift                                  |
| Codex bundle drift    | `./scripts/validate.sh --only codex`                | no drift                                  |
| opencode bundle drift | `./scripts/validate.sh --only opencode`             | no drift (skills + commands)              |
| JSON manifests        | `./scripts/validate.sh --only json`                 | both parse                                |
| Scripts executable    | `find ycc/skills -name "*.sh" -not -executable`     | empty                                     |
| Path refs resolve     | `ycc/skills/_shared/scripts/validate-file-paths.sh` | all `${CLAUDE_PLUGIN_ROOT}` refs resolve  |

### Edge Cases Checklist

- [ ] `--visual --dry-run` prints intent only; no visual artifact written
- [ ] `/ycc:plan --visual` force-writes a plan file before visualizing
- [ ] `--visual --parallel` and `--visual --team` both run visual generation after dispatch completes
- [ ] visual-recap against the **Forgejo** `origin` produces a local artifact and refuses hosted upload
- [ ] visual-recap against the **github** remote behaves identically (remote-agnostic)
- [ ] egress guard aborts when `.env`/key material is present in the diff
- [ ] hosted link generation fails soft — MDX is still written locally if the link step fails

---

## Validation Commands

### Static / Structural

```bash
./scripts/sync.sh
./scripts/validate.sh
```

EXPECT: regeneration clean; validator exits 0

### JSON Manifests

```bash
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 -m json.tool ycc/.claude-plugin/plugin.json >/dev/null
python3 -m json.tool mcp-configs/mcp.json >/dev/null
```

EXPECT: all parse, no second plugin entry introduced

### Script Hygiene

```bash
find ycc/skills -name "*.sh" -not -executable
bash -n ycc/skills/_shared/scripts/visual-recap-collect.sh
bash -n ycc/skills/_shared/scripts/visual-egress-guard.sh
```

EXPECT: no non-executable scripts; no syntax errors; pinned `shellcheck` clean

### Flag Presence

```bash
for s in prp-plan plan plan-workflow parallel-plan; do
  grep -q -- '--visual' "ycc/skills/$s/SKILL.md" "ycc/commands/$s.md" || echo "MISSING: $s"
done
```

EXPECT: no `MISSING:` output

### Manual Validation

- [ ] `/ycc:prp-plan --visual <feature>` writes `.plan.md` then a `visual/` MDX artifact + link
- [ ] `/ycc:visual-plan docs/prps/plans/<name>.plan.md` renders standalone
- [ ] `/ycc:visual-recap` produces `docs/prps/reviews/visual/<slug>/` with no network upload

---

## Acceptance Criteria

- [ ] `ycc/skills/visual-plan/SKILL.md` + `ycc/skills/visual-recap/SKILL.md` exist with valid frontmatter; reachable as `ycc:visual-plan` / `ycc:visual-recap`
- [ ] `ycc/commands/visual-plan.md` + `ycc/commands/visual-recap.md` exist (pairing satisfied)
- [ ] `--visual` present in `argument-hint` + flag table of all four planning skills and their command docs
- [ ] Each of the four skills sets `VISUAL_MODE` and routes to `ycc:visual-plan` post-generation; `--dry-run` short-circuits; `/ycc:plan` force-writes first
- [ ] `ycc:visual-plan` keeps MDX + hosted link + npx tooling + localhost bridge; contains NO GitHub Action reference; hosted egress consent-gated
- [ ] `ycc:visual-recap` is local-only → `docs/prps/reviews/visual/`; no hosted publish step
- [ ] Both new skills appear in `docs/inventory.json` and all three generated bundles after `./scripts/sync.sh`
- [ ] `./scripts/validate.sh` exits 0; both JSON manifests parse; `ycc:` namespace unchanged; no second plugin entry
- [ ] All new `*.sh` executable + strict-mode + pass pinned `shellcheck`
- **S1** `npx @agent-native/*` invoked at a pinned exact version; pin + egress documented in SKILL
- **S2** hosted upload OFF by default; shareable link requires explicit `--share`/consent naming the destination host
- **S3** visual-recap performs no remote fetch/upload by default
- **S4** diff/recap remote sourcing explicit; upload refused when resolved remote is the private Forgejo `origin`
- **S5** pre-upload secret/denylist scan (`.env*`, keys) aborts on hit
- **S6** localhost bridge binds `127.0.0.1`, ephemeral port + per-session token, origin allowlist
- **S7** new scripts: strict mode, input guards, `case` flag parsing, stdout/stderr discipline, exit 0/1
- **S8** shared bridge/egress/consent logic in one `_shared/scripts` helper reused by all four `--visual` skills
- **S9** `find ycc/skills -name "*.sh" -not -executable` empty; pinned `shellcheck` clean

## Completion Checklist

- [ ] Code follows discovered patterns (FLAG_PARSE, SKILL/COMMAND_FRONTMATTER, ERROR_HANDLING)
- [ ] `--visual` wording identical across all four skills via the shared `visual-mode.md` block
- [ ] Single hand-off contract documented (input = absolute plan path; output = sibling `visual/` + link to stdout)
- [ ] No GitHub Action added; Forgejo posture documented (no `.forgejo/workflows/` created)
- [ ] Remote-agnostic verified (`git remote get-url`/`git merge-base`; no hardcoded `github.com`/`origin/main`); tested against both remotes
- [ ] `npx @agent-native/*` version pinned and recorded in setup reference + command docs
- [ ] `mcp-configs/mcp.json` registers `plan` (alias accepted); manifests validated
- [ ] `./scripts/sync.sh` run; `./scripts/validate.sh` green (CI loop)
- [ ] All `${CLAUDE_PLUGIN_ROOT}` paths resolve; no generated files hand-edited
- [ ] `/goal` pairing decision recorded (include or explicitly skip)
- [ ] No unnecessary scope additions

## Risks

| Risk                                                                                                                               | Likelihood | Impact   | Mitigation                                                                                                                               |
| ---------------------------------------------------------------------------------------------------------------------------------- | ---------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `npx @agent-native/skills@latest` fetches+executes unpinned remote code with full shell/repo privileges (supply-chain / typosquat) | Medium     | Critical | Pin exact version; gate behind explicit `--visual` opt-in; document egress; consider `--ignore-scripts`/lockfile review                  |
| Hosted shareable links upload MDX (may embed private Forgejo code) to `plan.agent-native.com`; cached even after deletion          | High       | Critical | Local-files default; per-invocation consent gate (`--share`) naming the host; never auto-publish; route through `visual-egress-guard.sh` |
| Hosted-link / diff-base hardcodes `github.com` or `origin/main`, breaking the Forgejo `origin`                                     | High       | High     | `git remote get-url <name>` + `git merge-base` only; user-selectable remote; refuse upload on non-public remote                          |
| recap sources refs from whichever remote resolves first; private Forgejo branches leak into a hosted recap                         | Medium     | High     | recap local-only by default; explicit `--remote`; print remote+refspec before generating                                                 |
| localhost bridge over-permissive — any page reads repo content / triggers writes                                                   | Medium     | High     | bind `127.0.0.1`, ephemeral port, per-session token + short TTL, origin allowlist                                                        |
| secrets (`.env`, tokens) serialized into MDX and shipped                                                                           | Medium     | High     | pre-upload denylist scan mirroring `clean/validate-safety.sh`; redact or abort                                                           |
| Four compatibility bundles drift (source edited, bundles not regenerated)                                                          | High       | Medium   | `./scripts/sync.sh` + `./scripts/validate.sh` as a hard completion gate; CI catches drift                                                |
| `--visual` composes inconsistently across the four different plan-output paths                                                     | High       | Medium   | single hand-off contract; visual-plan derives `visual/` from any plan path; `/ycc:plan` force-writes                                     |
| `--visual` added to flag tables but interaction rules (dry-run short-circuit, no-artifact case) omitted on some skills             | Medium     | Medium   | one canonical `visual-mode.md` block referenced by all four                                                                              |
| `--visual` made command-only → silently dropped on Codex, degraded on Cursor                                                       | Medium     | Medium   | implement `--visual` as a SKILL-body branch (skills supported on all targets); command layer documents only                              |

## Notes

- **Confidence: 7/10.** Flag-composition and the bootstrap hand-off are clean and grounded in
  the four skills' existing flag tables (`--enhanced` is the exact model). The soft spot is the
  faithful hosted Agent-Native integration: it pulls an unpinned external toolchain and can
  upload private code — hence the security hardening (consent gate, pinning, egress guard,
  local-files default) layered on top of the faithful port. Pin the `@agent-native/core`
  version during Task 1.1 before writing any committed `npx` invocation.
- **`--visual` is a post-generation decorator, not a dispatch mode.** It runs after the plan is
  written + validated and is invisible to `--parallel`/`--team` dispatch (same property as the
  dispatch-agnostic `validate-prp-plan.sh`). `--dry-run` short-circuits it.
- **Two remotes are real and asymmetric**: `origin` = private Forgejo
  (`git.azules-celsius.ts.net`), `github` = public. Treat `origin` as non-public for egress
  decisions. There is NO `.forgejo/workflows/` today — "Forgejo-aware" here means
  remote-agnostic git sourcing, not authoring CI. If CI recap is ever wanted, mirror to both
  `.forgejo/workflows/` and `.github/workflows/`.
- **`get-plan-blocks` drift**: the upstream block vocabulary changes; the runtime author step
  must re-fetch the live catalog (or offline `plan blocks --out`) rather than trust the
  hardcoded MDX component list in the ported references.
- **MCP connector naming**: register `plan` and accept the legacy alias `agent-native-plans`,
  or hosted tool calls silently no-op.
- **`/goal` pairing decision needed**: `plan.md` is already `/goal`-paired. Adding `/goal`
  support to the new visual skills follows the repo's 4-part recipe (`goal-pairing.md`). This
  plan defers it (NOT Building) — flag to the user whether to fold it in now or as a follow-up.
- **Use `ycc:bundle-author`** to scaffold both new skill+command surfaces rather than
  hand-creating the directory tree; it encodes the source-of-truth split.
