#!/usr/bin/env python3
"""Unit tests for scripts/merge_managed_config.py.

Run directly (``python3 scripts/test_merge_managed_config.py``) or through
``./scripts/validate.sh --only config``.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import tomllib

REPO_ROOT = Path(__file__).resolve().parent.parent
HELPER = REPO_ROOT / "scripts" / "merge_managed_config.py"


class MergeHelperTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)
        self.state = self.tmp / "state.json"
        self.addCleanup(self._tmp.cleanup)

    def run_merge(
        self,
        profile: str,
        source: Path,
        destination: Path,
        groups: str,
        *,
        force: bool = False,
        expect_success: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        env = {**os.environ, "YCC_MANAGED_CONFIG_STATE": str(self.state)}
        argv = [
            sys.executable,
            str(HELPER),
            "--profile",
            profile,
            "--source",
            str(source),
            "--destination",
            str(destination),
            "--groups",
            groups,
        ]
        if force:
            argv.append("--force")
        result = subprocess.run(argv, capture_output=True, text=True, env=env)
        if expect_success:
            self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def write_json(self, path: Path, payload: dict) -> Path:
        path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        return path

    # -- JSON merge ------------------------------------------------------

    def test_creates_missing_destination(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        destination = self.tmp / "dest.json"

        self.run_merge("claude-settings", source, destination, "settings")

        self.assertEqual(json.loads(destination.read_text())["model"], "claude-fable-5-1")

    def test_preserves_unknown_destination_keys(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        destination = self.write_json(
            self.tmp / "dest.json",
            {"userOnlyKey": {"nested": True}, "tui": "fullscreen"},
        )

        self.run_merge("claude-settings", source, destination, "settings")

        merged = json.loads(destination.read_text())
        self.assertEqual(merged["userOnlyKey"], {"nested": True})
        self.assertEqual(merged["tui"], "fullscreen")
        self.assertEqual(merged["model"], "claude-fable-5-1")

    def test_object_policy_preserves_sibling_leaves(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"env": {"FORCE_AUTOUPDATE_PLUGINS": "1"}})
        destination = self.write_json(self.tmp / "dest.json", {"env": {"USER_TOKEN": "secret"}})

        self.run_merge("claude-settings", source, destination, "settings")

        env = json.loads(destination.read_text())["env"]
        self.assertEqual(env["USER_TOKEN"], "secret")
        self.assertEqual(env["FORCE_AUTOUPDATE_PLUGINS"], "1")

    def test_map_entries_preserve_unknown_entries(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"mcpServers": {"github": {"url": "https://example"}}})
        destination = self.write_json(self.tmp / "dest.json", {"mcpServers": {"private": {"url": "https://local"}}})

        self.run_merge("claude-mcp", source, destination, "mcp")

        servers = json.loads(destination.read_text())["mcpServers"]
        self.assertIn("private", servers)
        self.assertIn("github", servers)

    def test_list_union_preserves_user_entries(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"plugins": ["@repo/plugin"]})
        destination = self.write_json(self.tmp / "dest.json", {"plugins": ["@user/plugin"]})

        self.run_merge("opencode-config", source, destination, "plugins")

        self.assertEqual(json.loads(destination.read_text())["plugins"], ["@user/plugin", "@repo/plugin"])

    def test_local_edit_wins_without_force(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        destination = self.write_json(self.tmp / "dest.json", {"model": "opus[1m]"})

        result = self.run_merge("claude-settings", source, destination, "settings")

        self.assertEqual(json.loads(destination.read_text())["model"], "opus[1m]")
        self.assertIn("kept your local value", result.stdout)

    def test_force_overrides_local_edit(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        destination = self.write_json(self.tmp / "dest.json", {"model": "opus[1m]"})

        self.run_merge("claude-settings", source, destination, "settings", force=True)

        self.assertEqual(json.loads(destination.read_text())["model"], "claude-fable-5-1")

    def test_repo_update_applies_when_user_never_edited(self) -> None:
        source = self.tmp / "src.json"
        destination = self.tmp / "dest.json"
        self.write_json(source, {"model": "claude-fable-5-1"})

        self.run_merge("claude-settings", source, destination, "settings")
        self.write_json(source, {"model": "claude-fable-6"})
        self.run_merge("claude-settings", source, destination, "settings")

        self.assertEqual(json.loads(destination.read_text())["model"], "claude-fable-6")

    def test_repo_update_defers_to_later_user_edit(self) -> None:
        source = self.tmp / "src.json"
        destination = self.tmp / "dest.json"
        self.write_json(source, {"model": "claude-fable-5-1"})

        self.run_merge("claude-settings", source, destination, "settings")
        self.write_json(destination, {"model": "user-choice"})
        self.write_json(source, {"model": "claude-fable-6"})
        self.run_merge("claude-settings", source, destination, "settings")

        self.assertEqual(json.loads(destination.read_text())["model"], "user-choice")

    def test_idempotent(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        destination = self.tmp / "dest.json"

        self.run_merge("claude-settings", source, destination, "settings")
        first = destination.read_text()
        result = self.run_merge("claude-settings", source, destination, "settings")

        self.assertEqual(destination.read_text(), first)
        self.assertIn("up-to-date", result.stdout)

    def test_symlink_destination_becomes_real_file(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        target = self.write_json(self.tmp / "repo-owned.json", {"tui": "fullscreen"})
        destination = self.tmp / "dest.json"
        destination.symlink_to(target)

        self.run_merge("claude-settings", source, destination, "settings")

        self.assertFalse(destination.is_symlink())
        self.assertEqual(json.loads(target.read_text()), {"tui": "fullscreen"})
        self.assertEqual(json.loads(destination.read_text())["model"], "claude-fable-5-1")

    def test_invalid_destination_json_fails_without_mutation(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        destination = self.tmp / "dest.json"
        destination.write_text("{ not json", encoding="utf-8")

        result = self.run_merge("claude-settings", source, destination, "settings", expect_success=False)

        self.assertEqual(result.returncode, 1)
        self.assertEqual(destination.read_text(), "{ not json")

    def test_state_file_stores_hashes_only(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"env": {"TOKEN": "super-secret-value"}})
        destination = self.tmp / "dest.json"

        self.run_merge("claude-settings", source, destination, "settings")

        self.assertNotIn("super-secret-value", self.state.read_text())
        self.assertIn("last_applied_sha256", self.state.read_text())

    def test_unknown_group_fails(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "x"})
        destination = self.tmp / "dest.json"

        result = self.run_merge("claude-settings", source, destination, "nope", expect_success=False)

        self.assertEqual(result.returncode, 1)
        self.assertFalse(destination.exists())

    # -- TOML merge ------------------------------------------------------

    def test_toml_preserves_comments_and_unmanaged_tables(self) -> None:
        source = self.tmp / "src.toml"
        source.write_text('model = "gpt-6-astra"\n', encoding="utf-8")
        destination = self.tmp / "dest.toml"
        destination.write_text(
            '# my machine\nmodel = "gpt-5.6-sol"\n\n[projects."/home/me/work"]\ntrust_level = "trusted"\n',
            encoding="utf-8",
        )

        self.run_merge("codex-config", source, destination, "settings", force=True)

        text = destination.read_text()
        self.assertIn("# my machine", text)
        self.assertIn('[projects."/home/me/work"]', text)
        self.assertEqual(tomllib.loads(text)["model"], "gpt-6-astra")
        self.assertEqual(tomllib.loads(text)["projects"]["/home/me/work"]["trust_level"], "trusted")

    def test_toml_adds_missing_table(self) -> None:
        source = self.tmp / "src.toml"
        source.write_text('[agents]\ndefault_subagent_model = "gpt-5.6-sol"\n', encoding="utf-8")
        destination = self.tmp / "dest.toml"
        destination.write_text('model = "gpt-6-astra"\n', encoding="utf-8")

        self.run_merge("codex-config", source, destination, "settings")

        parsed = tomllib.loads(destination.read_text())
        self.assertEqual(parsed["agents"]["default_subagent_model"], "gpt-5.6-sol")
        self.assertEqual(parsed["model"], "gpt-6-astra")

    def test_toml_appends_to_existing_table(self) -> None:
        source = self.tmp / "src.toml"
        source.write_text('[agents]\ndefault_subagent_reasoning_effort = "high"\n', encoding="utf-8")
        destination = self.tmp / "dest.toml"
        destination.write_text("[agents]\nenabled = true\n\n[features]\napps = true\n", encoding="utf-8")

        self.run_merge("codex-config", source, destination, "settings")

        parsed = tomllib.loads(destination.read_text())
        self.assertEqual(parsed["agents"]["default_subagent_reasoning_effort"], "high")
        self.assertTrue(parsed["agents"]["enabled"])
        self.assertTrue(parsed["features"]["apps"])

    def test_toml_multiline_array_survives(self) -> None:
        source = self.tmp / "src.toml"
        source.write_text('model = "gpt-6-astra"\n', encoding="utf-8")
        destination = self.tmp / "dest.toml"
        destination.write_text(
            'model = "old"\n\n[tui]\nstatus_line = [\n  "model-with-reasoning",\n  "git-branch",\n]\n',
            encoding="utf-8",
        )

        self.run_merge("codex-config", source, destination, "settings", force=True)

        parsed = tomllib.loads(destination.read_text())
        self.assertEqual(parsed["tui"]["status_line"], ["model-with-reasoning", "git-branch"])
        self.assertEqual(parsed["model"], "gpt-6-astra")

    def test_toml_root_key_inserted_above_tables(self) -> None:
        source = self.tmp / "src.toml"
        source.write_text('model = "gpt-6-astra"\n', encoding="utf-8")
        destination = self.tmp / "dest.toml"
        destination.write_text("[features]\napps = true\n", encoding="utf-8")

        self.run_merge("codex-config", source, destination, "settings")

        parsed = tomllib.loads(destination.read_text())
        self.assertEqual(parsed["model"], "gpt-6-astra")
        self.assertTrue(parsed["features"]["apps"])

    def test_toml_updates_existing_nested_table_leaf(self) -> None:
        """Regression: nested managed tables must patch leaf-wise, not append."""
        source = self.tmp / "src.toml"
        source.write_text('[mcp_servers.github]\nurl = "https://api.githubcopilot.com/mcp"\n', encoding="utf-8")
        destination = self.tmp / "dest.toml"
        destination.write_text(
            '[mcp_servers.github]\nurl = "https://old"\nbearer_token_env_var = "MY_TOKEN"\n',
            encoding="utf-8",
        )

        self.run_merge("codex-config", source, destination, "mcp", force=True)

        parsed = tomllib.loads(destination.read_text())
        self.assertEqual(parsed["mcp_servers"]["github"]["url"], "https://api.githubcopilot.com/mcp")
        self.assertEqual(parsed["mcp_servers"]["github"]["bearer_token_env_var"], "MY_TOKEN")

    def test_toml_updates_existing_quoted_plugin_table(self) -> None:
        source = self.tmp / "src.toml"
        source.write_text('[plugins."ycc@local-ycc-plugins"]\nenabled = true\n', encoding="utf-8")
        destination = self.tmp / "dest.toml"
        destination.write_text('[plugins."ycc@local-ycc-plugins"]\nenabled = false\n', encoding="utf-8")

        self.run_merge("codex-config", source, destination, "plugins", force=True)

        parsed = tomllib.loads(destination.read_text())
        self.assertTrue(parsed["plugins"]["ycc@local-ycc-plugins"]["enabled"])

    def test_toml_agents_table_update_is_not_duplicated(self) -> None:
        source = self.tmp / "src.toml"
        source.write_text('[agents]\ndefault_subagent_model = "gpt-5.6-sol"\n', encoding="utf-8")
        destination = self.tmp / "dest.toml"
        destination.write_text('[agents]\ndefault_subagent_model = "old-model"\n', encoding="utf-8")

        self.run_merge("codex-config", source, destination, "settings", force=True)

        text = destination.read_text()
        self.assertEqual(text.count("[agents]"), 1)
        self.assertEqual(tomllib.loads(text)["agents"]["default_subagent_model"], "gpt-5.6-sol")

    def test_real_codex_config_merges_into_existing_config(self) -> None:
        """End-to-end guard against the committed Codex source shape."""
        source = REPO_ROOT / ".codex-plugin" / "config" / "config.toml"
        destination = self.tmp / "config.toml"
        destination.write_text(
            '# local\nmodel = "gpt-5.6-sol"\n\n'
            '[mcp_servers.github]\nurl = "https://old"\n\n'
            '[projects."/home/me/work"]\ntrust_level = "trusted"\n',
            encoding="utf-8",
        )

        self.run_merge("codex-config", source, destination, "settings,mcp,plugins", force=True)

        parsed = tomllib.loads(destination.read_text())
        self.assertEqual(parsed["model"], "gpt-6-astra")
        self.assertEqual(parsed["agents"]["default_subagent_reasoning_effort"], "high")
        self.assertEqual(parsed["mcp_servers"]["github"]["url"], "https://api.githubcopilot.com/mcp")
        self.assertEqual(parsed["projects"]["/home/me/work"]["trust_level"], "trusted")

    def test_provider_credentials_survive_model_variant_merge(self) -> None:
        """Regression: deep merge must add variants without dropping apiKey."""
        source = REPO_ROOT / ".opencode-plugin" / "opencode.json"
        destination = self.tmp / "opencode.json"
        self.write_json(
            destination,
            {
                "providers": {
                    "openai": {"settings": {"apiKey": "{env:MY_KEY}", "baseURL": "https://proxy.local/v1"}},
                    "9router": {"options": {"apiKey": "sk-private"}},
                }
            },
        )

        self.run_merge("opencode-config", source, destination, "settings")

        providers = json.loads(destination.read_text())["providers"]
        self.assertEqual(providers["openai"]["settings"]["apiKey"], "{env:MY_KEY}")
        self.assertEqual(providers["openai"]["settings"]["baseURL"], "https://proxy.local/v1")
        self.assertEqual(providers["9router"]["options"]["apiKey"], "sk-private")
        self.assertEqual(providers["openai"]["models"]["gpt-5.5"]["variants"][0]["id"], "subagent")

    def test_opencode_mcp_servers_merge_under_servers_key(self) -> None:
        source = REPO_ROOT / ".opencode-plugin" / "opencode.json"
        destination = self.tmp / "opencode.json"
        self.write_json(destination, {"mcp": {"servers": {"private": {"type": "remote", "url": "https://internal"}}}})

        self.run_merge("opencode-config", source, destination, "mcp")

        servers = json.loads(destination.read_text())["mcp"]["servers"]
        self.assertIn("private", servers)
        self.assertIn("github", servers)

    def test_dry_run_does_not_touch_symlink(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        target = self.write_json(self.tmp / "target.json", {"tui": "fullscreen"})
        destination = self.tmp / "dest.json"
        destination.symlink_to(target)

        env = {**os.environ, "YCC_MANAGED_CONFIG_STATE": str(self.state)}
        subprocess.run(
            [
                sys.executable,
                str(HELPER),
                "--profile",
                "claude-settings",
                "--source",
                str(source),
                "--destination",
                str(destination),
                "--groups",
                "settings",
                "--dry-run",
            ],
            capture_output=True,
            text=True,
            env=env,
            check=True,
        )

        self.assertTrue(destination.is_symlink())

    def test_invalid_source_leaves_symlink_intact(self) -> None:
        source = self.tmp / "src.json"
        source.write_text("{ broken", encoding="utf-8")
        target = self.write_json(self.tmp / "target.json", {"tui": "fullscreen"})
        destination = self.tmp / "dest.json"
        destination.symlink_to(target)

        self.run_merge("claude-settings", source, destination, "settings", expect_success=False)

        self.assertTrue(destination.is_symlink())

    def test_symlink_replacement_preserves_restrictive_mode(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        target = self.write_json(self.tmp / "target.json", {"tui": "fullscreen"})
        target.chmod(0o600)
        destination = self.tmp / "dest.json"
        destination.symlink_to(target)

        self.run_merge("claude-settings", source, destination, "settings")

        self.assertFalse(destination.is_symlink())
        self.assertEqual(destination.stat().st_mode & 0o777, 0o600)

    def test_first_run_equal_values_are_adopted_for_future_updates(self) -> None:
        """Regression: an already-matching config must still become tool-owned."""
        source = self.tmp / "src.json"
        destination = self.tmp / "dest.json"
        self.write_json(source, {"model": "claude-fable-5-1"})
        self.write_json(destination, {"model": "claude-fable-5-1"})

        self.run_merge("claude-settings", source, destination, "settings")
        self.write_json(source, {"model": "claude-fable-6"})
        self.run_merge("claude-settings", source, destination, "settings")

        self.assertEqual(json.loads(destination.read_text())["model"], "claude-fable-6")

    def test_state_write_failure_rolls_back_config(self) -> None:
        source = self.write_json(self.tmp / "src.json", {"model": "claude-fable-5-1"})
        destination = self.write_json(self.tmp / "dest.json", {"tui": "fullscreen"})
        blocked_state = self.tmp / "blocked"
        blocked_state.write_text("not a directory", encoding="utf-8")

        env = {**os.environ, "YCC_MANAGED_CONFIG_STATE": str(blocked_state / "state.json")}
        result = subprocess.run(
            [
                sys.executable,
                str(HELPER),
                "--profile",
                "claude-settings",
                "--source",
                str(source),
                "--destination",
                str(destination),
                "--groups",
                "settings",
            ],
            capture_output=True,
            text=True,
            env=env,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(destination.read_text()), {"tui": "fullscreen"})

    def test_cursor_fresh_install_writes_required_permission_keys(self) -> None:
        source = REPO_ROOT / ".cursor-plugin" / "config" / "cli-config.json"
        destination = self.tmp / "cli-config.json"

        self.run_merge("cursor-cli", source, destination, "settings")

        merged = json.loads(destination.read_text())
        self.assertEqual(merged["permissions"]["allow"], [])
        self.assertEqual(merged["permissions"]["deny"], [])
        self.assertEqual(merged["model"]["modelId"], "claude-fable-5-1")

    def test_removed_managed_leaf_is_cleaned_up(self) -> None:
        """Repo transport changes must not leave stale managed fields behind."""
        source = self.tmp / "src.json"
        destination = self.tmp / "dest.json"
        self.write_json(source, {"mcpServers": {"svc": {"command": "npx", "args": ["-y", "old"]}}})

        self.run_merge("claude-mcp", source, destination, "mcp")
        self.write_json(source, {"mcpServers": {"svc": {"type": "http", "url": "https://example"}}})
        self.run_merge("claude-mcp", source, destination, "mcp")

        svc = json.loads(destination.read_text())["mcpServers"]["svc"]
        self.assertEqual(svc, {"type": "http", "url": "https://example"})

    def test_removal_skips_locally_edited_leaf(self) -> None:
        source = self.tmp / "src.json"
        destination = self.tmp / "dest.json"
        self.write_json(source, {"mcpServers": {"svc": {"command": "npx", "url": "https://old"}}})
        self.run_merge("claude-mcp", source, destination, "mcp")

        payload = json.loads(destination.read_text())
        payload["mcpServers"]["svc"]["command"] = "my-local-launcher"
        self.write_json(destination, payload)

        self.write_json(source, {"mcpServers": {"svc": {"url": "https://old"}}})
        self.run_merge("claude-mcp", source, destination, "mcp")

        svc = json.loads(destination.read_text())["mcpServers"]["svc"]
        self.assertEqual(svc["command"], "my-local-launcher")

    def test_removal_never_touches_unmanaged_keys(self) -> None:
        source = self.tmp / "src.json"
        destination = self.tmp / "dest.json"
        self.write_json(source, {"mcpServers": {"svc": {"url": "https://x"}}})
        self.write_json(destination, {"mcpServers": {"mine": {"url": "https://mine"}}, "other": 1})

        self.run_merge("claude-mcp", source, destination, "mcp")
        self.run_merge("claude-mcp", source, destination, "mcp")

        merged = json.loads(destination.read_text())
        self.assertEqual(merged["mcpServers"]["mine"], {"url": "https://mine"})
        self.assertEqual(merged["other"], 1)

    def test_toml_removed_managed_leaf_is_cleaned_up(self) -> None:
        source = self.tmp / "src.toml"
        destination = self.tmp / "dest.toml"
        source.write_text('[mcp_servers.svc]\ncommand = "npx"\nurl = "https://old"\n', encoding="utf-8")
        destination.write_text("# keep me\n", encoding="utf-8")

        self.run_merge("codex-config", source, destination, "mcp")
        source.write_text('[mcp_servers.svc]\nurl = "https://new"\n', encoding="utf-8")
        self.run_merge("codex-config", source, destination, "mcp", force=True)

        text = destination.read_text()
        parsed = tomllib.loads(text)
        self.assertIn("# keep me", text)
        self.assertEqual(parsed["mcp_servers"]["svc"], {"url": "https://new"})

    def test_toml_preserves_unknown_mcp_servers(self) -> None:
        source = self.tmp / "src.toml"
        source.write_text('[mcp_servers.github]\nurl = "https://api.example/mcp"\n', encoding="utf-8")
        destination = self.tmp / "dest.toml"
        destination.write_text('[mcp_servers.private]\nurl = "https://internal"\n', encoding="utf-8")

        self.run_merge("codex-config", source, destination, "mcp")

        parsed = tomllib.loads(destination.read_text())
        self.assertIn("private", parsed["mcp_servers"])
        self.assertIn("github", parsed["mcp_servers"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
