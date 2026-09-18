#!/usr/bin/env python3
"""Verify native runtime configs match ycc/settings/models.json declarations."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import tomllib

REPO_ROOT = Path(__file__).resolve().parent.parent
MODELS = json.loads((REPO_ROOT / "ycc/settings/models.json").read_text(encoding="utf-8"))["targets"]
errors: list[str] = []


def expect(actual: object, wanted: object, label: str) -> None:
    if actual != wanted:
        errors.append(f"{label}: got {actual!r}, expected {wanted!r}")


# Claude native settings
claude = json.loads((REPO_ROOT / "ycc/settings/settings.json").read_text(encoding="utf-8"))
expect(claude.get("model"), MODELS["claude"]["main"]["model"], "Claude main model")
expect(
    claude.get("modelSettings", {}).get(MODELS["claude"]["main"]["model"], {}).get("effortLevel"),
    MODELS["claude"]["main"]["effort"],
    "Claude main effort",
)
expect(
    claude.get("env", {}).get("CLAUDE_CODE_SUBAGENT_MODEL"),
    MODELS["claude"]["subagent"]["model"],
    "Claude subagent model",
)
expect(
    claude.get("env", {}).get("CLAUDE_CODE_SUBAGENT_MODEL_FORCE"),
    "1",
    "Claude subagent model force",
)
expect(
    claude.get("modelSettings", {}).get("claude-opus-5", {}).get("effortLevel"),
    MODELS["claude"]["subagent"]["effort"],
    "Claude subagent effort",
)

# Codex native config
codex = tomllib.loads((REPO_ROOT / ".codex-plugin/config/config.toml").read_text(encoding="utf-8"))
expect(codex.get("model"), MODELS["codex"]["main"]["model"], "Codex main model")
expect(codex.get("model_reasoning_effort"), MODELS["codex"]["main"]["effort"], "Codex main effort")
expect(
    codex.get("agents", {}).get("default_subagent_model"), MODELS["codex"]["subagent"]["model"], "Codex subagent model"
)
expect(
    codex.get("agents", {}).get("default_subagent_reasoning_effort"),
    MODELS["codex"]["subagent"]["effort"],
    "Codex subagent effort",
)

# Cursor main CLI config (subagents are generator-validated separately)
cursor = json.loads((REPO_ROOT / ".cursor-plugin/config/cli-config.json").read_text(encoding="utf-8"))
expect(cursor.get("model", {}).get("modelId"), MODELS["cursor"]["main"]["model"], "Cursor main model")

# OpenCode generated config
opencode = json.loads((REPO_ROOT / ".opencode-plugin/opencode.json").read_text(encoding="utf-8"))
expect(opencode.get("model"), MODELS["opencode"]["main"]["model"], "OpenCode main model")
for agent in ("general", "explore"):
    model = opencode.get("agents", {}).get(agent, {}).get("model", "")
    if not model.endswith("#subagent"):
        errors.append(f"OpenCode {agent} model lacks #subagent variant: {model!r}")

if errors:
    for error in errors:
        print(f"  {error}", file=sys.stderr)
    raise SystemExit(1)

print("OK: runtime model/effort configs match ycc/settings/models.json declarations.")
