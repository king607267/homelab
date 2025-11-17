#!/bin/bash
set -eo pipefail
if ! command -v direnv &> /dev/null; then
    echo "Please install direnv https://github.com/direnv/direnv/blob/master/docs/installation.md"
    echo "hook into your shell. https://github.com/direnv/direnv/blob/master/docs/hook.md#setup"
    echo "sudo apt update && sudo apt install direnv && echo 'eval \"\$(direnv hook bash)\"' >> ~/.bashrc && source ~/.bashrc"
    exit 1
fi

if ! command -v ansible &> /dev/null; then
  echo "Please install ansible2.11+, https://technotim.live/posts/ansible-automation/#installing-the-latest-version-of-ansible"
  echo "curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py && python3 -m pip -V && echo 'export PATH=\"/home/`whoami`/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc && python3 -m pip install netaddr && python3 -m pip install --user ansible"
  exit 1
fi

if [ -f "../../.envrc_changeme" ]; then
  echo "Please edit ../../.envrc_changeme and change the values to your own. rename to .envrc  run again"
  exit 1
fi

k3s_ansible="./k3s_ansible/"
if [ -n "$install_vms" ]; then
  cd ../vms
  ./install.sh
  cd ../k3s
fi

if [ ! -d "$k3s_ansible" ]; then
  git clone https://github.com/king607267/k3s-ansible.git ${k3s_ansible}
else
  git -C ${k3s_ansible} pull
fi

ansible-galaxy collection install -r ${k3s_ansible}/collections/requirements.yml

all_path=${k3s_ansible}inventory/my-cluster/group_vars/all.yml

if [ ! -f "all_changeme.yml" ]; then
  cp -af ${k3s_ansible}inventory/sample/group_vars/all.yml all_changeme.yml
  echo "Please edit all_changeme.yml,.envrc and change the values to your own. run again"
  echo "nano all_changeme.yml"
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
ansible-playbook ${k3s_ansible}site.yml -i $hosts_path

for ip in $TF_VAR_master_ips; do
  ssh -o LogLevel=FATAL -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "${TF_VAR_user}"@$(echo $ip | sed 's/[][]//g; s/"//g; s/,//g') 'sudo cat /etc/rancher/k3s/k3s.yaml' > ./k3s.yaml
  break
done

sed -i "s|127.0.0.1|$(cat $all_path | grep apiserver_endpoint: | awk '{print $2}')|" ./k3s.yaml