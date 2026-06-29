#!/usr/bin/env bash
# Copy slash commands (+ optional skills and the starter .agents KB) into ~/.claude.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
REPO="$(cd "$HERE/.." && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$CLAUDE_DIR/commands"

for f in "$REPO/claude/commands/"*.md; do
  [ -e "$f" ] || continue
  dest="$CLAUDE_DIR/commands/$(basename "$f")"
  # Back up only a genuine user collision — not our own file from a prior install
  # (otherwise re-installs litter backups and uninstall would restore our file).
  if [ -f "$dest" ] && ! cmp -s "$f" "$dest"; then backup_file "$dest"; fi
  cp "$f" "$dest"
done
log "installed slash commands → $CLAUDE_DIR/commands"

# Subagent definitions (Paradigm 1: in-context, same-backend escalation).
if ls "$REPO/claude/agents/"*.md >/dev/null 2>&1; then
  mkdir -p "$CLAUDE_DIR/agents"
  for f in "$REPO/claude/agents/"*.md; do
    dest="$CLAUDE_DIR/agents/$(basename "$f")"
    if [ -f "$dest" ] && ! cmp -s "$f" "$dest"; then backup_file "$dest"; fi
    cp "$f" "$dest"
  done
  log "installed subagents → $CLAUDE_DIR/agents"
fi

# Optional skill mirrors (only if any SKILL.md exists).
if ls "$REPO/claude/skills/"*/SKILL.md >/dev/null 2>&1; then
  mkdir -p "$CLAUDE_DIR/skills"
  cp -R "$REPO/claude/skills/." "$CLAUDE_DIR/skills/"
  log "installed skills → $CLAUDE_DIR/skills"
fi

# Starter .agents knowledge base (reference; users adapt per project).
if [ -d "$REPO/agents" ]; then
  mkdir -p "$CLAUDE_DIR/.agents"
  cp -R "$REPO/agents/." "$CLAUDE_DIR/.agents/"
  log "installed starter KB → $CLAUDE_DIR/.agents"
fi
