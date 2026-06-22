#!/usr/bin/env bash
# Install config to ~/.config/determinator and add an idempotent sentinel block to the shell rc.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
REPO="$(cd "$HERE/.." && pwd)"
HOME_DIR="${DETERMINATOR_HOME:-$HOME/.local/share/determinator}"
CFG="${DETERMINATOR_CONFIG_DIR:-$HOME/.config/determinator}"

mkdir -p "$CFG"
# Don't clobber a customized config; only write if absent.
if [ ! -f "$CFG/determinator.env" ]; then cp "$REPO/config/determinator.env.example" "$CFG/determinator.env"; log "wrote $CFG/determinator.env"; else log "kept existing $CFG/determinator.env"; fi
if [ ! -f "$CFG/models.conf" ]; then cp "$REPO/config/models.conf" "$CFG/models.conf"; log "wrote $CFG/models.conf"; else log "kept existing $CFG/models.conf"; fi

# Pick the rc file from the user's login shell.
rc="$HOME/.bashrc"
case "${SHELL:-}" in
  *zsh) rc="$HOME/.zshrc" ;;
  *bash) rc="$HOME/.bashrc" ;;
esac

touch "$rc"
backup_file "$rc"
remove_block "$rc"   # idempotent: drop any prior block before re-adding
{
  echo "$DET_SENTINEL_START"
  echo "export DETERMINATOR_HOME=\"$HOME_DIR\""
  echo "export DETERMINATOR_CONFIG_DIR=\"$CFG\""
  echo 'export PATH="$DETERMINATOR_HOME/bin:$PATH"'
  echo "[ -f \"$CFG/determinator.env\" ] && . \"$CFG/determinator.env\""
  echo "alias dt=determinator"
  echo "$DET_SENTINEL_END"
} >> "$rc"
log "updated $rc — open a new shell or run: source $rc"
