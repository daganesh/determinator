#!/usr/bin/env bash
# Assert the MCP server speaks the protocol and lists its 3 tools.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
server="$REPO/mcp/local_workers/server.py"

out="$(printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | python3 "$server")"

echo "$out" | grep -q '"protocolVersion"' || { echo "FAIL: no initialize result"; exit 1; }
for t in summarize_diff gen_commit_msg triage_log; do
  echo "$out" | grep -q "\"$t\"" || { echo "FAIL: missing tool $t"; exit 1; }
done
echo "PASS: mcp protocol (initialize + 3 tools)"
