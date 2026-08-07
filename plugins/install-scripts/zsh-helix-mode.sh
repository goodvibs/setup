#!/bin/sh

PLUGINS_BIN="$HOME/Developer/Personal/setup/plugins/bin"

cat > "$PLUGINS_BIN/zsh-helix-mode" <<'EOF'
#!/usr/bin/env zsh
source "$HOME/Developer/Personal/zsh-helix-mode/zsh-helix-mode.zsh"
EOF
