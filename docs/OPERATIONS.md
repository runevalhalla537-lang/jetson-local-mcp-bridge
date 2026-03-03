# MCP Bridge Operations Runbook

## Service
- Name: `mcp-local.service`
- Endpoint: `http://127.0.0.1:8765/mcp`

## Common commands
```bash
systemctl --user status mcp-local.service
systemctl --user restart mcp-local.service
journalctl --user -u mcp-local.service -f
```

## Quick verifications
```bash
python3 - <<'PY'
import scripts.mcp_local_server as s
print(s.ubopod_status())
print(s.spark_model_warm_status().keys())
PY
```

## Daily self-check
```bash
./scripts/mcp_selfcheck.sh
```

Outputs report to:
- `workflows/reports/mcp-selfcheck-<timestamp>.md`

## Typical failure recovery
1. Restart service
2. Check Ubo bridge health (`/health`)
3. Check Spark Ollama `/api/ps`
4. Re-run self-check script

## Notes
- Keep endpoint loopback-only unless explicitly required.
- If publishing configs/docs, replace internal IPs with placeholders.
