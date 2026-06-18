# Agent-Native Runtime — Shared Setup Contract

Reference for ycc skills that drive the Agent-Native visual-planning runtime — currently
`${CLAUDE_PLUGIN_ROOT}/skills/visual-plan/SKILL.md` and
`${CLAUDE_PLUGIN_ROOT}/skills/visual-recap/SKILL.md`. Both skills cite this doc so the install
pin, the auth/reconnect flow, the connector names, the localhost bridge, and the egress
policy stay convergent. Fix them here, not per skill (DRY).

The pinned version below was resolved with `npm view @agent-native/core version` at authoring
time. Re-resolve and re-pin before a release if the runtime has advanced — never substitute a
floating `latest` dist-tag into committed content.

---

## Install (pinned)

Install a skill from the Agent-Native core CLI with an **explicit pinned version**:

```
npx -y @agent-native/core@0.59.1 skills add <skill>
```

- The pin (`0.59.1`) is the version resolved via `npm view @agent-native/core version`.
- Never commit a floating `latest` dist-tag — the block vocabulary and CLI surface drift
  between releases, so an unpinned install can silently change behavior. Pin, verify, then bump
  deliberately.

## Reconnect / auth (one-time per client)

Authorize the runtime against the hosted Plans origin once per client. This is a one-time
step per machine/client, not per skill run:

```
npx -y @agent-native/core@0.59.1 reconnect https://plan.agent-native.com --client [claude-code|codex|all]
```

- `--client all` reconnects every detected client at once.
- Re-run only when credentials are revoked or the client is reinstalled.

## MCP connector

The runtime exposes an MCP connector named **`plan`**. The legacy alias **`agent-native-plans`**
still resolves to the same connector — accept either name when detecting an existing
connection, but prefer `plan` in new guidance.

## Local-only operation

For local-only operation (no hosted calls, no auth required), set:

```
AGENT_NATIVE_PLANS_MODE=local-files
```

In this mode the runtime reads and writes plans on the local filesystem only; it does not
contact `plan.agent-native.com`.

## Localhost bridge

To preview a plan locally, use the `plan local` bridge commands against the plan directory:

```
plan local check --dir plans/<slug>
plan local serve --dir plans/<slug> --open
```

- `check` validates the plan files under `plans/<slug>` without serving.
- `serve` binds **127.0.0.1** on an **ephemeral, CLI-chosen port** and opens the preview with
  `--open`.
- The bridge performs **no DB writes** and sends **nothing to any server** — it is a purely
  local render of the on-disk plan.

## Block vocabulary (resolve at USE TIME)

> GOTCHA: The MDX block vocabulary drifts upstream between releases. Do **not** trust any
> hardcoded component/block list in skill bodies or in this doc.

At the runtime-author step (use time, not authoring time), fetch the live block catalog:

- Hosted/connected: call the **`get-plan-blocks`** MCP tool.
- Offline / `local-files` fallback: run `plan blocks --out <path>` to dump the current catalog.

Always render plan MDX against the freshly-fetched block list, never a list memorized in a
skill.

## Egress policy

Hosted upload is **OFF by default** and **consent-gated**:

- No plan content leaves the machine unless the operator passes an explicit `--share` flag
  that names the destination host `plan.agent-native.com`.
- All hosted egress MUST be routed through
  `${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/visual-egress-guard.sh` so the consent check
  and destination allowlist are enforced in one place.
- Localhost bridge usage (above) is not egress: it stays on 127.0.0.1 and writes nothing
  remote.

## Hosted Plans app

- Hosted origin: `https://plan.agent-native.com`.
- Create tools return **absolute, shareable URLs** under that origin.
- Plans backed by a **private repo are org-gated** — only members of the owning org can open
  the shared URL.
