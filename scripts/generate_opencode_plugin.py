#!/usr/bin/env python3
"""
Generate opencode-native plugin metadata: .opencode-plugin/opencode.json and
.opencode-plugin/AGENTS.md.

opencode has no plugin manifest file analogous to Claude Code's plugin.json
or Codex's .codex-plugin/plugin.json. The bundle's top-level config is the
opencode.json we emit here, and the native rules file is AGENTS.md.

opencode.json contents:
- `$schema`: https://opencode.ai/config.json
- `model`: openai/gpt-5.4 (bundle default; users can override globally)
- `instructions`: ["AGENTS.md"] so opencode pulls in the bundle's rules
- `provider.openai.models["gpt-5.4"]`: reasoningEffort=high, textVerbosity=low
  (per the plan §6; high-reasoning default for coding-agent work)
- `mcp`: translated from mcp-configs/mcp.json (Claude Code shape → opencode shape)

AGENTS.md is derived from the repo's CLAUDE.md with opencode text transforms
applied. The repo root AGENTS.md is just a pointer to CLAUDE.md, so we read
CLAUDE.md directly for substantive content.

Source of truth:
- ycc/.claude-plugin/plugin.json (name/version reference, not emitted)
- mcp-configs/mcp.json
- CLAUDE.md
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
    SOURCE_AGENTS_MD_CANDIDATES,
    SOURCE_MCP_PATH,
    apply_opencode_text_transforms,
    load_agent_aliases,
    translate_mcp_servers,
)

DEFAULT_MODEL = "openai/gpt-5.4"
DEFAULT_PROVIDER_CONFIG: dict[str, object] = {
    "openai": {
        "models": {
            "gpt-5.4": {
                "reasoningEffort": "high",
                "textVerbosity": "low",
            }
        }
    }
}


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
        "and it loads `.opencode-plugin/AGENTS.md` via the `instructions` field."
    )
    normalized = re.sub(marketplace_block_pattern, marketplace_block_replacement, normalized)
    normalized = normalized.replace(
        "├── .opencode-plugin/\n│   └── marketplace.json     # single ycc entry",
        "├── .claude-plugin/\n│   └── marketplace.json     # single ycc entry",
    )
    normalized = normalized.replace(
        '│   ├── .opencode-plugin/\n│   │   └── plugin.json      # name: "ycc", version: 2.0.0',
        '│   ├── .claude-plugin/\n│   │   └── plugin.json      # name: "ycc", version: 2.0.0',
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
    return translate_mcp_servers(raw_servers)


def build_opencode_config() -> dict[str, object]:
    config: dict[str, object] = {
        "$schema": "https://opencode.ai/config.json",
        "model": DEFAULT_MODEL,
        "instructions": ["AGENTS.md"],
        "provider": DEFAULT_PROVIDER_CONFIG,
    }
    mcp_block = load_mcp_block()
    if mcp_block:
        config["mcp"] = mcp_block
    return config


def build_agents_md() -> str:
    """Read the richest available source (CLAUDE.md preferred, AGENTS.md
    fallback) and apply opencode text transforms to produce the bundle's
    rules file.
    """
    source_text: str | None = None
    source_used: Path | None = None
    # Prefer CLAUDE.md because repo AGENTS.md is just a pointer.
    preferred = [
        REPO_ROOT / "CLAUDE.md",
        *SOURCE_AGENTS_MD_CANDIDATES,
    ]
    for candidate in preferred:
        if candidate.is_file():
            source_text = candidate.read_text(encoding="utf-8")
            source_used = candidate
            break
    if source_text is None:
        raise SystemExit("opencode plugin generator cannot find CLAUDE.md or AGENTS.md at repo root")

    aliases = load_agent_aliases()
    transformed = apply_opencode_text_transforms(
        source_text,
        aliases,
        rewrite_source_paths=False,
        rewrite_runtime_aliases=False,
    )
    transformed = normalize_agents_runtime_syntax(transformed)

    header = (
        f"<!-- Generated from {source_used.relative_to(REPO_ROOT) if source_used else 'CLAUDE.md'} "
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
