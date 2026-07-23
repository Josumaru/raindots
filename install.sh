#!/usr/bin/env bash
# Raindots installer — boots into the Go TUI installer.
set -euo pipefail

REPO_URL="https://github.com/josumaru/raindots.git"

if [[ -v BASH_SOURCE && -n "${BASH_SOURCE[0]:-}" ]]; then
  RAIN_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ ! -d "${RAIN_HOME:-/dev/null}/rain/config/hypr" ]]; then
  RAIN_HOME="${RAIN_DOTS:-$HOME/raindots}"
  if [[ -d "$RAIN_HOME/.git" ]]; then
    git -C "$RAIN_HOME" pull --ff-only
  else
    mkdir -p "$(dirname "$RAIN_HOME")"
    git clone --depth=1 "$REPO_URL" "$RAIN_HOME"
  fi
fi

cd "$RAIN_HOME/installer"
if [[ ! -x installer ]]; then
  echo "==> Building the TUI installer..."
  go build -o installer .
fi
exec ./installer "$@"
