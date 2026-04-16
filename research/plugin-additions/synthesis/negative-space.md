# Negative Space Analysis: plugin-additions

## Executive Summary

The biggest missing layer is a workflow for maintaining `ycc` itself as a multi-target product. The repo has planning and research depth, but comparatively little first-class support for authoring new bundle content, shipping releases, or validating target compatibility end to end.

## Unanswered Questions

1. What is the canonical contributor path for adding a new skill/agent/command?
2. What is the canonical release path for publishing a new bundle version safely?
3. Which advanced features are supported by which target today?
4. Which generated surfaces are safe to edit, and which are never meant to be edited?

## Missing Capability Categories

### Bundle authoring

- Scaffold a new `ycc` skill/agent/command with the right repo conventions

### Bundle release

- Bump version, regenerate derived outputs, validate, package marketplace metadata, and prepare release notes

### Compatibility audit

- Verify Claude/Cursor/Codex surfaces from one command or skill

### Hook workflow

- Turn hook guidance into concrete target-specific configuration

### Inventory generation

- Generate counts, parity, and capability tables from source

## Why These Gaps Matter

Each missing category makes the repo more dependent on maintainer memory. That is exactly the wrong dependency for a bundle this size.
