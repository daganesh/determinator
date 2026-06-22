#!/usr/bin/env bash
# Ensure ollama / claude / python3 / jq are present. Never installs without confirming.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
. "$HERE/lib.sh"
read -r OS PKG _ARCH <<EOF
$("$HERE/detect-os.sh")
EOF

ensure_ollama() {
  have ollama && { log "ollama present"; return 0; }
  log "ollama not found."
  case "$OS" in
    macos) confirm "Install ollama via Homebrew?" && brew install ollama || warn "skipped ollama — install from https://ollama.com" ;;
    linux) confirm "Install ollama via the official script (curl … | sh)?" && curl -fsSL https://ollama.com/install.sh | sh || warn "skipped ollama — install from https://ollama.com" ;;
    *) warn "install ollama manually from https://ollama.com" ;;
  esac
}

ensure_claude() {
  have claude && { log "claude present"; return 0; }
  warn "Claude Code ('claude') not found. Install it, e.g.: npm i -g @anthropic-ai/claude-code  (see https://docs.claude.com/claude-code)"
}

# ensure_pkg <bin> <brew-name> <apt/dnf-name>
ensure_pkg() {
  have "$1" && { log "$1 present"; return 0; }
  log "$1 not found."
  case "$PKG" in
    brew) confirm "Install $1 via brew?" && brew install "$2" || warn "skipped $1" ;;
    apt)  confirm "Install $1 via apt-get (sudo)?" && sudo apt-get update && sudo apt-get install -y "$3" || warn "skipped $1" ;;
    dnf)  confirm "Install $1 via dnf (sudo)?" && sudo dnf install -y "$3" || warn "skipped $1" ;;
    *) warn "install $1 manually" ;;
  esac
}

ensure_ollama
ensure_claude
ensure_pkg python3 python python3
ensure_pkg jq jq jq
