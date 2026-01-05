#!/bin/bash
set -eo pipefail
. var.sh
. check.sh
rm -f inventory.yml
echo "---" >> inventory.yml
echo "k3s_cluster_scaling:" >> inventory.yml
echo "  children:" >> inventory.yml
echo "    server:" >> inventory.yml
echo "      hosts:" >> inventory.yml
echo "        $(kubectl get nodes --selector='node-role.kubernetes.io/control-plane=true' -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):"  >> inventory.yml
echo "    server_scaling:" >> inventory.yml
echo "      hosts:" >> inventory.yml
server_scaling_ips=$(printf '%s\n' $(env | grep -o "^k3s_server_scaling_ips[0-9]*") | sort -t'v' -k2,2n | tail -1)
if [ -n "$server_scaling_ips" ] && [ "${!server_scaling_ips}" != '[]' ]; then
  echo "        $(kubectl get nodes --selector='node-role.kubernetes.io/control-plane=true' -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'):"  >> inventory.yml
  echo "        ${!server_scaling_ips}" | sed 's/[][]//g; s/"//g; s/,/:\n        /g; s/$/:/' >> inventory.yml
fi
echo "    agent_scaling:" >> inventory.yml
echo "      hosts:" >> inventory.yml
agent_scaling_ips=$(printf '%s\n' $(env | grep -o "^k3s_agent_scaling_ips[0-9]*") | sort -t'v' -k2,2n | tail -1)
if [ -n "$agent_scaling_ips" ] && [ "${!agent_scaling_ips}" != "[]" ]; then
  echo "        ${!agent_scaling_ips}" | sed 's/[][]//g; s/"//g; s/,/:\n        /g; s/$/:/' >> inventory.yml
fi
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
ansible-playbook playbooks/scaling.yml -i inventory.yml
cd "$k3sPath"

. kubectl.sh