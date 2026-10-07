#!/usr/bin/env python3
"""Unit tests for scripts/codex_marketplace.py.

Run directly (``python3 scripts/test_codex_marketplace.py``) or through
``./scripts/validate.sh --only config``.
"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HELPER = REPO_ROOT / "scripts" / "codex_marketplace.py"


class CodexMarketplaceTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)
        self.dest = self.tmp / "marketplace.json"
        self.addCleanup(self._tmp.cleanup)

    def run_helper(self, *args: str, expect_success: bool = True) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [sys.executable, str(HELPER), *args],
            capture_output=True,
            text=True,
        )
        if expect_success:
            self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def merge(
        self, mode: str = "local", src: str = "./.agents/plugins/ycc", expect_success: bool = True
    ) -> subprocess.CompletedProcess[str]:
        return self.run_helper("merge", str(self.dest), mode, src, expect_success=expect_success)

    def test_merge_local_missing_file(self) -> None:
        self.merge()
        text = self.dest.read_text(encoding="utf-8")
        self.assertTrue(text.endswith("\n"))
        data = json.loads(text)
        self.assertEqual(data["name"], "local-ycc-plugins")
        self.assertEqual(data["interface"], {"displayName": "Local YCC Plugins"})
        self.assertEqual(len(data["plugins"]), 1)
        self.assertEqual(
            data["plugins"][0]["source"],
            {"source": "local", "path": "./.agents/plugins/ycc"},
        )

    def test_merge_local_rejects_non_relative_path(self) -> None:
        result = self.merge(src="/abs/ycc", expect_success=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("must start with ./", result.stderr)
        self.assertFalse(self.dest.exists())

    def test_merge_repo(self) -> None:
        self.merge("repo")
        data = json.loads(self.dest.read_text(encoding="utf-8"))
        self.assertEqual(
            data["plugins"][0]["source"],
            {"source": "github", "repo": "yandy-r/claude-plugins", "ref": "main"},
        )

    def test_merge_preserves_and_replaces_in_place(self) -> None:
        other = {"name": "other", "source": {"source": "github", "repo": "a/b"}}
        self.dest.write_text(
            json.dumps({"name": "custom", "interface": {"displayName": "Custom"}, "plugins": [other]}),
            encoding="utf-8",
        )
        self.merge()
        self.merge()
        data = json.loads(self.dest.read_text(encoding="utf-8"))
        self.assertEqual(data["name"], "custom")
        self.assertEqual(data["interface"], {"displayName": "Custom"})
        self.assertEqual([p["name"] for p in data["plugins"]], ["other", "ycc"])
        self.assertEqual(other["source"], {"source": "github", "repo": "a/b"})

    def test_merge_rejects_root_array(self) -> None:
        self.dest.write_text("[]", encoding="utf-8")
        result = self.merge(expect_success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must contain a JSON object", result.stderr)

    def test_remove_keeps_other_plugins(self) -> None:
        other = {"name": "other", "source": {"source": "github", "repo": "a/b"}}
        self.dest.write_text(
            json.dumps({"name": "custom", "plugins": [other, {"name": "ycc"}]}),
            encoding="utf-8",
        )
        result = self.run_helper("remove", str(self.dest))
        self.assertIn("removed the ycc entry from", result.stdout)
        data = json.loads(self.dest.read_text(encoding="utf-8"))
        self.assertEqual(data["plugins"], [other])

    def test_remove_deletes_scaffold_only_file(self) -> None:
        self.merge()
        result = self.run_helper("remove", str(self.dest))
        self.assertIn("only the ycc entry was left", result.stdout)
        self.assertFalse(self.dest.exists())

    def test_remove_no_ycc_entry_noop(self) -> None:
        original = '{"name":"custom","plugins":[{"name":"other"}]}\n'
        self.dest.write_text(original, encoding="utf-8")
        result = self.run_helper("remove", str(self.dest))
        self.assertIn("nothing to remove", result.stdout)
        self.assertEqual(self.dest.read_text(encoding="utf-8"), original)


if __name__ == "__main__":
    unittest.main()
