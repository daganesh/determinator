#!/usr/bin/env bash
# Pull the default local model. Guide (do not auto-run) cloud sign-in.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
CFG="${DETERMINATOR_CONFIG_DIR:-$HOME/.config/determinator}"
# shellcheck source=/dev/null
[ -f "$CFG/models.conf" ] && . "$CFG/models.conf"
LOCAL_MODEL="${DET_LOCAL_MODEL:-llama3.1:8b}"
CLOUD_MODEL="${DET_CLOUD_MODEL:-}"

if ! have ollama; then
  warn "ollama not installed; skipping model pull. Install it and re-run: make install"
  exit 0
fi

if ollama list 2>/dev/null | awk 'NR>1{print $1}' | grep -qx "$LOCAL_MODEL"; then
  log "local model already pulled: $LOCAL_MODEL"
else
  log "Local model '$LOCAL_MODEL' can be several GB and needs RAM headroom for ≥64k context."
  if confirm "Pull $LOCAL_MODEL now?"; then ollama pull "$LOCAL_MODEL" || warn "pull failed"; else warn "skipped local model pull"; fi
fi

case "$CLOUD_MODEL" in
  *:cloud)
    log "Cloud tier is set to '$CLOUD_MODEL'. To enable it, sign in once:  ollama signin"
    log "(Cloud models run on Ollama's cloud — not local, not free, but no local RAM limit.)"
    ;;
esac
