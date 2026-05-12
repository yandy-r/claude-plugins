#!/usr/bin/env python3
"""
Generate Codex-native plugin metadata and marketplace files.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
from pathlib import Path

from generate_codex_common import (
    CODEX_PLUGIN_CONTAINER,
    PLUGIN_MANIFEST_PATH,
    PLUGIN_MCP_PATH,
    PLUGIN_ROOT,
    REPO_MARKETPLACE_PATH,
    SOURCE_MCP_PATH,
    SOURCE_PLUGIN_PATH,
)

REPOSITORY_URL = "https://github.com/yandy-r/claude-plugins"


def load_source_plugin() -> dict:
    return json.loads(SOURCE_PLUGIN_PATH.read_text(encoding="utf-8"))


def build_plugin_manifest() -> dict:
    source = load_source_plugin()
    description = str(source.get("description") or "").replace("Claude Code", "Codex")
    author = source.get("author") or {"name": "yandy-r"}
    version = source.get("version") or "0.0.0"
    return {
        "name": "ycc",
        "version": version,
        "description": description,
        "author": author,
        "repository": REPOSITORY_URL,
        "homepage": REPOSITORY_URL,
        "license": "MIT",
        "keywords": ["codex", "skills", "planning", "development"],
        "skills": "./skills/",
        "mcpServers": "./.mcp.json",
        "interface": {
            "displayName": "YCC",
            "shortDescription": "Planning, implementation, review, and workflow skills for Codex.",
            "longDescription": (
                "Yandy's Codex-native workflow bundle with planning, research, implementation, "
                "review, and GitHub-oriented development skills."
            ),
            "developerName": author.get("name", "yandy-r"),
            "category": "Productivity",
            "capabilities": ["Interactive", "Read", "Write"],
            "websiteURL": REPOSITORY_URL,
            "defaultPrompt": [
                "Use YCC to plan a medium-sized feature before implementation.",
                "Use YCC to review my branch and summarize the highest-risk findings.",
                "Use YCC to orchestrate a multi-step refactor across this repository.",
            ],
            "brandColor": "#0F766E",
        },
    }


def build_repo_marketplace() -> dict:
    return {
        "name": "local-ycc-plugins",
        "interface": {
            "displayName": "Local YCC Plugins",
        },
        "plugins": [
            {
                "name": "ycc",
                "source": {
                    "source": "local",
                    "path": "./plugins/ycc",
                },
                "policy": {
                    "installation": "AVAILABLE",
                    "authentication": "ON_INSTALL",
                },
                "category": "Productivity",
            }
        ],
    }


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    serialized = json.dumps(payload, indent=2) + "\n"
    if path.exists():
        existing = path.read_text(encoding="utf-8")
        if existing == serialized:
            return
    path.write_text(serialized, encoding="utf-8")


def write_all(dest_root: Path, dry_run: bool) -> set[Path]:
    files: set[Path] = set()
    manifest_path = dest_root / PLUGIN_MANIFEST_PATH.relative_to(CODEX_PLUGIN_CONTAINER.parent)
    mcp_path = dest_root / PLUGIN_MCP_PATH.relative_to(CODEX_PLUGIN_CONTAINER.parent)
    marketplace_path = dest_root / REPO_MARKETPLACE_PATH.relative_to(CODEX_PLUGIN_CONTAINER.parent)

    files.add(manifest_path.relative_to(dest_root))
    files.add(mcp_path.relative_to(dest_root))
    files.add(marketplace_path.relative_to(dest_root))

    if dry_run:
        for path in sorted(files):
            print(f"Would write {path}")
        return files

    write_json(manifest_path, build_plugin_manifest())
    mcp_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(SOURCE_MCP_PATH, mcp_path)
    write_json(marketplace_path, build_repo_marketplace())
    return files


def compare_files(generated_root: Path, repo_root: Path, files: set[Path]) -> list[str]:
    diffs: list[str] = []
    for rel in sorted(files):
        generated = generated_root / rel
        repo = repo_root / rel
        if not repo.exists():
            diffs.append(f"missing in repo: {rel}")
            continue
        if generated.read_bytes() != repo.read_bytes():
            diffs.append(f"drift: {rel}")
    return diffs


def run_check() -> int:
    repo_root = CODEX_PLUGIN_CONTAINER.parent
    with tempfile.TemporaryDirectory() as tmp:
        temp_root = Path(tmp)
        files = write_all(temp_root, dry_run=False)
        diffs = compare_files(temp_root, repo_root, files)
        if diffs:
            print(
                "Codex plugin metadata is out of date. Run: ./scripts/generate-codex-plugin.sh",
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
        write_all(CODEX_PLUGIN_CONTAINER.parent, dry_run=True)
        return

    write_all(CODEX_PLUGIN_CONTAINER.parent, dry_run=False)
    print(f"Wrote Codex plugin metadata under {PLUGIN_ROOT}")


if __name__ == "__main__":
    main()
