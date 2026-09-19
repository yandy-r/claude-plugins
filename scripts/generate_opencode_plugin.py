#!/usr/bin/env python3
"""
Generate opencode-native plugin metadata: .opencode-plugin/opencode.json and
.opencode-plugin/AGENTS.md.

opencode has no plugin manifest file analogous to Claude Code's plugin.json
or Codex's .codex-plugin/plugin.json. The bundle's top-level config is the
opencode.json we emit here, and the native rules file is AGENTS.md.

The emitted config targets OpenCode V2 exclusively. Note that
https://opencode.ai/config.json still serves the V1 schema, so it validates the
wrong shapes; scripts/validate_opencode_config.py encodes the V2 field set from
opencode.ai/v2/docs instead. The `$schema` URL is still emitted because editors
use it for autocomplete.

opencode.json contents:
- `$schema`: https://opencode.ai/config.json
- `model`: main model from ycc/settings/models.json (bundle default; users can
  override globally)
- `providers.<provider>.models[<model>]`: reasoningEffort from the models.json
  main entry, textVerbosity=low, plus a `subagent` variant carrying the
  sub-agent reasoning effort. opencode resolves variants as `model#subagent`.
- `agents.general` / `agents.explore`: pin the built-in subagents to the
  sub-agent model variant so delegated work runs at sub-agent effort.
- `plugins`: shared OpenCode V2 plugins loaded by server/runtime

The opencode model values are placeholders (models.json marks the target with
`placeholder: true`) because the usable catalog depends on the user's provider
subscriptions. Machines that need different models override
~/.config/opencode/opencode.json rather than this generated bundle file.
- `mcp`: translated from mcp-configs/mcp.json (Claude Code shape → opencode shape)

AGENTS.md is derived from ycc/settings/rules/CLAUDE.md (the user-global
generic ruleset) with opencode text transforms applied. The install target
for .opencode-plugin/AGENTS.md is ~/.config/opencode/AGENTS.md — i.e., the
user-global opencode rules file — so it must source from the generic
ycc/settings/rules tree, not this repo's project-specific CLAUDE.md.

Source of truth:
- ycc/.claude-plugin/plugin.json (name/version reference, not emitted)
- ycc/settings/models.json
- mcp-configs/mcp.json
- ycc/settings/rules/CLAUDE.md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import tempfile
from pathlib import Path

from generate_opencode_common import (
    OPENCODE_AGENTS_MD_PATH,
    OPENCODE_CONFIG_PATH,
    OPENCODE_PLUGIN_ROOT,
    REPO_ROOT,
    SOURCE_MCP_PATH,
    apply_opencode_text_transforms,
    load_agent_aliases,
    translate_mcp_servers,
)

# .opencode-plugin/AGENTS.md installs into ~/.config/opencode/AGENTS.md as the
# user-global opencode rules file, so it must source from the generic
# user-global rules tree — not this repo's project-specific CLAUDE.md.
SOURCE_RULES_PATH = REPO_ROOT / "ycc" / "settings" / "rules" / "CLAUDE.md"
SOURCE_MODEL_SETTINGS_PATH = REPO_ROOT / "ycc" / "settings" / "models.json"

# OpenCode V2 `plugins` entries (npm package specifiers). The goal plugin adds
# Codex-style goal mode: /goal commands, persistent goal state, and the goal
# tools the user-global AGENTS.md policy references.
DEFAULT_PLUGINS: list[str] = ["@prevalentware/opencode-goal-plugin"]

# Variant ID applied to the sub-agent reasoning effort. opencode selects it as
# `provider/model#subagent` (see opencode.ai/v2/docs/models §Variants).
SUBAGENT_VARIANT_ID = "subagent"

# Built-in opencode subagents that delegated work runs through.
BUILTIN_SUBAGENTS = ("general", "explore")


def load_model_settings() -> dict[str, object]:
    """Load the opencode entry from the shared model/effort source of truth."""
    if not SOURCE_MODEL_SETTINGS_PATH.is_file():
        raise SystemExit(f"opencode plugin generator cannot find {SOURCE_MODEL_SETTINGS_PATH.relative_to(REPO_ROOT)}")

    payload = json.loads(SOURCE_MODEL_SETTINGS_PATH.read_text(encoding="utf-8"))
    target = payload.get("targets", {}).get("opencode")
    if not isinstance(target, dict):
        raise SystemExit(f"{SOURCE_MODEL_SETTINGS_PATH.relative_to(REPO_ROOT)} is missing targets.opencode")

    for field in ("provider", "main", "subagent"):
        if field not in target:
            raise SystemExit(
                f"{SOURCE_MODEL_SETTINGS_PATH.relative_to(REPO_ROOT)}: targets.opencode.{field} is required"
            )
    return target


def split_model_reference(reference: str) -> tuple[str, str]:
    """Split a `provider/model` reference into its two parts."""
    provider, separator, model = reference.partition("/")
    if not separator or not provider or not model:
        raise SystemExit(
            f"{SOURCE_MODEL_SETTINGS_PATH.relative_to(REPO_ROOT)}: expected 'provider/model', got {reference!r}"
        )
    return provider, model


def build_provider_config(settings: dict[str, object]) -> dict[str, object]:
    """Emit provider settings carrying main effort plus a sub-agent variant."""
    provider, model = split_model_reference(str(settings["main"]["model"]))
    subagent_provider, subagent_model = split_model_reference(str(settings["subagent"]["model"]))

    models: dict[str, object] = {
        model: {
            "settings": {
                "reasoningEffort": settings["main"]["effort"],
                "textVerbosity": "low",
            },
            "variants": [
                {
                    "id": SUBAGENT_VARIANT_ID,
                    "settings": {
                        "reasoningEffort": settings["subagent"]["effort"],
                        "textVerbosity": "low",
                    },
                }
            ],
        }
    }

    # A distinct sub-agent model needs its own catalog entry carrying the
    # sub-agent effort; the shared case is already covered by the variant above.
    if (subagent_provider, subagent_model) != (provider, model):
        if subagent_provider != provider:
            raise SystemExit(
                f"{SOURCE_MODEL_SETTINGS_PATH.relative_to(REPO_ROOT)}: opencode main and subagent "
                f"models must share a provider (got {provider!r} and {subagent_provider!r})"
            )
        models[subagent_model] = {
            "settings": {
                "reasoningEffort": settings["subagent"]["effort"],
                "textVerbosity": "low",
            }
        }

    return {provider: {"models": models}}


def build_subagent_model_reference(settings: dict[str, object]) -> str:
    """Return the `provider/model#variant` reference built-in subagents use."""
    provider, model = split_model_reference(str(settings["subagent"]["model"]))
    main_provider, main_model = split_model_reference(str(settings["main"]["model"]))
    if (provider, model) == (main_provider, main_model):
        return f"{provider}/{model}#{SUBAGENT_VARIANT_ID}"
    return f"{provider}/{model}"


def build_agents_config(settings: dict[str, object]) -> dict[str, object]:
    """Pin opencode's built-in subagents to the sub-agent model reference."""
    reference = build_subagent_model_reference(settings)
    return {name: {"model": reference} for name in BUILTIN_SUBAGENTS}


def normalize_agents_runtime_syntax(text: str) -> str:
    """Normalize AGENTS.md invocation examples to canonical `ycc:` form."""
    normalized = text
    normalized = normalized.replace("`/ycc:{command}`", "`ycc:{command}`")
    normalized = normalized.replace('`subagent_type: "ycc:{agent}"`', "`ycc:{agent}`")
    normalized = normalized.replace("`@ycc:{agent}`", "`ycc:{agent}`")
    normalized = normalized.replace("`/ycc:clean`", "`ycc:clean`")
    normalized = normalized.replace("`@codebase-advisor`", "`ycc:codebase-advisor`")
    normalized = normalized.replace("`/clean`", "`ycc:clean`")
    normalized = re.sub(r"`@ycc:([a-z0-9-]+)`", r"`ycc:\1`", normalized)

    normalized = re.sub(
        r"marketplace at `\.opencode-plugin/marketplace\.json`\.",
        "metadata in `.opencode-plugin/opencode.json` with rules in `.opencode-plugin/AGENTS.md`.",
        normalized,
    )
    marketplace_block_pattern = (
        r"The marketplace registry at `\.opencode-plugin/marketplace\.json` contains a single entry:\n\n"
        r"```json\n\{\n  \"name\": \"ycc\",\n  \"version\": \"2\.0\.0\",\n  \"source\": \"\./ycc\"\n\}\n```"
    )
    marketplace_block_replacement = (
        "The opencode bundle metadata is defined in `.opencode-plugin/opencode.json`, "
        "and its rules are installed separately as the global `~/.config/opencode/AGENTS.md`."
    )
    normalized = re.sub(marketplace_block_pattern, marketplace_block_replacement, normalized)
    normalized = normalized.replace(
        "├── .opencode-plugin/\n│   └── marketplace.json     # single ycc entry",
        "├── .claude-plugin/\n│   └── marketplace.json     # single ycc entry",
    )
    normalized = normalized.replace(
        '│   ├── .opencode-plugin/\n│   │   └── plugin.json      # name: "ycc", version bumped by /ycc:bundle-release',
        '│   ├── .claude-plugin/\n│   │   └── plugin.json      # name: "ycc", version bumped by /ycc:bundle-release',
    )

    # opencode bundle metadata shape is opencode.json + AGENTS.md.
    normalized = normalized.replace(
        "1. Validate JSON with `python3 -m json.tool`:\n"
        "   - `python3 -m json.tool .opencode-plugin/marketplace.json`\n"
        "   - `python3 -m json.tool ycc/.opencode-plugin/plugin.json`",
        "1. Validate bundle metadata outputs:\n"
        "   - `python3 -m json.tool .opencode-plugin/opencode.json`\n"
        "   - `test -s .opencode-plugin/AGENTS.md`",
    )
    return normalized


def load_mcp_block() -> dict[str, object]:
    if not SOURCE_MCP_PATH.is_file():
        return {}
    with SOURCE_MCP_PATH.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)
    raw_servers = payload.get("mcpServers")
    if not isinstance(raw_servers, dict):
        return {}
    # Native OpenCode V2 nests named servers under mcp.servers.
    return {"servers": translate_mcp_servers(raw_servers)}


def build_opencode_config() -> dict[str, object]:
    model_settings = load_model_settings()
    # `instructions` is deliberately absent: V2 accepts the field but does not
    # resolve its entries, and the bundle's rules already install as the global
    # ~/.config/opencode/AGENTS.md, which V2 does load.
    config: dict[str, object] = {
        "$schema": "https://opencode.ai/config.json",
        "model": model_settings["main"]["model"],
        "plugins": DEFAULT_PLUGINS,
        "agents": build_agents_config(model_settings),
        # OpenCode V2 uses the plural `providers` key (opencode.ai/v2/docs/config).
        "providers": build_provider_config(model_settings),
    }
    mcp_block = load_mcp_block()
    if mcp_block:
        config["mcp"] = mcp_block
    return config


def build_agents_md() -> str:
    """Read ycc/settings/rules/CLAUDE.md (the user-global generic rules) and
    apply opencode text transforms to produce the bundle's rules file.

    .opencode-plugin/AGENTS.md installs to ~/.config/opencode/AGENTS.md, so it
    must source from the generic user-global rules tree — sourcing from the
    repo-root CLAUDE.md would leak this project's contributor-specific
    guidance into every opencode user's global rules.
    """
    if not SOURCE_RULES_PATH.is_file():
        raise SystemExit(f"opencode plugin generator cannot find {SOURCE_RULES_PATH.relative_to(REPO_ROOT)}")

    source_text = SOURCE_RULES_PATH.read_text(encoding="utf-8")

    aliases = load_agent_aliases()
    transformed = apply_opencode_text_transforms(
        source_text,
        aliases,
        rewrite_source_paths=False,
        rewrite_runtime_aliases=False,
    )
    transformed = normalize_agents_runtime_syntax(transformed)

    header = (
        f"<!-- Generated from {SOURCE_RULES_PATH.relative_to(REPO_ROOT)} "
        "by scripts/generate_opencode_plugin.py — do not edit by hand. -->\n\n"
    )
    return header + transformed


def write_json(path: Path, payload: dict, *, dry_run: bool) -> None:
    serialized = json.dumps(payload, indent=2) + "\n"
    if dry_run:
        print(f"Would write {path.relative_to(REPO_ROOT)} ({len(serialized)} bytes)")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == serialized:
        return
    path.write_text(serialized, encoding="utf-8")


def write_text(path: Path, content: str, *, dry_run: bool) -> None:
    if dry_run:
        print(f"Would write {path.relative_to(REPO_ROOT)} ({len(content)} bytes)")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return
    path.write_text(content, encoding="utf-8")


def write_all(dest_root: Path, dry_run: bool) -> dict[str, Path]:
    config_dest = dest_root / OPENCODE_CONFIG_PATH.relative_to(OPENCODE_PLUGIN_ROOT)
    agents_dest = dest_root / OPENCODE_AGENTS_MD_PATH.relative_to(OPENCODE_PLUGIN_ROOT)

    write_json(config_dest, build_opencode_config(), dry_run=dry_run)
    write_text(agents_dest, build_agents_md(), dry_run=dry_run)
    return {"config": config_dest, "rules": agents_dest}


def run_check() -> int:
    diffs: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        temp_root = Path(tmp)
        write_all(temp_root, dry_run=False)
        for rel in (
            OPENCODE_CONFIG_PATH.relative_to(OPENCODE_PLUGIN_ROOT),
            OPENCODE_AGENTS_MD_PATH.relative_to(OPENCODE_PLUGIN_ROOT),
        ):
            generated = temp_root / rel
            committed = OPENCODE_PLUGIN_ROOT / rel
            if not committed.exists():
                diffs.append(f"missing in repo: {rel}")
                continue
            if generated.read_bytes() != committed.read_bytes():
                diffs.append(f"drift: {rel}")

    if diffs:
        print(
            "opencode plugin metadata is out of date. Run: ./scripts/generate-opencode-plugin.sh",
            file=sys.stderr,
        )
        for diff in diffs:
            print(f"  {diff}", file=sys.stderr)
        return 1
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Exit 1 if generated output drifts")
    parser.add_argument("--dry-run", action="store_true", help="Print what would be written")
    args = parser.parse_args()

    if args.check:
        sys.exit(run_check())

    if args.dry_run:
        write_all(OPENCODE_PLUGIN_ROOT, dry_run=True)
        return

    OPENCODE_PLUGIN_ROOT.mkdir(parents=True, exist_ok=True)
    write_all(OPENCODE_PLUGIN_ROOT, dry_run=False)
    print(f"Wrote opencode plugin metadata under {OPENCODE_PLUGIN_ROOT}")


if __name__ == "__main__":
    main()
