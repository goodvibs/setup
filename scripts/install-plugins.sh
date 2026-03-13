#!/bin/sh

PLUGINS_INSTALL_SCRIPTS_DIR="$HOME/Developer/Personal/setup/plugins/install-scripts"

for file in $PLUGINS_INSTALL_SCRIPTS_DIR/*.sh; do
    echo "Running plugin install script: $file"
    $file
done
