#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETUP_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLUGINS_BIN="$SETUP_ROOT/plugins/bin"
GIT_OPEN_SRC="$(cd "$SETUP_ROOT/../git-open" 2>/dev/null && pwd)"

if [ -z "$GIT_OPEN_SRC" ] || [ ! -f "$GIT_OPEN_SRC/git-open" ]; then
  echo "git-open not found at $SETUP_ROOT/../git-open" >&2
  exit 1
fi

cp "$GIT_OPEN_SRC/git-open" "$PLUGINS_BIN/"
