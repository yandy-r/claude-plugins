#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/helpers.sh"

RENDER="${SKILL_ROOT}/scripts/render-artifact.sh"
TMP_BASE="$(mktemp -d -t yci-mop-render-XXXX)"
trap 'rm -rf "${TMP_BASE}"' EXIT

cat > "${TMP_BASE}/profile.json" <<'EOF'
{
  "customer": {"id": "widget-corp"},
  "compliance": {"regime": "commercial"},
  "deliverable": {"header_template": "header.md"},
  "safety": {
    "default_posture": "review",
    "change_window_required": true,
    "scope_enforcement": "block"
  }
}
EOF

cat > "${TMP_BASE}/header.md" <<'EOF'
## Widget Corp
EOF

cat > "${TMP_BASE}/change.json" <<'EOF'
{
  "change_id": "mop-test-001",
  "summary": "Raise MTU on dc1-edge-01.",
  "pre_change_markdown": "```sh\nshow running-config\n```",
  "apply_markdown": "```text\ninterface Gi0/0\n mtu 9000\n```",
  "post_change_markdown": "```sh\nshow interface status\n```"
}
EOF

cat > "${TMP_BASE}/blast-radius.md" <<'EOF'
**Impact level:** medium
EOF

cat > "${TMP_BASE}/rollback.txt" <<'EOF'
no mtu 9000
EOF

cat > "${TMP_BASE}/catalog.json" <<'EOF'
{
  "pre_check": [{"id": "pre-1", "source": "adapter", "category": "adapter", "description": "Confirm maintenance window is open."}],
  "post_check": [{"id": "post-1", "source": "adapter", "category": "adapter", "description": "Confirm service health is normal."}]
}
EOF

output_path="${TMP_BASE}/mop.md"
(
  cd "$TMP_BASE" || exit
  bash "$RENDER" \
    --profile "${TMP_BASE}/profile.json" \
    --change-json "${TMP_BASE}/change.json" \
    --blast-radius-markdown "${TMP_BASE}/blast-radius.md" \
    --rollback "${TMP_BASE}/rollback.txt" \
    --rollback-confidence low \
    --catalog "${TMP_BASE}/catalog.json" \
    --output "$output_path"
)

rendered="$(cat "$output_path")"
assert_file_exists "$output_path" "rendered file exists"
assert_contains "## Method of Procedure" "$rendered" "template heading"
assert_contains "Abort unless a human operator explicitly promotes the posture" "$rendered" "abort criteria derived"
assert_contains "Rollback confidence" "$rendered" "rollback callout rendered"
summary
