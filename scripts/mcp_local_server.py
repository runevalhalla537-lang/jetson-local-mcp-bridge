#!/usr/bin/env python3
import json
import os
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


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
