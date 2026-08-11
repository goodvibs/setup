#!/bin/sh
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGINS_BIN="$ROOT/plugins/bin"

mkdir -p "$PLUGINS_BIN"
ln -sf "$HOME/Developer/Personal/git-open/git-open" "$PLUGINS_BIN/git-open"
