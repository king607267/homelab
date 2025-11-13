#!/bin/bash
set -eo pipefail

k3s_ansible="./k3s_ansible/"
reset_path=${k3s_ansible}reset.yml
hosts_path=${k3s_ansible}inventory/my-cluster/hosts.ini

ansible-playbook $reset_path -i $hosts_path --ask-become-pass
if [ -n "$install_vms" ]; then
  cd ../vms
  tofu destroy --auto-approve
  cd ../k3s
fi