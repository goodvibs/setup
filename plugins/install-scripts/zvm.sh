#!/bin/sh

PLUGINS_BIN="$HOME/Developer/Personal/setup/plugins/bin"
ZVM_SRC="$HOME/Developer/Personal/zvm"

go build -C "$HOME/Developer/Personal/zvm" -ldflags "-s -w" -o "$PLUGINS_BIN/"

ln -s "$HOME/.zvm/bin/zig" "$PLUGINS_BIN"
