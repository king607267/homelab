#!/bin/bash
set -eo pipefail

k3s_ansible="./k3s_ansible/"
reset_path=${k3s_ansible}reset.yml
hosts_path=${k3s_ansible}inventory/my-cluster/hosts.ini
echo "Please input vms password:"
ansible-playbook $reset_path -i $hosts_path
if [ -n "$install_vms" ]; then
  cd ../vms
  ./uninstall.sh
  cd ../k3s
fi