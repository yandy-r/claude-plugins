#!/usr/bin/env bash
# yci — profile schema declaration (source this file; do not execute directly).
#
# Single source of truth for required/optional keys and enum allowed values.
# Consumed by load-profile.sh, init-profile.sh, and the test harness.
#
# Keep in sync with:
#   - yci/skills/customer-profile/references/schema.md
#   - docs/prps/prds/yci.prd.md §5.2

# Top-level keys --------------------------------------------------------------

# Must appear in every valid profile.
YCI_PROFILE_REQUIRED_TOP_LEVEL=(customer engagement compliance inventory approval deliverable safety)

# May appear; loader warns if absent and does NOT error.
YCI_PROFILE_OPTIONAL_TOP_LEVEL=(change_window vaults vendor_tooling)

# Nested required fields ------------------------------------------------------
#
# Convention: YCI_<UPPERCASE_SECTION>_REQUIRED=(...) for each top-level section
# with nested requirements. Loader iterates these arrays.

YCI_CUSTOMER_REQUIRED=(id display_name)
YCI_ENGAGEMENT_REQUIRED=(id type sow_ref scope_tags start_date end_date)
YCI_COMPLIANCE_REQUIRED=(regime evidence_schema_version)
YCI_INVENTORY_REQUIRED=(adapter)
YCI_APPROVAL_REQUIRED=(adapter)
YCI_DELIVERABLE_REQUIRED=(format header_template handoff_format)
YCI_SAFETY_REQUIRED=(default_posture change_window_required scope_enforcement)

# Enum allowed values ---------------------------------------------------------
#
# IMPORTANT: these MUST match schema.md's enum sections verbatim. The loader
# rejects any value not in the array for the corresponding field.

# Values for compliance.regime (schema.md "Compliance regimes" / PRD §11.2).
YCI_COMPLIANCE_REGIMES=(hipaa pci sox soc2 iso27001 nist commercial none)

# Values for safety.default_posture (schema.md "Safety postures" / PRD §11.7).
YCI_SAFETY_POSTURES=(dry-run review apply)

# Values for engagement.type (schema.md "Engagement types" / PRD §5.2).
YCI_ENGAGEMENT_TYPES=(discovery design implementation ongoing)

# Values for safety.scope_enforcement (schema.md "Scope enforcement values").
YCI_SCOPE_ENFORCEMENT=(warn block off)

# Values for deliverable.handoff_format (schema.md "deliverable" table).
YCI_DELIVERABLE_HANDOFF_FORMATS=(git-repo zip confluence pdf-bundle)

# Inventory/approval adapter types: schema.md enumerates these but the loader
# validates adapter presence (non-empty string), not a closed enum, because
# new adapters are added without schema changes. Uncomment if stricter
# validation is desired in a future iteration.
# YCI_INVENTORY_ADAPTERS=(file netbox nautobot servicenow-cmdb infoblox)
# YCI_APPROVAL_ADAPTERS=(github-pr email-signoff jira servicenow-request none)

# Helpers ---------------------------------------------------------------------

# yci_enum_contains <array-name> <value>
#   Returns 0 if <value> is in the named array, 1 otherwise.
yci_enum_contains() {
    local -n _yci_arr="$1"
    local needle="$2"
    local item
    for item in "${_yci_arr[@]}"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

# yci_required_for <section>
#   Echoes the space-separated required field list for <section>,
#   or nothing if no required fields are declared for that section.
yci_required_for() {
    local section
    section="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
    local varname="YCI_${section}_REQUIRED"
    if [ -n "${!varname+set}" ]; then
        local -n _yci_req_arr="$varname"
        printf '%s ' "${_yci_req_arr[@]}"
    fi
}
