#!/bin/bash
set -eo pipefail
currDir="$(pwd)"
arr=($app_install_sort)
for ((i=${#arr[@]}-1; i>=0; i--)); do
  if [ -d "${arr[i]}" ] && [ -f "${arr[i]}/uninstall.sh" ]; then
    echo "Installing $currDir/${arr[i]}/uninstall.sh"
    sh "$currDir/${arr[i]}/uninstall.sh"
  fi
done