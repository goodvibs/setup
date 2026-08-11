#!/bin/sh
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGINS_BIN="$ROOT/plugins/bin"

mkdir -p "$PLUGINS_BIN"

cat > "$PLUGINS_BIN/zsh-helix-mode" <<EOF
#!/usr/bin/env zsh
source "$HOME/Developer/Personal/zsh-helix-mode/zsh-helix-mode.zsh"
EOF
chmod +x "$PLUGINS_BIN/zsh-helix-mode"
