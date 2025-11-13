#!/bin/bash
set -eo pipefail
k3s_ansible="./k3s_ansible/"
if [ -n "$install_vms" ]; then
  sudo snap install --classic opentofu
  cd ../vms
  tofu init
  tofu destroy --auto-approve
  tofu apply --auto-approve
  cd ../k3s
fi

if [ ! -d "${k3s_ansible}" ]; then
  git clone https://github.com/king607267/k3s-ansible.git ${k3s_ansible}
else
  git -C ${k3s_ansible} pull
fi

#install requirements
ansible-galaxy collection install -r ${k3s_ansible}/collections/requirements.yml

all_path=${k3s_ansible}inventory/my-cluster/group_vars/all.yml

if [ ! -f "all_changeme.yml" ]; then
  cp -af ${k3s_ansible}inventory/sample/group_vars/all.yml all_changeme.yml
  echo "Please edit all_changeme.yml and change the values to your own. run again"
  exit 0
fi

cp -af ${k3s_ansible}inventory/sample ${k3s_ansible}inventory/my-cluster
cp -af all_changeme.yml  $all_path

hosts_path=${k3s_ansible}inventory/my-cluster/hosts.ini
echo "[master]" > "${hosts_path}"
for ip in $TF_VAR_master_ips; do
  echo "$ip"  | sed 's/[][]//g; s/"//g; s/,/\n/g' >> "${hosts_path}"
done
echo "" >> "${hosts_path}"
echo "[node]" >> "${hosts_path}"
for ip in $TF_VAR_node_ips; do
  echo "$ip"  | sed 's/[][]//g; s/"//g; s/,/\n/g' >> "${hosts_path}"
done

echo "" >> "${hosts_path}"
echo "[k3s_cluster:children]" >> "${hosts_path}"
echo "master" >> "${hosts_path}"
echo "node" >> "${hosts_path}"

cp -af ${k3s_ansible}ansible.example.cfg  ${k3s_ansible}ansible.cfg

ansible-playbook ${k3s_ansible}site.yml -i $hosts_path --ask-become-pass

for ip in $TF_VAR_master_ips; do
  ssh -o LogLevel=FATAL -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "${TF_VAR_user}"@$(echo $ip | sed 's/[][]//g; s/"//g; s/,//g') 'sudo cat /etc/rancher/k3s/k3s.yaml' > ./k3s.yaml
  break
done

sed -i "s|127.0.0.1|$(cat $all_path | grep apiserver_endpoint: | awk '{print $2}')|" ./k3s.yaml