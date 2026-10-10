#!/usr/bin/env python3
"""Shared OpenCode V2 agent and permission schema checks."""

from __future__ import annotations

from typing import Any

V2_AGENT_KEYS: frozenset[str] = frozenset(
    {"description", "mode", "model", "system", "permissions", "steps", "hidden", "color", "disabled", "request"}
)

V1_AGENT_RENAMES: dict[str, str] = {
    "disable": "disabled",
    "maxSteps": "steps",
    "options": "request",
    "permission": "permissions",
    "prompt": "system",
    "temperature": "request.body or provider settings",
    "tools": "permissions",
    "top_p": "request.body or provider settings",
}

V2_AGENT_MODES: frozenset[str] = frozenset({"primary", "subagent", "all"})
V2_EFFECTS: frozenset[str] = frozenset({"allow", "deny", "ask"})


def validate_permission_rules(where: str, value: Any) -> list[str]:
    """Return schema errors for an ordered OpenCode V2 permission list."""
    errors: list[str] = []
    if not isinstance(value, list):
        return [f"{where} must be an ordered list of rules; the V1 object form is ignored by V2"]

    for index, rule in enumerate(value):
        label = f"{where}[{index}]"
        if not isinstance(rule, dict):
            errors.append(f"{label} must be an object")
            continue

        missing = [field for field in ("action", "resource", "effect") if field not in rule]
        if missing:
            errors.append(f"{label} is missing {', '.join(missing)}")
        extra = set(rule) - {"action", "resource", "effect"}
        if extra:
            errors.append(f"{label} has unexpected fields: {', '.join(sorted(extra))}")

        for field in ("action", "resource", "effect"):
            if field not in rule:
                continue
            value_field = rule[field]
            if not isinstance(value_field, str) or not value_field:
                errors.append(f"{label}.{field} must be a non-empty string")

        effect = rule.get("effect")
        if isinstance(effect, str) and effect not in V2_EFFECTS:
            errors.append(f"{label}.effect={effect!r} must be one of allow, deny, ask")

    return errors


def validate_agent_schema(where: str, payload: dict[str, Any]) -> list[str]:
    """Return field and permission errors common to JSON and Markdown agents."""
    errors: list[str] = []
    for key in payload:
        if key in V1_AGENT_RENAMES:
            errors.append(f"{where}.{key} is V1; use {V1_AGENT_RENAMES[key]}")
        elif key not in V2_AGENT_KEYS:
            errors.append(f"{where}.{key} is not a documented V2 field")

    mode = payload.get("mode")
    if mode is not None and mode not in V2_AGENT_MODES:
        errors.append(f"{where}.mode={mode!r} must be one of primary, subagent, all")
    if "permissions" in payload:
        errors.extend(validate_permission_rules(f"{where}.permissions", payload["permissions"]))

    return errors
