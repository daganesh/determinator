#!/usr/bin/env bash
# Merge determinator's permission allow-list into ~/.claude/settings.json (jq, no clobber).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
settings="$CLAUDE_DIR/settings.json"

mkdir -p "$CLAUDE_DIR"
[ -f "$settings" ] || echo '{}' > "$settings"
if ! have jq; then warn "jq not found; skipping permissions merge"; exit 0; fi
backup_file "$settings"

adds='["Bash(ollama:*)","Bash(determinator:*)","Bash(determinator-escalate:*)","mcp__determinator-local-workers__*"]'
tmp="$(mktemp)"
jq --argjson adds "$adds" '
  .permissions = (.permissions // {})
  | .permissions.allow = (((.permissions.allow // []) + $adds) | unique)
' "$settings" > "$tmp" && cat "$tmp" > "$settings"
rm -f "$tmp"
log "merged determinator permissions into $settings"
