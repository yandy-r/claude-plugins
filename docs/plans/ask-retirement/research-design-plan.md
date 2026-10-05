# YAN-703 / GH #203 — Retire the `ask` Router Skill and Command

## Research

- `ycc/skills/ask/SKILL.md` was a thin router: classify query (guidance / impact /
  comparison), then always dispatch to `subagent_type: "ycc:codebase-advisor"`, plus a
  read-only boundary reminder.
- `ycc/commands/ask.md` (`/ycc:ask`) duplicated the same classification + dispatch
  inline.
- `references/response-patterns.md` existed only for the skill's response templates.
- `ycc/agents/codebase-advisor.md` (untouched) already covers the three operating
  modes, a read-only tool allowlist, and stating uncertainty/evidence gaps — so the
  router's framing content had no unique behavior to inherit. No alias or shared
  reference file was needed.
- Remaining mentions after removal were descriptive only: `plugin.json` /
  `marketplace.json` descriptions ("orchestration, ask, and project utilities") and
  two `bundle-author` reference examples. Historical consolidation plan
  (`docs/plans/2026-04-07-consolidate-plugins-to-ycc.md`) intentionally left as-is.

## Design

- Delete the router layer entirely; keep `codebase-advisor` as the single read-only
  entry point, invoked directly.
- README gets one migration block (outside `GENERATED-*` regions) telling users:
  ask the main session to delegate to `ycc:codebase-advisor`, request explicit
  search gaps / assumptions / analyzed-vs-skipped scope, and request implementation
  separately.
- Replace the `when-not-to-scaffold.md` "one-off task" example (`ycc:ask`) with direct
  delegation to `ycc:codebase-advisor`; drop the `ask.md` command example from
  `surface-map.md` (`plan.md` already suffices).
- Plugin descriptions drop the named `ask` offering; names and versions unchanged.
- No alias, no shared reference, no changes to the advisor, model mapping,
  `RELEASING.md`, `CHANGELOG.md`, or release notes.

## Approval and Target

- User approved deletion and explicitly chose a **v5.2.x minor, non-breaking commit
  (no `!`)**, accepting the architect's noted removal impact (retired invocation
  surfaces) as a migration note rather than a breaking bump.

## Plan (executed)

1. `git rm` `ycc/skills/ask/SKILL.md`,
   `ycc/skills/ask/references/response-patterns.md`, `ycc/commands/ask.md`.
2. Edit `ycc/skills/bundle-author/references/when-not-to-scaffold.md` and
   `surface-map.md` as above.
3. Edit descriptions in `ycc/.claude-plugin/plugin.json` and
   `.claude-plugin/marketplace.json` (names/versions untouched).
4. Add README migration block outside generated regions.
5. Run `./scripts/sync.sh` then `./scripts/validate.sh` (generated outputs changed
   only via sync).
6. Write this record.

## Verification

Performed (this change):

- `./scripts/sync.sh` — pass. Inventory now 51 skills / 50 commands / 55 agents;
  removed generated copies under `.cursor-plugin/`, `.codex-plugin/`, and
  `.opencode-plugin/` came from sync, not hand edits.
- `./scripts/validate.sh` — pass (inventory cursor codex opencode json config
  release mods).
- `python3 -m json.tool` on both edited JSONs — pass.
- Grep `ycc:ask|/ycc:ask|commands/ask|skills/ask` across `ycc/`, `README.md`,
  `docs/plans/` — only the README migration note, the historical 2.0.0 consolidation
  plan, and substring noise (`orchestrate`, `prp-implement`).
- Assertion check below — pass at time of writing.

Claims and limitations:

- The check proves path absence and advisor byte-identity against `git origin/main`
  (`436f553`). It does not exercise live Claude Code session loading, target-plugin
  installs, or model mapping — validator sweep covers structure only.
- Live `/ycc:` invocation testing (CLAUDE.md step 4) not performed here; owned by the
  parent orchestrator and independent code review.

## Runnable assertion check (stdlib only, no test file)

Run from repo root:

```bash
git fetch origin main --quiet 2>/dev/null; \
[ ! -e ycc/skills/ask ] && [ ! -e ycc/commands/ask.md ] \
  && [ ! -e .cursor-plugin/skills/ask ] && [ ! -e .codex-plugin/ycc/skills/ask ] \
  && [ ! -e .opencode-plugin/skills/ask ] && [ ! -e .opencode-plugin/commands/ask.md ] \
  && git diff --quiet 436f553 -- ycc/agents/codebase-advisor.md \
  && echo "ask-retirement assertions: PASS" || echo "ask-retirement assertions: FAIL"
```
