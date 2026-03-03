# Jetson Local MCP Bridge

Python-based local MCP server for Jetson that exposes reusable tools for:
- UboPod bridge (`status`, `notify`, `speak`)
- Spark Ollama model introspection

## Features
- Streamable HTTP MCP endpoint on localhost
- Systemd user service for persistence/restart
- Environment-driven endpoints (no hardcoded internal IPs)

## Included files
- `scripts/mcp_local_server.py`
- `scripts/mcp_local_server.env.example`
- `scripts/ubopod_quickcheck.sh`
- `scripts/mcp_selfcheck.sh`
- `systemd/mcp-local.service`
- `docs/jetson-python-mcp-setup.md`
- `docs/OPERATIONS.md`

## Quick start
1. Create venv and install dependencies:
   ```bash
   python3 -m venv mcp-server/.venv
   source mcp-server/.venv/bin/activate
   pip install --upgrade pip setuptools wheel
   pip install mcp
   ```
2. Copy env file and set your URLs:
   ```bash
   cp scripts/mcp_local_server.env.example ~/.config/mcp-local.env
   ```
3. Install systemd user unit (edit paths if needed):
   ```bash
   mkdir -p ~/.config/systemd/user
   cp systemd/mcp-local.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now mcp-local.service
   ```

## Security notes
- Default bind is loopback (`127.0.0.1`) for safety.
- If exposing beyond localhost, add auth/token + firewall allowlisting.
