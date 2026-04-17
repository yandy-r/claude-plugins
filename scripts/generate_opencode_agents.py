#!/usr/bin/env python3
"""
Generate opencode-native agents under .opencode-plugin/agents from ycc/agents.

opencode reads agents from <workspace>/.opencode/agents/<name>.md or
~/.config/opencode/agents/<name>.md. The filename stem becomes the agent
name; ``name`` in frontmatter is not required (and is dropped here).

Authoritative opencode agent frontmatter (per opencode.ai/docs/agents):
    description (required), mode, model, prompt, tools (deprecated),
    permission, temperature, top_p, steps, disable, hidden, color.

This generator performs:
1. Strips `name` / `title` / unknown Claude-specific fields.
2. Maps `model` via the opencode_model_aliases.json table. Unknown model
   values are dropped (opencode falls back to the global config default).
3. Converts `tools: [PascalCase, ...]` to `tools: {lowercase: bool, ...}`,
   dropping Claude-only tools (Task, TodoWrite, TeamCreate, ...).
4. Rewrites body text with opencode-native phrasing via
   apply_opencode_text_transforms.

Source of truth: ycc/agents/*.md.
"""

from __future__ import annotations

import argparse
import filecmp
import sys
import tempfile
from pathlib import Path

from generate_opencode_common import (
    OPENCODE_AGENTS_DIR,
    SRC_AGENTS_DIR,
    apply_opencode_text_transforms,
    dump_frontmatter,
    is_model_drop_sentinel,
    load_agent_aliases,
    load_model_aliases,
    map_model,
    map_tool_name,
    parse_frontmatter,
)


def convert_tools(value: object) -> dict[str, bool]:
    """Convert Claude ``tools`` into opencode's lowercase-keyed mapping.

    - List form (``[Read, Grep, Bash(ls:*)]``) → ``{read: true, grep: true, bash: true}``.
    - Dict form already keyed lowercase → preserved.
    - Anything else → empty dict (nothing is allowed by default).

    Claude-only tool names (Task, TodoWrite, ...) are dropped entirely.
    """
    resolved: dict[str, bool] = {}

    if isinstance(value, list):
        for item in value:
            if not isinstance(item, str):
                continue
            mapped = map_tool_name(item)
            if mapped is None:
                continue
            # Permit: later occurrences of the same tool cannot *disable* an
            # earlier allow, and we have no need for wildcards here.
            resolved[mapped] = True
        return resolved

    if isinstance(value, dict):
        for key, enabled in value.items():
            if not isinstance(key, str):
                continue
            mapped = map_tool_name(key)
            if mapped is None:
                continue
            # Preserve boolean-like semantics; non-bool values become False
            # to avoid injecting provider-specific permission grammar here.
            resolved[mapped] = bool(enabled)
        return resolved

    return resolved


def transform_agent(
    stem: str,
    raw: str,
    aliases: dict[str, str],
    model_aliases: dict[str, str],
) -> str:
    frontmatter, body = parse_frontmatter(raw)

    # Description is required by opencode. Fall back to the filename stem as a
    # last-resort placeholder so the generator never emits a frontmatter
    # missing the required field — a validator flags empty descriptions.
    description = str(frontmatter.get("description") or "").strip()
    transformed_description = apply_opencode_text_transforms(description, aliases).strip()
    if not transformed_description:
        transformed_description = f"{stem} agent"

    payload: dict[str, object] = {"description": transformed_description}

    raw_model = frontmatter.get("model")
    model_value = map_model(raw_model, model_aliases)
    if model_value:
        payload["model"] = model_value
    elif raw_model and not is_model_drop_sentinel(str(raw_model)):
        print(
            f"generate_opencode_agents: WARN unmapped model " f"'{raw_model}' on {stem}.md — dropping model field",
            file=sys.stderr,
        )

    if "tools" in frontmatter:
        tools_map = convert_tools(frontmatter["tools"])
        if tools_map:
            payload["tools"] = tools_map

    for passthrough in (
        "mode",
        "permission",
        "prompt",
        "temperature",
        "top_p",
        "steps",
        "disable",
        "hidden",
        "color",
    ):
        if passthrough in frontmatter and frontmatter[passthrough] not in (None, "", []):
            payload[passthrough] = frontmatter[passthrough]

    transformed_body = apply_opencode_text_transforms(body, aliases)
    return dump_frontmatter(payload) + transformed_body


def write_all(dest: Path, dry_run: bool) -> set[Path]:
    aliases = load_agent_aliases()
    model_aliases = load_model_aliases()
    written: set[Path] = set()

    for src in sorted(SRC_AGENTS_DIR.glob("*.md")):
        stem = src.stem
        output = transform_agent(
            stem,
            src.read_text(encoding="utf-8"),
            aliases,
            model_aliases,
        )
        target = dest / f"{stem}.md"
        written.add(target.relative_to(dest))
        if dry_run:
            print(f"Would write {target.relative_to(dest)}")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(output, encoding="utf-8")

    if not dry_run:
        existing = sorted(dest.glob("*.md"))
        for path in existing:
            if path.relative_to(dest) not in written:
                path.unlink()
    return written


def compare_trees(generated: Path, repo_dest: Path) -> list[str]:
    gen_files = {path.relative_to(generated) for path in generated.glob("*.md")}
    repo_files = {path.relative_to(repo_dest) for path in repo_dest.glob("*.md")} if repo_dest.is_dir() else set()

    diffs: list[str] = []
    for rel in sorted(gen_files | repo_files):
        if rel not in repo_files:
            diffs.append(f"missing in repo: {rel}")
            continue
        if rel not in gen_files:
            diffs.append(f"extra in repo: {rel}")
            continue
        if not filecmp.cmp(generated / rel, repo_dest / rel, shallow=False):
            diffs.append(f"drift: {rel}")
    return diffs


def run_check() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        temp_root = Path(tmp)
        write_all(temp_root, dry_run=False)
        diffs = compare_trees(temp_root, OPENCODE_AGENTS_DIR)
        if diffs:
            print(
                "opencode agents are out of date. Run: ./scripts/generate-opencode-agents.sh",
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
        if not OPENCODE_AGENTS_DIR.is_dir():
            print(
                f"Missing {OPENCODE_AGENTS_DIR}; run generator without --check first.",
                file=sys.stderr,
            )
            sys.exit(1)
        sys.exit(run_check())

    if args.dry_run:
        write_all(OPENCODE_AGENTS_DIR, dry_run=True)
        return

    OPENCODE_AGENTS_DIR.mkdir(parents=True, exist_ok=True)
    write_all(OPENCODE_AGENTS_DIR, dry_run=False)
    count = sum(1 for _ in OPENCODE_AGENTS_DIR.glob("*.md"))
    print(f"Wrote {count} files under {OPENCODE_AGENTS_DIR}")


if __name__ == "__main__":
    main()
