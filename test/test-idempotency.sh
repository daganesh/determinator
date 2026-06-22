#!/usr/bin/env bash
# Run install.sh twice in a sandbox HOME; assert zero duplication.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT

run() {
  env -i HOME="$SB" SHELL=/bin/bash PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    DET_ASSUME_YES=1 DET_SKIP_DEPS=1 \
    DETERMINATOR_HOME="$SB/.local/share/determinator" \
    DETERMINATOR_CONFIG_DIR="$SB/.config/determinator" \
    CLAUDE_CONFIG_DIR="$SB/.claude" \
    bash "$REPO/install.sh" >/dev/null 2>&1
}

run; run

blocks="$(grep -c 'determinator >>>' "$SB/.bashrc" 2>/dev/null || echo 0)"
[ "$blocks" -eq 1 ] || { echo "FAIL: rc sentinel blocks=$blocks (want 1)"; exit 1; }

baks="$(find "$SB" -name '*.det.bak' | wc -l | tr -d ' ')"
[ "$baks" -le 2 ] || { echo "FAIL: too many .det.bak files=$baks"; exit 1; }

if command -v jq >/dev/null 2>&1; then
  dups="$(jq -r '.permissions.allow[]' "$SB/.claude/settings.json" | sort | uniq -d)"
  [ -z "$dups" ] || { echo "FAIL: duplicate permissions: $dups"; exit 1; }
fi

echo "PASS: idempotency (1 rc block, no duplicate permissions)"
