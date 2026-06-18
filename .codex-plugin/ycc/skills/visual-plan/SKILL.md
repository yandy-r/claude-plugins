---
name: visual-plan
description: Turn an existing text plan into a rich, interactive visual plan — diagrams,
  file maps, annotated code, open questions, and an optional UI/prototype review surface.
  Read-only with respect to the plan file. Use when the user asks to "make this plan
  visual", "render a visual plan", "create a wireframe/canvas for this plan", "visualize
  the implementation plan", says "/visual-plan", or when a planning skill hands off
  via the shared `--visual` decorator.
---

# Visual Plan (Agent-Native Plans)

Turn an ordinary text plan into a structured, reviewable visual plan. Build the
plan a reader would normally skim in Markdown, but as a scannable document with
editable blocks mixed in: inline diagrams, annotated code, open questions, and
an optional top visual review surface (wireframe canvas, live prototype, or both
in tabs). Architecture and backend plans stay document-only; UI and product
plans start with the top canvas/prototype.

`visual-plan` is the packaged entry point (slash command `/visual-plan`). It
**consumes an existing plan** handed to it — it does not research, dispatch, or
re-plan. The runtime is the Agent-Native Plans CLI/MCP connector; its install
pin, auth/reconnect flow, connector names, localhost bridge, block-catalog
lookup, and egress policy are defined ONCE in
`~/.codex/plugins/ycc/shared/references/agent-native-setup.md`. Read
that file for any setup/auth/serve/egress detail rather than memorizing it here.

## Contract (read first)

This skill is the hand-off target of the shared `--visual` decorator. The full
contract lives in `~/.codex/plugins/ycc/shared/references/visual-mode.md`.
The non-negotiable invariants:

- **Accept ANY plan path.** Never assume `docs/prps/plans` or any fixed
  location. The plan path is supplied by the caller and may live anywhere.
- **Derive `visual/` relative to the given plan path.** Output goes into a
  `visual/` sibling of the plan file — `<dirname of plan>/visual/` — computed
  from the path handed in, never hardcoded.
- **NEVER edit the plan file.** Read it; write only into the derived `visual/`
  directory. The plan artifact stays byte-for-byte intact.
- **NEVER re-run research or dispatch.** Only consume the existing plan.
- **Print exactly one resulting link to stdout** — a hosted shareable URL, a
  localhost preview `http://127.0.0.1:PORT/...`, or `local files only`.

## Arguments

Parse `$ARGUMENTS`:

- **`<path/to/plan.md>`** (required positional) — absolute or repo-relative path
  to the source plan. Read it; derive `visual/` from its directory.
- **`--share`** (optional, **consent flag**) — the explicit, named opt-in to
  hosted egress (destination `plan.agent-native.com`). Without it, the skill
  runs in **local-files** mode and nothing leaves the machine. See **Egress &
  consent** below.

## Mode selection (auto)

Choose the review surface from the source plan's content — do not add visual
chrome by default:

- **UI-first** — work is primarily product UI; review should start with screens.
  Top canvas is the primary surface (`create-ui-plan`).
- **prototype-first** — review should start with a functional live prototype;
  interaction is the main question (`create-prototype-plan`).
- **design-first** — review needs full-fidelity branded screens
  (`create-plan-design`).
- **visual-intake** — only when the user explicitly asks for a questionnaire
  before planning (`create-visual-questions`). Never run it as `/visual-plan`
  preflight.
- **document-only** — architecture, backend, data, refactor, or API plans get NO
  top canvas; inline `diagram` blocks sit next to the relevant prose
  (`create-visual-plan`).

When the source plan is already a Codex / Codex / Markdown / pasted plan,
use it as `planText` and build the review surface from it instead of starting
over. Preserve its useful intent and codebase facts; publish a clean standalone
proposal (no "this revision changes…" framing).

## Block vocabulary — resolve at USE TIME

> The MDX block vocabulary drifts upstream between releases. Do NOT author from a
> memorized tag list — not from this skill, not from the references.

At author time (use time), fetch the live block catalog FIRST:

- Hosted / connected: call the **`get-plan-blocks`** MCP tool.
- Offline / `local-files`: run `plan blocks --out <path>` (per
  `agent-native-setup.md`) and read that file.

Render plan MDX against the freshly-fetched list. The references in this skill
describe block _families_ and quality bars; the catalog is the authority on
exact tag names, required fields, and prop shapes.

## Core workflow

1. **Read the source plan.** Read the file at the given path (read-only). Derive
   the output dir with the thin helper (it computes the `visual/` sibling per the
   contract and never hardcodes a location):

   ```
   OUT="$(~/.codex/plugins/ycc/skills/visual-plan/scripts/derive-visual-dir.sh <plan> --mkdir)"
   ```

   Gather the plan's exact text — do not invent source content.

2. **Resolve blocks.** Call `get-plan-blocks` (or the offline `plan blocks`
   fallback) for the authoritative catalog before authoring any MDX.
3. **Create the plan** with the mode-matched create tool (see Mode selection),
   passing the source as `planText`. For UI/product plans, compose the top canvas
   first with the primary wireframes and annotated states, then write the
   document body with native blocks. For non-visual plans, skip the top surface
   and place `diagram` / `code` / `annotated-code` / `table` blocks next to the
   relevant prose.
4. **Emit files** into the derived `visual/` dir: `plan.mdx` plus, when a canvas
   is used, `canvas.mdx` (and `prototype.mdx` for prototype plans). These are the
   portable source artifacts (per `visual-mode.md`).
5. **Surface the link.** Print exactly one link to stdout (see Contract). In
   local-files mode this is the localhost bridge URL from `plan local serve`
   (127.0.0.1, ephemeral port) or `local files only` if no server is available.
   With `--share`, it is the hosted shareable URL returned by the create tool.
6. **Read feedback** with `get-plan-feedback` before editing, after review, and
   before the final response. Treat anchor details and resolver intent as the
   source of truth for what each comment points at.
7. **Apply changes** with `update-visual-plan`, preferring targeted
   `contentPatches`: `patch-wireframe-html`, `patch-diagram-html`, `update-block`,
   `replace-blocks`, `update-rich-text`, plus `read-visual-plan-source` /
   `patch-visual-plan-source` for source-control-friendly MDX edits. Treat the
   top-level `content` payload as a full replacement, never a partial merge — if a
   full replacement is unavoidable, read the complete source first and carry
   forward every existing block and surface.

## Quality references — read before authoring

These are provider-neutral quality bars. Read the relevant one IN FULL before
authoring; do not paraphrase from memory:

- `~/.codex/plugins/ycc/skills/visual-plan/references/document-quality.md` — the
  plan-document quality bar and block families.
- `~/.codex/plugins/ycc/skills/visual-plan/references/canvas.md` — canvas /
  artboard / annotation mechanics and patch ops.
- `~/.codex/plugins/ycc/skills/visual-plan/references/wireframe.md` — the HTML
  wireframe quality bar (`.wf-*` tokens, surfaces, icons, skeletons).
- `~/.codex/plugins/ycc/skills/visual-plan/references/exemplar.md` — a worked
  example plus the anti-patterns to avoid.

## Planning is read-only

Make NO source edits while building or reviewing the visual plan, and never edit
the input plan file. Begin editing code only after the user approves the
direction. The plan is the approval gate: surface it, name which files/areas the
work touches, and request sign-off.

## Egress & consent (default OFF)

Hosted upload is **OFF by default** and **consent-gated**. The full policy lives
in `~/.codex/plugins/ycc/shared/references/agent-native-setup.md`;
the operational rules for this skill:

- **Default = `local-files`.** Set `AGENT_NATIVE_PLANS_MODE=local-files`. In this
  mode the runtime reads/writes plan files locally and never contacts
  `plan.agent-native.com`. Preview via the localhost bridge
  (`plan local serve --dir <OUT> --open`), which binds 127.0.0.1 on an ephemeral
  port, performs no DB writes, and sends nothing remote — this is **not** egress.
- **`--share` is the only opt-in.** It names the destination host
  `plan.agent-native.com`. Only when the operator passes `--share` may any plan
  content leave the machine.
- **Route all hosted egress through the guard.** Before any MDX/diff payload is
  uploaded, run:

  ```
  ~/.codex/plugins/ycc/shared/scripts/visual-egress-guard.sh \
    --payload <OUT> --destination plan.agent-native.com \
    --consent plan.agent-native.com
  ```

  The guard scans the payload for secrets, refuses non-public/private remotes,
  and requires a consent token matching the destination. If it exits non-zero,
  STOP — do not upload; report the gate that failed.

## Setup, auth, and the localhost bridge

Do not duplicate install/reconnect/serve commands here. For the pinned install
version, the one-time per-client reconnect, the `plan` MCP connector (legacy
alias `agent-native-plans`), local-files mode, and the localhost bridge
(`plan local check` / `plan local serve`), read
`~/.codex/plugins/ycc/shared/references/agent-native-setup.md`. If a
Plans tool returns `needs auth` / `Unauthorized` / `Session terminated`, stop and
give the user the reconnect step from that reference — never reinstall from
scratch to fix auth, and never fall back to inline chat-only plan output.

## Output

Exactly one of the following is printed to stdout, per the `visual-mode.md`
contract:

- a hosted shareable URL under `https://plan.agent-native.com` (only with
  `--share`, after the egress guard passes), or
- a localhost preview `http://127.0.0.1:PORT/...` (default local-files mode), or
- `local files only` when no server/host is available.

The calling planning skill surfaces whatever link this skill prints.
