#!/bin/bash
set -eo pipefail
currDir="$(pwd)"
for dir in $(ls -1d [0-9]* 2>/dev/null | sort -nr); do
    if [ -d "$dir" ] && [ -f "$dir/uninstall.sh" ]; then
        echo "Installing $currDir/$dir/uninstall.sh"
        sh "$currDir/$dir/uninstall.sh"
    fi
done