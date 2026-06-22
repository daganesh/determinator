#!/usr/bin/env bash
# Echo "os pkg arch", e.g. "macos brew arm64" or "linux apt x86_64".
set -euo pipefail
arch="$(uname -m)"
case "$(uname -s)" in
  Darwin) os=macos; pkg=brew ;;
  Linux)
    os=linux
    if command -v apt-get >/dev/null 2>&1; then pkg=apt
    elif command -v dnf >/dev/null 2>&1; then pkg=dnf
    elif command -v pacman >/dev/null 2>&1; then pkg=pacman
    else pkg=none; fi ;;
  *) os=unknown; pkg=none ;;
esac
echo "$os $pkg $arch"
