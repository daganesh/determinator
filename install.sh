#!/usr/bin/env bash
# determinator installer — idempotent, reversible backbone.
# Copies the repo to ~/.local/share/determinator, wires the shell, registers MCP,
# installs commands, and merges permissions. Re-runnable; `make uninstall` reverts.
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
. "$REPO/scripts/lib.sh"

export DETERMINATOR_HOME="${DETERMINATOR_HOME:-$HOME/.local/share/determinator}"
export DETERMINATOR_CONFIG_DIR="${DETERMINATOR_CONFIG_DIR:-$HOME/.config/determinator}"

log "Installing determinator → $DETERMINATOR_HOME"

# 1. preflight
read -r OS PKG ARCH <<EOF
$("$REPO/scripts/detect-os.sh")
EOF
log "detected: os=$OS pkg=$PKG arch=$ARCH"
[ "$OS" = unknown ] && { err "unsupported OS (need macOS or Linux)"; exit 1; }
[ "$OS" = macos ] && [ "$ARCH" != arm64 ] && warn "non-arm64 mac: local-model performance/RAM may suffer."

# 2. dependencies (DET_SKIP_DEPS=1 to manage them yourself / for testing)
if [ "${DET_SKIP_DEPS:-0}" = "1" ]; then log "skipping dependency checks (DET_SKIP_DEPS=1)"; else "$REPO/scripts/deps.sh"; fi

# 3. copy repo → install home (exclude VCS and local bak files)
mkdir -p "$DETERMINATOR_HOME"
( cd "$REPO" && tar --exclude='./.git' --exclude='*.det.bak' -cf - . ) | ( cd "$DETERMINATOR_HOME" && tar -xf - )
chmod +x "$DETERMINATOR_HOME/bin/"* 2>/dev/null || true
chmod +x "$DETERMINATOR_HOME/scripts/"*.sh 2>/dev/null || true
log "copied files to $DETERMINATOR_HOME"

# 4–8. wire everything (run the installed copies so paths resolve to $DETERMINATOR_HOME)
"$DETERMINATOR_HOME/scripts/write-profile.sh"
"$DETERMINATOR_HOME/scripts/pull-models.sh"
"$DETERMINATOR_HOME/scripts/prompt-api-key.sh"
"$DETERMINATOR_HOME/scripts/register-mcp.sh"
"$DETERMINATOR_HOME/scripts/install-commands.sh"
"$DETERMINATOR_HOME/scripts/set-permissions.sh"

# 9. quick verify
if [ -x "$DETERMINATOR_HOME/scripts/doctor.sh" ]; then
  "$DETERMINATOR_HOME/scripts/doctor.sh" --quick || warn "doctor reported issues (see above)"
fi

log "Done. Open a new shell (or: source your rc), then run:  determinator local"
