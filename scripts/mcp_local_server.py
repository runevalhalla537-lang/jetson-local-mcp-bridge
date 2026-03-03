#!/usr/bin/env python3
import json
import os
import subprocess
import urllib.request
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("local-network-tools", host="127.0.0.1", port=8765)

UBO_BRIDGE_URL = os.getenv("UBO_BRIDGE_URL", "http://<UBOPOD_IP>:8787")
SPARK_OLLAMA_URL = os.getenv("SPARK_OLLAMA_URL", "http://<SPARK_IP>:11434")


def _post(url: str, payload: dict) -> dict:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read().decode("utf-8"))


def _get(url: str) -> dict:
    with urllib.request.urlopen(url, timeout=10) as r:
        return json.loads(r.read().decode("utf-8"))


def _run(cmd: list[str]) -> dict:
    p = subprocess.run(cmd, capture_output=True, text=True)
    return {
        "ok": p.returncode == 0,
        "code": p.returncode,
        "stdout": p.stdout.strip(),
        "stderr": p.stderr.strip(),
    }


@mcp.tool()
def ubopod_status() -> dict:
    """Check Ubo bridge health."""
    return _get(f"{UBO_BRIDGE_URL}/health")


@mcp.tool()
def ubopod_notify(title: str, content: str) -> dict:
    """Send a Ubo notification via bridge."""
    return _post(f"{UBO_BRIDGE_URL}/notify", {"title": title, "content": content})


@mcp.tool()
def ubopod_speak(text: str) -> dict:
    """Speak text on Ubo via bridge."""
    return _post(f"{UBO_BRIDGE_URL}/speak", {"text": text})


@mcp.tool()
def spark_ollama_tags() -> dict:
    """Fetch model tags from Spark Ollama."""
    return _get(f"{SPARK_OLLAMA_URL}/api/tags")


@mcp.tool()
def spark_model_warm_status() -> dict:
    """Fetch currently loaded/warm models from Spark Ollama (/api/ps)."""
    return _get(f"{SPARK_OLLAMA_URL}/api/ps")


@mcp.tool()
def ubopod_quickcheck(notify: bool = False) -> dict:
    """Run Ubo quickcheck workflow script and return report path/status."""
    cmd = ["bash", "scripts/ubopod_quickcheck.sh"]
    if notify:
        cmd.append("--notify")
    result = _run(cmd)

    report_path = ""
    for line in result["stdout"].splitlines():
        if line.startswith("Wrote report:"):
            report_path = line.replace("Wrote report:", "").strip()
            break

    result["report_path"] = report_path
    return result


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
