#!/usr/bin/env bash
# determinator doctor — per-tier and per-component health matrix.
#   doctor.sh           full check (incl. network/model smoke tests)
#   doctor.sh --quick   offline structural checks only
set -uo pipefail   # NOT -e: we run every check and summarize
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
# shellcheck source=tierlib.sh
. "$HERE/tierlib.sh"
REPO="$(cd "$HERE/.." && pwd)"
HOME_DIR="${DETERMINATOR_HOME:-$HOME/.local/share/determinator}"
CFG="${DETERMINATOR_CONFIG_DIR:-$HOME/.config/determinator}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BASE="$HOME_DIR"; [ -d "$BASE" ] || BASE="$REPO"   # work pre- or post-install
QUICK=0; [ "${1:-}" = "--quick" ] && QUICK=1

FAIL=0
row() { # row ok|no|skip LABEL [detail]
  case "$1" in
    ok)   printf '  \033[1;32m✓\033[0m %-20s %s\n' "$2" "${3:-}" ;;
    no)   printf '  \033[1;31m✗\033[0m %-20s %s\n' "$2" "${3:-}"; FAIL=$((FAIL + 1)) ;;
    skip) printf '  \033[1;33m–\033[0m %-20s %s\n' "$2" "${3:-skipped}" ;;
  esac
}

echo "determinator doctor ($([ $QUICK = 1 ] && echo quick || echo full))  base=$BASE"
echo "-- toolchain --"
for t in claude python3 jq; do have "$t" && row ok "$t" "$(command -v "$t")" || row no "$t" "missing"; done
have ollama && row ok "ollama" "$(command -v ollama)" || row no "ollama" "missing (needed for local/cloud tiers)"

echo "-- structure --"
config_ok=0
if [ -f "$CFG/determinator.conf" ]; then row ok "config" "$CFG/determinator.conf"; config_ok=1; else row no "config" "run make install"; fi
[ -f "$BASE/mcp/local_workers/server.py" ] && row ok "mcp server file" || row no "mcp server file"

# MCP protocol ping (offline)
server="$BASE/mcp/local_workers/server.py"
if [ -f "$server" ] && have python3; then
  out="$(printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | python3 "$server" 2>/dev/null)"
  if echo "$out" | grep -q summarize_diff && echo "$out" | grep -q gen_commit_msg && echo "$out" | grep -q triage_log; then
    row ok "mcp tools" "3 tools respond"
  else row no "mcp tools" "tools/list failed"; fi
else row skip "mcp tools" "need python3 + server"; fi

# MCP registration
if have claude; then
  claude mcp get determinator-local-workers >/dev/null 2>&1 && row ok "mcp registered" || row no "mcp registered" "run scripts/register-mcp.sh"
else row skip "mcp registered" "claude not found"; fi

# insights dry-run (offline)
sample="$BASE/analytics/sample/sanitized-sessions.jsonl"
if have python3 && [ -f "$sample" ]; then
  python3 "$BASE/analytics/analyze_sessions.py" --path "$sample" >/dev/null 2>&1 && row ok "insights" "sample parsed" || row no "insights"
else row skip "insights" "need python3 + sample"; fi

# permissions merged
if have jq && [ -f "$CLAUDE_DIR/settings.json" ]; then
  jq -e '.permissions.allow | index("mcp__determinator-local-workers__*")' "$CLAUDE_DIR/settings.json" >/dev/null 2>&1 \
    && row ok "permissions" || row no "permissions" "run scripts/set-permissions.sh"
else row skip "permissions" "need jq + settings.json"; fi

# Load config so we can enumerate tiers.
[ "$config_ok" = 1 ] && det_load_config 2>/dev/null

echo "-- tiers (configured: ${DET_TIERS:-none}) --"
if [ "$config_ok" != 1 ]; then
  row skip "tiers" "no config"
elif [ $QUICK = 1 ]; then
  for t in ${DET_TIERS:-}; do
    det_resolve_tier "$t" && row ok "tier: $t" "$DET_R_BACKEND / $DET_R_MODEL" || row no "tier: $t" "missing model/backend"
  done
  echo "  (live smoke tests skipped — quick mode)"
elif ! have claude; then
  row skip "tiers" "claude not found"
else
  command -v curl >/dev/null 2>&1 && curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1 \
    && row ok "ollama daemon" || row no "ollama daemon" "not reachable (local/cloud will fail)"
  for t in ${DET_TIERS:-}; do
    if ! det_resolve_tier "$t"; then row no "tier: $t" "unresolved"; continue; fi
    ( det_apply_backend "$DET_R_BACKEND"
      out="$(claude -p 'reply with the single word: ok' --model "$DET_R_MODEL" --output-format json 2>/dev/null)"
      echo "$out" | grep -qiE '"result"|(^|[^a-z])ok([^a-z]|$)' ) \
      && row ok "tier: $t" "$DET_R_MODEL" || row no "tier: $t" "no reply from $DET_R_MODEL"
  done
  # escalation end-to-end (uses the plan tier)
  if "$BASE/bin/determinator-escalate" plan "reply with the single word: ok" >/dev/null 2>&1; then
    row ok "escalation" "plan returned"
  else row no "escalation" "determinator-escalate plan failed"; fi
fi

echo
if [ $FAIL -eq 0 ]; then echo "doctor: all checks passed"; exit 0; else echo "doctor: $FAIL check(s) failed"; exit 1; fi
