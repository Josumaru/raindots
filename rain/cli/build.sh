#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
echo "==> Building rain CLI..."
go build -o ../bin/rain .
echo "==> Done: rain/cli/rain -> rain/bin/rain"
