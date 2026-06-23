#!/usr/bin/env bash
# Pull models for all 'local'-backend tiers. Guide (don't auto-run) cloud sign-in.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
# shellcheck source=tierlib.sh
. "$HERE/tierlib.sh"
det_load_config || exit 0

if ! have ollama; then
  warn "ollama not installed; skipping model pull. Install it and re-run: make install"
  exit 0
fi

need_signin=0
for t in ${DET_TIERS:-}; do
  det_resolve_tier "$t" || continue
  case "$DET_R_BACKEND" in
    local)
      if ollama list 2>/dev/null | awk 'NR>1{print $1}' | grep -qx "$DET_R_MODEL"; then
        log "tier '$t': model already pulled ($DET_R_MODEL)"
      else
        log "tier '$t': model '$DET_R_MODEL' may be several GB and needs RAM headroom for ≥64k context."
        if confirm "Pull $DET_R_MODEL now?"; then ollama pull "$DET_R_MODEL" || warn "pull failed"; else warn "skipped"; fi
      fi
      ;;
    cloud) need_signin=1 ;;
  esac
done

if [ "$need_signin" = 1 ]; then
  log "One or more tiers use Ollama cloud models. To enable them, sign in once:  ollama signin"
  log "(Cloud models run on Ollama's cloud — not local, not free, but no local RAM limit.)"
fi
