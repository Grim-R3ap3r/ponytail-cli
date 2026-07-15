#!/usr/bin/env bash
# Self-check: evidence filter must drop PR#1780-style hand-wavy regressions.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
# Extract filter_findings by sourcing a stub: redefine only what we need.
CONFIDENCE_THRESHOLD=7

filter_findings() {
  local input="$1"
  local jqprog
  jqprog=$(cat <<'JQ'
    def speculative:
      ((.body // "") + " " + (.impact // ""))
      | test("(?i)\\b(may|might|could|possibly|potentially)\\b|any code |depending on|will break|can break|may have|could cause|could affect"; "i");
    def pinpoint:
      test("^[A-Za-z0-9_./\\\\-]+:[0-9]+(\\s|[-]|$)");
    def has_evidence:
      (.evidence | type == "array") and (.evidence | length > 0)
      and all(.evidence[]; type == "string" and length > 12 and pinpoint);
    def has_consumer_evidence:
      (.path as $p |
        [.evidence[]? | select((startswith($p + ":") | not) and pinpoint)]
        | length > 0);
    def is_regression:
      ((.body // "") | test("(?i)regression"));
    [
      .[]
      | select((.confidence // 0) >= $thresh)
      | select(has_evidence)
      | select(speculative | not)
      | select((is_regression | not) or has_consumer_evidence)
      | select(
          (.severity == "blocker")
          or (.severity == "warning")
          or (.severity == "nit")
        )
    ]
JQ
)
  echo "$input" | jq --argjson thresh "$CONFIDENCE_THRESHOLD" "$jqprog"
}

noise='[
  {"path":"repositories/constant_mapping_repository.go","line":115,"body":"**Regression:** Error checking changed from gorm.IsRecordNotFoundError to errors.Is. This affects error handling and any code depending on the specific error type checking will break.","confidence":9,"severity":"warning","evidence":["repositories/constant_mapping_repository.go:115 - changed to errors.Is"],"impact":"any code depending on old check will break"},
  {"path":"repositories/doctor_tag.go","line":67,"body":"**Regression:** Count returns int64. Callers may have type mismatch.","confidence":8,"severity":"warning","evidence":["repositories/doctor_tag.go:67 - returns int64"],"impact":"may break callers"},
  {"path":"real/bug.go","line":10,"body":"nil dereference on user before nil check","confidence":9,"severity":"blocker","evidence":["real/bug.go:10 - user.Name used before if user == nil"],"impact":"panic on empty input"},
  {"path":"api/handler.go","line":40,"body":"**Regression:** remove fallback default timeout.","confidence":8,"severity":"blocker","evidence":["worker/job.go:22 - still sleeps with old 30s assumption"],"impact":"worker jobs time out"}
]'

out=$(filter_findings "$noise")
count=$(echo "$out" | jq 'length')
paths=$(echo "$out" | jq -r '.[].path' | paste -sd, -)

[[ "$count" -eq 2 ]] || { echo "FAIL: expected 2 kept, got $count ($paths)"; exit 1; }
echo "$out" | jq -e 'map(.path) | index("real/bug.go")' >/dev/null
echo "$out" | jq -e 'map(.path) | index("api/handler.go")' >/dev/null
echo "PASS: dropped hand-wavy regressions; kept pinpointed bug + consumer regression"
