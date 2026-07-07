#!/usr/bin/env bash
# Shared helpers for determinator install/uninstall scripts. Source, don't exec.

DET_SENTINEL_START="# >>> determinator >>>"
DET_SENTINEL_END="# <<< determinator <<<"

log()  { printf '\033[1;34m[determinator]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[determinator] warning:\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[determinator] error:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# confirm "question" — 0 if yes. Auto-yes when DET_ASSUME_YES=1 (non-interactive installs).
confirm() {
  [ "${DET_ASSUME_YES:-0}" = "1" ] && return 0
  printf '%s [y/N] ' "$1"
  read -r _reply || return 1
  case "$_reply" in [yY] | [yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

# backup_file FILE — copy to FILE.det.bak ONCE (never overwrite an existing backup).
backup_file() {
  [ -f "$1" ] || return 0
  [ -f "$1.det.bak" ] || cp "$1" "$1.det.bak"
}

# Ensure the Ollama daemon is reachable; try to start it, then wait. 0 if up, 1 otherwise.
ensure_ollama_daemon() {
  have ollama || return 1
  have curl || { warn "curl not found; cannot check Ollama daemon"; return 1; }
  curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1 && return 0
  log "starting the Ollama daemon…"
  if have brew && brew services start ollama >/dev/null 2>&1; then :; else
    nohup ollama serve >/dev/null 2>&1 &
  fi
  local i
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    curl -fsS http://localhost:11434/api/tags >/dev/null 2>&1 && { log "Ollama daemon is up."; return 0; }
    sleep 1
  done
  warn "Ollama daemon didn't come up. Start it (\`ollama serve\` or \`brew services start ollama\`), then re-run: make install"
  return 1
}

# remove_block FILE — strip the determinator sentinel block in place, portably (awk, no GNU sed).
remove_block() {
  local file="$1" tmp
  [ -f "$file" ] || return 0
  tmp="$(mktemp)"
  awk -v s="$DET_SENTINEL_START" -v e="$DET_SENTINEL_END" '
    $0==s {skip=1; next}
    $0==e {skip=0; next}
    skip!=1 {print}
  ' "$file" > "$tmp" && cat "$tmp" > "$file"
  rm -f "$tmp"
}
