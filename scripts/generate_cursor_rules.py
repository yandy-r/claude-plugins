#!/usr/bin/env python3
"""
Generate Cursor-native rules under .cursor-plugin/rules from ycc/rules.

Converts nested ycc/rules/**/*.md to **/*.mdc with frontmatter, mirrors tree exactly.
Source of truth: ycc/rules/
"""

from __future__ import annotations

import argparse
import re
import stat
import sys
import tempfile
from pathlib import Path

import yaml

# Import shared text transforms from skills generator (same repo scripts/)
_SCRIPTS_DIR = Path(__file__).resolve().parent
if str(_SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS_DIR))
from generate_cursor_skills import apply_skills_text_transforms

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "ycc" / "rules"
DST_DIR = REPO_ROOT / ".cursor-plugin" / "rules"

# Standard web globs (matches prior flattened web__*.mdc rules)
WEB_STANDARD_GLOBS: list[str] = [
    "**/*.html",
    "**/*.css",
    "**/*.scss",
    "**/*.sass",
    "**/*.less",
    "**/*.js",
    "**/*.mjs",
    "**/*.cjs",
    "**/*.ts",
    "**/*.mts",
    "**/*.cts",
    "**/*.jsx",
    "**/*.tsx",
    "**/*.vue",
    "**/*.svelte",
]


def fix_markdown_links_md_to_mdc(body: str) -> str:
    """Rewrite relative .md links in markdown to .mdc (preserve anchors)."""

    def repl_paren(match: re.Match[str]) -> str:
        url = match.group(1)
        if "://" in url:
            return match.group(0)
        if "#" in url:
            base, frag = url.split("#", 1)
            frag = "#" + frag
        else:
            base, frag = url, ""
        if base.endswith(".md"):
            base = base[:-3] + ".mdc"
        return f"]({base}{frag})"

    out = re.sub(r"\]\(([^)]+)\)", repl_paren, body)

    def repl_full(m: re.Match[str]) -> str:
        text, url = m.group(1), m.group(2)
        if "://" in url:
            return m.group(0)
        if text.endswith(".md"):
            text = text[:-3] + ".mdc"
        if "#" in url:
            base, _, frag = url.partition("#")
            frag = "#" + frag
        else:
            base, frag = url, ""
        if base.endswith(".md"):
            base = base[:-3] + ".mdc"
        return f"[{text}]({base}{frag})"

    out = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", repl_full, out)
    return out


def extract_first_heading(body: str) -> str | None:
    m = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
    return m.group(1).strip() if m else None


def title_case_stem(stem: str) -> str:
    return " ".join(
        w.capitalize() for w in stem.replace("-", " ").replace("_", " ").split()
    )


def default_description(rel: Path, body: str) -> str:
    h = extract_first_heading(body)
    if h:
        return h
    return title_case_stem(rel.stem)


def parse_frontmatter(raw: str) -> tuple[bool, dict, str]:
    """Returns (has_yaml_block, data, body_without_frontmatter_if_present)."""
    if not raw.startswith("---\n"):
        return False, {}, raw
    end = raw.find("\n---\n", 4)
    if end == -1:
        return False, {}, raw
    fm_text = raw[4:end]
    body = raw[end + 5 :]
    if not fm_text.strip():
        return True, {}, body
    data = yaml.safe_load(fm_text)
    if data is None:
        data = {}
    if not isinstance(data, dict):
        data = {}
    return True, data, body


def normalize_rule_frontmatter(
    rel: Path,
    data: dict,
    body: str,
) -> dict:
    """Normalize Claude-style rule YAML to Cursor .mdc frontmatter."""
    out = dict(data)

    if "paths" in out and "globs" not in out:
        out["globs"] = out.pop("paths")

    parts = rel.parts
    # rel like common/coding-style.md or web/patterns.md
    top = parts[0] if parts else ""

    if "description" not in out or not out["description"]:
        out["description"] = default_description(rel, body)

    if top == "common":
        out["alwaysApply"] = True
        if "globs" in out:
            del out["globs"]
    elif top == "web":
        stem = rel.stem
        if stem == "design-quality":
            out["alwaysApply"] = True
            out.pop("globs", None)
        else:
            out["alwaysApply"] = False
            if "globs" not in out:
                out["globs"] = list(WEB_STANDARD_GLOBS)
    else:
        # language-specific: scoped by globs from source
        out["alwaysApply"] = False
        if "globs" not in out:
            out["globs"] = ["**/*"]

    return out


def dump_frontmatter(data: dict) -> str:
    # Stable key order for Cursor-friendly diffs
    order = ("description", "alwaysApply", "globs")
    ordered: dict = {}
    for k in order:
        if k in data:
            ordered[k] = data[k]
    for k, v in data.items():
        if k not in ordered:
            ordered[k] = v
    lines = yaml.safe_dump(
        ordered,
        sort_keys=False,
        allow_unicode=True,
        default_flow_style=False,
    ).rstrip()
    return f"---\n{lines}\n---\n"


def convert_rule_body(body: str) -> str:
    text = apply_skills_text_transforms(body)
    return fix_markdown_links_md_to_mdc(text)


def build_mdc(rel: Path, raw: str) -> str:
    """rel is relative path under ycc/rules (e.g. common/coding-style.md)."""
    _has_fm, fm_dict, body = parse_frontmatter(raw)
    merged = normalize_rule_frontmatter(rel, fm_dict, body)

    body_out = convert_rule_body(body)
    # Ensure description still present
    if "description" not in merged or not merged["description"]:
        merged["description"] = default_description(rel, body_out)

    return dump_frontmatter(merged) + body_out


def iter_source_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*") if p.is_file())


def copy_mode(src: Path, dst: Path) -> None:
    try:
        st = src.stat()
        dst.chmod(stat.S_IMODE(st.st_mode))
    except OSError:
        pass


def write_tree(dest: Path, dry_run: bool) -> set[Path]:
    if not SRC_DIR.is_dir():
        raise SystemExit(f"Missing source directory: {SRC_DIR}")

    written: set[Path] = set()

    for src in iter_source_files(SRC_DIR):
        rel = src.relative_to(SRC_DIR)
        if rel.name == "README.md":
            dst_file = dest / rel
            written.add(rel)
            if dry_run:
                print(f"Would write {dst_file.relative_to(REPO_ROOT)}")
                continue
            dst_file.parent.mkdir(parents=True, exist_ok=True)
            text = apply_skills_text_transforms(src.read_text(encoding="utf-8"))
            text = fix_markdown_links_md_to_mdc(text)
            dst_file.write_text(text, encoding="utf-8")
            copy_mode(src, dst_file)
            continue

        if rel.suffix.lower() != ".md":
            continue

        out_rel = rel.with_suffix(".mdc")
        dst_file = dest / out_rel
        written.add(out_rel)

        if dry_run:
            print(f"Would write {dst_file.relative_to(REPO_ROOT)}")
            continue

        dst_file.parent.mkdir(parents=True, exist_ok=True)
        raw = src.read_text(encoding="utf-8")
        mdc = build_mdc(rel, raw)
        dst_file.write_text(mdc, encoding="utf-8")
        # Mode: follow source .md (usually 644)
        copy_mode(src, dst_file)

    if not dry_run:
        prune_orphans(dest, written)

    return written


def prune_orphans(dest: Path, source_rels: set[Path]) -> None:
    all_dest: list[Path] = [p for p in dest.rglob("*") if p.is_file()]
    for p in sorted(all_dest, key=lambda x: len(x.parts), reverse=True):
        try:
            rel = p.relative_to(dest)
        except ValueError:
            continue
        if rel not in source_rels:
            p.unlink()
    dirs = sorted(
        {d for d in dest.rglob("*") if d.is_dir()},
        key=lambda x: len(x.parts),
        reverse=True,
    )
    for d in dirs:
        if d == dest:
            continue
        try:
            next(d.iterdir())
        except StopIteration:
            d.rmdir()


def compare_trees(generated: Path, repo_dst: Path) -> list[str]:
    diffs: list[str] = []
    gen_files: set[Path] = set()
    for p in generated.rglob("*"):
        if p.is_file():
            gen_files.add(p.relative_to(generated))

    dst_files: set[Path] = set()
    if repo_dst.is_dir():
        for p in repo_dst.rglob("*"):
            if p.is_file():
                dst_files.add(p.relative_to(repo_dst))

    for rel in sorted(gen_files | dst_files):
        g = generated / rel
        r = repo_dst / rel
        if rel not in dst_files:
            diffs.append(f"missing in repo: {rel}")
            continue
        if rel not in gen_files:
            diffs.append(f"extra in repo: {rel}")
            continue
        if g.read_bytes() != r.read_bytes():
            diffs.append(f"drift: {rel}")
    return diffs


def lint_generated_rules() -> int:
    """Verify each .mdc has required frontmatter keys."""
    errors = 0
    for path in sorted(DST_DIR.rglob("*.mdc")):
        raw = path.read_text(encoding="utf-8")
        if not raw.startswith("---\n"):
            print(
                f"MISSING frontmatter: {path.relative_to(REPO_ROOT)}", file=sys.stderr
            )
            errors += 1
            continue
        end = raw.find("\n---\n", 4)
        if end == -1:
            print(
                f"MALFORMED frontmatter: {path.relative_to(REPO_ROOT)}", file=sys.stderr
            )
            errors += 1
            continue
        fm_text = raw[4:end]
        data = yaml.safe_load(fm_text) or {}
        if "description" not in data:
            print(
                f"MISSING description: {path.relative_to(REPO_ROOT)}", file=sys.stderr
            )
            errors += 1
        if "alwaysApply" not in data:
            print(
                f"MISSING alwaysApply: {path.relative_to(REPO_ROOT)}", file=sys.stderr
            )
            errors += 1
        if not data.get("alwaysApply") and "globs" not in data:
            print(
                f"MISSING globs (scoped rule): {path.relative_to(REPO_ROOT)}",
                file=sys.stderr,
            )
            errors += 1
    return errors


def run_check() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tpath = Path(tmp)
        write_tree(tpath, dry_run=False)
        diffs = compare_trees(tpath, DST_DIR)
        if diffs:
            print(
                "Cursor rules are out of date. Run: ./scripts/generate-cursor-rules.sh",
                file=sys.stderr,
            )
            for line in diffs:
                print(f"  {line}", file=sys.stderr)
            return 1
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit 1 if .cursor-plugin/rules differs from generator output",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print paths that would be written (no writes)",
    )
    parser.add_argument(
        "--lint",
        action="store_true",
        help="Validate frontmatter on existing .cursor-plugin/rules (no generation)",
    )
    args = parser.parse_args()

    if args.lint:
        n = lint_generated_rules()
        sys.exit(1 if n else 0)

    if args.check:
        if not DST_DIR.is_dir():
            print(
                f"Missing {DST_DIR}; run generator without --check first.",
                file=sys.stderr,
            )
            sys.exit(1)
        sys.exit(run_check())

    if args.dry_run:
        write_tree(DST_DIR, dry_run=True)
        return

    write_tree(DST_DIR, dry_run=False)
    n = sum(1 for _ in DST_DIR.rglob("*") if _.is_file())
    print(f"Wrote {n} files under {DST_DIR}")


if __name__ == "__main__":
    main()
