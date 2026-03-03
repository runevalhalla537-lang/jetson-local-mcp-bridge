# Jetson Python MCP Server Setup

## Install
```bash
python3 -m venv ~/mcp-server/.venv
source ~/mcp-server/.venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install mcp
```

## Configure
Create `~/.config/mcp-local.env`:
```bash
UBO_BRIDGE_URL=http://<UBOPOD_IP>:8787
SPARK_OLLAMA_URL=http://<SPARK_IP>:11434
```

## Service
```bash
mkdir -p ~/.config/systemd/user
cp systemd/mcp-local.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now mcp-local.service
```

## Verify
```bash
systemctl --user status mcp-local.service
journalctl --user -u mcp-local.service -f
```

MCP endpoint:
- `http://127.0.0.1:8765/mcp`

## Provided tools
- `ubopod_status()`
- `ubopod_notify(title, content)`
- `ubopod_speak(text)`
- `spark_ollama_tags()`
