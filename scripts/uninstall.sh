#!/usr/bin/env bash
# Reverse every install step using sentinels + backups. Leaves Ollama/models intact.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CFG="${DETERMINATOR_CONFIG_DIR:-$HOME/.config/determinator}"
HOME_DIR="${DETERMINATOR_HOME:-$HOME/.local/share/determinator}"

# 1. shell rc blocks
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do remove_block "$rc"; done
log "removed shell rc blocks"

# 2. MCP server
if have claude; then claude mcp remove determinator-local-workers -s user >/dev/null 2>&1 || true; log "removed MCP server"; fi

# 3. slash commands (restore any .det.bak collisions)
if [ -d "$HOME_DIR/claude/commands" ]; then
  for f in "$HOME_DIR/claude/commands/"*.md; do
    [ -e "$f" ] || continue
    dest="$CLAUDE_DIR/commands/$(basename "$f")"
    rm -f "$dest"
    [ -f "$dest.det.bak" ] && mv "$dest.det.bak" "$dest"
  done
  log "removed slash commands"
fi

# 3b. subagent definitions (restore any .det.bak collisions)
if [ -d "$HOME_DIR/claude/agents" ]; then
  for f in "$HOME_DIR/claude/agents/"*.md; do
    [ -e "$f" ] || continue
    dest="$CLAUDE_DIR/agents/$(basename "$f")"
    rm -f "$dest"
    [ -f "$dest.det.bak" ] && mv "$dest.det.bak" "$dest"
  done
  log "removed subagents"
fi

# 4. permissions: jq-remove only our entries
settings="$CLAUDE_DIR/settings.json"
if [ -f "$settings" ] && have jq; then
  tmp="$(mktemp)"
  jq '
    if .permissions.allow then
      .permissions.allow |= map(select(
        . != "Bash(ollama:*)" and
        . != "Bash(determinator:*)" and
        . != "Bash(determinator-escalate:*)" and
        . != "mcp__determinator-local-workers__*"))
    else . end
  ' "$settings" > "$tmp" && cat "$tmp" > "$settings"
  rm -f "$tmp"
  log "removed determinator permissions"
fi

# 5. config + installed copy (prompt; secrets included)
if confirm "Remove $CFG (config + any stored API key)?"; then rm -rf "$CFG"; log "removed $CFG"; fi
if confirm "Remove installed copy at $HOME_DIR?"; then rm -rf "$HOME_DIR"; log "removed $HOME_DIR"; fi

log "Done. Ollama and any pulled models were left intact."
