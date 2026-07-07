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

cat <<'BANNER'

  determinator installer
  ----------------------
  This will (asking before anything that installs or downloads):
    • check deps: ollama, claude, python3, jq
    • pull the local-tier model (several GB) and start the Ollama daemon
    • add a small block to your shell rc (PATH + `dt` alias); backed up first
    • register the local MCP workers with Claude Code (user scope)
    • install the /dt-* slash commands, subagents, and permission allow-list
  Premium tier uses your Claude subscription login by default (no API key asked).
  Fully reversible: `make uninstall`.

BANNER

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

rc="$HOME/.bashrc"; case "${SHELL:-}" in *zsh) rc="$HOME/.zshrc" ;; esac
cat <<SUMMARY

  ✓ determinator installed.

  Next:
    1. Load it:        source $rc        (or open a new terminal)
    2. See your tiers: determinator list
    3. Full check:     determinator doctor
    4. Start cheap:    determinator local        (alias: dt local)
       Start premium:  determinator reasoning
    5. Your usage:     run  /dt-insights  inside a Claude session

  Premium (reasoning) uses your Claude subscription — make sure you're logged in:
  run \`claude\` once and complete /login if you haven't.

SUMMARY
