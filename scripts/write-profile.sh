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
if [ ! -f "$CFG/determinator.conf" ]; then
  cp "$REPO/config/determinator.conf.example" "$CFG/determinator.conf"
  log "wrote $CFG/determinator.conf"
else
  log "kept existing $CFG/determinator.conf"
fi

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
  echo "alias dt=determinator"
  echo "$DET_SENTINEL_END"
} >> "$rc"
log "updated $rc — open a new shell or run: source $rc"
