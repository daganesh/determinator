# determinator tier resolution + backend wiring. Source this; don't exec it.
# Consumed by bin/determinator and bin/determinator-escalate.

DET_CFG_DIR="${DETERMINATOR_CONFIG_DIR:-$HOME/.config/determinator}"

# Load the user config (defines DET_TIERS, DET_TIER_<name>_*, DET_*_TIER).
det_load_config() {
  local conf="$DET_CFG_DIR/determinator.conf"
  if [ ! -f "$conf" ]; then
    echo "determinator: config not found at $conf — run 'make install' first." >&2
    return 1
  fi
  # shellcheck source=/dev/null
  . "$conf"
}

# Resolve a tier name → DET_R_MODEL / DET_R_BACKEND. Returns nonzero if unknown.
det_resolve_tier() {
  local mv="DET_TIER_${1}_MODEL" bv="DET_TIER_${1}_BACKEND"
  DET_R_MODEL="${!mv:-}"
  DET_R_BACKEND="${!bv:-}"
  [ -n "$DET_R_MODEL" ] && [ -n "$DET_R_BACKEND" ]
}

# Apply a backend's environment to the current process.
#   local|cloud → Ollama at localhost (cloud differs only by the model's :cloud suffix)
#   anthropic   → unset everything so `claude` uses the subscription login; opt-in key via secrets.env
det_apply_backend() {
  case "$1" in
    local | cloud)
      export ANTHROPIC_BASE_URL="http://localhost:11434"
      export ANTHROPIC_AUTH_TOKEN="ollama"
      export ANTHROPIC_API_KEY=""
      ;;
    anthropic)
      unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY
      # shellcheck source=/dev/null
      if [ -f "$DET_CFG_DIR/secrets.env" ]; then . "$DET_CFG_DIR/secrets.env"; fi
      ;;
    *)
      echo "determinator: unknown backend '$1'" >&2
      return 1
      ;;
  esac
}
