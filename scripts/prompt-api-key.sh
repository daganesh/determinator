#!/usr/bin/env bash
# Premium auth. DEFAULT = Claude subscription login (no key asked). API key is opt-in.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
CFG="${DETERMINATOR_CONFIG_DIR:-$HOME/.config/determinator}"
mkdir -p "$CFG"

log "Premium tier authentication:"
echo "  [1] Use my Claude subscription login (recommended — no metered cost)   [default]"
echo "  [2] Use a metered Anthropic API key"

if [ "${DET_ASSUME_YES:-0}" = "1" ]; then
  choice=1
else
  printf "Choose [1/2]: "
  read -r choice || choice=1
fi

case "$choice" in
  2)
    printf "Paste ANTHROPIC_API_KEY (input hidden): "
    stty -echo 2>/dev/null || true
    read -r key || key=""
    stty echo 2>/dev/null || true
    echo
    if [ -n "$key" ]; then
      umask 077
      printf 'export ANTHROPIC_API_KEY=%q\n' "$key" > "$CFG/secrets.env"
      chmod 600 "$CFG/secrets.env"
      log "wrote $CFG/secrets.env (chmod 600). Premium tier will use the metered API."
    else
      warn "empty key — staying on subscription mode."
    fi
    ;;
  *)
    # Ensure no stale key forces metered billing.
    [ -f "$CFG/secrets.env" ] && { rm -f "$CFG/secrets.env"; log "removed prior secrets.env"; }
    log "Premium uses your Claude subscription login. If not logged in yet, run: claude  (then /login)."
    ;;
esac
