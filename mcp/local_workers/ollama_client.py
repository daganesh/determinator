"""Tiny zero-dependency client for Ollama's native generate API.

Used by the determinator local MCP workers to run cheap language tasks on the
free, on-machine model. Stdlib only (urllib) so the MCP server needs no pip install.
"""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

DEFAULT_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
DEFAULT_MODEL = os.environ.get("DET_WORKER_MODEL", "llama3.1:8b")


def generate(prompt: str, system: str | None = None, *, model: str | None = None,
             host: str | None = None, num_ctx: int = 8192, timeout: int = 120) -> str:
    """Run a single-shot completion against Ollama's /api/generate and return the text.

    Raises RuntimeError with a friendly message if the daemon is unreachable.
    """
    model = model or DEFAULT_MODEL
    host = (host or DEFAULT_HOST).rstrip("/")
    body: dict = {"model": model, "prompt": prompt, "stream": False, "options": {"num_ctx": num_ctx}}
    if system:
        body["system"] = system
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(f"{host}/api/generate", data=data,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.URLError as e:
        raise RuntimeError(
            f"could not reach Ollama at {host} ({e}). Is the daemon running? "
            f"Try: ollama serve  /  ollama pull {model}"
        ) from e
    return (payload.get("response") or "").strip()
