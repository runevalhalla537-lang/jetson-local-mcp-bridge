#!/usr/bin/env bash
set -euo pipefail

WORKDIR="/home/openclaw/.openclaw/workspace"
REPORT_DIR="${WORKDIR}/workflows/reports"
TS="$(date +%Y-%m-%dT%H-%M-%S)"
REPORT="${REPORT_DIR}/mcp-selfcheck-${TS}.md"
mkdir -p "$REPORT_DIR"

status="PASS"

svc_status="$(systemctl --user is-active mcp-local.service 2>/dev/null || true)"
if [[ "$svc_status" != "active" ]]; then
  status="WARN"
fi

py_out="$({ python3 - <<'PY'
import json
import scripts.mcp_local_server as s
r = {}
try:
    r['ubopod_status'] = s.ubopod_status()
except Exception as e:
    r['ubopod_status_error'] = str(e)
try:
    r['spark_warm'] = s.spark_model_warm_status()
except Exception as e:
    r['spark_warm_error'] = str(e)
print(json.dumps(r))
PY
} 2>&1)" || true

if echo "$py_out" | grep -qi "error"; then
  status="WARN"
fi

cat > "$REPORT" <<EOF
# MCP Selfcheck

- Timestamp: $(date -Iseconds)
- Service active: ${svc_status}
- Overall: ${status}

## Tool probe output

\`\`\`
${py_out}
\`\`\`
EOF

echo "Wrote report: $REPORT"
echo "Overall: $status"

[[ "$status" == "PASS" ]]
