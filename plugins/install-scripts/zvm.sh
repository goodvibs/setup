#!/bin/sh
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGINS_BIN="$ROOT/plugins/bin"

mkdir -p "$PLUGINS_BIN"

go build -C "$HOME/Developer/Personal/zvm" -ldflags "-s -w" -o "$PLUGINS_BIN/"
chmod +x "$PLUGINS_BIN/zvm" 2>/dev/null || true

ln -sf "$HOME/.zvm/bin/zig" "$PLUGINS_BIN/zig"
