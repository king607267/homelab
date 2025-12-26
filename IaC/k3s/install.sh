#!/bin/bash
set -eo pipefail
. var.sh
. check.sh
rm -f inventory.yml
echo "---" >> inventory.yml
echo "k3s_cluster:" >> inventory.yml
echo "  children:" >> inventory.yml
echo "    server:" >> inventory.yml
echo "      hosts:" >> inventory.yml
#判断TF_VAR_master_ips不为空并且不为[]
if [ -n "$TF_VAR_master_ips" ] && [ "$TF_VAR_master_ips" != "[]" ]; then
echo "        $TF_VAR_master_ips" | sed 's/[][]//g; s/"//g; s/,/:\n        /g; s/$/:/' >> inventory.yml
fi
echo "    agent:" >> inventory.yml
echo "      hosts:" >> inventory.yml
if [ -n "$TF_VAR_node_ips" ] && [ "$TF_VAR_node_ips" != "[]" ]; then
echo "        $TF_VAR_node_ips" | sed 's/[][]//g; s/"//g; s/,/:\n        /g; s/$/:/' >> inventory.yml
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
ansible-playbook playbooks/site.yml -i inventory.yml
cd "$k3sPath"

master_ip=$(echo "$TF_VAR_master_ips" | sed 's/[][]//g; s/"//g;'| awk -F',' '{print $1}')
ssh -o LogLevel=FATAL -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "${TF_VAR_user}"@"$master_ip" 'sudo cat /etc/rancher/k3s/k3s.yaml' > "$kubeConfigPath"
if [ -f "$kubeConfigPath" ]; then
  sed -i "s|127.0.0.1|$master_ip|" "$kubeConfigPath"
fi
. kubectl.sh