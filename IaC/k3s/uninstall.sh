#!/bin/bash
set -eo pipefail

k3sAnsiblePath="k3sAnsible/"
reset_path=playbooks/reset.yml
hosts_path=inventory.yml
k3sPath="$(pwd)"

echo "Please input vms password:"
cd "$k3sAnsiblePath"
ansible-playbook $reset_path -i $hosts_path
cd "$k3sPath"
if [ -f "inventory.yml" ]; then
  rm inventory.yml
fi