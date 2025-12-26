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
echo "        $TF_VAR_master_ips" | sed 's/[][]//g; s/"//g; s/,/:\n        /g; s/$/:/' >> inventory.yml
echo "    server_scaling:" >> inventory.yml
echo "      hosts:" >> inventory.yml
echo "        $TF_VAR_master_ips" | sed 's/[][]//g; s/"//g; s/,/:\n        /g; s/$/:/' >> inventory.yml
echo "    agent_scaling:" >> inventory.yml
echo "      hosts:" >> inventory.yml
if [ -n "$k3s_agent_scaling_ips1" ] && [ "$k3s_agent_scaling_ips1" != "[]" ]; then
  agent_scaling_ips=$(printf '%s\n' $(env | grep -o "^k3s_agent_scaling_ips1[0-9]*") | sort -t'v' -k2,2n | tail -1)
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