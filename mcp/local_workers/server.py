#!/usr/bin/env python3
"""determinator local MCP workers — a stdlib-only stdio MCP server.

Exposes three cheap language tools that run on the local Ollama model, so a
premium Claude Code session can offload them without spending premium tokens:

  - summarize_diff   : summarize a git diff into a short description
  - gen_commit_msg   : write a commit message from a staged diff
  - triage_log       : classify an error/build log and suggest a first action

Transport: newline-delimited JSON-RPC 2.0 over stdio (MCP stdio transport).
No third-party packages required.
"""
from __future__ import annotations

import json
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ollama_client import generate  # noqa: E402

PROTOCOL_VERSION = "2024-11-05"
SERVER_INFO = {"name": "determinator-local-workers", "version": "0.1.0"}

TOOLS = [
    {
        "name": "summarize_diff",
        "description": "Summarize a git diff into a short human-readable change description, using the local Ollama model.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "diff": {"type": "string", "description": "Unified git diff text"},
                "max_words": {"type": "integer", "description": "Approximate length cap", "default": 80},
            },
            "required": ["diff"],
        },
    },
    {
        "name": "gen_commit_msg",
        "description": "Generate a commit message from a staged git diff, using the local Ollama model.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "diff": {"type": "string", "description": "Staged unified git diff text"},
                "style": {"type": "string", "enum": ["conventional", "plain"], "default": "conventional"},
            },
            "required": ["diff"],
        },
    },
    {
        "name": "triage_log",
        "description": "Triage an error/build log: classify severity, extract the root error, and suggest a first action. Local Ollama model.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "log": {"type": "string", "description": "Error or build log text"},
                "context": {"type": "string", "description": "Optional surrounding context"},
            },
            "required": ["log"],
        },
    },
]


def _summarize_diff(args: dict) -> str:
    mw = int(args.get("max_words", 80))
    prompt = (
        f"Summarize the following git diff in at most {mw} words. "
        f"State what changed and why, no preamble.\n\n{args['diff']}"
    )
    return generate(prompt)


def _gen_commit_msg(args: dict) -> str:
    style = args.get("style", "conventional")
    rule = ("Use the Conventional Commits format: a `type(scope): subject` line "
            "(<=72 chars) then an optional body."
            if style == "conventional" else
            "Use a short imperative subject line then an optional body.")
    prompt = (
        f"Write a git commit message for this staged diff. {rule} "
        f"Output only the commit message.\n\n{args['diff']}"
    )
    return generate(prompt)


def _triage_log(args: dict) -> str:
    ctx = f"\n\nContext:\n{args['context']}" if args.get("context") else ""
    prompt = (
        "Triage this log. Reply with three short lines:\n"
        "Severity: <info|warning|error|fatal>\n"
        "Root cause: <one sentence>\n"
        "First action: <one concrete step>\n\n"
        f"Log:\n{args['log']}{ctx}"
    )
    return generate(prompt)


DISPATCH = {
    "summarize_diff": _summarize_diff,
    "gen_commit_msg": _gen_commit_msg,
    "triage_log": _triage_log,
}


def _result(rid, result):
    return {"jsonrpc": "2.0", "id": rid, "result": result}


def _error(rid, code, message):
    return {"jsonrpc": "2.0", "id": rid, "error": {"code": code, "message": message}}


def handle(req: dict):
    method = req.get("method")
    rid = req.get("id")
    if method == "initialize":
        return _result(rid, {
            "protocolVersion": PROTOCOL_VERSION,
            "capabilities": {"tools": {}},
            "serverInfo": SERVER_INFO,
        })
    if method == "tools/list":
        return _result(rid, {"tools": TOOLS})
    if method == "tools/call":
        params = req.get("params") or {}
        name = params.get("name")
        args = params.get("arguments") or {}
        fn = DISPATCH.get(name)
        if fn is None:
            return _error(rid, -32602, f"unknown tool: {name}")
        try:
            text = fn(args)
            return _result(rid, {"content": [{"type": "text", "text": text}]})
        except Exception as e:  # surface as a tool error, not a transport error
            return _result(rid, {"content": [{"type": "text", "text": f"error: {e}"}], "isError": True})
    if method in ("notifications/initialized", "initialized", "notifications/cancelled"):
        return None  # notifications get no response
    if rid is not None:
        return _error(rid, -32601, f"method not found: {method}")
    return None


def main() -> int:
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except json.JSONDecodeError:
            continue
        resp = handle(req)
        if resp is not None:
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
