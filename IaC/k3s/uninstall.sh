#!/bin/bash
set -eo pipefail

k3sAnsiblePath="k3sAnsible/"
reset_path=${k3sAnsiblePath}reset.yml
hosts_path=${k3sAnsiblePath}inventory/my-cluster/hosts.ini
vmsPath="$( dirname $(pwd))/vms/"
k3sPath="$(pwd)"

echo "Please input vms password:"
ansible-playbook $reset_path -i $hosts_path
if [ -n "$install_vms" ]; then
  cd "$vmsPath"
  ./uninstall.sh
  cd "$k3sPath"
fi