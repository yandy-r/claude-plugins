#!/usr/bin/env python3
"""
Shared helpers for Codex-native generation.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
YCC_DIR = REPO_ROOT / "ycc"
SRC_SKILLS_DIR = YCC_DIR / "skills"
SRC_AGENTS_DIR = YCC_DIR / "agents"

CODEX_PLUGIN_CONTAINER = REPO_ROOT / ".codex-plugin"
PLUGIN_ROOT = CODEX_PLUGIN_CONTAINER / "ycc"
PLUGIN_SKILLS_DIR = PLUGIN_ROOT / "skills"
PLUGIN_SHARED_DIR = PLUGIN_ROOT / "shared"
PLUGIN_MANIFEST_PATH = PLUGIN_ROOT / ".codex-plugin" / "plugin.json"
PLUGIN_MCP_PATH = PLUGIN_ROOT / ".mcp.json"
PLUGIN_AGENTS_DIR = CODEX_PLUGIN_CONTAINER / "agents"
REPO_MARKETPLACE_PATH = REPO_ROOT / ".agents" / "plugins" / "marketplace.json"

SOURCE_PLUGIN_PATH = YCC_DIR / ".claude-plugin" / "plugin.json"
SOURCE_MCP_PATH = REPO_ROOT / "mcp-configs" / "mcp.json"

HOME_INSTALL_PLUGIN_ROOT = "~/.codex/plugins/ycc"


def strip_preamble_before_frontmatter(text: str) -> str:
    """Remove stray lines before the first YAML frontmatter opener."""
    if text.startswith("---"):
        return text

    lines = text.splitlines(keepends=True)
    for index, line in enumerate(lines):
        if line.strip() == "---":
            return "".join(lines[index:])
    return text


def parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    """Return (frontmatter_dict, body)."""
    stripped = strip_preamble_before_frontmatter(text)
    if not stripped.startswith("---\n"):
        return {}, stripped

    end = stripped.find("\n---\n", 4)
    if end == -1:
        return {}, stripped

    raw_frontmatter = stripped[4:end]
    body = stripped[end + 5 :]
    if not raw_frontmatter.strip():
        return {}, body

    data = yaml.safe_load(raw_frontmatter)
    if not isinstance(data, dict):
        return {}, body
    return data, body


def dump_frontmatter(data: dict[str, Any]) -> str:
    serialized = yaml.safe_dump(
        data,
        sort_keys=False,
        allow_unicode=True,
        default_flow_style=False,
    ).rstrip()
    return f"---\n{serialized}\n---\n"


def fix_mcp_malformed_tokens(text: str) -> str:
    """Fix mcp**server**tool typos copied from older prompts."""
    previous = None
    output = text
    while previous != output:
        previous = output
        output = re.sub(
            r"mcp\*\*([a-zA-Z0-9]+)\*\*([a-zA-Z0-9][a-zA-Z0-9.-]*)",
            r"mcp__\1__\2",
            output,
        )
    return output


def load_agent_aliases() -> dict[str, str]:
    aliases: dict[str, str] = {}
    for path in sorted(SRC_AGENTS_DIR.glob("*.md")):
        frontmatter, _ = parse_frontmatter(path.read_text(encoding="utf-8"))
        name = str(frontmatter.get("name") or path.stem)
        aliases[path.stem] = name
        aliases[name] = name
    return aliases


def map_namespaced_reference(name: str, aliases: dict[str, str]) -> str:
    return aliases.get(name, name)


def apply_codex_text_transforms(text: str, aliases: dict[str, str]) -> str:
    output = fix_mcp_malformed_tokens(text)

    # Product/file naming.
    output = output.replace("CLAUDE.md", "AGENTS.md")
    output = output.replace("claude.template.md", "agents.template.md")
    output = output.replace(".claude-plugin/", ".codex-plugin/")

    # Home/config paths.
    output = output.replace("~/.claude/", "~/.codex/")
    output = re.sub(r"\$\{HOME\}/\.claude/", r"${HOME}/.codex/", output)
    output = re.sub(r"\$HOME/\.claude/", r"$HOME/.codex/", output)
    output = output.replace("/.claude/", "/.codex/")
    output = output.replace("../../_shared/scripts", "../../../shared/scripts")

    # Product wording.
    output = output.replace("Claude Code", "Codex")
    output = output.replace("Claude CLI", "Codex CLI")
    output = output.replace("Claude home directory", "Codex home directory")
    output = output.replace("main Claude session", "main Codex session")
    output = output.replace("the main Claude session", "the main Codex session")
    output = output.replace("Restart Claude CLI", "Restart Codex")
    output = output.replace("Claude CLI logs", "Codex logs")
    output = output.replace(
        "set up Claude CLI environment", "set up the Codex environment"
    )
    output = output.replace("closing Claude Code", "closing Codex")
    output = output.replace("a live Claude Code session", "a live Codex session")
    output = re.sub(
        r"\bClaude API with structured output\b",
        "LLM API with structured output",
        output,
    )

    # Skill/command references.
    output = re.sub(
        r"/ycc:([a-zA-Z0-9-]+)",
        lambda match: f"${map_namespaced_reference(match.group(1), aliases)}",
        output,
    )
    output = re.sub(
        r"\bycc:([a-zA-Z0-9-]+)\b",
        lambda match: map_namespaced_reference(match.group(1), aliases),
        output,
    )

    # Claude-specific agent/tool phrasing -> Codex-native wording.
    output = re.sub(
        r'Use the Task tool with \*\*`subagent_type: "([^"]+)"`\*\*',
        lambda match: f"Spawn the `{map_namespaced_reference(match.group(1), aliases)}` custom agent",
        output,
    )
    output = re.sub(
        r'Use the Agent tool with `subagent_type: "([^"]+)"`',
        lambda match: f"Spawn the `{map_namespaced_reference(match.group(1), aliases)}` custom agent",
        output,
    )
    output = re.sub(
        r'`subagent_type: "([^"]+)"`',
        lambda match: f"`{map_namespaced_reference(match.group(1), aliases)}`",
        output,
    )
    output = re.sub(
        r", each with `team_name=\"[^\"]+\"`",
        "",
        output,
    )
    output = output.replace("team_name=", "name=")
    output = output.replace("Task tool calls", "parallel agent runs")
    output = output.replace("Task tool call", "agent run")
    output = output.replace("Task tool", "parallel agent workflow")
    output = output.replace("Agent tool calls", "parallel agent runs")
    output = output.replace("Agent tool call", "agent run")
    output = output.replace("Agent tool", "parallel agent workflow")
    output = output.replace("TodoWrite", "the task tracker")
    output = output.replace("AskUserQuestion", "ask the user")
    output = output.replace("TeamCreate", "create an agent group")
    output = output.replace("TeamDelete", "close the agent group")
    output = output.replace("TaskCreate", "record the task")
    output = output.replace("TaskUpdate", "update the task tracker")
    output = output.replace("TaskList", "the task tracker")
    output = output.replace("TaskGet", "the task details")
    output = output.replace("SendMessage", "send follow-up instructions")
    output = output.replace('message={type: "shutdown_request"}', "a shutdown request")

    if output and not output.endswith("\n"):
        output += "\n"
    return output


def compress_skill_description(text: str, max_length: int = 1024) -> str:
    """Fit a skill description into Codex's current frontmatter limit."""
    normalized = " ".join(text.split())
    if len(normalized) <= max_length:
        return normalized

    # Drop low-value provenance text first.
    normalized = re.sub(r"\s*Adapted from .*?$", "", normalized).strip()
    if len(normalized) <= max_length:
        return normalized

    sentences = re.split(r"(?<=[.!?])\s+", normalized)
    kept: list[str] = []
    for sentence in sentences:
        candidate = " ".join(kept + [sentence]).strip()
        if len(candidate) > max_length:
            break
        kept.append(sentence)

    compressed = " ".join(kept).strip()
    if compressed and len(compressed) <= max_length:
        return compressed

    hard_limit = max_length - 3
    return normalized[:hard_limit].rstrip() + "..."
