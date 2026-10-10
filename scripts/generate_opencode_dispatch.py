#!/usr/bin/env python3
"""Project Claude dispatch prose onto OpenCode V2's native child-session API."""

from __future__ import annotations

from pathlib import Path

from generate_opencode_dispatch_markdown import (
    _project_standalone_only_terms,
    _remove_empty_fenced_blocks,
    _remove_team_operations,
    _strip_embedded_team_communication_sections,
    _strip_team_sections,
    _translate_native_vocabulary,
)
from generate_opencode_dispatch_markdown import (
    project_opencode_dispatch_description as project_opencode_dispatch_description,
)
from generate_opencode_dispatch_special import (
    _project_implementor,
    _project_plan,
    _project_prp_implement,
    _project_prp_plan,
    _project_review_checklist,
)
from generate_opencode_dispatch_workflows import (
    _project_foreground_result_contracts,
    _project_implement_plan,
    _project_operational_team_clauses,
    _project_required_workflow_surfaces,
    _project_research_workflow_contracts,
)

SCRIPT_DIR = Path(__file__).resolve().parent
STANDALONE_DISPATCH_SOURCE = "_shared/references/standalone-dispatch.md"
STANDALONE_DISPATCH_TEMPLATE = SCRIPT_DIR / "opencode_templates" / "standalone-dispatch.md"


def render_standalone_dispatch_reference() -> str:
    """Return the maintained OpenCode-only standalone dispatch contract."""
    try:
        rendered = STANDALONE_DISPATCH_TEMPLATE.read_text(encoding="utf-8")
    except OSError as exc:
        raise RuntimeError(f"OpenCode dispatch template is unavailable: {STANDALONE_DISPATCH_TEMPLATE}") from exc
    return _ensure_trailing_newline(rendered)


def _ensure_trailing_newline(text: str) -> str:
    return text.rstrip("\n") + "\n" if text else ""


def project_opencode_dispatch(text: str, source_path: str | Path) -> str:
    """Return OpenCode-native dispatch prose for one generated source file."""
    normalized_path = Path(source_path).as_posix()
    if normalized_path.endswith(STANDALONE_DISPATCH_SOURCE):
        return render_standalone_dispatch_reference()

    projected = _strip_team_sections(text)
    projected = _strip_embedded_team_communication_sections(projected)
    projected = _project_foreground_result_contracts(projected)
    projected = _project_research_workflow_contracts(projected, normalized_path)
    is_entrypoint = normalized_path.endswith("SKILL.md") or normalized_path.startswith("commands/")
    projected = _remove_team_operations(projected, add_compatibility_note=is_entrypoint)
    projected = _project_standalone_only_terms(projected)
    projected = _translate_native_vocabulary(projected)
    projected = _project_research_workflow_contracts(projected, normalized_path)
    if normalized_path.endswith("implement-plan/SKILL.md"):
        projected = _project_implement_plan(projected)
    if normalized_path.endswith("agents/implementor.md"):
        projected = _project_implementor(projected)
    if normalized_path.endswith("_shared/references/review-checklist.md"):
        projected = _project_review_checklist(projected)
    if normalized_path.endswith("prp-implement/SKILL.md"):
        projected = _project_prp_implement(projected)
    if normalized_path.endswith("prp-plan/SKILL.md"):
        projected = _project_prp_plan(projected)
    if normalized_path.endswith("plan/SKILL.md"):
        projected = _project_plan(projected)
    projected = _project_operational_team_clauses(projected, normalized_path)
    projected = _project_required_workflow_surfaces(projected, normalized_path)
    projected = _remove_empty_fenced_blocks(projected)
    return _ensure_trailing_newline(projected)
