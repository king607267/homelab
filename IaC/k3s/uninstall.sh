#!/bin/bash
set -eo pipefail
. var.sh

rm -f inventory.yml
echo "---" >> inventory.yml
echo "k3s_cluster:" >> inventory.yml
echo "  children:" >> inventory.yml
echo "    server:" >> inventory.yml
echo "      hosts:" >> inventory.yml
echo "        $(kubectl get nodes --selector='node-role.kubernetes.io/control-plane=true' -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | sed 's/ /:\n        /g;'):" >> inventory.yml
echo "    agent:" >> inventory.yml
echo "      hosts:" >> inventory.yml
echo "        $(kubectl get nodes  -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | sed 's/ /:\n        /g;'):" >> inventory.yml
grep -A 100 "vars:" ${k3sAnsiblePath}inventory-sample.yml >> inventory.yml
sed -i "s/ansible_user:.*$/ansible_user: $TF_VAR_user/g" inventory.yml
sed -i "s/k3s_version:.*$/k3s_version: $k3s_version/g" inventory.yml
sed -i "s/token:.*$/token: $k3s_token/g" inventory.yml
sed -i "s/# extra_server_args:.*$/extra_server_args: $k3s_server_args/g" inventory.yml

echo "Please edit inventory.yml and change the values to your own."
read -p "Press Enter to start editing..."
${EDITOR:-nano} "inventory.yml"
cp -af inventory.yml ${k3sAnsiblePath}inventory.yml
cd "$k3sAnsiblePath"
ansible-playbook "$reset_path" -i inventory.yml
cd "$k3sPath"
rm -f inventory.yml