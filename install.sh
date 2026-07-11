#!/usr/bin/env zsh
set -euo pipefail

RAIN_HOME="${0:A:h}"
CONFIG_DIR="$RAIN_HOME/rain/config"
BIN_DIR="$RAIN_HOME/rain/bin"
CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> Symlinking configs to $CONFIG_TARGET"
echo ""

# Config dirs: rain/config/* → ~/.config/*
for dir in hypr quickshell; do
    src="$CONFIG_DIR/$dir"
    target="$CONFIG_TARGET/$dir"

    [[ -d $src ]] || { echo "  [SKIP] $dir (source not found)"; continue; }

    # Backup existing real dir/symlink
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

# Build rain CLI if binary missing
if [[ ! -f "$BIN_DIR/rain" ]]; then
    echo ""
    echo "  Building rain CLI..."
    "$RAIN_HOME/rain/cli/build.sh" 2>/dev/null || echo "  WARN: rain CLI build failed (install Go to fix)"
fi

echo ""
echo "==> Done. Configs now live from:"
echo "    $CONFIG_DIR"
echo ""
echo "    Add to ~/.zshrc for CLI access:"
echo "    export PATH=\"\$PATH:$BIN_DIR\""
echo ""
echo "    Edit files in raindots/ — changes apply immediately."
