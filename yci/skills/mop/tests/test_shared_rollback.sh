#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/helpers.sh"

ROLLBACK="${PLUGIN_ROOT}/skills/_shared/scripts/derive-change-rollback.sh"
NORMALIZE="${SKILL_ROOT}/scripts/normalize-change.sh"
CHANGES_DIR="${FIXTURES_ROOT}/changes"

test_terraform_rollback() {
    local envelope out
    envelope="$(bash "$NORMALIZE" --input "${CHANGES_DIR}/terraform-plan.json")"
    out="$(printf '%s' "$envelope" | bash "$ROLLBACK")"
    assert_contains "terraform state push -force pre-change-tfstate" "$out" "terraform rollback path"
    assert_contains "aws_security_group_rule.allow_https" "$out" "terraform resource address"
}

test_iosxe_rollback() {
    local envelope out
    envelope="$(bash "$NORMALIZE" --input "${CHANGES_DIR}/iosxe.cli")"
    out="$(printf '%s' "$envelope" | bash "$ROLLBACK")"
    assert_contains "no mtu 9000" "$out" "iosxe inverse command"
}

test_panos_rollback() {
    local envelope out
    envelope="$(bash "$NORMALIZE" --input "${CHANGES_DIR}/panos.cli")"
    out="$(printf '%s' "$envelope" | bash "$ROLLBACK")"
    assert_contains "delete network interface ethernet ethernet1/1 layer3 mtu 9000" "$out" "panos inverse command"
}

test_terraform_rollback
test_iosxe_rollback
test_panos_rollback
summary
