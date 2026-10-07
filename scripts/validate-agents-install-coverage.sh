#!/usr/bin/env bash
# Verifies that every ~/.agents/<root>/... reference inside the
# .agents-plugin/ bundle is either:
#   (a) installable: <root> is in AGENTS_BUNDLE_UNITS
#       (scripts/lib/install/targets/agents.sh) AND
#       the backing file exists under .agents-plugin/<root>/...
#   (b) intentionally not bundle-shipped (a path the installer must never
#       own, e.g. ~/.agents/plugins/ which Codex owns).
#
# Regression guard for bugs where the generator emits a reference but the
# install step never copies the backing dir, or vice versa.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUNDLE_ROOT="${REPO_ROOT}/.agents-plugin"
INSTALL_SCRIPT="${REPO_ROOT}/scripts/lib/install/targets/agents.sh"

if [[ ! -d "${BUNDLE_ROOT}" ]]; then
    echo "validate-agents-install-coverage: ${BUNDLE_ROOT} not found" >&2
    exit 1
fi
if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
    echo "validate-agents-install-coverage: ${INSTALL_SCRIPT} not found" >&2
    exit 1
fi

echo "== Install-coverage check (~/.agents/... references) =="
python3 - "${BUNDLE_ROOT}" "${INSTALL_SCRIPT}" <<'PY'
import re
import sys
from pathlib import Path

bundle_root = Path(sys.argv[1])
install_script = Path(sys.argv[2])

# Single source of truth: AGENTS_BUNDLE_UNITS in the agents target lib.
text = install_script.read_text(encoding="utf-8")
match = re.search(r"^AGENTS_BUNDLE_UNITS=\(([a-z0-9- ]+)\)$", text, re.M)
if not match:
    print(
        f"FAIL: could not find AGENTS_BUNDLE_UNITS=(...) in {install_script} — "
        "validator cannot determine what the installer actually copies.",
        file=sys.stderr,
    )
    sys.exit(1)
MANAGED_UNITS = set(match.group(1).split())

# Roots intentionally NOT bundle-shipped by this target:
ALLOWLIST_ROOTS = {
    "plugins",  # ~/.agents/plugins/ is Codex's plugin area — never touched here
}

PATH_RE = re.compile(
    r"~/\.agents/([A-Za-z0-9._-]+)(?:/([A-Za-z0-9._/-]*))?"
)

unknown_roots: dict[str, str] = {}    # root -> first .agents-plugin file referencing it
missing_targets: list[tuple[str, str, str]] = []  # (src, raw_ref, expected_path)

for path in sorted(bundle_root.rglob("*")):
    if not path.is_file():
        continue
    try:
        body = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    for m in PATH_RE.finditer(body):
        root = m.group(1)
        rest = m.group(2) or ""
        if root in ALLOWLIST_ROOTS:
            continue
        if root not in MANAGED_UNITS:
            unknown_roots.setdefault(root, str(path.relative_to(bundle_root)))
            continue
        rest_clean = rest.rstrip("/")
        if rest_clean:
            target = bundle_root / root / rest_clean
        else:
            target = bundle_root / root
        if not target.exists():
            missing_targets.append(
                (
                    str(path.relative_to(bundle_root)),
                    m.group(0),
                    str(target.relative_to(bundle_root.parent)),
                )
            )

failed = False

if unknown_roots:
    failed = True
    print(
        "FAIL: bundle references roots that are neither in "
        "AGENTS_BUNDLE_UNITS nor on the allowlist:",
        file=sys.stderr,
    )
    for root, src in sorted(unknown_roots.items()):
        print(
            f"  ~/.agents/{root}/... "
            f"(first seen in .agents-plugin/{src})",
            file=sys.stderr,
        )
    print(
        "  Fix: either add the dir to AGENTS_BUNDLE_UNITS in "
        "scripts/lib/install/targets/agents.sh "
        "(if the target should ship it) or add it to ALLOWLIST_ROOTS in "
        "this validator (if it must stay untouched).",
        file=sys.stderr,
    )

if missing_targets:
    failed = True
    print(
        "FAIL: bundle references files that do not exist in "
        ".agents-plugin/:",
        file=sys.stderr,
    )
    for src, ref, expected in missing_targets:
        print(f"  .agents-plugin/{src}", file=sys.stderr)
        print(f"    references: {ref}", file=sys.stderr)
        print(f"    expected:   {expected}", file=sys.stderr)
    print(
        "  Fix: regenerate the bundle (./scripts/sync.sh --only agents) "
        "or update the source skill to point at a path that actually ships.",
        file=sys.stderr,
    )

if failed:
    sys.exit(1)

print(
    f"OK: every ~/.agents/<root>/... reference in "
    f"{bundle_root.name}/ resolves to a backing file or an allowlisted path."
)
PY
