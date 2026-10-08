"""Entry selection for merge_managed_config.py (``--entries`` / ``--list-entries``).

Map-shaped managed rules (``deep`` and ``map-entries`` — MCP servers, plugin
tables) hold named entries. Selecting entries narrows a run to just those
names: the source is filtered to them, and ownership state outside them is
hidden from planning so a partial sync or remove never prunes the rest.
"""

from __future__ import annotations

from collections.abc import Callable
from typing import Any

ENTRY_POLICIES = ("deep", "map-entries")


def entry_rule_paths(profile: dict[str, Any], groups: list[str]) -> list[list[str]]:
    """Container paths of the selected groups' map-shaped rules."""
    return [
        list(rule["path"])
        for group in groups
        for rule in profile["groups"].get(group, [])
        if rule["policy"] in ENTRY_POLICIES
    ]


def _container(data: Any, path: list[str]) -> dict[str, Any] | None:
    current = data
    for part in path:
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current if isinstance(current, dict) else None


def available_entries(profile: dict[str, Any], groups: list[str], source: dict[str, Any]) -> list[str]:
    """Entry names the source manages, in source order, without duplicates."""
    names: list[str] = []
    for path in entry_rule_paths(profile, groups):
        container = _container(source, path)
        for name in container or {}:
            if name not in names:
                names.append(name)
    return names


def select_source_entries(
    profile: dict[str, Any], groups: list[str], source: dict[str, Any], entries: list[str]
) -> dict[str, Any]:
    """Copy of ``source`` whose map-shaped containers keep only ``entries``."""
    selected: dict[str, Any] = dict(source)
    for path in entry_rule_paths(profile, groups):
        if _container(source, path) is None:
            continue
        # Shallow-copy each dict along the path so the original stays intact.
        parent = selected
        for part in path[:-1]:
            parent[part] = dict(parent[part])
            parent = parent[part]
        container = parent[path[-1]]
        parent[path[-1]] = {name: value for name, value in container.items() if name in entries}
    return selected


def outside_selection(profile: dict[str, Any], groups: list[str], path: list[str], entries: list[str]) -> bool:
    """True when ``path`` is inside a map-shaped container but not a selected entry."""
    for rule_path in entry_rule_paths(profile, groups):
        if path[: len(rule_path)] == rule_path:
            return len(path) <= len(rule_path) or path[len(rule_path)] not in entries
    return False


def selected_state(
    profile: dict[str, Any],
    groups: list[str],
    state_entry: dict[str, Any],
    entries: list[str],
    parse_pointer: Callable[[str], list[str]],
) -> dict[str, Any]:
    """The part of ``state_entry`` a selected run may plan against."""
    return {
        key: value
        for key, value in state_entry.items()
        if not (key.startswith("/") and outside_selection(profile, groups, parse_pointer(key), entries))
    }
