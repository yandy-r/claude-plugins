#!/usr/bin/env python3
"""Tests for scripts/generate_codex_mcp.py (mcp.json -> Codex MCP translation).

Run directly (``python3 scripts/test_generate_codex_mcp.py``) or through
``./scripts/validate.sh --only config``.
"""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from generate_codex_common import SOURCE_MCP_PATH  # noqa: E402
from generate_codex_mcp import (  # noqa: E402
    CodexMcpError,
    build_codex_mcp_config,
    build_codex_mcp_servers,
    translate_server,
)


class TranslateServerTestCase(unittest.TestCase):
    def test_remote_server(self) -> None:
        raw = {"type": "http", "url": "https://x", "headers": {"A": "b"}}
        self.assertEqual(translate_server("x", raw), {"url": "https://x", "http_headers": {"A": "b"}})

    def test_local_server_passes_same_name_env_through(self) -> None:
        raw = {"command": "npx", "args": ["-y", "pkg"], "env": {"TOKEN": "${TOKEN}", "MODE": "ro"}}
        self.assertEqual(
            translate_server("x", raw),
            {"command": "npx", "args": ["-y", "pkg"], "env_vars": ["TOKEN"], "env": {"MODE": "ro"}},
        )

    def test_renamed_env_reference_is_rejected(self) -> None:
        with self.assertRaises(CodexMcpError):
            translate_server("x", {"command": "npx", "env": {"A": "${B}"}})

    def test_override_replaces_translation_and_keeps_source_order(self) -> None:
        source = {"a": {"url": "https://a"}, "b": {"url": "https://b"}}
        servers = build_codex_mcp_servers(source, {"a": {"url": "https://override"}, "c": {"url": "https://c"}})
        self.assertEqual(list(servers), ["a", "b", "c"])
        self.assertEqual(servers["a"], {"url": "https://override"})

    def test_parity_with_mcp_json(self) -> None:
        source = json.loads(SOURCE_MCP_PATH.read_text(encoding="utf-8"))["mcpServers"]
        codex = build_codex_mcp_config()["mcp_servers"]
        self.assertTrue(set(source) <= set(codex), set(source) - set(codex))


if __name__ == "__main__":
    unittest.main(verbosity=2)
