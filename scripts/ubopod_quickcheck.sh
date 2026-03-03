#!/usr/bin/env bash
set -euo pipefail

# UboPod quick workflow check:
# - verifies bridge health endpoint
# - optionally sends a test notification
# - writes a timestamped report for handoff/continuity

UBO_HOST_DEFAULT="<UBOPOD_IP>"
BRIDGE_PORT_DEFAULT="8787"
REPORT_DIR_DEFAULT="workflows/reports"

UBO_HOST="${UBO_HOST:-$UBO_HOST_DEFAULT}"
BRIDGE_PORT="${BRIDGE_PORT:-$BRIDGE_PORT_DEFAULT}"
REPORT_DIR="${REPORT_DIR:-$REPORT_DIR_DEFAULT}"
SEND_NOTIFY=0
TIMEOUT=5

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --host <ip-or-hostname>   UboPod host (default: ${UBO_HOST_DEFAULT})
  --port <port>             Bridge port (default: ${BRIDGE_PORT_DEFAULT})
  --notify                  Send a test notification to /notify
  --timeout <seconds>       curl timeout per request (default: 5)
  --report-dir <path>       Report output directory (default: workflows/reports)
  -h, --help                Show this help

Env overrides:
  UBO_HOST, BRIDGE_PORT, REPORT_DIR
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      UBO_HOST="$2"; shift 2 ;;
    --port)
      BRIDGE_PORT="$2"; shift 2 ;;
    --notify)
      SEND_NOTIFY=1; shift ;;
    --timeout)
      TIMEOUT="$2"; shift 2 ;;
    --report-dir)
      REPORT_DIR="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2 ;;
  esac
done

BASE_URL="http://${UBO_HOST}:${BRIDGE_PORT}"
TIMESTAMP="$(date +%Y-%m-%dT%H-%M-%S)"
mkdir -p "$REPORT_DIR"
REPORT_PATH="${REPORT_DIR}/ubopod-quickcheck-${TIMESTAMP}.md"

health_http_code="000"
health_body=""
notify_http_code="SKIPPED"
notify_body=""

health_tmp="$(mktemp)"
if health_http_code=$(curl -sS -m "$TIMEOUT" -o "$health_tmp" -w "%{http_code}" "${BASE_URL}/health" 2>/dev/null); then
  health_body="$(cat "$health_tmp")"
else
  health_http_code="000"
  health_body="curl_failed"
fi
rm -f "$health_tmp"

if [[ "$SEND_NOTIFY" -eq 1 ]]; then
  notify_tmp="$(mktemp)"
  payload='{"text":"OpenClaw quickcheck ping","source":"openclaw-quickcheck"}'
  if notify_http_code=$(curl -sS -m "$TIMEOUT" -X POST "${BASE_URL}/notify" \
      -H "Content-Type: application/json" \
      -d "$payload" \
      -o "$notify_tmp" -w "%{http_code}" 2>/dev/null); then
    notify_body="$(cat "$notify_tmp")"
  else
    notify_http_code="000"
    notify_body="curl_failed"
  fi
  rm -f "$notify_tmp"
fi

status="PASS"
if [[ "$health_http_code" != "200" ]]; then
  status="WARN"
fi
if [[ "$SEND_NOTIFY" -eq 1 && "$notify_http_code" != "200" ]]; then
  status="WARN"
fi

cat > "$REPORT_PATH" <<EOF
# UboPod Quickcheck Report

- Timestamp: $(date -Iseconds)
- Target: ${BASE_URL}
- Overall: ${status}

## Health Check (/health)
- HTTP: ${health_http_code}
- Body: 

\`\`\`
${health_body}
\`\`\`

## Notify Check (/notify)
- Attempted: $([[ "$SEND_NOTIFY" -eq 1 ]] && echo "yes" || echo "no")
- HTTP: ${notify_http_code}
- Body:

\`\`\`
${notify_body}
\`\`\`

## Next Actions
- If health is not 200: verify service on host and network reachability.
- If notify fails but health passes: inspect bridge endpoint wiring and payload schema.
EOF

echo "Wrote report: ${REPORT_PATH}"
echo "Overall: ${status}"

if [[ "$status" != "PASS" ]]; then
  exit 1
fi
