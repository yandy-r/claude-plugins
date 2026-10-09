#!/usr/bin/env python3
"""Regression tests for OpenCode V2 agent permission generation."""

from __future__ import annotations

import unittest

from generate_opencode_agents import convert_tools_to_permissions, transform_agent
from generate_opencode_common import parse_frontmatter

DENY_ALL = {"action": "*", "resource": "*", "effect": "deny"}
ENV_READ_GUARDS = [
    {"action": "read", "resource": "*.env", "effect": "ask"},
    {"action": "read", "resource": "*.env.*", "effect": "ask"},
    {"action": "read", "resource": "*.env.example", "effect": "allow"},
]
EXTERNAL_DIRECTORY_ASK = {"action": "external_directory", "resource": "*", "effect": "ask"}


class OpenCodeAgentGenerationTestCase(unittest.TestCase):
    def test_translates_native_actions_and_preserves_sensitive_read_guards(self) -> None:
        permissions = convert_tools_to_permissions(
            ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "WebFetch", "WebSearch"]
        )

        self.assertEqual(
            permissions,
            [
                DENY_ALL,
                {"action": "read", "resource": "*", "effect": "allow"},
                {"action": "edit", "resource": "*", "effect": "allow"},
                {"action": "glob", "resource": "*", "effect": "allow"},
                {"action": "grep", "resource": "*", "effect": "allow"},
                {"action": "shell", "resource": "*", "effect": "allow"},
                {"action": "webfetch", "resource": "*", "effect": "allow"},
                {"action": "websearch", "resource": "*", "effect": "allow"},
                EXTERNAL_DIRECTORY_ASK,
                *ENV_READ_GUARDS,
            ],
        )

    def test_preserves_scoped_bash_as_shell_rules(self) -> None:
        permissions = convert_tools_to_permissions(["Read", "Bash(ls:*)", "Bash(git status:*)", "Bash(npm:*)"])

        self.assertIn({"action": "shell", "resource": "ls *", "effect": "allow"}, permissions)
        self.assertIn({"action": "shell", "resource": "git status *", "effect": "allow"}, permissions)
        self.assertIn({"action": "shell", "resource": "npm *", "effect": "allow"}, permissions)
        self.assertNotIn({"action": "read", "resource": "ls *", "effect": "allow"}, permissions)
        self.assertIn(EXTERNAL_DIRECTORY_ASK, permissions)

    def test_preserves_commas_inside_one_bash_scope(self) -> None:
        permissions = convert_tools_to_permissions('Bash(python:-c "a,b")')

        self.assertIn(
            {"action": "shell", "resource": 'python -c "a,b"', "effect": "allow"},
            permissions,
        )
        self.assertEqual(sum(rule["action"] == "shell" for rule in permissions), 1)

    def test_restores_external_directory_approval_after_broad_deny(self) -> None:
        permissions = convert_tools_to_permissions(["Read"])

        self.assertLess(permissions.index(DENY_ALL), permissions.index(EXTERNAL_DIRECTORY_ASK))
        self.assertEqual(permissions[-4], EXTERNAL_DIRECTORY_ASK)

        web_only = convert_tools_to_permissions(["WebFetch"])
        self.assertNotIn(EXTERNAL_DIRECTORY_ASK, web_only)

    def test_supports_comma_string_and_native_mcp_actions(self) -> None:
        permissions = convert_tools_to_permissions(
            "Read, LS, Task, AskUserQuestion, mcp__maps-mcp__places-search, "
            "mcp__convex__functionSpec, mcp__github__*, TodoWrite"
        )

        self.assertIn({"action": "glob", "resource": "*", "effect": "allow"}, permissions)
        self.assertIn({"action": "subagent", "resource": "*", "effect": "allow"}, permissions)
        self.assertIn({"action": "question", "resource": "*", "effect": "allow"}, permissions)
        self.assertIn(
            {"action": "maps-mcp_places-search", "resource": "*", "effect": "allow"},
            permissions,
        )
        self.assertIn({"action": "convex_functionSpec", "resource": "*", "effect": "allow"}, permissions)
        self.assertIn({"action": "github_*", "resource": "*", "effect": "allow"}, permissions)
        self.assertFalse(any(rule["action"] == "todowrite" for rule in permissions))

    def test_boolean_mapping_uses_native_case_insensitive_aliases(self) -> None:
        permissions = convert_tools_to_permissions(
            {"read": True, "write": True, "bash": True, "task": True, "websearch": False}
        )

        self.assertIn({"action": "read", "resource": "*", "effect": "allow"}, permissions)
        self.assertIn({"action": "edit", "resource": "*", "effect": "allow"}, permissions)
        self.assertIn({"action": "shell", "resource": "*", "effect": "allow"}, permissions)
        self.assertIn({"action": "subagent", "resource": "*", "effect": "allow"}, permissions)
        self.assertFalse(any(rule["action"] in {"write", "bash", "task", "websearch"} for rule in permissions))

    def test_rejects_non_bash_scopes_instead_of_broadening_them(self) -> None:
        for tool in ("Read(src/**)", "Edit(docs/**)"):
            with self.subTest(tool=tool):
                with self.assertRaisesRegex(ValueError, "only Bash scopes can be translated"):
                    convert_tools_to_permissions([tool])

    def test_explicit_empty_tools_denies_all(self) -> None:
        self.assertEqual(convert_tools_to_permissions([]), [DENY_ALL])

    def test_omitted_tools_inherits_host_defaults(self) -> None:
        output = transform_agent("reader", "---\ndescription: Reader\n---\nRead files.\n", {})
        frontmatter, _ = parse_frontmatter(output)

        self.assertNotIn("permissions", frontmatter)

    def test_transform_emits_only_v2_permission_metadata(self) -> None:
        raw = """---
description: Reviewer
tools: [Read, Grep, Glob]
permission:
  edit: deny
prompt: legacy
temperature: 0.2
top_p: 0.5
disable: true
---
Review code.
"""

        output = transform_agent("reviewer", raw, {})
        frontmatter, _ = parse_frontmatter(output)

        self.assertIn("permissions", frontmatter)
        self.assertTrue(frontmatter["disabled"])
        for legacy in ("tools", "permission", "prompt", "temperature", "top_p", "disable"):
            self.assertNotIn(legacy, frontmatter)


if __name__ == "__main__":
    unittest.main(verbosity=2)
