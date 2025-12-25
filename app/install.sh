#!/bin/bash
set -eo pipefail
currDir="$(pwd)"
#helm repo update
for dir in $app_install_sort; do
    if [[ ! $dir == \#* ]] && [ -f "$dir/install.sh" ]; then
        echo "Installing $currDir/$dir/install.sh"
        sh "$currDir/$dir/install.sh"
    fi
done