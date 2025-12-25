#!/bin/bash
set -eo pipefail
currDir="$(pwd)"
for dir in $app_install_sort; do
    if [ -d "$dir" ] && [ -f "$dir/uninstall.sh" ]; then
        echo "Installing $currDir/$dir/uninstall.sh"
        sh "$currDir/$dir/uninstall.sh"
    fi
done