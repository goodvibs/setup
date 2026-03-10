#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETUP_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLUGINS_BIN="$SETUP_ROOT/plugins/bin"
ZVM_SRC="$(cd "$SETUP_ROOT/../zvm" 2>/dev/null && pwd)"

if [ -z "$ZVM_SRC" ]; then
  echo "zvm source not found at $SETUP_ROOT/../zvm" >&2
  exit 1
fi

go build -C "$ZVM_SRC" -ldflags "-s -w" -o "$PLUGINS_BIN/"
