#!/usr/bin/env bash
# Register the local-LLM MCP workers, user-scoped (no per-project approval). Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
HOME_DIR="${DETERMINATOR_HOME:-$HOME/.local/share/determinator}"
CFG="${DETERMINATOR_CONFIG_DIR:-$HOME/.config/determinator}"
# Use the 'local' tier's model as the free worker model (fall back if unset).
# shellcheck source=/dev/null
[ -f "$CFG/determinator.conf" ] && . "$CFG/determinator.conf"
WORKER_MODEL="${DET_TIER_local_MODEL:-llama3.1:8b}"
SERVER="$HOME_DIR/mcp/local_workers/server.py"

if ! have claude; then warn "claude not found; skipping MCP registration"; exit 0; fi
[ -f "$SERVER" ] || { warn "MCP server not found at $SERVER; skipping"; exit 0; }

claude mcp remove determinator-local-workers -s user >/dev/null 2>&1 || true
claude mcp add -s user \
  -e OLLAMA_HOST=http://localhost:11434 \
  -e DET_WORKER_MODEL="$WORKER_MODEL" \
  determinator-local-workers -- python3 "$SERVER"
log "registered MCP server 'determinator-local-workers' (user scope, model=$WORKER_MODEL)"
