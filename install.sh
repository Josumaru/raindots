#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/josumaru/raindots.git"

# Determine RAIN_HOME (repo root)
if [[ -n "${RAIN_DOTS:-}" ]]; then
    RAIN_HOME="$RAIN_DOTS"
elif [[ "${BASH_SOURCE[0]}" != /* ]] && [[ ! -f "${BASH_SOURCE[0]}" ]]; then
    # Running via curl pipe — no local script path; clone the repo
    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT
    echo "==> Cloning raindots to $TMPDIR"
    git clone --depth=1 "$REPO_URL" "$TMPDIR" || {
        echo "ERROR: Failed to clone $REPO_URL"
        exit 1
    }
    RAIN_HOME="$TMPDIR"
else
    # Running from a local copy: get the script's directory
    RAIN_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
fi

CONFIG_DIR="$RAIN_HOME/rain/config"
BIN_DIR="$RAIN_HOME/rain/bin"
CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> Symlinking configs to $CONFIG_TARGET"
echo ""

for dir in hypr quickshell; do
    src="$CONFIG_DIR/$dir"
    target="$CONFIG_TARGET/$dir"
    [[ -d $src ]] || { echo "  [SKIP] $dir (source not found)"; continue; }
    if [[ -L $target ]] || [[ -d $target ]]; then
        bak="${target}.bak.$(date +%s)"
        echo "  Backing up $target -> $bak"
        mv "$target" "$bak"
    fi
    echo "  $target -> $src"
    ln -sfn "$src" "$target"
done

# CLI binary: rain/bin/ → ~/.config/rain/
bin_src="$BIN_DIR"
bin_target="$CONFIG_TARGET/rain"
if [[ -d $bin_src ]]; then
    mkdir -p "$bin_target" 2>/dev/null || true
    if [[ -L $bin_target ]] || [[ -d $bin_target ]]; then
        echo "  $bin_target -> $bin_src"
        ln -sfn "$bin_src" "$bin_target"
    fi
fi

if [[ ! -f "$BIN_DIR/rain" ]]; then
    echo ""
    echo "  Building rain CLI..."
    if command -v go &>/dev/null; then
        cd "$RAIN_HOME/rain/cli" && go build -o "$BIN_DIR/rain" . 2>/dev/null || true
    else
        echo "  WARN: Go not found — skip rain CLI build"
    fi
fi

echo ""
echo "==> Done. Configs now live from:"
echo "    $CONFIG_DIR"
echo ""
echo "    Add to ~/.bashrc / ~/.zshrc for CLI access:"
echo "    export PATH=\"\$PATH:$BIN_DIR\""
echo ""
echo "    Edit files in raindots/ — changes apply immediately."
echo "    To update later: cd $RAIN_HOME && git pull"
echo "    Or re-run this installer to resync symlinks."