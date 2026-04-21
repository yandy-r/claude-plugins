#!/usr/bin/env bash
# yci compliance-adapter contract constants.
#
# Sourceable library — DO NOT set -euo pipefail at file scope.
# Read by:
#   - yci/skills/_shared/scripts/load-compliance-adapter.sh   (runtime loader)
#   - scripts/validate-yci-skills.sh                          (structural validator)
#
# The contract itself is documented in yci/CONTRIBUTING.md § "What Every Adapter Should Ship".
# This file is the machine-readable mirror of that prose contract — keep them in sync.

# shellcheck disable=SC2034
# The arrays below are read by callers after sourcing; shellcheck cannot see
# across the source boundary so it flags them as unused inside this file.

# Files every adapter directory must ship, regardless of regime.
# A regime listed in YCI_ADAPTER_SCHEMA_EXEMPT is additionally allowed to omit
# evidence-schema.json and redaction.rules (see YCI_ADAPTER_FULL_FILES).
YCI_ADAPTER_REQUIRED_FILES=(
  ADAPTER.md
  evidence-template.md
  handoff-checklist.md
)

# Files a non-exempt regime additionally ships on top of the required set.
YCI_ADAPTER_FULL_FILES=(
  ADAPTER.md
  evidence-schema.json
  evidence-template.md
  redaction.rules
  handoff-checklist.md
)

# Regimes that are exempt from evidence-schema.json and redaction.rules.
# The canonical and only current member is "none".
YCI_ADAPTER_SCHEMA_EXEMPT=(
  none
)

# Current evidence schema version shipped by the commercial adapter.
# Bump when commercial/evidence-schema.json changes shape.
YCI_ADAPTER_COMMERCIAL_SCHEMA_VERSION=1

# yci_adapter_is_schema_exempt <regime>
#
# Prints nothing. Returns 0 if <regime> is in YCI_ADAPTER_SCHEMA_EXEMPT, else 1.
# Callers SHOULD quote the argument to tolerate an empty regime.
yci_adapter_is_schema_exempt() {
  local needle="${1:-}"
  local entry
  for entry in "${YCI_ADAPTER_SCHEMA_EXEMPT[@]}"; do
    if [ "${entry}" = "${needle}" ]; then
      return 0
    fi
  done
  return 1
}

# yci_adapter_expected_files <regime>
#
# Prints the list of files that adapter <regime> must ship, one per line.
# Uses YCI_ADAPTER_REQUIRED_FILES for exempt regimes, YCI_ADAPTER_FULL_FILES
# otherwise. Exits the function with return 0 on success.
yci_adapter_expected_files() {
  local regime="${1:-}"
  local file
  if yci_adapter_is_schema_exempt "${regime}"; then
    for file in "${YCI_ADAPTER_REQUIRED_FILES[@]}"; do
      printf '%s\n' "${file}"
    done
  else
    for file in "${YCI_ADAPTER_FULL_FILES[@]}"; do
      printf '%s\n' "${file}"
    done
  fi
  return 0
}
