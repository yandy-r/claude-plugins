#!/usr/bin/env python3
"""Regression tests for OpenCode V2 config validation and MCP translation."""

from __future__ import annotations

import json
import unittest
from pathlib import Path
from typing import Any

from generate_opencode_common import translate_mcp_servers
from validate_opencode_config import validate_config

REPO_ROOT = Path(__file__).resolve().parent.parent


class OpenCodeConfigValidationTestCase(unittest.TestCase):
    def assert_has_error(self, errors: list[str], expected: str) -> None:
        self.assertTrue(
            any(expected in error for error in errors),
            f"expected an error containing {expected!r}; got {errors!r}",
        )

    def test_generated_bundle_is_valid_v2(self) -> None:
        config = json.loads((REPO_ROOT / ".opencode-plugin/opencode.json").read_text(encoding="utf-8"))

        self.assertEqual(validate_config(config), [])

    def test_rejects_v1_and_inert_top_level_fields(self) -> None:
        config: dict[str, Any] = {
            "$schema": "https://opencode.ai/config.json",
            "model": "Frontier",
            "instructions": ["AGENTS.md"],
            "permissions": {"default_policy": "allow"},
            "auto_approve": True,
            "provider": {"9router": {}},
            "plugins": [],
            "mcp": {
                "github": {"type": "local", "command": ["npx"]},
                "servers": {},
            },
        }

        errors = validate_config(config)

        self.assert_has_error(errors, "instructions has no effect in V2")
        self.assert_has_error(errors, "auto_approve is not a documented V2 config field")
        self.assert_has_error(errors, "provider is V1 config; use providers")
        self.assert_has_error(errors, "model='Frontier' is not a 'provider/model' reference")
        self.assert_has_error(errors, "permissions must be an ordered list")
        self.assert_has_error(errors, "sit directly under mcp")

    def test_rejects_v1_nested_fields_and_bad_variant(self) -> None:
        config: dict[str, Any] = {
            "$schema": "https://opencode.ai/config.json",
            "model": "9router/Frontier-Lite",
            "providers": {
                "9router": {
                    "npm": "@ai-sdk/openai-compatible",
                    "options": {"baseURL": "https://example.test/v1"},
                    "models": {
                        "Frontier-Lite": {
                            "modalities": {"input": ["text"], "output": ["text"]},
                            "limit": {"context": 1_000_000},
                        }
                    },
                }
            },
            "agents": {
                "general": {
                    "model": "9router/Frontier-Lite#high",
                    "mode": "subagent",
                },
                "legacy": {
                    "prompt": "Legacy agent prompt",
                    "tools": {},
                    "mode": "worker",
                },
            },
            "plugins": [],
            "mcp": {
                "servers": {
                    "github": {
                        "type": "local",
                        "command": ["npx"],
                        "environment": {
                            "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_API_TOKEN}",
                        },
                    }
                }
            },
        }

        errors = validate_config(config)

        self.assert_has_error(errors, "providers.9router.npm is V1; use package")
        self.assert_has_error(errors, "providers.9router.options is V1; use settings")
        self.assert_has_error(errors, "modalities is V1; use capabilities")
        self.assert_has_error(errors, "limit.output must be an integer token count")
        self.assert_has_error(errors, "selects an undeclared variant")
        self.assert_has_error(errors, "agents.legacy.prompt is V1; use system")
        self.assert_has_error(errors, "agents.legacy.tools is V1; use permissions")
        self.assert_has_error(errors, "mode='worker' must be one of primary, subagent, all")
        self.assert_has_error(errors, "uses a shell placeholder")

    def test_mcp_translation_uses_v2_disabled_field(self) -> None:
        translated = translate_mcp_servers(
            {
                "local": {"command": "npx", "args": ["server"], "enabled": False},
                "remote": {"url": "https://example.test/mcp", "enabled": False},
            }
        )

        self.assertTrue(translated["local"]["disabled"])
        self.assertNotIn("enabled", translated["local"])
        self.assertTrue(translated["remote"]["disabled"])
        self.assertNotIn("enabled", translated["remote"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
