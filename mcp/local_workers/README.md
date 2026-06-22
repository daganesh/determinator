# determinator local MCP workers

A **stdlib-only** stdio MCP server that runs cheap language tasks on your local Ollama
model. It lets a premium Claude Code session offload routine text work without spending
premium tokens.

## Tools

| Tool | Input | Does |
|---|---|---|
| `summarize_diff` | `diff`, `max_words?` | Short human description of a git diff |
| `gen_commit_msg` | `diff`, `style?` (`conventional`\|`plain`) | Commit message from a staged diff |
| `triage_log` | `log`, `context?` | Severity + root cause + first action for an error/build log |

## How it works

- Transport: newline-delimited JSON-RPC 2.0 over stdio (the MCP stdio transport).
- Model calls: `ollama_client.py` POSTs to Ollama's native `/api/generate` at
  `$OLLAMA_HOST` (default `http://localhost:11434`) using the model in `$DET_WORKER_MODEL`
  (default `llama3.1:8b`). No third-party Python packages are needed.

## Registration

The installer registers it user-scoped (available in every project, no per-project prompt):

```bash
claude mcp add -s user \
  -e OLLAMA_HOST=http://localhost:11434 \
  -e DET_WORKER_MODEL=llama3.1:8b \
  determinator-local-workers -- python3 /path/to/mcp/local_workers/server.py
```

Equivalent `.mcp.json` (project scope or plugin form):

```json
{
  "mcpServers": {
    "determinator-local-workers": {
      "type": "stdio",
      "command": "python3",
      "args": ["${CLAUDE_PROJECT_DIR:-.}/mcp/local_workers/server.py"],
      "env": { "OLLAMA_HOST": "http://localhost:11434", "DET_WORKER_MODEL": "llama3.1:8b" }
    }
  }
}
```

## Smoke test

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | python3 server.py
```
