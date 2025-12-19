#!/bin/bash
set -eo pipefail
currDir="$(pwd)"
#helm repo update
for dir in [0-9]*; do
    if [ -d "$dir" ] && [ -f "$dir/install.sh" ]; then
        echo "Installing $currDir/$dir/install.sh"
        sh "$currDir/$dir/install.sh"
    fi
done